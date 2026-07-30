import 'package:flutter/material.dart';
import 'package:fynans/adapters/sms/parsed_transaction.dart';
import 'package:fynans/adapters/sms/read_sms_service.dart';
import 'package:fynans/adapters/sms/sms_parser_service.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/utils/formatters.dart';
import 'package:fynans/ui/widgets/common/common.dart';

/// One parsed message, kept alongside the raw SMS it came from so the original
/// text can be shown next to what the parser made of it.
class ParsedSms {
  const ParsedSms({
    required this.details,
    required this.sender,
    required this.body,
  });

  final ParsedTransactionDetails details;
  final String sender;

  /// The untouched SMS text.
  final String body;
}

/// Diagnostic view of what the parser makes of the inbox.
///
/// This screen itself never writes; the launch sweep in `main.dart` is what
/// imports these messages into the database.
class TestSmsScreen extends StatefulWidget {
  const TestSmsScreen({super.key});

  @override
  State<TestSmsScreen> createState() => _TestSmsScreenState();
}

class _TestSmsScreenState extends State<TestSmsScreen> {
  final _readSmsService = ReadSmsService();
  final _smsParserService = SmsParserService();

  bool _isLoading = true;
  bool _showOriginal = false;
  List<ParsedSms> _parsed = [];

  @override
  void initState() {
    super.initState();
    _readAndParseSms();
  }

  Future<void> _readAndParseSms() async {
    if (mounted) setState(() => _isLoading = true);

    // Non-consuming read: re-scan the whole inbox each time so this list always
    // shows every parsable transaction, including on refresh.
    final messages = await _readSmsService.getAllSms();
    final results = <ParsedSms>[];

    for (final msg in messages) {
      final details = _smsParserService.parseTransactionDetails(
        sender: msg.sender,
        body: msg.body,
        date: msg.date,
      );
      if (details != null) {
        results.add(
          ParsedSms(details: details, sender: msg.sender, body: msg.body),
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _parsed = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.gutter,
            AppSpacing.sm,
            AppSpacing.gutter,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppSectionLabel('Parser output'),
                        AppSpacing.gapXxs,
                        Text(
                          _isLoading
                              ? 'Scanning inbox…'
                              : '${_parsed.length} '
                                  '${_parsed.length == 1 ? "message" : "messages"} '
                                  'parsed',
                          style: AppTypography.h2,
                        ),
                      ],
                    ),
                  ),
                  AppButton(
                    label: 'Rescan',
                    icon: Icons.refresh_rounded,
                    variant: AppButtonVariant.secondary,
                    size: AppButtonSize.sm,
                    onPressed: _isLoading ? null : _readAndParseSms,
                  ),
                ],
              ),
              AppSpacing.gapMd,
              Row(
                children: [
                  AppPill(
                    'Show original SMS',
                    icon: _showOriginal
                        ? Icons.check_rounded
                        : Icons.subject_rounded,
                    tone: _showOriginal
                        ? AppPillTone.accent
                        : AppPillTone.outline,
                    onTap: () =>
                        setState(() => _showOriginal = !_showOriginal),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: _isLoading
              ? const AppLoading()
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _readAndParseSms,
                  child: _parsed.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: AppSpacing.xxxl * 2),
                            AppEmptyState(
                              icon: Icons.sms_failed_outlined,
                              title: 'No parsable bank SMS found',
                              message: 'Grant SMS permission, or pull down to '
                                  'rescan the inbox.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.gutter,
                            AppSpacing.md,
                            AppSpacing.gutter,
                            AppSpacing.xxxl,
                          ),
                          itemCount: _parsed.length,
                          separatorBuilder: (_, __) => AppSpacing.gapMd,
                          itemBuilder: (context, index) => ParsedSmsCard(
                            data: _parsed[index],
                            showOriginal: _showOriginal,
                          ),
                        ),
                ),
        ),
      ],
    );
  }
}

/// A single parsed message: what the parser extracted, and optionally the raw
/// SMS it was extracted from.
class ParsedSmsCard extends StatelessWidget {
  const ParsedSmsCard({
    super.key,
    required this.data,
    this.showOriginal = false,
  });

  final ParsedSms data;

  /// Reveal the untouched SMS text under the parsed fields.
  final bool showOriginal;

  ({String label, AppPillTone tone, MoneyTone money}) get _kind =>
      switch (data.details.type) {
        TransactionType.debit => (
            label: 'Debit',
            tone: AppPillTone.danger,
            money: MoneyTone.negative,
          ),
        TransactionType.credit => (
            label: 'Credit',
            tone: AppPillTone.success,
            money: MoneyTone.positive,
          ),
        TransactionType.declined => (
            label: 'Declined',
            tone: AppPillTone.muted,
            money: MoneyTone.neutral,
          ),
        TransactionType.unknown => (
            label: 'Unknown',
            tone: AppPillTone.muted,
            money: MoneyTone.neutral,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final details = data.details;
    final kind = _kind;

    return AppCard(
      label: data.sender,
      title: details.merchant ?? 'Unknown merchant',
      trailing: AppPill(kind.label, tone: kind.tone, dense: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MoneyText(details.amount, tone: kind.money),
          AppSpacing.gapMd,
          AppKeyValueGrid(
            children: [
              AppKeyValue(
                label: 'Received',
                value: Fmt.fullDateTime(details.date),
                icon: Icons.event_outlined,
                mono: true,
              ),
              if (details.accountNumber != null)
                AppKeyValue(
                  label: 'Account',
                  value: '••${details.accountNumber}',
                  icon: Icons.credit_card_outlined,
                  mono: true,
                ),
              if (details.balance != null)
                AppKeyValue(
                  label: 'Balance',
                  // MoneyText already renders mono upper-case.
                  valueWidget: MoneyText(
                    details.balance!,
                    style: AppTypography.monoBody,
                  ),
                  icon: Icons.account_balance_outlined,
                ),
            ],
          ),
          if (showOriginal) ...[
            AppSpacing.gapMd,
            const Divider(),
            AppSpacing.gapMd,
            AppQuoteBlock(
              data.body,
              label: 'Original message',
              icon: Icons.subject_rounded,
            ),
          ],
        ],
      ),
    );
  }
}
