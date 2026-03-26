// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $UrlsTable extends Urls with TableInfo<$UrlsTable, Url> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UrlsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _slugMeta = const VerificationMeta('slug');
  @override
  late final GeneratedColumn<String> slug = GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 5,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _originalUrlMeta = const VerificationMeta(
    'originalUrl',
  );
  @override
  late final GeneratedColumn<String> originalUrl = GeneratedColumn<String>(
    'original_url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, slug, originalUrl, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'urls';
  @override
  VerificationContext validateIntegrity(
    Insertable<Url> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    if (data.containsKey('original_url')) {
      context.handle(
        _originalUrlMeta,
        originalUrl.isAcceptableOrUnknown(
          data['original_url']!,
          _originalUrlMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalUrlMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Url map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Url(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}id'],
          )!,
      slug:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}slug'],
          )!,
      originalUrl:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}original_url'],
          )!,
      createdAt:
          attachedDatabase.typeMapping.read(
            DriftSqlType.dateTime,
            data['${effectivePrefix}created_at'],
          )!,
    );
  }

  @override
  $UrlsTable createAlias(String alias) {
    return $UrlsTable(attachedDatabase, alias);
  }
}

class Url extends DataClass implements Insertable<Url> {
  final int id;
  final String slug;
  final String originalUrl;
  final DateTime createdAt;
  const Url({
    required this.id,
    required this.slug,
    required this.originalUrl,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['slug'] = Variable<String>(slug);
    map['original_url'] = Variable<String>(originalUrl);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UrlsCompanion toCompanion(bool nullToAbsent) {
    return UrlsCompanion(
      id: Value(id),
      slug: Value(slug),
      originalUrl: Value(originalUrl),
      createdAt: Value(createdAt),
    );
  }

  factory Url.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Url(
      id: serializer.fromJson<int>(json['id']),
      slug: serializer.fromJson<String>(json['slug']),
      originalUrl: serializer.fromJson<String>(json['originalUrl']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'slug': serializer.toJson<String>(slug),
      'originalUrl': serializer.toJson<String>(originalUrl),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Url copyWith({
    int? id,
    String? slug,
    String? originalUrl,
    DateTime? createdAt,
  }) => Url(
    id: id ?? this.id,
    slug: slug ?? this.slug,
    originalUrl: originalUrl ?? this.originalUrl,
    createdAt: createdAt ?? this.createdAt,
  );
  Url copyWithCompanion(UrlsCompanion data) {
    return Url(
      id: data.id.present ? data.id.value : this.id,
      slug: data.slug.present ? data.slug.value : this.slug,
      originalUrl:
          data.originalUrl.present ? data.originalUrl.value : this.originalUrl,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Url(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, slug, originalUrl, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Url &&
          other.id == this.id &&
          other.slug == this.slug &&
          other.originalUrl == this.originalUrl &&
          other.createdAt == this.createdAt);
}

class UrlsCompanion extends UpdateCompanion<Url> {
  final Value<int> id;
  final Value<String> slug;
  final Value<String> originalUrl;
  final Value<DateTime> createdAt;
  const UrlsCompanion({
    this.id = const Value.absent(),
    this.slug = const Value.absent(),
    this.originalUrl = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UrlsCompanion.insert({
    this.id = const Value.absent(),
    required String slug,
    required String originalUrl,
    this.createdAt = const Value.absent(),
  }) : slug = Value(slug),
       originalUrl = Value(originalUrl);
  static Insertable<Url> custom({
    Expression<int>? id,
    Expression<String>? slug,
    Expression<String>? originalUrl,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (slug != null) 'slug': slug,
      if (originalUrl != null) 'original_url': originalUrl,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UrlsCompanion copyWith({
    Value<int>? id,
    Value<String>? slug,
    Value<String>? originalUrl,
    Value<DateTime>? createdAt,
  }) {
    return UrlsCompanion(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      originalUrl: originalUrl ?? this.originalUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (slug.present) {
      map['slug'] = Variable<String>(slug.value);
    }
    if (originalUrl.present) {
      map['original_url'] = Variable<String>(originalUrl.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UrlsCompanion(')
          ..write('id: $id, ')
          ..write('slug: $slug, ')
          ..write('originalUrl: $originalUrl, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UrlsTable urls = $UrlsTable(this);
  late final UrlDao urlDao = UrlDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [urls];
}

typedef $$UrlsTableCreateCompanionBuilder =
    UrlsCompanion Function({
      Value<int> id,
      required String slug,
      required String originalUrl,
      Value<DateTime> createdAt,
    });
typedef $$UrlsTableUpdateCompanionBuilder =
    UrlsCompanion Function({
      Value<int> id,
      Value<String> slug,
      Value<String> originalUrl,
      Value<DateTime> createdAt,
    });

class $$UrlsTableFilterComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UrlsTableOrderingComposer extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UrlsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UrlsTable> {
  $$UrlsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  GeneratedColumn<String> get originalUrl => $composableBuilder(
    column: $table.originalUrl,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UrlsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UrlsTable,
          Url,
          $$UrlsTableFilterComposer,
          $$UrlsTableOrderingComposer,
          $$UrlsTableAnnotationComposer,
          $$UrlsTableCreateCompanionBuilder,
          $$UrlsTableUpdateCompanionBuilder,
          (Url, BaseReferences<_$AppDatabase, $UrlsTable, Url>),
          Url,
          PrefetchHooks Function()
        > {
  $$UrlsTableTableManager(_$AppDatabase db, $UrlsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$UrlsTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$UrlsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$UrlsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> slug = const Value.absent(),
                Value<String> originalUrl = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => UrlsCompanion(
                id: id,
                slug: slug,
                originalUrl: originalUrl,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String slug,
                required String originalUrl,
                Value<DateTime> createdAt = const Value.absent(),
              }) => UrlsCompanion.insert(
                id: id,
                slug: slug,
                originalUrl: originalUrl,
                createdAt: createdAt,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UrlsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UrlsTable,
      Url,
      $$UrlsTableFilterComposer,
      $$UrlsTableOrderingComposer,
      $$UrlsTableAnnotationComposer,
      $$UrlsTableCreateCompanionBuilder,
      $$UrlsTableUpdateCompanionBuilder,
      (Url, BaseReferences<_$AppDatabase, $UrlsTable, Url>),
      Url,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UrlsTableTableManager get urls => $$UrlsTableTableManager(_db, _db.urls);
}
