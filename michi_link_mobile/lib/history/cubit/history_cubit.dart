import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:michi_link_mobile/app/app.dart';

part 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required String collarId,
    DateTime? initialDate,
    double? initialStartHour,
    double? initialEndHour,
  }) : super(
         HistoryState(
           collarId: collarId,
           selectedDate:
               initialDate ??
               () {
                 final now = DateTime.now();
                 return DateTime(now.year, now.month, now.day);
               }(),
           startHour:
               initialStartHour ??
               () {
                 final now = DateTime.now();
                 return now.hour.toDouble().clamp(0.0, 23.0);
               }(),
           endHour:
               initialEndHour ??
               () {
                 final now = DateTime.now();
                 return (now.hour + 1).toDouble().clamp(1.0, 24.0);
               }(),
         ),
       );

  void selectDate(DateTime date) {
    final cleanDate = DateTime(date.year, date.month, date.day);
    if (cleanDate == state.selectedDate) return;

    emit(state.copyWith(selectedDate: cleanDate, selectedRecord: () => null));
  }

  void previousDay() {
    final prev = state.effectiveDate.subtract(const Duration(days: 1));
    selectDate(prev);
  }

  void nextDay() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final next = state.effectiveDate.add(const Duration(days: 1));
    if (next.isAfter(today)) return;
    selectDate(next);
  }

  void changeTimeRange(double startHour, double endHour) {
    if (startHour == state.startHour && endHour == state.endHour) return;
    emit(
      state.copyWith(
        startHour: startHour,
        endHour: endHour,
        selectedRecord: () => null,
      ),
    );
  }

  void selectRecord(HistoryRecord? record) {
    emit(state.copyWith(selectedRecord: () => record));
  }
}
