import 'package:fynans/entities/payment_card.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/use_cases/remove_card.dart';

/// "HDFC •••• 1234".
String cardName(PaymentCard card) => '${card.issuer} •••• ${card.last4}';

/// "1 transaction" or "3 transactions".
String transactionCountText(int count) =>
    count == 1 ? '1 transaction' : '$count transactions';

/// "3 transactions (₹2,150.00)".
String hiddenTransactionsText(HiddenTransactions hidden) =>
    '${transactionCountText(hidden.count)} (${Fmt.money(hidden.total)})';

/// The card's status in a few words, for example "Closed on 31 Oct 2026".
String cardStatusText(PaymentCard card) => switch (card.status) {
      CardStatus.active => 'Active',
      CardStatus.closed => 'Closed on ${Fmt.fullDate(card.closedOn!)}',
      CardStatus.untracked => 'Untracked',
    };
