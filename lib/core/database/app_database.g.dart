// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurveysTableTable extends SurveysTable
    with TableInfo<$SurveysTableTable, SurveyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveysTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sectionsJsonMeta = const VerificationMeta(
    'sectionsJson',
  );
  @override
  late final GeneratedColumn<String> sectionsJson = GeneratedColumn<String>(
    'sections_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    sectionsJson,
    updatedAt,
    fetchedAt,
    isActive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surveys_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('sections_json')) {
      context.handle(
        _sectionsJsonMeta,
        sectionsJson.isAcceptableOrUnknown(
          data['sections_json']!,
          _sectionsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sectionsJsonMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      sectionsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sections_json'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  $SurveysTableTable createAlias(String alias) {
    return $SurveysTableTable(attachedDatabase, alias);
  }
}

class SurveyRow extends DataClass implements Insertable<SurveyRow> {
  final String id;
  final String title;
  final String? description;

  /// The survey's [SurveySection] list (each with its nested questions),
  /// as JSON — see the class doc for why this whole tree is one blob
  /// rather than normalized tables.
  final String sectionsJson;
  final DateTime updatedAt;
  final DateTime fetchedAt;
  final bool isActive;
  const SurveyRow({
    required this.id,
    required this.title,
    this.description,
    required this.sectionsJson,
    required this.updatedAt,
    required this.fetchedAt,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['sections_json'] = Variable<String>(sectionsJson);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  SurveysTableCompanion toCompanion(bool nullToAbsent) {
    return SurveysTableCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      sectionsJson: Value(sectionsJson),
      updatedAt: Value(updatedAt),
      fetchedAt: Value(fetchedAt),
      isActive: Value(isActive),
    );
  }

  factory SurveyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      sectionsJson: serializer.fromJson<String>(json['sectionsJson']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
      isActive: serializer.fromJson<bool>(json['isActive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'sectionsJson': serializer.toJson<String>(sectionsJson),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
      'isActive': serializer.toJson<bool>(isActive),
    };
  }

  SurveyRow copyWith({
    String? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? sectionsJson,
    DateTime? updatedAt,
    DateTime? fetchedAt,
    bool? isActive,
  }) => SurveyRow(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    sectionsJson: sectionsJson ?? this.sectionsJson,
    updatedAt: updatedAt ?? this.updatedAt,
    fetchedAt: fetchedAt ?? this.fetchedAt,
    isActive: isActive ?? this.isActive,
  );
  SurveyRow copyWithCompanion(SurveysTableCompanion data) {
    return SurveyRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      sectionsJson: data.sectionsJson.present
          ? data.sectionsJson.value
          : this.sectionsJson,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    sectionsJson,
    updatedAt,
    fetchedAt,
    isActive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.sectionsJson == this.sectionsJson &&
          other.updatedAt == this.updatedAt &&
          other.fetchedAt == this.fetchedAt &&
          other.isActive == this.isActive);
}

class SurveysTableCompanion extends UpdateCompanion<SurveyRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> sectionsJson;
  final Value<DateTime> updatedAt;
  final Value<DateTime> fetchedAt;
  final Value<bool> isActive;
  final Value<int> rowid;
  const SurveysTableCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.sectionsJson = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveysTableCompanion.insert({
    required String id,
    required String title,
    this.description = const Value.absent(),
    required String sectionsJson,
    required DateTime updatedAt,
    required DateTime fetchedAt,
    this.isActive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       sectionsJson = Value(sectionsJson),
       updatedAt = Value(updatedAt),
       fetchedAt = Value(fetchedAt);
  static Insertable<SurveyRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? sectionsJson,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? fetchedAt,
    Expression<bool>? isActive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (sectionsJson != null) 'sections_json': sectionsJson,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (isActive != null) 'is_active': isActive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveysTableCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? sectionsJson,
    Value<DateTime>? updatedAt,
    Value<DateTime>? fetchedAt,
    Value<bool>? isActive,
    Value<int>? rowid,
  }) {
    return SurveysTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      sectionsJson: sectionsJson ?? this.sectionsJson,
      updatedAt: updatedAt ?? this.updatedAt,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      isActive: isActive ?? this.isActive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (sectionsJson.present) {
      map['sections_json'] = Variable<String>(sectionsJson.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveysTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('sectionsJson: $sectionsJson, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('isActive: $isActive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyResponsesTableTable extends SurveyResponsesTable
    with TableInfo<$SurveyResponsesTableTable, SurveyResponseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyResponsesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surveyIdMeta = const VerificationMeta(
    'surveyId',
  );
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
    'survey_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _surveyTitleMeta = const VerificationMeta(
    'surveyTitle',
  );
  @override
  late final GeneratedColumn<String> surveyTitle = GeneratedColumn<String>(
    'survey_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answersJsonMeta = const VerificationMeta(
    'answersJson',
  );
  @override
  late final GeneratedColumn<String> answersJson = GeneratedColumn<String>(
    'answers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('draft'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _submittedAtMeta = const VerificationMeta(
    'submittedAt',
  );
  @override
  late final GeneratedColumn<DateTime> submittedAt = GeneratedColumn<DateTime>(
    'submitted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surveyorIdMeta = const VerificationMeta(
    'surveyorId',
  );
  @override
  late final GeneratedColumn<String> surveyorId = GeneratedColumn<String>(
    'surveyor_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _surveyorNameMeta = const VerificationMeta(
    'surveyorName',
  );
  @override
  late final GeneratedColumn<String> surveyorName = GeneratedColumn<String>(
    'surveyor_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _appVersionMeta = const VerificationMeta(
    'appVersion',
  );
  @override
  late final GeneratedColumn<String> appVersion = GeneratedColumn<String>(
    'app_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localId,
    serverId,
    surveyId,
    surveyTitle,
    answersJson,
    status,
    createdAt,
    updatedAt,
    submittedAt,
    syncedAt,
    retryCount,
    lastError,
    surveyorId,
    surveyorName,
    startedAt,
    latitude,
    longitude,
    appVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_responses_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurveyResponseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    } else if (isInserting) {
      context.missing(_localIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('survey_id')) {
      context.handle(
        _surveyIdMeta,
        surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta),
      );
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('survey_title')) {
      context.handle(
        _surveyTitleMeta,
        surveyTitle.isAcceptableOrUnknown(
          data['survey_title']!,
          _surveyTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surveyTitleMeta);
    }
    if (data.containsKey('answers_json')) {
      context.handle(
        _answersJsonMeta,
        answersJson.isAcceptableOrUnknown(
          data['answers_json']!,
          _answersJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_answersJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('submitted_at')) {
      context.handle(
        _submittedAtMeta,
        submittedAt.isAcceptableOrUnknown(
          data['submitted_at']!,
          _submittedAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('surveyor_id')) {
      context.handle(
        _surveyorIdMeta,
        surveyorId.isAcceptableOrUnknown(data['surveyor_id']!, _surveyorIdMeta),
      );
    }
    if (data.containsKey('surveyor_name')) {
      context.handle(
        _surveyorNameMeta,
        surveyorName.isAcceptableOrUnknown(
          data['surveyor_name']!,
          _surveyorNameMeta,
        ),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('app_version')) {
      context.handle(
        _appVersionMeta,
        appVersion.isAcceptableOrUnknown(data['app_version']!, _appVersionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localId};
  @override
  SurveyResponseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyResponseRow(
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      surveyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_id'],
      )!,
      surveyTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}survey_title'],
      )!,
      answersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answers_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      submittedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}submitted_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      surveyorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surveyor_id'],
      ),
      surveyorName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surveyor_name'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      appVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}app_version'],
      ),
    );
  }

  @override
  $SurveyResponsesTableTable createAlias(String alias) {
    return $SurveyResponsesTableTable(attachedDatabase, alias);
  }
}

class SurveyResponseRow extends DataClass
    implements Insertable<SurveyResponseRow> {
  /// Client-generated UUID. This is the row's real identity — a draft or
  /// pending response has no server id yet, and using a stable local id
  /// (instead of, say, an autoincrement int) means a response created
  /// offline can be safely retried/deduplicated once it does reach the
  /// server (send it as the idempotency key).
  final String localId;
  final String? serverId;
  final String surveyId;

  /// Snapshot of the survey title at fill time, so the Sync Center can
  /// always show something meaningful even if the survey cache is later
  /// replaced or the survey is no longer active.
  final String surveyTitle;

  /// `{ questionId: answerValue }`. Answer shapes vary by question type —
  /// text, a string list, or a number — decoded into typed answers at the
  /// `data/` layer boundary (see `survey_local_datasource.dart`).
  final String answersJson;

  /// [SyncStatus] name: draft | pending | syncing | synced | failed.
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? syncedAt;
  final int retryCount;
  final String? lastError;
  final String? surveyorId;
  final String? surveyorName;
  final DateTime? startedAt;
  final double? latitude;
  final double? longitude;
  final String? appVersion;
  const SurveyResponseRow({
    required this.localId,
    this.serverId,
    required this.surveyId,
    required this.surveyTitle,
    required this.answersJson,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.syncedAt,
    required this.retryCount,
    this.lastError,
    this.surveyorId,
    this.surveyorName,
    this.startedAt,
    this.latitude,
    this.longitude,
    this.appVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_id'] = Variable<String>(localId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['survey_id'] = Variable<String>(surveyId);
    map['survey_title'] = Variable<String>(surveyTitle);
    map['answers_json'] = Variable<String>(answersJson);
    map['status'] = Variable<String>(status);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || submittedAt != null) {
      map['submitted_at'] = Variable<DateTime>(submittedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || surveyorId != null) {
      map['surveyor_id'] = Variable<String>(surveyorId);
    }
    if (!nullToAbsent || surveyorName != null) {
      map['surveyor_name'] = Variable<String>(surveyorName);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || appVersion != null) {
      map['app_version'] = Variable<String>(appVersion);
    }
    return map;
  }

  SurveyResponsesTableCompanion toCompanion(bool nullToAbsent) {
    return SurveyResponsesTableCompanion(
      localId: Value(localId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      surveyId: Value(surveyId),
      surveyTitle: Value(surveyTitle),
      answersJson: Value(answersJson),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      submittedAt: submittedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(submittedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      surveyorId: surveyorId == null && nullToAbsent
          ? const Value.absent()
          : Value(surveyorId),
      surveyorName: surveyorName == null && nullToAbsent
          ? const Value.absent()
          : Value(surveyorName),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      appVersion: appVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(appVersion),
    );
  }

  factory SurveyResponseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyResponseRow(
      localId: serializer.fromJson<String>(json['localId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      surveyTitle: serializer.fromJson<String>(json['surveyTitle']),
      answersJson: serializer.fromJson<String>(json['answersJson']),
      status: serializer.fromJson<String>(json['status']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      submittedAt: serializer.fromJson<DateTime?>(json['submittedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      surveyorId: serializer.fromJson<String?>(json['surveyorId']),
      surveyorName: serializer.fromJson<String?>(json['surveyorName']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      appVersion: serializer.fromJson<String?>(json['appVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localId': serializer.toJson<String>(localId),
      'serverId': serializer.toJson<String?>(serverId),
      'surveyId': serializer.toJson<String>(surveyId),
      'surveyTitle': serializer.toJson<String>(surveyTitle),
      'answersJson': serializer.toJson<String>(answersJson),
      'status': serializer.toJson<String>(status),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'submittedAt': serializer.toJson<DateTime?>(submittedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
      'surveyorId': serializer.toJson<String?>(surveyorId),
      'surveyorName': serializer.toJson<String?>(surveyorName),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'appVersion': serializer.toJson<String?>(appVersion),
    };
  }

  SurveyResponseRow copyWith({
    String? localId,
    Value<String?> serverId = const Value.absent(),
    String? surveyId,
    String? surveyTitle,
    String? answersJson,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> submittedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
    Value<String?> surveyorId = const Value.absent(),
    Value<String?> surveyorName = const Value.absent(),
    Value<DateTime?> startedAt = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> appVersion = const Value.absent(),
  }) => SurveyResponseRow(
    localId: localId ?? this.localId,
    serverId: serverId.present ? serverId.value : this.serverId,
    surveyId: surveyId ?? this.surveyId,
    surveyTitle: surveyTitle ?? this.surveyTitle,
    answersJson: answersJson ?? this.answersJson,
    status: status ?? this.status,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    submittedAt: submittedAt.present ? submittedAt.value : this.submittedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
    surveyorId: surveyorId.present ? surveyorId.value : this.surveyorId,
    surveyorName: surveyorName.present ? surveyorName.value : this.surveyorName,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    appVersion: appVersion.present ? appVersion.value : this.appVersion,
  );
  SurveyResponseRow copyWithCompanion(SurveyResponsesTableCompanion data) {
    return SurveyResponseRow(
      localId: data.localId.present ? data.localId.value : this.localId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      surveyTitle: data.surveyTitle.present
          ? data.surveyTitle.value
          : this.surveyTitle,
      answersJson: data.answersJson.present
          ? data.answersJson.value
          : this.answersJson,
      status: data.status.present ? data.status.value : this.status,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      submittedAt: data.submittedAt.present
          ? data.submittedAt.value
          : this.submittedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      surveyorId: data.surveyorId.present
          ? data.surveyorId.value
          : this.surveyorId,
      surveyorName: data.surveyorName.present
          ? data.surveyorName.value
          : this.surveyorName,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      appVersion: data.appVersion.present
          ? data.appVersion.value
          : this.appVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyResponseRow(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('surveyId: $surveyId, ')
          ..write('surveyTitle: $surveyTitle, ')
          ..write('answersJson: $answersJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('surveyorId: $surveyorId, ')
          ..write('surveyorName: $surveyorName, ')
          ..write('startedAt: $startedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('appVersion: $appVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localId,
    serverId,
    surveyId,
    surveyTitle,
    answersJson,
    status,
    createdAt,
    updatedAt,
    submittedAt,
    syncedAt,
    retryCount,
    lastError,
    surveyorId,
    surveyorName,
    startedAt,
    latitude,
    longitude,
    appVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyResponseRow &&
          other.localId == this.localId &&
          other.serverId == this.serverId &&
          other.surveyId == this.surveyId &&
          other.surveyTitle == this.surveyTitle &&
          other.answersJson == this.answersJson &&
          other.status == this.status &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.submittedAt == this.submittedAt &&
          other.syncedAt == this.syncedAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError &&
          other.surveyorId == this.surveyorId &&
          other.surveyorName == this.surveyorName &&
          other.startedAt == this.startedAt &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.appVersion == this.appVersion);
}

class SurveyResponsesTableCompanion extends UpdateCompanion<SurveyResponseRow> {
  final Value<String> localId;
  final Value<String?> serverId;
  final Value<String> surveyId;
  final Value<String> surveyTitle;
  final Value<String> answersJson;
  final Value<String> status;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> submittedAt;
  final Value<DateTime?> syncedAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<String?> surveyorId;
  final Value<String?> surveyorName;
  final Value<DateTime?> startedAt;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> appVersion;
  final Value<int> rowid;
  const SurveyResponsesTableCompanion({
    this.localId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.surveyTitle = const Value.absent(),
    this.answersJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.submittedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.surveyorId = const Value.absent(),
    this.surveyorName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyResponsesTableCompanion.insert({
    required String localId,
    this.serverId = const Value.absent(),
    required String surveyId,
    required String surveyTitle,
    required String answersJson,
    this.status = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.submittedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.surveyorId = const Value.absent(),
    this.surveyorName = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.appVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localId = Value(localId),
       surveyId = Value(surveyId),
       surveyTitle = Value(surveyTitle),
       answersJson = Value(answersJson),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SurveyResponseRow> custom({
    Expression<String>? localId,
    Expression<String>? serverId,
    Expression<String>? surveyId,
    Expression<String>? surveyTitle,
    Expression<String>? answersJson,
    Expression<String>? status,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? submittedAt,
    Expression<DateTime>? syncedAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<String>? surveyorId,
    Expression<String>? surveyorName,
    Expression<DateTime>? startedAt,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? appVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localId != null) 'local_id': localId,
      if (serverId != null) 'server_id': serverId,
      if (surveyId != null) 'survey_id': surveyId,
      if (surveyTitle != null) 'survey_title': surveyTitle,
      if (answersJson != null) 'answers_json': answersJson,
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (submittedAt != null) 'submitted_at': submittedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (surveyorId != null) 'surveyor_id': surveyorId,
      if (surveyorName != null) 'surveyor_name': surveyorName,
      if (startedAt != null) 'started_at': startedAt,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (appVersion != null) 'app_version': appVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyResponsesTableCompanion copyWith({
    Value<String>? localId,
    Value<String?>? serverId,
    Value<String>? surveyId,
    Value<String>? surveyTitle,
    Value<String>? answersJson,
    Value<String>? status,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? submittedAt,
    Value<DateTime?>? syncedAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<String?>? surveyorId,
    Value<String?>? surveyorName,
    Value<DateTime?>? startedAt,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? appVersion,
    Value<int>? rowid,
  }) {
    return SurveyResponsesTableCompanion(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      surveyId: surveyId ?? this.surveyId,
      surveyTitle: surveyTitle ?? this.surveyTitle,
      answersJson: answersJson ?? this.answersJson,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      surveyorId: surveyorId ?? this.surveyorId,
      surveyorName: surveyorName ?? this.surveyorName,
      startedAt: startedAt ?? this.startedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      appVersion: appVersion ?? this.appVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (surveyTitle.present) {
      map['survey_title'] = Variable<String>(surveyTitle.value);
    }
    if (answersJson.present) {
      map['answers_json'] = Variable<String>(answersJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (submittedAt.present) {
      map['submitted_at'] = Variable<DateTime>(submittedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (surveyorId.present) {
      map['surveyor_id'] = Variable<String>(surveyorId.value);
    }
    if (surveyorName.present) {
      map['surveyor_name'] = Variable<String>(surveyorName.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (appVersion.present) {
      map['app_version'] = Variable<String>(appVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyResponsesTableCompanion(')
          ..write('localId: $localId, ')
          ..write('serverId: $serverId, ')
          ..write('surveyId: $surveyId, ')
          ..write('surveyTitle: $surveyTitle, ')
          ..write('answersJson: $answersJson, ')
          ..write('status: $status, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('submittedAt: $submittedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('surveyorId: $surveyorId, ')
          ..write('surveyorName: $surveyorName, ')
          ..write('startedAt: $startedAt, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('appVersion: $appVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurveysTableTable surveysTable = $SurveysTableTable(this);
  late final $SurveyResponsesTableTable surveyResponsesTable =
      $SurveyResponsesTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    surveysTable,
    surveyResponsesTable,
  ];
}

typedef $$SurveysTableTableCreateCompanionBuilder =
    SurveysTableCompanion Function({
      required String id,
      required String title,
      Value<String?> description,
      required String sectionsJson,
      required DateTime updatedAt,
      required DateTime fetchedAt,
      Value<bool> isActive,
      Value<int> rowid,
    });
typedef $$SurveysTableTableUpdateCompanionBuilder =
    SurveysTableCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> description,
      Value<String> sectionsJson,
      Value<DateTime> updatedAt,
      Value<DateTime> fetchedAt,
      Value<bool> isActive,
      Value<int> rowid,
    });

class $$SurveysTableTableFilterComposer
    extends Composer<_$AppDatabase, $SurveysTableTable> {
  $$SurveysTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurveysTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveysTableTable> {
  $$SurveysTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurveysTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveysTableTable> {
  $$SurveysTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sectionsJson => $composableBuilder(
    column: $table.sectionsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);
}

class $$SurveysTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurveysTableTable,
          SurveyRow,
          $$SurveysTableTableFilterComposer,
          $$SurveysTableTableOrderingComposer,
          $$SurveysTableTableAnnotationComposer,
          $$SurveysTableTableCreateCompanionBuilder,
          $$SurveysTableTableUpdateCompanionBuilder,
          (
            SurveyRow,
            BaseReferences<_$AppDatabase, $SurveysTableTable, SurveyRow>,
          ),
          SurveyRow,
          PrefetchHooks Function()
        > {
  $$SurveysTableTableTableManager(_$AppDatabase db, $SurveysTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveysTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveysTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveysTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> sectionsJson = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveysTableCompanion(
                id: id,
                title: title,
                description: description,
                sectionsJson: sectionsJson,
                updatedAt: updatedAt,
                fetchedAt: fetchedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> description = const Value.absent(),
                required String sectionsJson,
                required DateTime updatedAt,
                required DateTime fetchedAt,
                Value<bool> isActive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveysTableCompanion.insert(
                id: id,
                title: title,
                description: description,
                sectionsJson: sectionsJson,
                updatedAt: updatedAt,
                fetchedAt: fetchedAt,
                isActive: isActive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurveysTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurveysTableTable,
      SurveyRow,
      $$SurveysTableTableFilterComposer,
      $$SurveysTableTableOrderingComposer,
      $$SurveysTableTableAnnotationComposer,
      $$SurveysTableTableCreateCompanionBuilder,
      $$SurveysTableTableUpdateCompanionBuilder,
      (SurveyRow, BaseReferences<_$AppDatabase, $SurveysTableTable, SurveyRow>),
      SurveyRow,
      PrefetchHooks Function()
    >;
typedef $$SurveyResponsesTableTableCreateCompanionBuilder =
    SurveyResponsesTableCompanion Function({
      required String localId,
      Value<String?> serverId,
      required String surveyId,
      required String surveyTitle,
      required String answersJson,
      Value<String> status,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> submittedAt,
      Value<DateTime?> syncedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String?> surveyorId,
      Value<String?> surveyorName,
      Value<DateTime?> startedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> appVersion,
      Value<int> rowid,
    });
typedef $$SurveyResponsesTableTableUpdateCompanionBuilder =
    SurveyResponsesTableCompanion Function({
      Value<String> localId,
      Value<String?> serverId,
      Value<String> surveyId,
      Value<String> surveyTitle,
      Value<String> answersJson,
      Value<String> status,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> submittedAt,
      Value<DateTime?> syncedAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<String?> surveyorId,
      Value<String?> surveyorName,
      Value<DateTime?> startedAt,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<String?> appVersion,
      Value<int> rowid,
    });

class $$SurveyResponsesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTableTable> {
  $$SurveyResponsesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyId => $composableBuilder(
    column: $table.surveyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyTitle => $composableBuilder(
    column: $table.surveyTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyorId => $composableBuilder(
    column: $table.surveyorId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surveyorName => $composableBuilder(
    column: $table.surveyorName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SurveyResponsesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTableTable> {
  $$SurveyResponsesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyId => $composableBuilder(
    column: $table.surveyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyTitle => $composableBuilder(
    column: $table.surveyTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyorId => $composableBuilder(
    column: $table.surveyorId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surveyorName => $composableBuilder(
    column: $table.surveyorName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SurveyResponsesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyResponsesTableTable> {
  $$SurveyResponsesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get surveyTitle => $composableBuilder(
    column: $table.surveyTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get answersJson => $composableBuilder(
    column: $table.answersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get submittedAt => $composableBuilder(
    column: $table.submittedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get surveyorId => $composableBuilder(
    column: $table.surveyorId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surveyorName => $composableBuilder(
    column: $table.surveyorName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get appVersion => $composableBuilder(
    column: $table.appVersion,
    builder: (column) => column,
  );
}

class $$SurveyResponsesTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SurveyResponsesTableTable,
          SurveyResponseRow,
          $$SurveyResponsesTableTableFilterComposer,
          $$SurveyResponsesTableTableOrderingComposer,
          $$SurveyResponsesTableTableAnnotationComposer,
          $$SurveyResponsesTableTableCreateCompanionBuilder,
          $$SurveyResponsesTableTableUpdateCompanionBuilder,
          (
            SurveyResponseRow,
            BaseReferences<
              _$AppDatabase,
              $SurveyResponsesTableTable,
              SurveyResponseRow
            >,
          ),
          SurveyResponseRow,
          PrefetchHooks Function()
        > {
  $$SurveyResponsesTableTableTableManager(
    _$AppDatabase db,
    $SurveyResponsesTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyResponsesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyResponsesTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SurveyResponsesTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> localId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> surveyId = const Value.absent(),
                Value<String> surveyTitle = const Value.absent(),
                Value<String> answersJson = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> surveyorId = const Value.absent(),
                Value<String?> surveyorName = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveyResponsesTableCompanion(
                localId: localId,
                serverId: serverId,
                surveyId: surveyId,
                surveyTitle: surveyTitle,
                answersJson: answersJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                submittedAt: submittedAt,
                syncedAt: syncedAt,
                retryCount: retryCount,
                lastError: lastError,
                surveyorId: surveyorId,
                surveyorName: surveyorName,
                startedAt: startedAt,
                latitude: latitude,
                longitude: longitude,
                appVersion: appVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localId,
                Value<String?> serverId = const Value.absent(),
                required String surveyId,
                required String surveyTitle,
                required String answersJson,
                Value<String> status = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> submittedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> surveyorId = const Value.absent(),
                Value<String?> surveyorName = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> appVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurveyResponsesTableCompanion.insert(
                localId: localId,
                serverId: serverId,
                surveyId: surveyId,
                surveyTitle: surveyTitle,
                answersJson: answersJson,
                status: status,
                createdAt: createdAt,
                updatedAt: updatedAt,
                submittedAt: submittedAt,
                syncedAt: syncedAt,
                retryCount: retryCount,
                lastError: lastError,
                surveyorId: surveyorId,
                surveyorName: surveyorName,
                startedAt: startedAt,
                latitude: latitude,
                longitude: longitude,
                appVersion: appVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SurveyResponsesTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SurveyResponsesTableTable,
      SurveyResponseRow,
      $$SurveyResponsesTableTableFilterComposer,
      $$SurveyResponsesTableTableOrderingComposer,
      $$SurveyResponsesTableTableAnnotationComposer,
      $$SurveyResponsesTableTableCreateCompanionBuilder,
      $$SurveyResponsesTableTableUpdateCompanionBuilder,
      (
        SurveyResponseRow,
        BaseReferences<
          _$AppDatabase,
          $SurveyResponsesTableTable,
          SurveyResponseRow
        >,
      ),
      SurveyResponseRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurveysTableTableTableManager get surveysTable =>
      $$SurveysTableTableTableManager(_db, _db.surveysTable);
  $$SurveyResponsesTableTableTableManager get surveyResponsesTable =>
      $$SurveyResponsesTableTableTableManager(_db, _db.surveyResponsesTable);
}
