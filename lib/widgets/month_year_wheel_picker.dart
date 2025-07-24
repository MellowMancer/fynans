import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wheel_picker/wheel_picker.dart';

class MonthYearWheelPicker extends StatefulWidget {
  const MonthYearWheelPicker({super.key, required this.initialDate, required this.firstDate, required this.lastDate, required this.onChanged});

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  State<MonthYearWheelPicker> createState() => MonthYearWheelPickerState();

  /// Shows a modal bottom sheet with the MonthYearWheelPicker.
  static Future<DateTime?> show({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    // This variable will be updated by the picker's onChanged callback.
    DateTime selectedDate = initialDate;

    return showModalBottomSheet<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 300,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, selectedDate),
                  child: const Text('Done'),
                ),
              ),
              Expanded(
                child: MonthYearWheelPicker(
                  initialDate: initialDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onChanged: (newDate) => selectedDate = newDate,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class MonthYearWheelPickerState extends State<MonthYearWheelPicker>{
  late final _monthsWheel = WheelPickerController(
    itemCount: 12,
    initialIndex: widget.initialDate.month - 1, 
  );
  late final _yearsWheel = WheelPickerController(
    itemCount: widget.lastDate.year - widget.firstDate.year + 1,
    initialIndex: widget.initialDate.year - widget.firstDate.year,
  );


  late int _selectedMonthIndex;
  late int _selectedYearIndex;

  @override
  void initState() {
    super.initState();
    _selectedMonthIndex = widget.initialDate.month - 1;
    _selectedYearIndex = widget.initialDate.year - widget.firstDate.year;
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 26.0, height: 1.5);
    final wheelStyle = WheelPickerStyle(
      itemExtent: textStyle.fontSize! * textStyle.height!, // Text height
      squeeze: 1.25,
      diameterRatio: .8,
      surroundingOpacity: .25,
      magnification: 1.2,
    );

    Widget monthItemBuilder(BuildContext context, int index) {
      final monthNames = DateFormat.MMM().dateSymbols.MONTHS;
      return Text(monthNames[index], style: textStyle);
    }

    Widget yearItemBuilder(BuildContext context, int index) {
      final year = widget.firstDate.year + index;
      return Text('$year', style: textStyle);
    }

    return Center(
      child: SizedBox(
        width: 200.0,
        height: 200.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _centerBar(context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Expanded(
                    child: WheelPicker(
                      builder: monthItemBuilder,
                      controller: _monthsWheel,
                      looping: false,
                      style: wheelStyle,
                      selectedIndexColor: Theme.of(context).colorScheme.primary,
                      onIndexChanged: (index, _) {
                        _selectedMonthIndex = index;
                        _onDateChanged();
                      },
                    ),
                  ),
                  Expanded(
                    child: WheelPicker(
                      builder: yearItemBuilder,
                      controller: _yearsWheel,
                      looping: false,
                      style: wheelStyle,
                      selectedIndexColor: Theme.of(context).colorScheme.primary,
                      onIndexChanged: (index, _) {
                        _selectedYearIndex = index;
                        _onDateChanged();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    )
    );
  }

  void _onDateChanged() {
    final selectedMonth = _selectedMonthIndex + 1; // Convert 0-indexed to 1-indexed month
    final selectedYear = widget.firstDate.year + _selectedYearIndex;
    final newDate = DateTime(selectedYear, selectedMonth, 1);
    widget.onChanged(newDate);
  }

  @override
  void dispose() {
    // Don't forget to dispose the controllers at the end.
    _monthsWheel.dispose();
    _yearsWheel.dispose();
    super.dispose();
  }

  Widget _centerBar(BuildContext context) {
    return Center(
      child: Container(
        height: 38.0,
        decoration: BoxDecoration(
          color: const Color(0xFFC3C9FA).withAlpha(26),
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
}

}
