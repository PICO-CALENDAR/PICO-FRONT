import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pico/classes/custom_calendar.dart';
import 'dart:math' as math;

class PicoArranger extends EventArranger<EventDetail> {
  @override
  List<OrganizedCalendarEventData<EventDetail>> arrange(
      {required List<CalendarEventData<EventDetail>> events,
      required double height,
      required double width,
      required double heightPerMinute,
      required int startHour}) {
    final totalWidth = width;

    List<_SideEventConfigs<EventDetail>> categorizedColumnedEvents(
        List<CalendarEventData<EventDetail>> events) {
      final merged = const MergeEventArranger<EventDetail>().arrange(
        events: events,
        height: height,
        width: width,
        heightPerMinute: heightPerMinute,
        startHour: startHour,
      );

      final arranged = <_SideEventConfigs<EventDetail>>[];

      for (final event in merged) {
        if (event.events.isEmpty) {
          // NOTE(parth): This is safety condition.
          // This condition should never be true.
          // If by chance this becomes true, there is something wrong with
          // logic. And that need to be fixed ASAP.

          continue;
        }

        if (event.events.length > 1) {
          // NOTE: This means all the events are overlapping with each other.
          // So, we will extract all the events that can be fit in
          // Single column without overlapping and run the function
          // again for the rest of the events.

          final columnedEvents = _extractSingleColumnEvents(
            event.events,
            event.endDuration.getTotalMinutes,
          );

          final sided = categorizedColumnedEvents(
            event.events.where((e) => !columnedEvents.contains(e)).toList(),
          );

          var maxColumns = 1;

          for (final event in sided) {
            if (event.columns > maxColumns) {
              maxColumns = event.columns;
            }
          }

          arranged.add(_SideEventConfigs(
            columns: maxColumns + 1,
            event: columnedEvents,
            sideEvents: sided,
          ));
        } else {
          // If this block gets executed that means we have only one event.
          // Return the event as is.

          arranged.add(_SideEventConfigs(columns: 1, event: event.events));
        }
      }

      return arranged;
    }

    List<OrganizedCalendarEventData<EventDetail>> arrangeEvents(
        List<_SideEventConfigs<EventDetail>> events,
        double width,
        double offset) {
      final arranged = <OrganizedCalendarEventData<EventDetail>>[];

      for (final event in events) {
        final slotWidth = math.min(width / event.columns, double.maxFinite);

        if (event.event.isNotEmpty) {
          // TODO(parth): Arrange events and add it in arranged.

          arranged.addAll(event.event.map((e) {
            final startTime = e.startTime!;
            final endTime = e.endTime!;

            // startTime.getTotalMinutes returns the number of minutes from 00h00 to the beginning hour of the event
            // But the first hour to be displayed (startHour) could be 06h00, so we have to substract
            // The number of minutes from 00h00 to startHour which is equal to startHour * 60

            final bottom = height -
                (endTime.getTotalMinutes - (startHour * 60) == 0
                        ? 1440 - (startHour * 60)
                        : endTime.getTotalMinutes - (startHour * 60)) *
                    heightPerMinute;

            final top = (startTime.getTotalMinutes - (startHour * 60)) *
                heightPerMinute;

            return OrganizedCalendarEventData<EventDetail>(
              left: offset,
              right: totalWidth - (offset + slotWidth),
              top: top,
              bottom: bottom,
              startDuration: startTime,
              endDuration: endTime,
              events: [e],
            );
          }));
        }

        if (event.sideEvents.isNotEmpty) {
          arranged.addAll(arrangeEvents(
            event.sideEvents,
            math.max(0, width - slotWidth),
            slotWidth + offset,
          ));
        }
      }

      return arranged;
    }

    // 시간 중복이 되는 것끼리 chunking
    final merged = const MergeEventArranger<EventDetail>().arrange(
      events: events,
      height: height,
      width: width,
      heightPerMinute: heightPerMinute,
      startHour: startHour,
    );

    final arranged = <OrganizedCalendarEventData<EventDetail>>[];

    for (var rowEvent in merged) {
      final rowEventData = rowEvent.events;
      if (rowEventData.isEmpty) {
        continue;
      }

      // 이벤트 리스트에서 카테고리 추출
      final categories = rowEventData.map((e) => e.event?.category).toSet();

      for (var category in categories) {
        final List<OrganizedCalendarEventData<EventDetail>> arrangedByCat;
        final eventListInCategory =
            rowEventData.where((e) => e.event?.category == category).toList();
        final columnedByCat = categorizedColumnedEvents(eventListInCategory);

        if (category == EventCategory.mine) {
          if (categories.contains(EventCategory.ours)) {
            arrangedByCat = arrangeEvents(columnedByCat, totalWidth / 3, 0);
          } else {
            arrangedByCat = arrangeEvents(columnedByCat, totalWidth / 2, 0);
          }
        } else if (category == EventCategory.yours) {
          if (categories.contains(EventCategory.ours)) {
            arrangedByCat = arrangeEvents(
                columnedByCat, totalWidth / 3, totalWidth * 2 / 3);
          } else {
            arrangedByCat =
                arrangeEvents(columnedByCat, totalWidth / 2, totalWidth / 2);
          }
        } else {
          // 우리
          if (categories.length == 3) {
            arrangedByCat =
                arrangeEvents(columnedByCat, totalWidth / 3, totalWidth / 3);
          } else {
            if (categories.contains(EventCategory.mine)) {
              arrangedByCat = arrangeEvents(
                  columnedByCat, totalWidth * 2 / 3, totalWidth / 3);
            } else if (categories.contains(EventCategory.yours)) {
              arrangedByCat =
                  arrangeEvents(columnedByCat, totalWidth * 2 / 3, 0);
            } else {
              arrangedByCat = arrangeEvents(columnedByCat, totalWidth, 0);
            }
          }
        }

        arranged.addAll(arrangedByCat);
      }
    }

    return arranged;
  }

  List<CalendarEventData<EventDetail>> _extractSingleColumnEvents(
      List<CalendarEventData<EventDetail>> events, int end) {
    // Find the longest event from the list.
    final longestEvent = events.fold<CalendarEventData<EventDetail>>(
      events.first,
      (e1, e2) => e1.duration > e2.duration ? e1 : e2,
    );

    // Create a new list from events and remove the longest one from it.
    final searchEvents = [...events]..remove(longestEvent);

    // Create a new list for events in single column.
    // Right now it has longest event,
    // By the end of the function, this will have the list of the events,
    // that are not intersecting with each other.
    // and this will be returned from the function.
    final columnedEvents = [longestEvent];

    // Calculate effective end minute from latest columned event.
    var endMinutes = longestEvent.endTime!.getTotalMinutes;

    // Run the loop while effective end minute of columned events are
    // less than end.
    while (endMinutes < end && searchEvents.isNotEmpty) {
      // Maps the event with it's duration.
      final mappings = <int, CalendarEventData<EventDetail>>{};

      // Create a new list from searchEvents.
      for (final event in [...searchEvents]) {
        // Need to add logic to include edges...
        final start = event.startTime!.getTotalMinutes;

        // TODO(parth): Need to improve this.
        // This does not handle the case where there is a event before the
        // longest event which is not intersecting.
        //
        if (start < endMinutes || start == endMinutes) {
          // Remove search event from list so, we do not iterate through it
          // again.
          searchEvents.remove(event);
        } else {
          // Add the event in mappings.
          final diff = event.startTime!.getTotalMinutes - endMinutes;

          mappings.addAll({
            diff: event,
          });
        }
      }

      // This can be any integer larger than 1440 as one day has 1440 minutes.
      // so, different of 2 events end and start time will never be greater than
      // 1440.
      var min = 4000;

      for (final mapping in mappings.entries) {
        if (mapping.key < min) {
          min = mapping.key;
        }
      }

      if (mappings[min] != null) {
        // If mapping had min event, add it in columnedEvents,
        // and remove it from searchEvents so, we do not iterate through it
        // again.
        columnedEvents.add(mappings[min]!);
        searchEvents.remove(mappings[min]);

        endMinutes = mappings[min]!.endTime!.getTotalMinutes;
      }
    }

    return columnedEvents;
  }
}

class _SideEventConfigs<T extends Object?> {
  final int columns;
  final List<CalendarEventData<T>> event;
  final List<_SideEventConfigs<T>> sideEvents;

  const _SideEventConfigs({
    this.event = const [],
    required this.columns,
    this.sideEvents = const [],
  });
}