import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/entry.dart';

void showCalendarModal(
  BuildContext context,
  List<Entry> entries,
  ScrollController scrollController,
) {
  FocusScope.of(context).unfocus();

  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: "calendar",
    barrierColor: Colors.transparent, // Make the default barrier transparent
    transitionDuration: const Duration(milliseconds: 300), // Keep duration
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return Stack(
        alignment: Alignment.center,
        children: [
          // Animated BackdropFilter
          AnimatedBuilder(
            animation: curvedAnimation,
            builder: (context, _) {
              // Removed child from builder as it's not used here
              return BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: curvedAnimation.value * 12.0, // Animate sigmaX
                  sigmaY: curvedAnimation.value * 12.0, // Animate sigmaY
                ),
                // The child of BackdropFilter is a Container that covers the screen.
                // Its opacity is also animated to ensure the blur effect fades in smoothly.
                child: Container(
                  color: Colors.black.withOpacity(
                    curvedAnimation.value * 0.0,
                  ), // Effectively transparent, but part of the animated layer
                ),
              );
            },
          ),
          // The actual dialog content, animated with Fade, Slide, and Scale
          FadeTransition(
            opacity: curvedAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.85,
                  end: 1.0,
                ).animate(curvedAnimation),
                child: child, // This 'child' is the result of pageBuilder
              ),
            ),
          ),
        ],
      );
    },
    pageBuilder:
        (_, __, ___) =>
        // This is the core content of the dialog
        GestureDetector(
          // Outer GestureDetector for dismissing when tapping outside the modal content
          onTap: () => Navigator.of(context).pop(),
          child: Material(
            color:
                Colors
                    .transparent, // Makes the area outside the card transparent
            child: Center(
              // Center the actual modal content
              child: GestureDetector(
                // Inner GestureDetector to prevent taps on the card from closing the dialog
                onTap: () {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 330,
                    maxHeight: 360,
                  ),
                  child: Material(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                    elevation: 16,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                      child: CalendarView(
                        entries: entries,
                        scrollController: scrollController,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
  );
}

class CalendarView extends StatelessWidget {
  final List<Entry> entries;
  final ScrollController scrollController;

  const CalendarView({
    super.key,
    required this.entries,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subtleTextColor = textColor.withOpacity(0.6);
    final verySubtleTextColor = textColor.withOpacity(0.3);
    final primaryAccentColor = theme.colorScheme.primary; // Usually deepPurple

    final validDates =
        entries
            .map(
              (e) => DateTime(
                e.rawDateTime.year,
                e.rawDateTime.month,
                e.rawDateTime.day,
              ),
            )
            .toSet();

    return SizedBox(
      height: 290, // Adjusted for potentially slightly larger text/padding
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.now(),
        focusedDay: DateTime.now(),
        sixWeekMonthsEnforced: false,
        rowHeight: 36, // Increased row height for clarity
        daysOfWeekHeight: 24, // Increased height
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            fontFamily: 'IBM Plex Sans',
            color: textColor,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            size: 20,
            color: subtleTextColor,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            size: 20,
            color: subtleTextColor,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 8.0),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtleTextColor,
          ),
          weekendStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtleTextColor.withOpacity(
              0.8,
            ), // Weekends slightly less prominent
          ),
        ),
        calendarStyle: CalendarStyle(
          cellMargin: const EdgeInsets.all(2.0), // Added margin
          defaultTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: textColor.withOpacity(0.85),
          ),
          weekendTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: textColor.withOpacity(0.7), // Weekends slightly dimmer
          ),
          disabledTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: verySubtleTextColor,
          ),
          outsideTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: verySubtleTextColor,
          ),
          todayDecoration: BoxDecoration(
            // color: primaryAccentColor.withOpacity(isDarkTheme ? 0.2 : 0.1),
            border: Border.all(
              color: primaryAccentColor.withOpacity(0.5),
              width: 1.5,
            ),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            color: primaryAccentColor, // Make today's text stand out
            fontWeight: FontWeight.bold,
          ),
          selectedDecoration: BoxDecoration(
            color: primaryAccentColor,
            shape: BoxShape.circle,
            // boxShadow: [ // Subtle shadow for selected date
            //   BoxShadow(
            //     color: primaryAccentColor.withOpacity(0.3),
            //     blurRadius: 4,
            //     offset: Offset(0, 2),
            //   )
            // ]
          ),
          selectedTextStyle: TextStyle(
            color:
                isDarkTheme
                    ? Colors.black
                    : Colors.white, // Contrast with primaryAccentColor
            fontFamily: 'IBM Plex Sans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          // Consider adding a subtle border to all cells for an "industrial" grid look
          // cellBorder: Border.all(color: textColor.withOpacity(0.08), width: 0.5),
        ),
        enabledDayPredicate:
            (day) =>
                validDates.contains(DateTime(day.year, day.month, day.day)),
        onDaySelected: (selectedDay, _) {
          Navigator.of(context).pop();
          Future.delayed(const Duration(milliseconds: 100), () {
            if (context.mounted) {
              FocusScope.of(context).unfocus();
            }
            final index = entries.indexWhere(
              (e) =>
                  e.rawDateTime.year == selectedDay.year &&
                  e.rawDateTime.month == selectedDay.month &&
                  e.rawDateTime.day == selectedDay.day,
            );
            if (index >= 0) {
              scrollController.animateTo(
                index *
                    180.0, // This magic number might need context or be a constant
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
              );
            }
          });
        },
      ),
    );
  }
}
