// Copyright (c) 2021 Simform Solutions. All rights reserved.
// Use of this source code is governed by a MIT-style license
// that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../calendar_constants.dart';
import '../calendar_controller_provider.dart';
import '../calendar_event_data.dart';
import '../components/components.dart';
import '../constants.dart';
import '../event_controller.dart';
import '../extensions.dart';
import '../typedefs.dart';

class MonthView<T> extends StatefulWidget {
  /// A function that returns a [Widget] that determines appearance of
  /// each cell in month calendar.
  final CellBuilder<T>? cellBuilder;

  /// Builds month page title.
  ///
  /// Used default title builder if null.
  final DateWidgetBuilder? headerBuilder;

  /// Called when user changes month.
  final CalendarPageChangeCallBack? onPageChange;

  /// This function will be called when user taps on month view cell.
  final CellTapCallback<T>? onCellTap;

  /// This function will be called when user will tap on a single event
  /// tile inside a cell.
  ///
  /// This function will only work if [cellBuilder] is null.
  final TileTapCallback<T>? onEventTap;

  /// Builds the name of the weeks.
  ///
  /// Used default week builder if null.
  ///
  /// Here day will range from 0 to 6 starting from Monday to Sunday.
  final WeekDayBuilder? weekDayBuilder;

  /// Determines the lower boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.epochDate] is default.
  final DateTime? minMonth;

  /// Determines upper boundary user can scroll.
  ///
  /// If not provided [CalendarConstants.maxDate] is default.
  final DateTime? maxMonth;

  /// Defines initial display month.
  ///
  /// If not provided [DateTime.now] is default date.
  final DateTime? initialMonth;

  /// Defines whether to show default borders or not.
  ///
  /// Default value is true
  ///
  /// Use [borderSize] to define width of the border and
  /// [borderColor] to define color of the border.
  final bool showBorder;

  /// Defines width of default border
  ///
  /// Default value is [Colors.blue]
  ///
  /// It will take affect only if [showBorder] is set.
  final Color borderColor;

  /// Page transition duration used when user try to change page using
  /// [MonthView.nextPage] or [MonthView.previousPage]
  final Duration pageTransitionDuration;

  /// Page transition curve used when user try to change page using
  /// [MonthView.nextPage] or [MonthView.previousPage]
  final Curve pageTransitionCurve;

  /// A required parameters that controls events for month view.
  ///
  /// This will auto update month view when user adds events in controller.
  /// This controller will store all the events. And returns events
  /// for particular day.
  ///
  /// If [controller] is null it will take controller from
  /// [CalendarControllerProvider.controller].
  final EventController<T>? controller;

  /// Defines width of default border
  ///
  /// Default value is 1
  ///
  /// It will take affect only if [showBorder] is set.
  final double borderSize;

  /// Defines aspect ratio of day cells in month calendar page.
  final double cellAspectRatio;

  final String displayFormat;

  final String locale;

  final bool? isShowCurrentDate;

  final List<DateTime>? disabledDates;

  final List<int>? disabledWeekdays;

  /// Width of month view.
  ///
  /// If null is provided then It will take width of closest [MediaQuery].
  final double? width;

  /// Main [Widget] to display month view.
  const MonthView({
    Key? key,
    this.showBorder = true,
    this.borderColor = Constants.defaultBorderColor,
    this.cellBuilder,
    this.minMonth,
    this.maxMonth,
    this.controller,
    this.initialMonth,
    this.borderSize = 1,
    this.cellAspectRatio = 0.55,
    this.headerBuilder,
    this.weekDayBuilder,
    this.pageTransitionDuration = const Duration(milliseconds: 300),
    this.pageTransitionCurve = Curves.ease,
    this.width,
    required this.displayFormat,
    required this.locale,
    this.onPageChange,
    this.onCellTap,
    this.onEventTap,
    this.isShowCurrentDate,
    this.disabledDates,
    this.disabledWeekdays,
  }) : super(key: key);

  @override
  MonthViewState<T> createState() => MonthViewState<T>();
}

/// State of month view.
class MonthViewState<T> extends State<MonthView<T>> {
  late DateTime _minDate;
  late DateTime _maxDate;

  late DateTime _currentDate;

  late int _currentIndex;

  int _totalMonths = 0;

  late PageController _pageController;

  late double _width;
  late double _height;

  late double _cellWidth;
  late double _cellHeight;

  late CellBuilder<T> _cellBuilder;

  late WeekDayBuilder _weekBuilder;

  late DateWidgetBuilder _headerBuilder;

  late EventController<T> _controller;

  bool _controllerAdded = false;

  late VoidCallback _reloadCallback;

  late List<String> _days;

  late bool _isShowCurrentDate;

  late List<DateTime> _disabledDates;

  late List<int> _disabledWeekdays;

  late TileTapCallback<T>? _onEventTap;

  @override
  void initState() {
    super.initState();

    _days = DateFormat.EEEE(widget.locale.toString()).dateSymbols.SHORTWEEKDAYS;

    _reloadCallback = _reload;

    // Initialize minimum date.
    _minDate = widget.minMonth ?? CalendarConstants.epochDate;

    // Initialize maximum date.
    _maxDate = widget.maxMonth ?? CalendarConstants.maxDate;

    assert(
      _minDate.isBefore(_maxDate),
      "Minimum date should be less than maximum date.\n"
      "Provided minimum date: $_minDate, maximum date: $_maxDate",
    );

    // Initialize current date.
    _currentDate = widget.initialMonth ?? DateTime.now();

    // make sure that _currentDate is between _minDate and _maxDate.
    if (_currentDate.isBefore(_minDate)) {
      _currentDate = _minDate;
    } else if (_currentDate.isAfter(_maxDate)) {
      _currentDate = _maxDate;
    }

    // Get number of months between _minDate and _maxDate.
    // This number will be number of page in page view.
    _totalMonths = _maxDate.getMonthDifference(_minDate);

    // Calculate the current index of page view.
    _currentIndex = _minDate.getMonthDifference(_currentDate) - 1;

    // Initialize page controller to control page actions.
    _pageController = PageController(initialPage: _currentIndex);

    // Initialize cell builder. Assign default if widget.cellBuilder is null.
    _cellBuilder = widget.cellBuilder ?? _defaultCellBuilder;

    // Initialize week builder. Assign default if widget.weekBuilder is null.
    // This widget will come under header this will display week days.
    _weekBuilder = widget.weekDayBuilder ?? _defaultWeekDayBuilder;

    // Initialize header builder. Assign default if widget.headerBuilder
    // is null.
    //
    // This widget will be displayed on top of the page.
    // from where user can see month and change month.
    _headerBuilder = widget.headerBuilder ?? _defaultHeaderBuilder;

    _isShowCurrentDate = widget.isShowCurrentDate ?? false;

    _disabledDates = widget.disabledDates ?? [];

    _disabledWeekdays = widget.disabledWeekdays ?? [];

    _onEventTap = (d, dt) {
      setState(() {
        _currentDate = dt;
      });

      widget.onEventTap?.call(d, dt);
    };
  }

  @override
  void dispose() {
    _controller.removeListener(_reloadCallback);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_controllerAdded) {
      _controller = widget.controller ??
          CalendarControllerProvider.of<T>(context).controller;

      // Reloads the view if there is any change in controller or user adds
      // new events.
      _controller.addListener(_reloadCallback);

      _controllerAdded = true;
    }

    _width = widget.width ?? MediaQuery.of(context).size.width;
    _cellWidth = _width / 7;
    _cellHeight = _cellWidth / widget.cellAspectRatio;
    _height = _cellHeight * 6;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        width: _width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: _width,
              child: _headerBuilder(
                  _currentDate, widget.displayFormat, widget.locale),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChange,
                itemBuilder: (_, index) {
                  final date = DateTime(_minDate.year, _minDate.month + index);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: _width,
                        child: Row(
                          children: List.generate(
                            7,
                            (index) => SizedBox(
                              width: _cellWidth,
                              child: _weekBuilder(index),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          child: SizedBox(
                            height: _height,
                            width: _width,
                            child: _MonthPageBuilder<T>(
                              key: ValueKey(date.toIso8601String()),
                              onCellTap: (list, dt) {
                                setState(() {
                                  _currentDate = dt;
                                });
                                widget.onCellTap?.call(list, dt);
                              },
                              width: _width,
                              height: _height,
                              controller: _controller,
                              borderColor: widget.borderColor,
                              borderSize: widget.borderSize,
                              cellBuilder: _cellBuilder,
                              cellRatio: widget.cellAspectRatio,
                              date: date,
                              minMonth: widget.minMonth,
                              showBorder: widget.showBorder,
                              currentDate: _currentDate,
                              isShowCurrentDate: _isShowCurrentDate,
                              disabledDates: _disabledDates,
                              disabledWeekdays: _disabledWeekdays,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                itemCount: _totalMonths,
              ),
            ),
          ],
        ),
      ),
    );
  }

  EventController<T> get controller {
    assert(_controllerAdded, "EventController is not initialized yet.");

    return _controller;
  }

  void _reload() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Calls when user changes page using gesture or inbuilt methods.
  void _onPageChange(int value) {
    if (mounted) {
      setState(() {
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month + (value - _currentIndex),
          _currentDate.day,
        );
        _currentIndex = value;
      });
    }
    widget.onPageChange?.call(_currentDate, _currentIndex);
  }

  /// Default month view header builder
  Widget _defaultHeaderBuilder(
      DateTime date, String displayFormat, String locale) {
    return MonthPageHeader(
      onTitleTapped: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: _minDate,
          lastDate: _maxDate,
        );

        if (selectedDate == null) return;
        jumpToMonth(selectedDate);
      },
      onPreviousMonth: previousPage,
      date: date,
      onNextMonth: nextPage,
      displayFormat: displayFormat,
      locale: locale,
    );
  }

  /// Default builder for week line.
  Widget _defaultWeekDayBuilder(int index) {
    return WeekDayTile(
      dayIndex: index,
      days: _days,
    );
  }

  /// Default cell builder. Used when [widget.cellBuilder] is null
  Widget _defaultCellBuilder<T>(
      date, List<CalendarEventData<T>> events, isToday, isInMonth, isEnabled) {
    return FilledCell<T>(
      date: date,
      shouldHighlight: isToday,
      backgroundColor: !isEnabled
          ? Constants.grey
          : isInMonth
              ? Constants.white
              : Constants.offWhite,
      events: events,
      onTileTap: _onEventTap as TileTapCallback<T>?,
    );
  }

  /// Animate to next page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  void nextPage({Duration? duration, Curve? curve}) {
    _pageController.nextPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Animate to previous page
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  void previousPage({Duration? duration, Curve? curve}) {
    _pageController.previousPage(
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Jumps to page number [page]
  void jumpToPage(int page) {
    _pageController.jumpToPage(page);
  }

  /// Animate to page number [page].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  Future<void> animateToPage(int page,
      {Duration? duration, Curve? curve}) async {
    await _pageController.animateToPage(page,
        duration: duration ?? widget.pageTransitionDuration,
        curve: curve ?? widget.pageTransitionCurve);
  }

  /// Returns current page number.
  int get currentPage => _currentIndex;

  /// Jumps to page which gives month calendar for [month]
  void jumpToMonth(DateTime month) {
    if (month.isBefore(_minDate) || month.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    _pageController.jumpToPage(_minDate.getMonthDifference(month) - 1);
  }

  /// Animate to page which gives month calendar for [month].
  ///
  /// Arguments [duration] and [curve] will override default values provided
  /// as [MonthView.pageTransitionDuration] and [MonthView.pageTransitionCurve]
  /// respectively.
  Future<void> animateToMonth(DateTime month,
      {Duration? duration, Curve? curve}) async {
    if (month.isBefore(_minDate) || month.isAfter(_maxDate)) {
      throw "Invalid date selected.";
    }
    await _pageController.animateToPage(
      _minDate.getMonthDifference(month) - 1,
      duration: duration ?? widget.pageTransitionDuration,
      curve: curve ?? widget.pageTransitionCurve,
    );
  }

  /// Returns the current visible date in month view.
  DateTime get currentDate =>
      DateTime(_currentDate.year, _currentDate.month, _currentDate.day);
}

/// A single month page.
class _MonthPageBuilder<T> extends StatelessWidget {
  final DateTime? minMonth;
  final double cellRatio;
  final bool showBorder;
  final double borderSize;
  final Color borderColor;
  final CellBuilder<T> cellBuilder;
  final DateTime date;
  final EventController<T> controller;
  final double width;
  final double height;
  final CellTapCallback<T>? onCellTap;
  final bool isShowCurrentDate;
  final List<DateTime> disabledDates;
  final List<int> disabledWeekdays;
  final DateTime currentDate;

  const _MonthPageBuilder({
    Key? key,
    required this.minMonth,
    required this.cellRatio,
    required this.showBorder,
    required this.borderSize,
    required this.borderColor,
    required this.cellBuilder,
    required this.date,
    required this.controller,
    required this.width,
    required this.height,
    required this.onCellTap,
    required this.isShowCurrentDate,
    required this.disabledDates,
    required this.disabledWeekdays,
    required this.currentDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final monthDays = date.datesOfMonths;

    return Container(
      width: width,
      height: height,
      child: GridView.builder(
        physics: ClampingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: cellRatio,
        ),
        itemCount: 42,
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final events = controller.getEventsOnDay(monthDays[index]);
          final isValidDate = !(minMonth != null &&
              monthDays[index].isBefore(DateUtils.dateOnly(minMonth!)));
          final isDisabledDate =
              disabledDates.contains(DateUtils.dateOnly(monthDays[index]));
          final isDisabledWeekday = events.isEmpty &&
              disabledWeekdays.contains(monthDays[index].weekday);

          return GestureDetector(
            onTap: isValidDate
                ? () => onCellTap?.call(events, monthDays[index])
                : null,
            child: Container(
              decoration: BoxDecoration(
                border: monthDays[index].compareWithoutTime(currentDate) &&
                        isShowCurrentDate
                    ? Border.all(
                        color: Constants.headerBackground,
                        width: borderSize + 1,
                      )
                    : showBorder
                        ? Border.all(
                            color: borderColor,
                            width: borderSize,
                          )
                        : null,
              ),
              child: cellBuilder(
                monthDays[index],
                events,
                monthDays[index].compareWithoutTime(DateTime.now()),
                monthDays[index].month == date.month &&
                    !isDisabledDate &&
                    !isDisabledWeekday,
                isValidDate,
              ),
            ),
          );
        },
      ),
    );
  }
}
