# Appmobile-gob — Encuestas Chiapas

App móvil (Flutter) para captura de encuestas del Gobierno de Chiapas, con
**modo offline-first**: las encuestas se descargan y cachean localmente, se
llenan sin conexión, y se sincronizan solas en cuanto vuelve el internet.

## Arquitectura

Clean Architecture, feature-first. Cada feature tiene tres capas y las
dependencias solo apuntan hacia adentro (`presentation → domain ← data`):

```
lib/
  core/                     # Todo lo transversal, sin conocer features
    constants/              # URLs, timeouts, claves de storage
    theme/                  # Colores, tipografía, spacing, ThemeData
    router/                 # go_router (rutas, transiciones)
    network/                # Cliente Dio + mapeo de errores
    database/               # Drift (SQLite) — esquema + queries
    connectivity/           # Detección online/offline
    sync/                   # Motor de sincronización genérico
    utils/                  # Result<T>, logger, helpers responsive
    widgets/                # Botones, estados vacío/error, banner offline
    providers.dart          # Única "raíz de composición" cross-feature

  features/
    auth/                   # Login del encuestador
    surveys/                # Encuestas: listar, llenar, guardar, enviar
    sync/                   # Centro de sincronización
    home/                   # Shell de navegación (bottom nav)
```

Dentro de cada feature: `domain/` (entidades + contratos, Dart puro, sin
Flutter/Drift/Dio), `data/` (implementación con Drift/Dio), `presentation/`
(pantallas + controllers con Riverpod).

## Decisiones técnicas

| Área | Elección | Por qué |
|---|---|---|
| Estado / DI | Riverpod (sin codegen) | Menos boilerplate, testeable, sin magia |
| Base local | Drift sobre SQLite | Tal como pediste — más streams reactivos y tipado que `sqflite` puro |
| Red | Dio | Interceptores para token y logging |
| Navegación | go_router | Deep-linking, transiciones declarativas |
| Sesión | flutter_secure_storage | Token cifrado, nunca en texto plano |

## El flujo offline-first (lo importante)

1. **Descarga:** al abrir la lista, se intenta refrescar contra el backend;
   si funciona, se reemplaza la caché local (`SurveysTable`). Si falla
   (sin señal), se sigue mostrando lo que ya había en SQLite.
2. **Llenado:** cada respuesta se autoguarda en SQLite en cada cambio
   (`SurveyResponsesTable`, estado `draft`) — si matan la app a medio
   llenado, no se pierde nada. Al crear el borrador se capturan folio
   (UUID), encuestador (de la sesión) y, en segundo plano sin bloquear el
   llenado, GPS + versión de app (`core/location/location_service.dart`,
   `core/utils/app_info.dart`) — con fallback silencioso si no hay
   permiso/señal.
3. **Envío:** al enviar, la respuesta pasa a `pending` (esto es 100% local,
   nunca falla) y se intenta un envío inmediato en segundo plano.
4. **Sincronización:** un motor genérico (`core/sync/sync_engine.dart`)
   reintenta lo que siga `pending`/`failed` cuando: vuelve la conexión, cada
   2 minutos como respaldo, o el usuario pulsa "Sincronizar" en el Centro de
   sincronización. Nunca hay una tabla de "cola" separada — el estado de
   cada respuesta *es* la cola. Además, `core/network/retry_interceptor.dart`
   reintenta automáticamente (con backoff corto) errores transitorios de
   una sola petición — complementario al motor de sync, que cubre
   "offline por horas".

### Estructura de una encuesta

`Survey → List<SurveySection> → List<SurveyQuestion>`. El llenado sigue
siendo una pregunta a la vez (mejor para el público objetivo), pero agrupa
por sección en la barra de progreso ("Sección 2 de 3 · Tu experiencia").
Tipos de pregunta soportados (`QuestionType`): texto corto, texto largo,
opción única, opción múltiple (ambas con "Otra, especifica" opcional vía
`allowOther`), escala 1–N, sí/no, fecha, y **matriz Likert** (tarjetas
apiladas en teléfono, tabla real en tablet). Ver
`lib/features/surveys/domain/survey.dart`.

## ⚠️ Antes de conectarlo a tu backend real

El contrato REST en `lib/core/network/api_endpoints.dart` es un placeholder
razonable (`GET /surveys`, `POST /surveys/{id}/responses`, etc.), documentado
ahí mismo. Cuando tengas la API real de la web de encuestas, solo hace falta
tocar:

- `lib/core/network/api_endpoints.dart` (rutas)
- `lib/features/auth/data/auth_remote_datasource.dart`
- `lib/features/surveys/data/survey_remote_datasource.dart`
- `lib/features/surveys/domain/survey.dart` (si el JSON de preguntas trae
  campos distintos a `id/text/type/required/options/scaleMin/scaleMax`)

Nada más se entera del cambio — esa es la idea de tener `domain/` separado.

La URL base se pasa por variable de entorno, no hay que tocar código para
cambiar de ambiente:

```bash
flutter run --dart-define=API_BASE_URL=https://tu-api-real.gob.mx/api
```

## Comandos

```bash
flutter pub get
flutter run                        # con emulador/dispositivo conectado
flutter build apk --release        # APK universal
flutter build apk --split-per-abi  # APKs más livianos por arquitectura
flutter build appbundle            # .aab, lo que pide Play Store
flutter analyze                    # 0 issues al día de hoy
flutter test                       # smoke test de arranque
```

Si tocas `lib/core/database/app_database.dart` (agregar/cambiar tablas),
hay que regenerar el código de Drift:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Qué falta / próximos pasos sugeridos

- Conectar el contrato REST real (ver arriba) — ahora incluye `folio`,
  `surveyorId`/`surveyorName`, `location` y `appVersion` en el body de
  `POST /surveys/{id}/responses`.
- Pantalla "olvidé mi contraseña" si el backend la soporta.
- Captura de foto por pregunta, si alguna encuesta la necesita — mismo
  patrón que los demás `QuestionType`.
- Ícono y nombre de la app todavía son los de plantilla de Flutter.
- Tests unitarios del repositorio/sync engine (hoy solo hay un smoke test
  de arranque).

## Nota sobre el stack sugerido (Isar/BLoC) vs. lo implementado

El documento de requerimientos sugería Isar o sqflite, y BLoC/Cubit o
Riverpod. Se mantuvo **Drift + Riverpod** (ya elegidos y probados en este
proyecto) en vez de migrar a Isar/BLoC: cumplen exactamente el mismo rol
(persistencia offline-first reactiva; estado/DI reactivo), migrar no
aportaría nada funcional y sí arriesgaría reintroducir bugs en código ya
verificado. Si hay una razón de equipo/estándar para forzar Isar o BLoC,
es un cambio acotado (una capa cada uno) y se puede hacer después.
