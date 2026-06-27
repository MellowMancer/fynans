/// A package-neutral SMS record used across the app (transaction parsing,
/// scam scanning, dev TestSMS screen) so no UI/service is coupled to a
/// specific SMS plugin's message type.
class InboxSms {
  final String sender;
  final String body;
  final DateTime date;

  const InboxSms({
    required this.sender,
    required this.body,
    required this.date,
  });
}
