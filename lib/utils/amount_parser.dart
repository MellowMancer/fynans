/// Pure parser/validator for user-entered transaction amounts.
library;

/// Outcome of [parseAmount]: [value] is the parsed amount on success, otherwise
/// [error] holds a human-readable reason and [value] is null.
class AmountParseResult {
  /// The parsed positive amount, or null when parsing failed.
  final double? value;

  /// A human-readable failure reason, or null when parsing succeeded.
  final String? error;

  const AmountParseResult.success(double this.value) : error = null;
  const AmountParseResult.failure(String this.error) : value = null;
}

/// Parses [input] into a positive amount, rejecting empty, non-numeric,
/// negative, and zero values.
AmountParseResult parseAmount(String? input) {
  final trimmed = input?.trim() ?? '';
  if (trimmed.isEmpty) {
    return const AmountParseResult.failure('Please enter an amount');
  }
  final parsed = double.tryParse(trimmed);
  if (parsed == null) {
    return const AmountParseResult.failure('Please enter a valid number');
  }
  if (parsed <= 0) {
    return const AmountParseResult.failure('Amount must be greater than zero');
  }
  return AmountParseResult.success(parsed);
}
