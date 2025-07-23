enum GroupingOption {
  group('Group'),
  tag('Tag'),
  recipient('Recipient');

  const GroupingOption(this.displayName);
  final String displayName;
}