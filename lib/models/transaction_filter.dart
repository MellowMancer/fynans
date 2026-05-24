import 'package:meta/meta.dart';
import 'package:fynans/models/transaction.dart';

/// Immutable value object encapsulating all predicate logic for filtering
/// a [Transaction]. Pass null to any service method for "match all".
@immutable
class TransactionFilter {
  final String? group;
  final String? tag;
  final String? party;

  const TransactionFilter({
    this.group,
    this.tag,
    this.party,
  });

  const TransactionFilter.empty()
      : group = null,
        tag = null,
        party = null;

  bool get isEmpty => group == null && tag == null && party == null;

  /// Single source of truth: does [t] satisfy every active criterion?
  bool matches(Transaction t) {
    if (group != null &&
        !t.group.any((g) => g.trim().toLowerCase() == group!.toLowerCase())) {
      return false;
    }
    if (tag != null &&
        !t.tags.any((tg) => tg.trim().toLowerCase() == tag!.toLowerCase())) {
      return false;
    }
    if (party != null &&
        t.party.trim().toLowerCase() != party!.toLowerCase()) {
      return false;
    }
    return true;
  }

  TransactionFilter copyWith({
    Object? group = _sentinel,
    Object? tag = _sentinel,
    Object? party = _sentinel,
  }) {
    return TransactionFilter(
      group: group == _sentinel ? this.group : group as String?,
      tag: tag == _sentinel ? this.tag : tag as String?,
      party: party == _sentinel ? this.party : party as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TransactionFilter &&
      other.group == group &&
      other.tag == tag &&
      other.party == party;

  @override
  int get hashCode => Object.hash(group, tag, party);
}

const _sentinel = Object();
