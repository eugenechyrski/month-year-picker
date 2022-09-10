import 'dart:math' as math;

import 'package:flutter/material.dart' hide YearPicker;

import 'l10n/month_year_picker_localizations.dart';
import 'pickers.dart';
import 'utils.dart';

const _widthDivisor = 1.4;
const _heightDivisor = 1.25;
// ################################# CONSTANTS #################################
const _portraitDialogSize = Size(320.0 / _widthDivisor,
    480.0 / _heightDivisor - _datePickerHeaderPortraitHeight);
const _landscapeDialogSize = Size(
    496.0 / _widthDivisor - _datePickerHeaderLandscapeWidth,
    344.0 / _heightDivisor);
const _dialogSizeAnimationDuration = Duration(milliseconds: 200);
const _datePickerHeaderLandscapeWidth = 192.0 / _widthDivisor;

const _datePickerHeaderPortraitHeight = 120.0;

// ################################# FUNCTIONS #################################
/// Displays month year picker dialog.
/// [initialDate] is the initially selected month.
/// [firstDate] is the lower bound for month selection.
/// [lastDate] is the upper bound for month selection.
Future<DateTime?> showMonthYearPicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  SelectableMonthYearPredicate? selectableMonthYearPredicate,
  Locale? locale,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  TextDirection? textDirection,
  TransitionBuilder? builder,
  MonthYearPickerMode initialMonthYearPickerMode = MonthYearPickerMode.month,
}) async {
  initialDate = monthYearOnly(initialDate);
  firstDate = monthYearOnly(firstDate);
  lastDate = monthYearOnly(lastDate);

  assert(
    !lastDate.isBefore(firstDate),
    'lastDate $lastDate must be on or after firstDate $firstDate.',
  );
  assert(
    !initialDate.isBefore(firstDate),
    'initialDate $initialDate must be on or after firstDate $firstDate.',
  );
  assert(
    !initialDate.isAfter(lastDate),
    'initialDate $initialDate must be on or before lastDate $lastDate.',
  );
  assert(debugCheckHasMaterialLocalizations(context));
  assert(debugCheckHasMonthYearPickerLocalizations(context));
  assert(debugCheckHasDirectionality(context));

  Widget dialog = MonthYearPickerDialog(
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    initialMonthYearPickerMode: initialMonthYearPickerMode,
    selectableMonthYearPredicate: selectableMonthYearPredicate,
  );

  if (textDirection != null) {
    dialog = Directionality(
      textDirection: textDirection,
      child: dialog,
    );
  }

  if (locale != null) {
    dialog = Localizations.override(
      context: context,
      locale: locale,
      child: dialog,
    );
  }

  return await showDialog<DateTime>(
    context: context,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    builder: (context) => builder == null ? dialog : builder(context, dialog),
  );
}

// ################################ ENUMERATIONS ###############################
enum MonthYearPickerMode {
  month,
  year,
}

// ################################## CLASSES ##################################
class MonthYearPickerDialog extends StatefulWidget {
  // ------------------------------- CONSTRUCTORS ------------------------------
  const MonthYearPickerDialog({
    Key? key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.initialMonthYearPickerMode,
    this.selectableMonthYearPredicate,
    this.onMonthSelected,
  }) : super(key: key);

  // ---------------------------------- FIELDS ---------------------------------
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime>? onMonthSelected;
  final MonthYearPickerMode initialMonthYearPickerMode;
  final SelectableMonthYearPredicate? selectableMonthYearPredicate;

  // --------------------------------- METHODS ---------------------------------
  @override
  State<MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<MonthYearPickerDialog> {
  // ---------------------------------- FIELDS ---------------------------------
  final _yearPickerState = GlobalKey<YearPickerState>();
  final _monthPickerState = GlobalKey<MonthPickerState>();
  var _isShowingYear = false;
  var _canGoPrevious = false;
  var _canGoNext = false;
  late DateTime _selectedDate = widget.initialDate;
  late final ValueChanged<DateTime>? _onMonthSelected = widget.onMonthSelected;

  // -------------------------------- PROPERTIES -------------------------------
  Size get _dialogSize {
    final orientation = MediaQuery.of(context).orientation;
    final offset =
        Theme.of(context).materialTapTargetSize == MaterialTapTargetSize.padded
            ? const Offset(0.0, 24.0)
            : Offset.zero;
    switch (orientation) {
      case Orientation.portrait:
        return _portraitDialogSize + offset;
      case Orientation.landscape:
        return _landscapeDialogSize + offset;
    }
  }

  // --------------------------------- METHODS ---------------------------------
  @override
  void initState() {
    super.initState();
    _isShowingYear =
        widget.initialMonthYearPickerMode == MonthYearPickerMode.year;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(_updatePaginators);
    });
  }

  @override
  Widget build(BuildContext context) {
    final materialLocalizations = MaterialLocalizations.of(context);
    final localizations = MonthYearPickerLocalizations.of(context);
    final media = MediaQuery.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final orientation = media.orientation;
    final textTheme = theme.textTheme;
    // Constrain the textScaleFactor to the largest supported value to prevent
    // layout issues.
    final textScaleFactor = math.min(media.textScaleFactor, 1.3);
    final direction = Directionality.of(context);

    final onPrimarySurface = colorScheme.brightness == Brightness.light
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final dateStyle = orientation == Orientation.landscape
        ? textTheme.headline5?.copyWith(color: onPrimarySurface)
        : textTheme.headline4?.copyWith(color: onPrimarySurface);

    final Widget actions = Container(
      alignment: AlignmentDirectional.centerEnd,
      constraints: const BoxConstraints(minHeight: 52.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: OverflowBar(
        spacing: 8.0,
        children: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedDate),
            child: Text(localizations.okButtonLabel),
          ),
        ],
      ),
    );

    final switcher = Stack(
      children: [
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsetsDirectional.fromSTEB(
              32.0,
              24.0,
              8.0,
              24.0,
            ),
            primary: Theme.of(context).textTheme.caption?.color,
          ),
          child: Row(
            children: [
              Text(materialLocalizations.formatYear(_selectedDate)),
              AnimatedRotation(
                duration: _dialogSizeAnimationDuration,
                turns: _isShowingYear ? 0.5 : 0.0,
                child: const Icon(Icons.arrow_drop_down),
              ),
            ],
          ),
          onPressed: () {
            setState(() {
              _isShowingYear = !_isShowingYear;
              _updatePaginators();
            });
          },
        ),
        PositionedDirectional(
          end: 0.0,
          top: 0.0,
          bottom: 0.0,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  direction == TextDirection.rtl
                      ? Icons.keyboard_arrow_right
                      : Icons.keyboard_arrow_left,
                ),
                onPressed: _canGoPrevious ? _goToPreviousPage : null,
              ),
              IconButton(
                icon: Icon(
                  direction == TextDirection.rtl
                      ? Icons.keyboard_arrow_left
                      : Icons.keyboard_arrow_right,
                ),
                onPressed: _canGoNext ? _goToNextPage : null,
              )
            ],
          ),
        ),
        const SizedBox(width: 12.0),
      ],
    );

    final picker = LayoutBuilder(
      builder: (context, constraints) {
        final pickerMaxWidth = _landscapeDialogSize.width;
        final width = constraints.maxHeight < pickerMaxWidth
            ? constraints.maxHeight / 3.0 * 4.0
            : null;

        return Stack(
          children: [
            AnimatedPositioned(
              duration: _dialogSizeAnimationDuration,
              curve: Curves.easeOut,
              left: 0.0,
              right: (pickerMaxWidth - (width ?? pickerMaxWidth)),
              top: _isShowingYear ? 0.0 : -constraints.maxHeight,
              bottom: _isShowingYear ? 0.0 : constraints.maxHeight,
              child: SizedBox(
                height: constraints.maxHeight,
                child: YearPicker(
                  key: _yearPickerState,
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onPageChanged: _updateSelectedDate,
                  onYearSelected: _updateYear,
                  selectedDate: _selectedDate,
                  selectableMonthYearPredicate:
                      widget.selectableMonthYearPredicate,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: _dialogSizeAnimationDuration,
              curve: Curves.easeOut,
              left: 0.0,
              right: (pickerMaxWidth - (width ?? pickerMaxWidth)),
              top: _isShowingYear ? constraints.maxHeight : 0.0,
              bottom: _isShowingYear ? -constraints.maxHeight : 0.0,
              child: SizedBox(
                height: constraints.maxHeight,
                child: MonthPicker(
                  key: _monthPickerState,
                  initialDate: _selectedDate,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  onPageChanged: _updateSelectedDate,
                  onMonthSelected: _updateMonth,
                  selectedDate: _selectedDate,
                  selectableMonthYearPredicate:
                      widget.selectableMonthYearPredicate,
                ),
              ),
            )
          ],
        );
      },
    );

    final dialogSize = _dialogSize * textScaleFactor;
    return Directionality(
      textDirection: direction,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 24.0,
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedContainer(
          width: dialogSize.width,
          height: dialogSize.height,
          duration: _dialogSizeAnimationDuration,
          curve: Curves.easeIn,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: textScaleFactor,
            ),
            child: Builder(
              builder: (context) {
                switch (orientation) {
                  case Orientation.portrait:
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        switcher,
                        Expanded(child: picker),
                      ],
                    );
                  case Orientation.landscape:
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              switcher,
                              Expanded(child: picker),
                            ],
                          ),
                        ),
                      ],
                    );
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _updateYear(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, _selectedDate.month);
      _isShowingYear = false;
      _monthPickerState.currentState!.goToYear(year: _selectedDate.year);
    });
  }

  void _updateMonth(DateTime date) {
    if (_onMonthSelected != null) {
      _onMonthSelected!(DateTime(date.year, date.month));
    }
    setState(() {
      _selectedDate = DateTime(date.year, date.month);
    });
  }

  void _updateSelectedDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month);
      _updatePaginators();
    });
  }

  void _updatePaginators() {
    if (_isShowingYear) {
      _canGoNext = _yearPickerState.currentState!.canGoUp;
      _canGoPrevious = _yearPickerState.currentState!.canGoDown;
    } else {
      _canGoNext = _monthPickerState.currentState!.canGoUp;
      _canGoPrevious = _monthPickerState.currentState!.canGoDown;
    }
  }

  void _goToPreviousPage() {
    if (_isShowingYear) {
      _yearPickerState.currentState!.goDown();
    } else {
      _monthPickerState.currentState!.goDown();
    }
  }

  void _goToNextPage() {
    if (_isShowingYear) {
      _yearPickerState.currentState!.goUp();
    } else {
      _monthPickerState.currentState!.goUp();
    }
  }
}
