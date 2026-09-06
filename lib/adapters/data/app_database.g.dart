// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CardsTable extends Cards with TableInfo<$CardsTable, CardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _issuerMeta = const VerificationMeta('issuer');
  @override
  late final GeneratedColumn<String> issuer = GeneratedColumn<String>(
      'issuer', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
      'last4', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _creditLimitMeta =
      const VerificationMeta('creditLimit');
  @override
  late final GeneratedColumn<double> creditLimit = GeneratedColumn<double>(
      'credit_limit', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _nicknameMeta =
      const VerificationMeta('nickname');
  @override
  late final GeneratedColumn<String> nickname = GeneratedColumn<String>(
      'nickname', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, issuer, last4, creditLimit, nickname];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cards';
  @override
  VerificationContext validateIntegrity(Insertable<CardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('issuer')) {
      context.handle(_issuerMeta,
          issuer.isAcceptableOrUnknown(data['issuer']!, _issuerMeta));
    } else if (isInserting) {
      context.missing(_issuerMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
          _last4Meta, last4.isAcceptableOrUnknown(data['last4']!, _last4Meta));
    } else if (isInserting) {
      context.missing(_last4Meta);
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
          _creditLimitMeta,
          creditLimit.isAcceptableOrUnknown(
              data['credit_limit']!, _creditLimitMeta));
    } else if (isInserting) {
      context.missing(_creditLimitMeta);
    }
    if (data.containsKey('nickname')) {
      context.handle(_nicknameMeta,
          nickname.isAcceptableOrUnknown(data['nickname']!, _nicknameMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {issuer, last4},
      ];
  @override
  CardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      issuer: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issuer'])!,
      last4: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last4'])!,
      creditLimit: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}credit_limit'])!,
      nickname: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}nickname']),
    );
  }

  @override
  $CardsTable createAlias(String alias) {
    return $CardsTable(attachedDatabase, alias);
  }
}

class CardRow extends DataClass implements Insertable<CardRow> {
  final int id;
  final String issuer;

  /// 2-4 digits, stored as text so a leading zero survives.
  final String last4;
  final double creditLimit;
  final String? nickname;
  const CardRow(
      {required this.id,
      required this.issuer,
      required this.last4,
      required this.creditLimit,
      this.nickname});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['issuer'] = Variable<String>(issuer);
    map['last4'] = Variable<String>(last4);
    map['credit_limit'] = Variable<double>(creditLimit);
    if (!nullToAbsent || nickname != null) {
      map['nickname'] = Variable<String>(nickname);
    }
    return map;
  }

  CardsCompanion toCompanion(bool nullToAbsent) {
    return CardsCompanion(
      id: Value(id),
      issuer: Value(issuer),
      last4: Value(last4),
      creditLimit: Value(creditLimit),
      nickname: nickname == null && nullToAbsent
          ? const Value.absent()
          : Value(nickname),
    );
  }

  factory CardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardRow(
      id: serializer.fromJson<int>(json['id']),
      issuer: serializer.fromJson<String>(json['issuer']),
      last4: serializer.fromJson<String>(json['last4']),
      creditLimit: serializer.fromJson<double>(json['creditLimit']),
      nickname: serializer.fromJson<String?>(json['nickname']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'issuer': serializer.toJson<String>(issuer),
      'last4': serializer.toJson<String>(last4),
      'creditLimit': serializer.toJson<double>(creditLimit),
      'nickname': serializer.toJson<String?>(nickname),
    };
  }

  CardRow copyWith(
          {int? id,
          String? issuer,
          String? last4,
          double? creditLimit,
          Value<String?> nickname = const Value.absent()}) =>
      CardRow(
        id: id ?? this.id,
        issuer: issuer ?? this.issuer,
        last4: last4 ?? this.last4,
        creditLimit: creditLimit ?? this.creditLimit,
        nickname: nickname.present ? nickname.value : this.nickname,
      );
  CardRow copyWithCompanion(CardsCompanion data) {
    return CardRow(
      id: data.id.present ? data.id.value : this.id,
      issuer: data.issuer.present ? data.issuer.value : this.issuer,
      last4: data.last4.present ? data.last4.value : this.last4,
      creditLimit:
          data.creditLimit.present ? data.creditLimit.value : this.creditLimit,
      nickname: data.nickname.present ? data.nickname.value : this.nickname,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardRow(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('last4: $last4, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('nickname: $nickname')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, issuer, last4, creditLimit, nickname);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardRow &&
          other.id == this.id &&
          other.issuer == this.issuer &&
          other.last4 == this.last4 &&
          other.creditLimit == this.creditLimit &&
          other.nickname == this.nickname);
}

class CardsCompanion extends UpdateCompanion<CardRow> {
  final Value<int> id;
  final Value<String> issuer;
  final Value<String> last4;
  final Value<double> creditLimit;
  final Value<String?> nickname;
  const CardsCompanion({
    this.id = const Value.absent(),
    this.issuer = const Value.absent(),
    this.last4 = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.nickname = const Value.absent(),
  });
  CardsCompanion.insert({
    this.id = const Value.absent(),
    required String issuer,
    required String last4,
    required double creditLimit,
    this.nickname = const Value.absent(),
  })  : issuer = Value(issuer),
        last4 = Value(last4),
        creditLimit = Value(creditLimit);
  static Insertable<CardRow> custom({
    Expression<int>? id,
    Expression<String>? issuer,
    Expression<String>? last4,
    Expression<double>? creditLimit,
    Expression<String>? nickname,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (issuer != null) 'issuer': issuer,
      if (last4 != null) 'last4': last4,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (nickname != null) 'nickname': nickname,
    });
  }

  CardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? issuer,
      Value<String>? last4,
      Value<double>? creditLimit,
      Value<String?>? nickname}) {
    return CardsCompanion(
      id: id ?? this.id,
      issuer: issuer ?? this.issuer,
      last4: last4 ?? this.last4,
      creditLimit: creditLimit ?? this.creditLimit,
      nickname: nickname ?? this.nickname,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (issuer.present) {
      map['issuer'] = Variable<String>(issuer.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<double>(creditLimit.value);
    }
    if (nickname.present) {
      map['nickname'] = Variable<String>(nickname.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardsCompanion(')
          ..write('id: $id, ')
          ..write('issuer: $issuer, ')
          ..write('last4: $last4, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('nickname: $nickname')
          ..write(')'))
        .toString();
  }
}

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
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
      'card_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _cardAvailableLimitMeta =
      const VerificationMeta('cardAvailableLimit');
  @override
  late final GeneratedColumn<double> cardAvailableLimit =
      GeneratedColumn<double>('card_available_limit', aliasedName, true,
          type: DriftSqlType.double, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        amount,
        date,
        party,
        isCredit,
        note,
        smsId,
        smsBody,
        tags,
        groups,
        cardId,
        cardAvailableLimit
      ];
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
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    }
    if (data.containsKey('card_available_limit')) {
      context.handle(
          _cardAvailableLimitMeta,
          cardAvailableLimit.isAcceptableOrUnknown(
              data['card_available_limit']!, _cardAvailableLimitMeta));
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
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}card_id']),
      cardAvailableLimit: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}card_available_limit']),
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

  /// The card this spend/payment belongs to; null for ordinary bank
  /// transactions. `PRAGMA foreign_keys = ON` (see [AppDatabase.migration])
  /// is what actually enforces this reference — SQLite ignores it otherwise.
  final int? cardId;

  /// The available limit reported by this transaction's card SMS, if any.
  /// See `Transaction.cardAvailableLimit`.
  final double? cardAvailableLimit;
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
      required this.groups,
      this.cardId,
      this.cardAvailableLimit});
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
    if (!nullToAbsent || cardId != null) {
      map['card_id'] = Variable<int>(cardId);
    }
    if (!nullToAbsent || cardAvailableLimit != null) {
      map['card_available_limit'] = Variable<double>(cardAvailableLimit);
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
      cardId:
          cardId == null && nullToAbsent ? const Value.absent() : Value(cardId),
      cardAvailableLimit: cardAvailableLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(cardAvailableLimit),
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
      cardId: serializer.fromJson<int?>(json['cardId']),
      cardAvailableLimit:
          serializer.fromJson<double?>(json['cardAvailableLimit']),
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
      'cardId': serializer.toJson<int?>(cardId),
      'cardAvailableLimit': serializer.toJson<double?>(cardAvailableLimit),
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
          List<String>? groups,
          Value<int?> cardId = const Value.absent(),
          Value<double?> cardAvailableLimit = const Value.absent()}) =>
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
        cardId: cardId.present ? cardId.value : this.cardId,
        cardAvailableLimit: cardAvailableLimit.present
            ? cardAvailableLimit.value
            : this.cardAvailableLimit,
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
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      cardAvailableLimit: data.cardAvailableLimit.present
          ? data.cardAvailableLimit.value
          : this.cardAvailableLimit,
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
          ..write('groups: $groups, ')
          ..write('cardId: $cardId, ')
          ..write('cardAvailableLimit: $cardAvailableLimit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, amount, date, party, isCredit, note,
      smsId, smsBody, tags, groups, cardId, cardAvailableLimit);
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
          other.groups == this.groups &&
          other.cardId == this.cardId &&
          other.cardAvailableLimit == this.cardAvailableLimit);
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
  final Value<int?> cardId;
  final Value<double?> cardAvailableLimit;
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
    this.cardId = const Value.absent(),
    this.cardAvailableLimit = const Value.absent(),
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
    this.cardId = const Value.absent(),
    this.cardAvailableLimit = const Value.absent(),
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
    Expression<int>? cardId,
    Expression<double>? cardAvailableLimit,
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
      if (cardId != null) 'card_id': cardId,
      if (cardAvailableLimit != null)
        'card_available_limit': cardAvailableLimit,
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
      Value<List<String>>? groups,
      Value<int?>? cardId,
      Value<double?>? cardAvailableLimit}) {
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
      cardId: cardId ?? this.cardId,
      cardAvailableLimit: cardAvailableLimit ?? this.cardAvailableLimit,
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
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (cardAvailableLimit.present) {
      map['card_available_limit'] = Variable<double>(cardAvailableLimit.value);
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
          ..write('groups: $groups, ')
          ..write('cardId: $cardId, ')
          ..write('cardAvailableLimit: $cardAvailableLimit')
          ..write(')'))
        .toString();
  }
}

class $DetectedCardsTable extends DetectedCards
    with TableInfo<$DetectedCardsTable, DetectedCardRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectedCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _issuerGuessMeta =
      const VerificationMeta('issuerGuess');
  @override
  late final GeneratedColumn<String> issuerGuess = GeneratedColumn<String>(
      'issuer_guess', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _senderMeta = const VerificationMeta('sender');
  @override
  late final GeneratedColumn<String> sender = GeneratedColumn<String>(
      'sender', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _last4Meta = const VerificationMeta('last4');
  @override
  late final GeneratedColumn<String> last4 = GeneratedColumn<String>(
      'last4', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _firstSeenMeta =
      const VerificationMeta('firstSeen');
  @override
  late final GeneratedColumn<DateTime> firstSeen = GeneratedColumn<DateTime>(
      'first_seen', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _lastSeenMeta =
      const VerificationMeta('lastSeen');
  @override
  late final GeneratedColumn<DateTime> lastSeen = GeneratedColumn<DateTime>(
      'last_seen', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sightingCountMeta =
      const VerificationMeta('sightingCount');
  @override
  late final GeneratedColumn<int> sightingCount = GeneratedColumn<int>(
      'sighting_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(1));
  static const VerificationMeta _dismissedMeta =
      const VerificationMeta('dismissed');
  @override
  late final GeneratedColumn<bool> dismissed = GeneratedColumn<bool>(
      'dismissed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("dismissed" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        issuerGuess,
        sender,
        last4,
        firstSeen,
        lastSeen,
        sightingCount,
        dismissed
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detected_cards';
  @override
  VerificationContext validateIntegrity(Insertable<DetectedCardRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('issuer_guess')) {
      context.handle(
          _issuerGuessMeta,
          issuerGuess.isAcceptableOrUnknown(
              data['issuer_guess']!, _issuerGuessMeta));
    } else if (isInserting) {
      context.missing(_issuerGuessMeta);
    }
    if (data.containsKey('sender')) {
      context.handle(_senderMeta,
          sender.isAcceptableOrUnknown(data['sender']!, _senderMeta));
    } else if (isInserting) {
      context.missing(_senderMeta);
    }
    if (data.containsKey('last4')) {
      context.handle(
          _last4Meta, last4.isAcceptableOrUnknown(data['last4']!, _last4Meta));
    } else if (isInserting) {
      context.missing(_last4Meta);
    }
    if (data.containsKey('first_seen')) {
      context.handle(_firstSeenMeta,
          firstSeen.isAcceptableOrUnknown(data['first_seen']!, _firstSeenMeta));
    } else if (isInserting) {
      context.missing(_firstSeenMeta);
    }
    if (data.containsKey('last_seen')) {
      context.handle(_lastSeenMeta,
          lastSeen.isAcceptableOrUnknown(data['last_seen']!, _lastSeenMeta));
    } else if (isInserting) {
      context.missing(_lastSeenMeta);
    }
    if (data.containsKey('sighting_count')) {
      context.handle(
          _sightingCountMeta,
          sightingCount.isAcceptableOrUnknown(
              data['sighting_count']!, _sightingCountMeta));
    }
    if (data.containsKey('dismissed')) {
      context.handle(_dismissedMeta,
          dismissed.isAcceptableOrUnknown(data['dismissed']!, _dismissedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
        {issuerGuess, last4},
      ];
  @override
  DetectedCardRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectedCardRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      issuerGuess: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}issuer_guess'])!,
      sender: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sender'])!,
      last4: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}last4'])!,
      firstSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}first_seen'])!,
      lastSeen: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_seen'])!,
      sightingCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sighting_count'])!,
      dismissed: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}dismissed'])!,
    );
  }

  @override
  $DetectedCardsTable createAlias(String alias) {
    return $DetectedCardsTable(attachedDatabase, alias);
  }
}

class DetectedCardRow extends DataClass implements Insertable<DetectedCardRow> {
  final int id;

  /// Best-effort friendly name derived from the sender (e.g. "HDFC"); falls
  /// back to the raw sender when nothing maps. Never authoritative — the user
  /// can retype it when confirming.
  final String issuerGuess;
  final String sender;
  final String last4;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int sightingCount;

  /// True once the user says "not mine" — stays true so the same card isn't
  /// re-prompted on a future sighting.
  final bool dismissed;
  const DetectedCardRow(
      {required this.id,
      required this.issuerGuess,
      required this.sender,
      required this.last4,
      required this.firstSeen,
      required this.lastSeen,
      required this.sightingCount,
      required this.dismissed});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['issuer_guess'] = Variable<String>(issuerGuess);
    map['sender'] = Variable<String>(sender);
    map['last4'] = Variable<String>(last4);
    map['first_seen'] = Variable<DateTime>(firstSeen);
    map['last_seen'] = Variable<DateTime>(lastSeen);
    map['sighting_count'] = Variable<int>(sightingCount);
    map['dismissed'] = Variable<bool>(dismissed);
    return map;
  }

  DetectedCardsCompanion toCompanion(bool nullToAbsent) {
    return DetectedCardsCompanion(
      id: Value(id),
      issuerGuess: Value(issuerGuess),
      sender: Value(sender),
      last4: Value(last4),
      firstSeen: Value(firstSeen),
      lastSeen: Value(lastSeen),
      sightingCount: Value(sightingCount),
      dismissed: Value(dismissed),
    );
  }

  factory DetectedCardRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectedCardRow(
      id: serializer.fromJson<int>(json['id']),
      issuerGuess: serializer.fromJson<String>(json['issuerGuess']),
      sender: serializer.fromJson<String>(json['sender']),
      last4: serializer.fromJson<String>(json['last4']),
      firstSeen: serializer.fromJson<DateTime>(json['firstSeen']),
      lastSeen: serializer.fromJson<DateTime>(json['lastSeen']),
      sightingCount: serializer.fromJson<int>(json['sightingCount']),
      dismissed: serializer.fromJson<bool>(json['dismissed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'issuerGuess': serializer.toJson<String>(issuerGuess),
      'sender': serializer.toJson<String>(sender),
      'last4': serializer.toJson<String>(last4),
      'firstSeen': serializer.toJson<DateTime>(firstSeen),
      'lastSeen': serializer.toJson<DateTime>(lastSeen),
      'sightingCount': serializer.toJson<int>(sightingCount),
      'dismissed': serializer.toJson<bool>(dismissed),
    };
  }

  DetectedCardRow copyWith(
          {int? id,
          String? issuerGuess,
          String? sender,
          String? last4,
          DateTime? firstSeen,
          DateTime? lastSeen,
          int? sightingCount,
          bool? dismissed}) =>
      DetectedCardRow(
        id: id ?? this.id,
        issuerGuess: issuerGuess ?? this.issuerGuess,
        sender: sender ?? this.sender,
        last4: last4 ?? this.last4,
        firstSeen: firstSeen ?? this.firstSeen,
        lastSeen: lastSeen ?? this.lastSeen,
        sightingCount: sightingCount ?? this.sightingCount,
        dismissed: dismissed ?? this.dismissed,
      );
  DetectedCardRow copyWithCompanion(DetectedCardsCompanion data) {
    return DetectedCardRow(
      id: data.id.present ? data.id.value : this.id,
      issuerGuess:
          data.issuerGuess.present ? data.issuerGuess.value : this.issuerGuess,
      sender: data.sender.present ? data.sender.value : this.sender,
      last4: data.last4.present ? data.last4.value : this.last4,
      firstSeen: data.firstSeen.present ? data.firstSeen.value : this.firstSeen,
      lastSeen: data.lastSeen.present ? data.lastSeen.value : this.lastSeen,
      sightingCount: data.sightingCount.present
          ? data.sightingCount.value
          : this.sightingCount,
      dismissed: data.dismissed.present ? data.dismissed.value : this.dismissed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectedCardRow(')
          ..write('id: $id, ')
          ..write('issuerGuess: $issuerGuess, ')
          ..write('sender: $sender, ')
          ..write('last4: $last4, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('sightingCount: $sightingCount, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, issuerGuess, sender, last4, firstSeen,
      lastSeen, sightingCount, dismissed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectedCardRow &&
          other.id == this.id &&
          other.issuerGuess == this.issuerGuess &&
          other.sender == this.sender &&
          other.last4 == this.last4 &&
          other.firstSeen == this.firstSeen &&
          other.lastSeen == this.lastSeen &&
          other.sightingCount == this.sightingCount &&
          other.dismissed == this.dismissed);
}

class DetectedCardsCompanion extends UpdateCompanion<DetectedCardRow> {
  final Value<int> id;
  final Value<String> issuerGuess;
  final Value<String> sender;
  final Value<String> last4;
  final Value<DateTime> firstSeen;
  final Value<DateTime> lastSeen;
  final Value<int> sightingCount;
  final Value<bool> dismissed;
  const DetectedCardsCompanion({
    this.id = const Value.absent(),
    this.issuerGuess = const Value.absent(),
    this.sender = const Value.absent(),
    this.last4 = const Value.absent(),
    this.firstSeen = const Value.absent(),
    this.lastSeen = const Value.absent(),
    this.sightingCount = const Value.absent(),
    this.dismissed = const Value.absent(),
  });
  DetectedCardsCompanion.insert({
    this.id = const Value.absent(),
    required String issuerGuess,
    required String sender,
    required String last4,
    required DateTime firstSeen,
    required DateTime lastSeen,
    this.sightingCount = const Value.absent(),
    this.dismissed = const Value.absent(),
  })  : issuerGuess = Value(issuerGuess),
        sender = Value(sender),
        last4 = Value(last4),
        firstSeen = Value(firstSeen),
        lastSeen = Value(lastSeen);
  static Insertable<DetectedCardRow> custom({
    Expression<int>? id,
    Expression<String>? issuerGuess,
    Expression<String>? sender,
    Expression<String>? last4,
    Expression<DateTime>? firstSeen,
    Expression<DateTime>? lastSeen,
    Expression<int>? sightingCount,
    Expression<bool>? dismissed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (issuerGuess != null) 'issuer_guess': issuerGuess,
      if (sender != null) 'sender': sender,
      if (last4 != null) 'last4': last4,
      if (firstSeen != null) 'first_seen': firstSeen,
      if (lastSeen != null) 'last_seen': lastSeen,
      if (sightingCount != null) 'sighting_count': sightingCount,
      if (dismissed != null) 'dismissed': dismissed,
    });
  }

  DetectedCardsCompanion copyWith(
      {Value<int>? id,
      Value<String>? issuerGuess,
      Value<String>? sender,
      Value<String>? last4,
      Value<DateTime>? firstSeen,
      Value<DateTime>? lastSeen,
      Value<int>? sightingCount,
      Value<bool>? dismissed}) {
    return DetectedCardsCompanion(
      id: id ?? this.id,
      issuerGuess: issuerGuess ?? this.issuerGuess,
      sender: sender ?? this.sender,
      last4: last4 ?? this.last4,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      sightingCount: sightingCount ?? this.sightingCount,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (issuerGuess.present) {
      map['issuer_guess'] = Variable<String>(issuerGuess.value);
    }
    if (sender.present) {
      map['sender'] = Variable<String>(sender.value);
    }
    if (last4.present) {
      map['last4'] = Variable<String>(last4.value);
    }
    if (firstSeen.present) {
      map['first_seen'] = Variable<DateTime>(firstSeen.value);
    }
    if (lastSeen.present) {
      map['last_seen'] = Variable<DateTime>(lastSeen.value);
    }
    if (sightingCount.present) {
      map['sighting_count'] = Variable<int>(sightingCount.value);
    }
    if (dismissed.present) {
      map['dismissed'] = Variable<bool>(dismissed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectedCardsCompanion(')
          ..write('id: $id, ')
          ..write('issuerGuess: $issuerGuess, ')
          ..write('sender: $sender, ')
          ..write('last4: $last4, ')
          ..write('firstSeen: $firstSeen, ')
          ..write('lastSeen: $lastSeen, ')
          ..write('sightingCount: $sightingCount, ')
          ..write('dismissed: $dismissed')
          ..write(')'))
        .toString();
  }
}

class $CardStatementsTable extends CardStatements
    with TableInfo<$CardStatementsTable, CardStatementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CardStatementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _cardIdMeta = const VerificationMeta('cardId');
  @override
  late final GeneratedColumn<int> cardId = GeneratedColumn<int>(
      'card_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES cards (id)'));
  static const VerificationMeta _statementDateMeta =
      const VerificationMeta('statementDate');
  @override
  late final GeneratedColumn<DateTime> statementDate =
      GeneratedColumn<DateTime>('statement_date', aliasedName, false,
          type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _dueDateMeta =
      const VerificationMeta('dueDate');
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
      'due_date', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _totalDueMeta =
      const VerificationMeta('totalDue');
  @override
  late final GeneratedColumn<double> totalDue = GeneratedColumn<double>(
      'total_due', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _minimumDueMeta =
      const VerificationMeta('minimumDue');
  @override
  late final GeneratedColumn<double> minimumDue = GeneratedColumn<double>(
      'minimum_due', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
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
  List<GeneratedColumn> get $columns => [
        id,
        cardId,
        statementDate,
        dueDate,
        totalDue,
        minimumDue,
        smsId,
        smsBody
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'card_statements';
  @override
  VerificationContext validateIntegrity(Insertable<CardStatementRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('card_id')) {
      context.handle(_cardIdMeta,
          cardId.isAcceptableOrUnknown(data['card_id']!, _cardIdMeta));
    } else if (isInserting) {
      context.missing(_cardIdMeta);
    }
    if (data.containsKey('statement_date')) {
      context.handle(
          _statementDateMeta,
          statementDate.isAcceptableOrUnknown(
              data['statement_date']!, _statementDateMeta));
    } else if (isInserting) {
      context.missing(_statementDateMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(_dueDateMeta,
          dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta));
    }
    if (data.containsKey('total_due')) {
      context.handle(_totalDueMeta,
          totalDue.isAcceptableOrUnknown(data['total_due']!, _totalDueMeta));
    }
    if (data.containsKey('minimum_due')) {
      context.handle(
          _minimumDueMeta,
          minimumDue.isAcceptableOrUnknown(
              data['minimum_due']!, _minimumDueMeta));
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
  CardStatementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CardStatementRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      cardId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}card_id'])!,
      statementDate: attachedDatabase.typeMapping.read(
          DriftSqlType.dateTime, data['${effectivePrefix}statement_date'])!,
      dueDate: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}due_date']),
      totalDue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}total_due']),
      minimumDue: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}minimum_due']),
      smsId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_id']),
      smsBody: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}sms_body']),
    );
  }

  @override
  $CardStatementsTable createAlias(String alias) {
    return $CardStatementsTable(attachedDatabase, alias);
  }
}

class CardStatementRow extends DataClass
    implements Insertable<CardStatementRow> {
  final int id;
  final int cardId;
  final DateTime statementDate;
  final DateTime? dueDate;
  final double? totalDue;
  final double? minimumDue;
  final String? smsId;
  final String? smsBody;
  const CardStatementRow(
      {required this.id,
      required this.cardId,
      required this.statementDate,
      this.dueDate,
      this.totalDue,
      this.minimumDue,
      this.smsId,
      this.smsBody});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['card_id'] = Variable<int>(cardId);
    map['statement_date'] = Variable<DateTime>(statementDate);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    if (!nullToAbsent || totalDue != null) {
      map['total_due'] = Variable<double>(totalDue);
    }
    if (!nullToAbsent || minimumDue != null) {
      map['minimum_due'] = Variable<double>(minimumDue);
    }
    if (!nullToAbsent || smsId != null) {
      map['sms_id'] = Variable<String>(smsId);
    }
    if (!nullToAbsent || smsBody != null) {
      map['sms_body'] = Variable<String>(smsBody);
    }
    return map;
  }

  CardStatementsCompanion toCompanion(bool nullToAbsent) {
    return CardStatementsCompanion(
      id: Value(id),
      cardId: Value(cardId),
      statementDate: Value(statementDate),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      totalDue: totalDue == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDue),
      minimumDue: minimumDue == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumDue),
      smsId:
          smsId == null && nullToAbsent ? const Value.absent() : Value(smsId),
      smsBody: smsBody == null && nullToAbsent
          ? const Value.absent()
          : Value(smsBody),
    );
  }

  factory CardStatementRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CardStatementRow(
      id: serializer.fromJson<int>(json['id']),
      cardId: serializer.fromJson<int>(json['cardId']),
      statementDate: serializer.fromJson<DateTime>(json['statementDate']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      totalDue: serializer.fromJson<double?>(json['totalDue']),
      minimumDue: serializer.fromJson<double?>(json['minimumDue']),
      smsId: serializer.fromJson<String?>(json['smsId']),
      smsBody: serializer.fromJson<String?>(json['smsBody']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cardId': serializer.toJson<int>(cardId),
      'statementDate': serializer.toJson<DateTime>(statementDate),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'totalDue': serializer.toJson<double?>(totalDue),
      'minimumDue': serializer.toJson<double?>(minimumDue),
      'smsId': serializer.toJson<String?>(smsId),
      'smsBody': serializer.toJson<String?>(smsBody),
    };
  }

  CardStatementRow copyWith(
          {int? id,
          int? cardId,
          DateTime? statementDate,
          Value<DateTime?> dueDate = const Value.absent(),
          Value<double?> totalDue = const Value.absent(),
          Value<double?> minimumDue = const Value.absent(),
          Value<String?> smsId = const Value.absent(),
          Value<String?> smsBody = const Value.absent()}) =>
      CardStatementRow(
        id: id ?? this.id,
        cardId: cardId ?? this.cardId,
        statementDate: statementDate ?? this.statementDate,
        dueDate: dueDate.present ? dueDate.value : this.dueDate,
        totalDue: totalDue.present ? totalDue.value : this.totalDue,
        minimumDue: minimumDue.present ? minimumDue.value : this.minimumDue,
        smsId: smsId.present ? smsId.value : this.smsId,
        smsBody: smsBody.present ? smsBody.value : this.smsBody,
      );
  CardStatementRow copyWithCompanion(CardStatementsCompanion data) {
    return CardStatementRow(
      id: data.id.present ? data.id.value : this.id,
      cardId: data.cardId.present ? data.cardId.value : this.cardId,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      totalDue: data.totalDue.present ? data.totalDue.value : this.totalDue,
      minimumDue:
          data.minimumDue.present ? data.minimumDue.value : this.minimumDue,
      smsId: data.smsId.present ? data.smsId.value : this.smsId,
      smsBody: data.smsBody.present ? data.smsBody.value : this.smsBody,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CardStatementRow(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('statementDate: $statementDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('totalDue: $totalDue, ')
          ..write('minimumDue: $minimumDue, ')
          ..write('smsId: $smsId, ')
          ..write('smsBody: $smsBody')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, cardId, statementDate, dueDate, totalDue, minimumDue, smsId, smsBody);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CardStatementRow &&
          other.id == this.id &&
          other.cardId == this.cardId &&
          other.statementDate == this.statementDate &&
          other.dueDate == this.dueDate &&
          other.totalDue == this.totalDue &&
          other.minimumDue == this.minimumDue &&
          other.smsId == this.smsId &&
          other.smsBody == this.smsBody);
}

class CardStatementsCompanion extends UpdateCompanion<CardStatementRow> {
  final Value<int> id;
  final Value<int> cardId;
  final Value<DateTime> statementDate;
  final Value<DateTime?> dueDate;
  final Value<double?> totalDue;
  final Value<double?> minimumDue;
  final Value<String?> smsId;
  final Value<String?> smsBody;
  const CardStatementsCompanion({
    this.id = const Value.absent(),
    this.cardId = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.totalDue = const Value.absent(),
    this.minimumDue = const Value.absent(),
    this.smsId = const Value.absent(),
    this.smsBody = const Value.absent(),
  });
  CardStatementsCompanion.insert({
    this.id = const Value.absent(),
    required int cardId,
    required DateTime statementDate,
    this.dueDate = const Value.absent(),
    this.totalDue = const Value.absent(),
    this.minimumDue = const Value.absent(),
    this.smsId = const Value.absent(),
    this.smsBody = const Value.absent(),
  })  : cardId = Value(cardId),
        statementDate = Value(statementDate);
  static Insertable<CardStatementRow> custom({
    Expression<int>? id,
    Expression<int>? cardId,
    Expression<DateTime>? statementDate,
    Expression<DateTime>? dueDate,
    Expression<double>? totalDue,
    Expression<double>? minimumDue,
    Expression<String>? smsId,
    Expression<String>? smsBody,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (cardId != null) 'card_id': cardId,
      if (statementDate != null) 'statement_date': statementDate,
      if (dueDate != null) 'due_date': dueDate,
      if (totalDue != null) 'total_due': totalDue,
      if (minimumDue != null) 'minimum_due': minimumDue,
      if (smsId != null) 'sms_id': smsId,
      if (smsBody != null) 'sms_body': smsBody,
    });
  }

  CardStatementsCompanion copyWith(
      {Value<int>? id,
      Value<int>? cardId,
      Value<DateTime>? statementDate,
      Value<DateTime?>? dueDate,
      Value<double?>? totalDue,
      Value<double?>? minimumDue,
      Value<String?>? smsId,
      Value<String?>? smsBody}) {
    return CardStatementsCompanion(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      statementDate: statementDate ?? this.statementDate,
      dueDate: dueDate ?? this.dueDate,
      totalDue: totalDue ?? this.totalDue,
      minimumDue: minimumDue ?? this.minimumDue,
      smsId: smsId ?? this.smsId,
      smsBody: smsBody ?? this.smsBody,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (cardId.present) {
      map['card_id'] = Variable<int>(cardId.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<DateTime>(statementDate.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (totalDue.present) {
      map['total_due'] = Variable<double>(totalDue.value);
    }
    if (minimumDue.present) {
      map['minimum_due'] = Variable<double>(minimumDue.value);
    }
    if (smsId.present) {
      map['sms_id'] = Variable<String>(smsId.value);
    }
    if (smsBody.present) {
      map['sms_body'] = Variable<String>(smsBody.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CardStatementsCompanion(')
          ..write('id: $id, ')
          ..write('cardId: $cardId, ')
          ..write('statementDate: $statementDate, ')
          ..write('dueDate: $dueDate, ')
          ..write('totalDue: $totalDue, ')
          ..write('minimumDue: $minimumDue, ')
          ..write('smsId: $smsId, ')
          ..write('smsBody: $smsBody')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CardsTable cards = $CardsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $DetectedCardsTable detectedCards = $DetectedCardsTable(this);
  late final $CardStatementsTable cardStatements = $CardStatementsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [cards, transactions, detectedCards, cardStatements];
}

typedef $$CardsTableCreateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  required String issuer,
  required String last4,
  required double creditLimit,
  Value<String?> nickname,
});
typedef $$CardsTableUpdateCompanionBuilder = CardsCompanion Function({
  Value<int> id,
  Value<String> issuer,
  Value<String> last4,
  Value<double> creditLimit,
  Value<String?> nickname,
});

final class $$CardsTableReferences
    extends BaseReferences<_$AppDatabase, $CardsTable, CardRow> {
  $$CardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TransactionsTable, List<TransactionRow>>
      _transactionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.transactions,
              aliasName: 'cards__id__transactions__card_id');

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$CardStatementsTable, List<CardStatementRow>>
      _cardStatementsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.cardStatements,
              aliasName: 'cards__id__card_statements__card_id');

  $$CardStatementsTableProcessedTableManager get cardStatementsRefs {
    final manager = $$CardStatementsTableTableManager($_db, $_db.cardStatements)
        .filter((f) => f.cardId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cardStatementsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CardsTableFilterComposer extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuer => $composableBuilder(
      column: $table.issuer, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nickname => $composableBuilder(
      column: $table.nickname, builder: (column) => ColumnFilters(column));

  Expression<bool> transactionsRefs(
      Expression<bool> Function($$TransactionsTableFilterComposer f) f) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableFilterComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> cardStatementsRefs(
      Expression<bool> Function($$CardStatementsTableFilterComposer f) f) {
    final $$CardStatementsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardStatements,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardStatementsTableFilterComposer(
              $db: $db,
              $table: $db.cardStatements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuer => $composableBuilder(
      column: $table.issuer, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nickname => $composableBuilder(
      column: $table.nickname, builder: (column) => ColumnOrderings(column));
}

class $$CardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardsTable> {
  $$CardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issuer =>
      $composableBuilder(column: $table.issuer, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<double> get creditLimit => $composableBuilder(
      column: $table.creditLimit, builder: (column) => column);

  GeneratedColumn<String> get nickname =>
      $composableBuilder(column: $table.nickname, builder: (column) => column);

  Expression<T> transactionsRefs<T extends Object>(
      Expression<T> Function($$TransactionsTableAnnotationComposer a) f) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.transactions,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TransactionsTableAnnotationComposer(
              $db: $db,
              $table: $db.transactions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> cardStatementsRefs<T extends Object>(
      Expression<T> Function($$CardStatementsTableAnnotationComposer a) f) {
    final $$CardStatementsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.cardStatements,
        getReferencedColumn: (t) => t.cardId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardStatementsTableAnnotationComposer(
              $db: $db,
              $table: $db.cardStatements,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardsTable,
    CardRow,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (CardRow, $$CardsTableReferences),
    CardRow,
    PrefetchHooks Function({bool transactionsRefs, bool cardStatementsRefs})> {
  $$CardsTableTableManager(_$AppDatabase db, $CardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> issuer = const Value.absent(),
            Value<String> last4 = const Value.absent(),
            Value<double> creditLimit = const Value.absent(),
            Value<String?> nickname = const Value.absent(),
          }) =>
              CardsCompanion(
            id: id,
            issuer: issuer,
            last4: last4,
            creditLimit: creditLimit,
            nickname: nickname,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String issuer,
            required String last4,
            required double creditLimit,
            Value<String?> nickname = const Value.absent(),
          }) =>
              CardsCompanion.insert(
            id: id,
            issuer: issuer,
            last4: last4,
            creditLimit: creditLimit,
            nickname: nickname,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$CardsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {transactionsRefs = false, cardStatementsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (transactionsRefs) db.transactions,
                if (cardStatementsRefs) db.cardStatements
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (transactionsRefs)
                    await $_getPrefetchedData<CardRow, $CardsTable,
                            TransactionRow>(
                        currentTable: table,
                        referencedTable:
                            $$CardsTableReferences._transactionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardsTableReferences(db, table, p0)
                                .transactionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items),
                  if (cardStatementsRefs)
                    await $_getPrefetchedData<CardRow, $CardsTable,
                            CardStatementRow>(
                        currentTable: table,
                        referencedTable:
                            $$CardsTableReferences._cardStatementsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CardsTableReferences(db, table, p0)
                                .cardStatementsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.cardId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardsTable,
    CardRow,
    $$CardsTableFilterComposer,
    $$CardsTableOrderingComposer,
    $$CardsTableAnnotationComposer,
    $$CardsTableCreateCompanionBuilder,
    $$CardsTableUpdateCompanionBuilder,
    (CardRow, $$CardsTableReferences),
    CardRow,
    PrefetchHooks Function({bool transactionsRefs, bool cardStatementsRefs})>;
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
  Value<int?> cardId,
  Value<double?> cardAvailableLimit,
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
  Value<int?> cardId,
  Value<double?> cardAvailableLimit,
});

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, TransactionRow> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) =>
      db.cards.createAlias('transactions__card_id__cards__id');

  $$CardsTableProcessedTableManager? get cardId {
    final $_column = $_itemColumn<int>('card_id');
    if ($_column == null) return null;
    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

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

  ColumnFilters<double> get cardAvailableLimit => $composableBuilder(
      column: $table.cardAvailableLimit,
      builder: (column) => ColumnFilters(column));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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

  ColumnOrderings<double> get cardAvailableLimit => $composableBuilder(
      column: $table.cardAvailableLimit,
      builder: (column) => ColumnOrderings(column));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableOrderingComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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

  GeneratedColumn<double> get cardAvailableLimit => $composableBuilder(
      column: $table.cardAvailableLimit, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
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
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function({bool cardId})> {
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
            Value<int?> cardId = const Value.absent(),
            Value<double?> cardAvailableLimit = const Value.absent(),
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
            cardId: cardId,
            cardAvailableLimit: cardAvailableLimit,
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
            Value<int?> cardId = const Value.absent(),
            Value<double?> cardAvailableLimit = const Value.absent(),
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
            cardId: cardId,
            cardAvailableLimit: cardAvailableLimit,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TransactionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable:
                        $$TransactionsTableReferences._cardIdTable(db),
                    referencedColumn:
                        $$TransactionsTableReferences._cardIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
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
    (TransactionRow, $$TransactionsTableReferences),
    TransactionRow,
    PrefetchHooks Function({bool cardId})>;
typedef $$DetectedCardsTableCreateCompanionBuilder = DetectedCardsCompanion
    Function({
  Value<int> id,
  required String issuerGuess,
  required String sender,
  required String last4,
  required DateTime firstSeen,
  required DateTime lastSeen,
  Value<int> sightingCount,
  Value<bool> dismissed,
});
typedef $$DetectedCardsTableUpdateCompanionBuilder = DetectedCardsCompanion
    Function({
  Value<int> id,
  Value<String> issuerGuess,
  Value<String> sender,
  Value<String> last4,
  Value<DateTime> firstSeen,
  Value<DateTime> lastSeen,
  Value<int> sightingCount,
  Value<bool> dismissed,
});

class $$DetectedCardsTableFilterComposer
    extends Composer<_$AppDatabase, $DetectedCardsTable> {
  $$DetectedCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get issuerGuess => $composableBuilder(
      column: $table.issuerGuess, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sightingCount => $composableBuilder(
      column: $table.sightingCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get dismissed => $composableBuilder(
      column: $table.dismissed, builder: (column) => ColumnFilters(column));
}

class $$DetectedCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $DetectedCardsTable> {
  $$DetectedCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get issuerGuess => $composableBuilder(
      column: $table.issuerGuess, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sender => $composableBuilder(
      column: $table.sender, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get last4 => $composableBuilder(
      column: $table.last4, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get firstSeen => $composableBuilder(
      column: $table.firstSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get lastSeen => $composableBuilder(
      column: $table.lastSeen, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sightingCount => $composableBuilder(
      column: $table.sightingCount,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get dismissed => $composableBuilder(
      column: $table.dismissed, builder: (column) => ColumnOrderings(column));
}

class $$DetectedCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DetectedCardsTable> {
  $$DetectedCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get issuerGuess => $composableBuilder(
      column: $table.issuerGuess, builder: (column) => column);

  GeneratedColumn<String> get sender =>
      $composableBuilder(column: $table.sender, builder: (column) => column);

  GeneratedColumn<String> get last4 =>
      $composableBuilder(column: $table.last4, builder: (column) => column);

  GeneratedColumn<DateTime> get firstSeen =>
      $composableBuilder(column: $table.firstSeen, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSeen =>
      $composableBuilder(column: $table.lastSeen, builder: (column) => column);

  GeneratedColumn<int> get sightingCount => $composableBuilder(
      column: $table.sightingCount, builder: (column) => column);

  GeneratedColumn<bool> get dismissed =>
      $composableBuilder(column: $table.dismissed, builder: (column) => column);
}

class $$DetectedCardsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DetectedCardsTable,
    DetectedCardRow,
    $$DetectedCardsTableFilterComposer,
    $$DetectedCardsTableOrderingComposer,
    $$DetectedCardsTableAnnotationComposer,
    $$DetectedCardsTableCreateCompanionBuilder,
    $$DetectedCardsTableUpdateCompanionBuilder,
    (
      DetectedCardRow,
      BaseReferences<_$AppDatabase, $DetectedCardsTable, DetectedCardRow>
    ),
    DetectedCardRow,
    PrefetchHooks Function()> {
  $$DetectedCardsTableTableManager(_$AppDatabase db, $DetectedCardsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectedCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectedCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectedCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> issuerGuess = const Value.absent(),
            Value<String> sender = const Value.absent(),
            Value<String> last4 = const Value.absent(),
            Value<DateTime> firstSeen = const Value.absent(),
            Value<DateTime> lastSeen = const Value.absent(),
            Value<int> sightingCount = const Value.absent(),
            Value<bool> dismissed = const Value.absent(),
          }) =>
              DetectedCardsCompanion(
            id: id,
            issuerGuess: issuerGuess,
            sender: sender,
            last4: last4,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            sightingCount: sightingCount,
            dismissed: dismissed,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String issuerGuess,
            required String sender,
            required String last4,
            required DateTime firstSeen,
            required DateTime lastSeen,
            Value<int> sightingCount = const Value.absent(),
            Value<bool> dismissed = const Value.absent(),
          }) =>
              DetectedCardsCompanion.insert(
            id: id,
            issuerGuess: issuerGuess,
            sender: sender,
            last4: last4,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            sightingCount: sightingCount,
            dismissed: dismissed,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DetectedCardsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DetectedCardsTable,
    DetectedCardRow,
    $$DetectedCardsTableFilterComposer,
    $$DetectedCardsTableOrderingComposer,
    $$DetectedCardsTableAnnotationComposer,
    $$DetectedCardsTableCreateCompanionBuilder,
    $$DetectedCardsTableUpdateCompanionBuilder,
    (
      DetectedCardRow,
      BaseReferences<_$AppDatabase, $DetectedCardsTable, DetectedCardRow>
    ),
    DetectedCardRow,
    PrefetchHooks Function()>;
typedef $$CardStatementsTableCreateCompanionBuilder = CardStatementsCompanion
    Function({
  Value<int> id,
  required int cardId,
  required DateTime statementDate,
  Value<DateTime?> dueDate,
  Value<double?> totalDue,
  Value<double?> minimumDue,
  Value<String?> smsId,
  Value<String?> smsBody,
});
typedef $$CardStatementsTableUpdateCompanionBuilder = CardStatementsCompanion
    Function({
  Value<int> id,
  Value<int> cardId,
  Value<DateTime> statementDate,
  Value<DateTime?> dueDate,
  Value<double?> totalDue,
  Value<double?> minimumDue,
  Value<String?> smsId,
  Value<String?> smsBody,
});

final class $$CardStatementsTableReferences extends BaseReferences<
    _$AppDatabase, $CardStatementsTable, CardStatementRow> {
  $$CardStatementsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $CardsTable _cardIdTable(_$AppDatabase db) =>
      db.cards.createAlias('card_statements__card_id__cards__id');

  $$CardsTableProcessedTableManager get cardId {
    final $_column = $_itemColumn<int>('card_id')!;

    final manager = $$CardsTableTableManager($_db, $_db.cards)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cardIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$CardStatementsTableFilterComposer
    extends Composer<_$AppDatabase, $CardStatementsTable> {
  $$CardStatementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get totalDue => $composableBuilder(
      column: $table.totalDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get minimumDue => $composableBuilder(
      column: $table.minimumDue, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsId => $composableBuilder(
      column: $table.smsId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnFilters(column));

  $$CardsTableFilterComposer get cardId {
    final $$CardsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableFilterComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardStatementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CardStatementsTable> {
  $$CardStatementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
      column: $table.dueDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get totalDue => $composableBuilder(
      column: $table.totalDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get minimumDue => $composableBuilder(
      column: $table.minimumDue, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsId => $composableBuilder(
      column: $table.smsId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get smsBody => $composableBuilder(
      column: $table.smsBody, builder: (column) => ColumnOrderings(column));

  $$CardsTableOrderingComposer get cardId {
    final $$CardsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableOrderingComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardStatementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CardStatementsTable> {
  $$CardStatementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get statementDate => $composableBuilder(
      column: $table.statementDate, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<double> get totalDue =>
      $composableBuilder(column: $table.totalDue, builder: (column) => column);

  GeneratedColumn<double> get minimumDue => $composableBuilder(
      column: $table.minimumDue, builder: (column) => column);

  GeneratedColumn<String> get smsId =>
      $composableBuilder(column: $table.smsId, builder: (column) => column);

  GeneratedColumn<String> get smsBody =>
      $composableBuilder(column: $table.smsBody, builder: (column) => column);

  $$CardsTableAnnotationComposer get cardId {
    final $$CardsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.cardId,
        referencedTable: $db.cards,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CardsTableAnnotationComposer(
              $db: $db,
              $table: $db.cards,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$CardStatementsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CardStatementsTable,
    CardStatementRow,
    $$CardStatementsTableFilterComposer,
    $$CardStatementsTableOrderingComposer,
    $$CardStatementsTableAnnotationComposer,
    $$CardStatementsTableCreateCompanionBuilder,
    $$CardStatementsTableUpdateCompanionBuilder,
    (CardStatementRow, $$CardStatementsTableReferences),
    CardStatementRow,
    PrefetchHooks Function({bool cardId})> {
  $$CardStatementsTableTableManager(
      _$AppDatabase db, $CardStatementsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CardStatementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CardStatementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CardStatementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> cardId = const Value.absent(),
            Value<DateTime> statementDate = const Value.absent(),
            Value<DateTime?> dueDate = const Value.absent(),
            Value<double?> totalDue = const Value.absent(),
            Value<double?> minimumDue = const Value.absent(),
            Value<String?> smsId = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
          }) =>
              CardStatementsCompanion(
            id: id,
            cardId: cardId,
            statementDate: statementDate,
            dueDate: dueDate,
            totalDue: totalDue,
            minimumDue: minimumDue,
            smsId: smsId,
            smsBody: smsBody,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int cardId,
            required DateTime statementDate,
            Value<DateTime?> dueDate = const Value.absent(),
            Value<double?> totalDue = const Value.absent(),
            Value<double?> minimumDue = const Value.absent(),
            Value<String?> smsId = const Value.absent(),
            Value<String?> smsBody = const Value.absent(),
          }) =>
              CardStatementsCompanion.insert(
            id: id,
            cardId: cardId,
            statementDate: statementDate,
            dueDate: dueDate,
            totalDue: totalDue,
            minimumDue: minimumDue,
            smsId: smsId,
            smsBody: smsBody,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CardStatementsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({cardId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (cardId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.cardId,
                    referencedTable:
                        $$CardStatementsTableReferences._cardIdTable(db),
                    referencedColumn:
                        $$CardStatementsTableReferences._cardIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$CardStatementsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CardStatementsTable,
    CardStatementRow,
    $$CardStatementsTableFilterComposer,
    $$CardStatementsTableOrderingComposer,
    $$CardStatementsTableAnnotationComposer,
    $$CardStatementsTableCreateCompanionBuilder,
    $$CardStatementsTableUpdateCompanionBuilder,
    (CardStatementRow, $$CardStatementsTableReferences),
    CardStatementRow,
    PrefetchHooks Function({bool cardId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CardsTableTableManager get cards =>
      $$CardsTableTableManager(_db, _db.cards);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$DetectedCardsTableTableManager get detectedCards =>
      $$DetectedCardsTableTableManager(_db, _db.detectedCards);
  $$CardStatementsTableTableManager get cardStatements =>
      $$CardStatementsTableTableManager(_db, _db.cardStatements);
}
