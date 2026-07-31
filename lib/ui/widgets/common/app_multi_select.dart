import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/app_labels.dart';
import 'package:fynans/ui/widgets/common/app_pill.dart';
import 'package:fynans/ui/widgets/common/app_state_views.dart';

/// Below this many options the search box is pointless, so it is hidden.
const int _kSearchThreshold = 6;

/// A dropdown-style field for picking several values from a list.
/// Applies the caller's optional display transform.
String _display(String value, String Function(String)? format) =>
    format == null ? value : format(value);

class AppMultiSelectField extends StatelessWidget {
  const AppMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.formatOption,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// Optional display transform (e.g.
  final String Function(String)? formatOption;


  @override
  Widget build(BuildContext context) {
    final hasSelection = selected.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSectionLabel(
            label,
            trailing: hasSelection
                ? MonoText.small('${selected.length} selected')
                : null,
          ),
          AppSpacing.gapSm,
          InkWell(
            onTap: options.isEmpty ? null : () => _open(context),
            borderRadius: AppRadius.mdAll,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: hasSelection ? context.colors.accent : context.colors.border,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: hasSelection
                        ? Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: [
                              for (final value in selected)
                                AppPill(
                                  _display(value, formatOption),
                                  tone: AppPillTone.accent,
                                  dense: true,
                                  onRemove: () => onChanged(
                                    {...selected}..remove(value),
                                  ),
                                ),
                            ],
                          )
                        : Text(
                            options.isEmpty
                                ? 'No ${label.toLowerCase()} values yet'
                                : 'Any ${label.toLowerCase()}',
                            style: context.type.body.copyWith(
                              color: context.colors.inkFaint,
                            ),
                          ),
                  ),
                  AppSpacing.hGapSm,
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: context.colors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      constraints: const BoxConstraints(maxHeight: 560),
      builder: (_) => _MultiSelectSheet(
        label: label,
        options: options,
        selected: selected,
        formatOption: formatOption,
      ),
    );
    if (result != null) onChanged(result);
  }
}

class _MultiSelectSheet extends StatefulWidget {
  const _MultiSelectSheet({
    required this.label,
    required this.options,
    required this.selected,
    this.formatOption,
  });

  final String label;
  final List<String> options;
  final Set<String> selected;
  final String Function(String)? formatOption;

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late final Set<String> _draft = {...widget.selected};
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }


  List<String> get _visible {
    if (_query.isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options
        .where((o) => o.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    final showSearch = widget.options.length >= _kSearchThreshold;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Select ${widget.label.toLowerCase()}',
                    style: context.type.h2),
                if (showSearch) ...[
                  AppSpacing.gapMd,
                  TextField(
                    controller: _search,
                    autofocus: false,
                    style: context.type.body.copyWith(color: context.colors.ink),
                    onChanged: (value) => setState(() => _query = value.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search ${widget.label.toLowerCase()}',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16),
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: visible.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Text(
                      'Nothing matches “$_query”',
                      style: context.type.small,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final option = visible[index];
                      final checked = _draft.contains(option);
                      return CheckboxListTile(
                        value: checked,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: context.colors.accent,
                        title: Text(
                          _display(option, widget.formatOption),
                          style: context.type.bodyStrong,
                        ),
                        onChanged: (_) => setState(
                          () => checked
                              ? _draft.remove(option)
                              : _draft.add(option),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(),
          AppSheetActions(
            secondaryLabel: 'Clear',
            onSecondary: () => Navigator.pop(context, <String>{}),
            primaryLabel: _draft.isEmpty ? 'Done' : 'Done (${_draft.length})',
            onPrimary: () => Navigator.pop(context, _draft),
          ),
        ],
      ),
    );
  }
}
