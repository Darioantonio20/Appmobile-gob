import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/brand_assets.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/brand_grecas_accent.dart';
import '../../../core/widgets/staggered_fade_in.dart';
import 'auth_controller.dart';

/// Login for the encuestador (field surveyor). On success there's nothing
/// left to do here — `appRouterProvider` watches [authControllerProvider]
/// and redirects to the survey list on its own.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(authControllerProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    result.when(
      success: (_) {}, // router redirects automatically
      failure: (failure) => setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      }),
    );
    if (result.isFailure) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // One-shot: shows the backend's own logout confirmation once, right
    // after landing back here, then clears it so it can't reappear on a
    // later rebuild (e.g. rotating the device or hot-reloading).
    ref.listen(logoutMessageProvider, (previous, next) {
      if (next == null) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next)));
      ref.read(logoutMessageProvider.notifier).state = null;
    });

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            const Positioned.fill(child: BrandGrecasAccent()),
            SafeArea(
              child: SingleChildScrollView(
                child: ResponsiveCenter(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.lg),
                        StaggeredFadeSlideIn(
                          index: 0,
                          beginOffset: const Offset(0, 0.15),
                          child: Center(
                            child: Image.asset(
                              BrandAssets.humanismoQueTransforma,
                              height: 148,
                              fit: BoxFit.contain,
                              semanticLabel:
                                  'Humanismo que Transforma — Gobierno de Chiapas 2024–2030',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StaggeredFadeSlideIn(
                          index: 1,
                          child: Text(
                            'Sistema de Encuestas Ciudadanas',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        StaggeredFadeSlideIn(
                          index: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Correo electrónico',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _emailController,
                                autofillHints: const [AutofillHints.email],
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: theme.textTheme.bodyLarge,
                                decoration: const InputDecoration(
                                  hintText: 'tu.correo@chiapas.gob.mx',
                                  prefixIcon: Icon(Icons.mail_outline_rounded),
                                ),
                                onFieldSubmitted: (_) =>
                                    _passwordFocus.requestFocus(),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Ingresa tu correo electrónico.';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Ingresa un correo electrónico válido.';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Contraseña',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              TextFormField(
                                controller: _passwordController,
                                focusNode: _passwordFocus,
                                autofillHints: const [AutofillHints.password],
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                style: theme.textTheme.bodyLarge,
                                decoration: InputDecoration(
                                  hintText: 'Tu contraseña',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Mostrar contraseña'
                                        : 'Ocultar contraseña',
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _submit(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingresa tu contraseña.';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        // AnimatedSize + fade instead of a plain conditional child: a
                        // login error appearing instantly (or the whole form jumping
                        // when it disappears on retry) reads as jarring, especially
                        // for this audience — this grows/shrinks and fades instead.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _errorMessage == null
                              ? const SizedBox(width: double.infinity)
                              : Padding(
                                  padding: const EdgeInsets.only(
                                    top: AppSpacing.md,
                                  ),
                                  child: AnimatedOpacity(
                                    opacity: _errorMessage == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 220),
                                    child: Container(
                                      padding: const EdgeInsets.all(
                                        AppSpacing.md,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radiusMd,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            color: theme
                                                .colorScheme
                                                .onErrorContainer,
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Expanded(
                                            child: Text(
                                              _errorMessage ?? '',
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color: theme
                                                        .colorScheme
                                                        .onErrorContainer,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        StaggeredFadeSlideIn(
                          index: 4,
                          child: AppButton(
                            label: 'Iniciar sesión',
                            isLoading: _isLoading,
                            onPressed: _submit,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        StaggeredFadeSlideIn(
                          index: 5,
                          child: Text(
                            '¿Problemas para ingresar? Comunícate con tu coordinador de campo.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        // Full institutional attribution — the humanismo mark up top
                        // is the app's own recognizable brand; this closes the loop
                        // with exactly which office is behind it.
                        StaggeredFadeSlideIn(
                          index: 6,
                          child: Center(
                            child: Image.asset(
                              BrandAssets.secretaria,
                              height: 52,
                              fit: BoxFit.contain,
                              semanticLabel:
                                  'Secretaría Ejecutiva del Sistema Anticorrupción del Estado de Chiapas',
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
