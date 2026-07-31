import 'package:meta/meta.dart';
import 'package:fynans/entities/transaction.dart';

/// Which direction of money movement to keep.
enum DirectionFilter {
  any('All'),
  inflow('Inflow'),
  outflow('Outflow');

  const DirectionFilter(this.label);

  final String label;

  bool get isAny => this == DirectionFilter.any;
}

/// Immutable value object encapsulating all predicate logic for filtering a
/// [Transaction].
@immutable
class TransactionFilter {
  /// Selected values per dimension.
  final Set<String> groups;
  final Set<String> tags;
  final Set<String> parties;

  /// Inflow only, outflow only, or both.
  final DirectionFilter direction;

  /// Inclusive bounds on the (always positive) transaction amount.
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilter({
    this.groups = const {},
    this.tags = const {},
    this.parties = const {},
    this.direction = DirectionFilter.any,
    this.minAmount,
    this.maxAmount,
  });

  const TransactionFilter.empty() : this();

  bool get isEmpty =>
      groups.isEmpty &&
      tags.isEmpty &&
      parties.isEmpty &&
      direction.isAny &&
      minAmount == null &&
      maxAmount == null;

  /// How many criteria are active — drives the badge on the filter button.
  int get activeCount =>
      groups.length +
      tags.length +
      parties.length +
      (direction.isAny ? 0 : 1) +
      (minAmount != null || maxAmount != null ? 1 : 0);

  /// Single source of truth: does [t] satisfy every active criterion?
  bool matches(Transaction t) {
    if (!_matchesAny(groups, t.group)) return false;
    if (!_matchesAny(tags, t.tags)) return false;
    if (!_matchesAny(parties, [t.party])) return false;
    switch (direction) {
      case DirectionFilter.inflow:
        if (!t.isCredit) return false;
      case DirectionFilter.outflow:
        if (t.isCredit) return false;
      case DirectionFilter.any:
        break;
    }
    if (minAmount != null && t.amount < minAmount!) return false;
    if (maxAmount != null && t.amount > maxAmount!) return false;
    return true;
  }

  /// Pass an empty set to clear a dimension; omit it to leave it unchanged.
  TransactionFilter copyWith({
    Set<String>? groups,
    Set<String>? tags,
    Set<String>? parties,
    DirectionFilter? direction,
    Object? minAmount = _sentinel,
    Object? maxAmount = _sentinel,
  }) {
    return TransactionFilter(
      groups: groups ?? this.groups,
      tags: tags ?? this.tags,
      parties: parties ?? this.parties,
      direction: direction ?? this.direction,
      minAmount:
          minAmount == _sentinel ? this.minAmount : minAmount as double?,
      maxAmount:
          maxAmount == _sentinel ? this.maxAmount : maxAmount as double?,
    );
  }

  /// True when [selected] is unconstrained, or any of [values] is in it
  /// (case-insensitively).
  static bool _matchesAny(Set<String> selected, Iterable<String> values) {
    if (selected.isEmpty) return true;
    final lowered = values.map((v) => v.trim().toLowerCase()).toSet();
    return selected.any((s) => lowered.contains(s.trim().toLowerCase()));
  }

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  /// Order-independent hash for a set of values.
  static int _setHash(Set<String> values) =>
      Object.hashAllUnordered(values);

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      _sameSet(other.groups, groups) &&
      _sameSet(other.tags, tags) &&
      _sameSet(other.parties, parties) &&
      other.direction == direction &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount;

  @override
  int get hashCode => Object.hash(
        _setHash(groups),
        _setHash(tags),
        _setHash(parties),
        direction,
        minAmount,
        maxAmount,
      );
}

const _sentinel = Object();
