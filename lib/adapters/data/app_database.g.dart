// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TransactionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
      'amount', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
      'date', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _partyMeta = const VerificationMeta('party');
  @override
  late final GeneratedColumn<String> party = GeneratedColumn<String>(
      'party', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isCreditMeta =
      const VerificationMeta('isCredit');
  @override
  late final GeneratedColumn<bool> isCredit = GeneratedColumn<bool>(
      'is_credit', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_credit" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _smsIdMeta = const VerificationMeta('smsId');
  @override
  late final GeneratedColumn<String> smsId = GeneratedColumn<String>(
      'sms_id', aliasedName, true,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _smsBodyMeta =
      const VerificationMeta('smsBody');
  @override
  late final GeneratedColumn<String> smsBody = GeneratedColumn<String>(
      'sms_body', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> tags =
      GeneratedColumn<String>('tags', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($TransactionsTable.$convertertags);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> groups =
      GeneratedColumn<String>('groups', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<List<String>>($TransactionsTable.$convertergroups);
  @override
  List<GeneratedColumn> get $columns =>
      [id, amount, date, party, isCredit, note, smsId, smsBody, tags, groups];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(Insertable<TransactionRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('amount')) {
      context.handle(_amountMeta,
          amount.isAcceptableOrUnknown(data['amount']!, _amountMeta));
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('party')) {
      context.handle(
          _partyMeta, party.isAcceptableOrUnknown(data['party']!, _partyMeta));
    } else if (isInserting) {
      context.missing(_partyMeta);
    }
    if (data.containsKey('is_credit')) {
      context.handle(_isCreditMeta,
          isCredit.isAcceptableOrUnknown(data['is_credit']!, _isCreditMeta));
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('sms_id')) {
      context.handle(
          _smsIdMeta, smsId.isAcceptableOrUnknown(data['sms_id']!, _smsIdMeta));
    }
    if (data.containsKey('sms_body')) {
      context.handle(_smsBodyMeta,
          smsBody.isAcceptableOrUnknown(data['sms_body']!, _smsBodyMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TransactionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TransactionRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      amount: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}amount'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}date'])!,
      party: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}party'])!,
      isCredit: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_credit'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      smsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_id']),
      smsBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_body']),
      tags: $TransactionsTable.$convertertags.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}tags'])!),
      groups: $TransactionsTable.$convertergroups.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}groups'])!),
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<List<String>, String, List<dynamic>>
      $convertertags = const StringListConverter();
  static JsonTypeConverter2<List<String>, String, List<dynamic>>
      $convertergroups = const StringListConverter();
}

class TransactionRow extends DataClass implements Insertable<TransactionRow> {
  final int id;
  final double amount;
  final DateTime date;
  final String party;
  final bool isCredit;
  final String? note;

  /// Raw-SMS identity of auto-imported records; null for manual entries.
  ///
  /// Unique, so import idempotency is a schema invariant rather than a
  /// read-then-write check. SQLite treats NULLs as distinct, so any number of
  /// manual entries coexist.
  final String? smsId;
  final String? smsBody;
  final List<String> tags;
  final List<String> groups;
  const TransactionRow(
      {required this.id,
      required this.amount,
      required this.date,
      required this.party,
      required this.isCredit,
      this.note,
      this.smsId,
      this.smsBody,
      required this.tags,
      required this.groups});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['party'] = Variable<String>(party);
    map['is_credit'] = Variable<bool>(isCredit);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || smsId != null) {
      map['sms_id'] = Variable<String>(smsId);
    }
    if (!nullToAbsent || smsBody != null) {
      map['sms_body'] = Variable<String>(smsBody);
    }
    {
      map['tags'] =
          Variable<String>($TransactionsTable.$convertertags.toSql(tags));
    }
    {
      map['groups'] =
          Variable<String>($TransactionsTable.$convertergroups.toSql(groups));
    }
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      amount: Value(amount),
      date: Value(date),
      party: Value(party),
      isCredit: Value(isCredit),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      smsId:
          smsId == null && nullToAbsent ? const Value.absent() : Value(smsId),
      smsBody: smsBody == null && nullToAbsent
          ? const Value.absent()
          : Value(smsBody),
      tags: Value(tags),
      groups: Value(groups),
    );
  }

  factory TransactionRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TransactionRow(
      id: serializer.fromJson<int>(json['id']),
      amount: serializer.fromJson<double>(json['amount']),
      date: serializer.fromJson<DateTime>(json['date']),
      party: serializer.fromJson<String>(json['party']),
      isCredit: serializer.fromJson<bool>(json['isCredit']),
      note: serializer.fromJson<String?>(json['note']),
      smsId: serializer.fromJson<String?>(json['smsId']),
      smsBody: serializer.fromJson<String?>(json['smsBody']),
      tags: $TransactionsTable.$convertertags
          .fromJson(serializer.fromJson<List<dynamic>>(json['tags'])),
      groups: $TransactionsTable.$convertergroups
          .fromJson(serializer.fromJson<List<dynamic>>(json['groups'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'party': serializer.toJson<String>(party),
      'isCredit': serializer.toJson<bool>(isCredit),
      'note': serializer.toJson<String?>(note),
      'smsId': serializer.toJson<String?>(smsId),
      'smsBody': serializer.toJson<String?>(smsBody),
      'tags': serializer.toJson<List<dynamic>>(
          $TransactionsTable.$convertertags.toJson(tags)),
      'groups': serializer.toJson<List<dynamic>>(
          $TransactionsTable.$convertergroups.toJson(groups)),
    };
  }

  TransactionRow copyWith(
          {int? id,
          double? amount,
          DateTime? date,
          String? party,
          bool? isCredit,
          Value<String?> note = const Value.absent(),
          Value<String?> smsId = const Value.absent(),
          Value<String?> smsBody = const Value.absent(),
          List<String>? tags,
          List<String>? groups}) =>
      TransactionRow(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        date: date ?? this.date,
        party: party ?? this.party,
        isCredit: isCredit ?? this.isCredit,
        note: note.present ? note.value : this.note,
        smsId: smsId.present ? smsId.value : this.smsId,
        smsBody: smsBody.present ? smsBody.value : this.smsBody,
        tags: tags ?? this.tags,
        groups: groups ?? this.groups,
      );
  TransactionRow copyWithCompanion(TransactionsCompanion data) {
    return TransactionRow(
      id: data.id.present ? data.id.value : this.id,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      party: data.party.present ? data.party.value : this.party,
      isCredit: data.isCredit.present ? data.isCredit.value : this.isCredit,
      note: data.note.present ? data.note.value : this.note,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      smsBody: data.smsBody.present ? data.smsBody.value : this.smsBody,
      tags: data.tags.present ? data.tags.value : this.tags,
      groups: data.groups.present ? data.groups.value : this.groups,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TransactionRow(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('party: $party, ')
          ..write('isCredit: $isCredit, ')
          ..write('note: $note, ')
          ..write('smsId: $smsId, ')
          ..write('smsBody: $smsBody, ')
          ..write('tags: $tags, ')
          ..write('groups: $groups')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, amount, date, party, isCredit, note, smsId, smsBody, tags, groups);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TransactionRow &&
          other.id == this.id &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.party == this.party &&
          other.isCredit == this.isCredit &&
          other.note == this.note &&
          other.smsId == this.smsId &&
          other.smsBody == this.smsBody &&
          other.tags == this.tags &&
          other.groups == this.groups);
}

class TransactionsCompanion extends UpdateCompanion<TransactionRow> {
  final Value<int> id;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> party;
  final Value<bool> isCredit;
  final Value<String?> note;
  final Value<String?> smsId;
  final Value<String?> smsBody;
  final Value<List<String>> tags;
  final Value<List<String>> groups;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.party = const Value.absent(),
    this.isCredit = const Value.absent(),
    this.note = const Value.absent(),
    this.smsId = const Value.absent(),
    this.smsBody = const Value.absent(),
    this.tags = const Value.absent(),
    this.groups = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required double amount,
    required DateTime date,
    required String party,
    this.isCredit = const Value.absent(),
    this.note = const Value.absent(),
    this.smsId = const Value.absent(),
    this.smsBody = const Value.absent(),
    required List<String> tags,
    required List<String> groups,
  })  : amount = Value(amount),
        date = Value(date),
        party = Value(party),
        tags = Value(tags),
        groups = Value(groups);
  static Insertable<TransactionRow> custom({
    Expression<int>? id,
    Expression<double>? amount,
    Expression<DateTime>? date,
    Expression<String>? party,
    Expression<bool>? isCredit,
    Expression<String>? note,
    Expression<String>? smsId,
    Expression<String>? smsBody,
    Expression<String>? tags,
    Expression<String>? groups,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (party != null) 'party': party,
      if (isCredit != null) 'is_credit': isCredit,
      if (note != null) 'note': note,
      if (smsId != null) 'sms_id': smsId,
      if (smsBody != null) 'sms_body': smsBody,
      if (tags != null) 'tags': tags,
      if (groups != null) 'groups': groups,
    });
  }

  TransactionsCompanion copyWith(
      {Value<int>? id,
      Value<double>? amount,
      Value<DateTime>? date,
      Value<String>? party,
      Value<bool>? isCredit,
      Value<String?>? note,
      Value<String?>? smsId,
      Value<String?>? smsBody,
      Value<List<String>>? tags,
      Value<List<String>>? groups}) {
    return TransactionsCompanion(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      party: party ?? this.party,
      isCredit: isCredit ?? this.isCredit,
      note: note ?? this.note,
      smsId: smsId ?? this.smsId,
      smsBody: smsBody ?? this.smsBody,
      tags: tags ?? this.tags,
      groups: groups ?? this.groups,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (party.present) {
      map['party'] = Variable<String>(party.value);
    }
    if (isCredit.present) {
      map['is_credit'] = Variable<bool>(isCredit.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (smsBody.present) {
      map['sms_body'] = Variable<String>(smsBody.value);
    }
    if (tags.present) {
      map['tags'] =
          Variable<String>($TransactionsTable.$convertertags.toSql(tags.value));
    }
    if (groups.present) {
      map['groups'] = Variable<String>(
          $TransactionsTable.$convertergroups.toSql(groups.value));
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('party: $party, ')
          ..write('isCredit: $isCredit, ')
          ..write('note: $note, ')
          ..write('smsId: $smsId, ')
          ..write('smsBody: $smsBody, ')
          ..write('tags: $tags, ')
          ..write('groups: $groups')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [transactions];
}

typedef $$TransactionsTableCreateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  required double amount,
  required DateTime date,
  required String party,
  Value<bool> isCredit,
  Value<String?> note,
  Value<String?> smsId,
  Value<String?> smsBody,
  required List<String> tags,
  required List<String> groups,
});
typedef $$TransactionsTableUpdateCompanionBuilder = TransactionsCompanion
    Function({
  Value<int> id,
  Value<double> amount,
  Value<DateTime> date,
  Value<String> party,
  Value<bool> isCredit,
  Value<String?> note,
  Value<String?> smsId,
  Value<String?> smsBody,
  Value<List<String>> tags,
  Value<List<String>> groups,
});

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get party => $composableBuilder(
      column: $table.party, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCredit => $composableBuilder(
      column: $table.isCredit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsId => $composableBuilder(
      column: $table.smsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String> get tags =>
      $composableBuilder(
          column: $table.tags,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get groups => $composableBuilder(
          column: $table.groups,
          builder: (column) => ColumnWithTypeConverterFilters(column));
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get amount => $composableBuilder(
      column: $table.amount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get party => $composableBuilder(
      column: $table.party, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCredit => $composableBuilder(
      column: $table.isCredit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsId => $composableBuilder(
      column: $table.smsId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tags => $composableBuilder(
      column: $table.tags, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groups => $composableBuilder(
      column: $table.groups, builder: (column) => ColumnOrderings(column));
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get party =>
      $composableBuilder(column: $table.party, builder: (column) => column);

  GeneratedColumn<bool> get isCredit =>
      $composableBuilder(column: $table.isCredit, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get smsId =>
      $composableBuilder(column: $table.smsId, builder: (column) => column);

  GeneratedColumn<String> get smsBody =>
      $composableBuilder(column: $table.smsBody, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get tags =>
      $composableBuilder(column: $table.tags, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get groups =>
      $composableBuilder(column: $table.groups, builder: (column) => column);
}

class $$TransactionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()> {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<double> amount = const Value.absent(),
            Value<DateTime> date = const Value.absent(),
            Value<String> party = const Value.absent(),
            Value<bool> isCredit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> smsId = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
            Value<List<String>> tags = const Value.absent(),
            Value<List<String>> groups = const Value.absent(),
          }) =>
              TransactionsCompanion(
            id: id,
            amount: amount,
            date: date,
            party: party,
            isCredit: isCredit,
            note: note,
            smsId: smsId,
            smsBody: smsBody,
            tags: tags,
            groups: groups,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required double amount,
            required DateTime date,
            required String party,
            Value<bool> isCredit = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<String?> smsId = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
            required List<String> tags,
            required List<String> groups,
          }) =>
              TransactionsCompanion.insert(
            id: id,
            amount: amount,
            date: date,
            party: party,
            isCredit: isCredit,
            note: note,
            smsId: smsId,
            smsBody: smsBody,
            tags: tags,
            groups: groups,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TransactionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TransactionsTable,
    TransactionRow,
    $$TransactionsTableFilterComposer,
    $$TransactionsTableOrderingComposer,
    $$TransactionsTableAnnotationComposer,
    $$TransactionsTableCreateCompanionBuilder,
    $$TransactionsTableUpdateCompanionBuilder,
    (
      TransactionRow,
      BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow>
    ),
    TransactionRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
}
