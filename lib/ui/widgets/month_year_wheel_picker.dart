import 'package:flutter/material.dart';
import 'package:fynans/ui/theme/app_colors.dart';
import 'package:fynans/ui/theme/app_spacing.dart';
import 'package:fynans/ui/theme/app_typography.dart';
import 'package:fynans/ui/widgets/common/common.dart';
import 'package:intl/intl.dart';
import 'package:wheel_picker/wheel_picker.dart';

/// Wheel sizing.
const double _kItemFontSize = 20;
const double _kItemHeight = 1.6;
const double _kWheelHeight = 190;
const double _kSelectionBarHeight = 36;

/// Month + year wheel, shown as a bottom sheet via [show].
class MonthYearWheelPicker extends StatefulWidget {
  const MonthYearWheelPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<MonthYearWheelPicker> createState() => MonthYearWheelPickerState();

  /// Opens the picker and resolves to the chosen month, or null if dismissed.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    var selectedDate = initialDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            0,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionLabel('Jump to'),
              AppSpacing.gapXs,
              Text('Pick a month', style: context.type.h2),
              AppSpacing.gapLg,
              SizedBox(
                height: _kWheelHeight,
                child: MonthYearWheelPicker(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onChanged: (date) => selectedDate = date,
                ),
              ),
              AppSpacing.gapLg,
              AppButton(
                label: 'Done',
                variant: AppButtonVariant.dark,
                expand: true,
                onPressed: () => Navigator.pop(context, selectedDate),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthYearWheelPickerState extends State<MonthYearWheelPicker> {
  /// Not a constant: the wheel's ink follows the active theme.
  TextStyle _itemStyle(BuildContext context) => TextStyle(
        fontFamily: AppTypography.mono,
        fontSize: _kItemFontSize,
        height: _kItemHeight,
        color: context.colors.ink,
      );

  static final WheelPickerStyle _wheelStyle = WheelPickerStyle(
    itemExtent: _kItemFontSize * _kItemHeight,
    squeeze: 1.15,
    diameterRatio: 1.1,
    surroundingOpacity: .3,
    magnification: 1.15,
  );

  /// SHORTMONTHS, not MONTHS — three-letter labels (JAN, FEB) keep the wheel
  /// legible; the full names overflowed the column.
  static final List<String> _monthNames =
      DateFormat().dateSymbols.SHORTMONTHS;

  late final _monthsWheel = WheelPickerController(
    itemCount: 12,
    initialIndex: widget.initialDate.month - 1,
  );
  late final _yearsWheel = WheelPickerController(
    itemCount: widget.lastDate.year - widget.firstDate.year + 1,
    initialIndex: widget.initialDate.year - widget.firstDate.year,
  );

  late int _monthIndex = widget.initialDate.month - 1;
  late int _yearIndex = widget.initialDate.year - widget.firstDate.year;

  @override
  void dispose() {
    _monthsWheel.dispose();
    _yearsWheel.dispose();
    super.dispose();
  }

  void _emitChange() => widget.onChanged(_clamped());

  /// Test hook: drive the wheels without simulating a fling, so the clamping
  /// contract can be asserted directly.
  @visibleForTesting
  void debugSelect({int? monthIndex, int? yearIndex}) {
    if (monthIndex != null) _monthIndex = monthIndex;
    if (yearIndex != null) _yearIndex = yearIndex;
    _emitChange();
  }

  /// The wheels offer all 12 months for every year, so a selection can fall
  /// outside the caller's declared bounds (e.g.
  DateTime _clamped() {
    final picked = DateTime(widget.firstDate.year + _yearIndex, _monthIndex + 1, 1);
    final first = DateTime(widget.firstDate.year, widget.firstDate.month, 1);
    final last = DateTime(widget.lastDate.year, widget.lastDate.month, 1);
    if (picked.isBefore(first)) return first;
    if (picked.isAfter(last)) return last;
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            height: _kSelectionBarHeight,
            decoration: BoxDecoration(
              color: context.colors.surfaceAccent,
              borderRadius: AppRadius.mdAll,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: WheelPicker(
                controller: _monthsWheel,
                looping: false,
                style: _wheelStyle,
                selectedIndexColor: context.colors.accent,
                onIndexChanged: (index, _) {
                  _monthIndex = index;
                  _emitChange();
                },
                builder: (context, index) =>
                    MonoText(_monthNames[index], style: _itemStyle(context)),
              ),
            ),
            Expanded(
              child: WheelPicker(
                controller: _yearsWheel,
                looping: false,
                style: _wheelStyle,
                selectedIndexColor: context.colors.accent,
                onIndexChanged: (index, _) {
                  _yearIndex = index;
                  _emitChange();
                },
                builder: (context, index) => MonoText(
                  '${widget.firstDate.year + index}',
                  style: _itemStyle(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
