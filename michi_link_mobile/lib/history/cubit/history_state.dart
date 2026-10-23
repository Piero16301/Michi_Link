part of 'history_cubit.dart';

class HistoryState extends Equatable {
  const HistoryState({
    this.collarId = '',
    this.selectedDate,
    this.startHour = 0,
    this.endHour = 24,
    this.selectedRecord,
  });

  final String collarId;
  final DateTime? selectedDate;
  final double startHour;
  final double endHour;
  final HistoryRecord? selectedRecord;

  DateTime get effectiveDate {
    final now = DateTime.now();
    return selectedDate ?? DateTime(now.year, now.month, now.day);
  }

  DateTime get startDateTime {
    final d = effectiveDate;
    final hour = startHour.toInt().clamp(0, 23);
    final minute = ((startHour - startHour.toInt()) * 60).round().clamp(0, 59);
    return DateTime(d.year, d.month, d.day, hour, minute);
  }

  DateTime get endDateTime {
    final d = effectiveDate;
    final hour = endHour.toInt();
    if (hour >= 24) {
      return DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
    }
    final minute = ((endHour - hour) * 60).round().clamp(0, 59);
    return DateTime(d.year, d.month, d.day, hour, minute, 59, 999);
  }

  HistoryState copyWith({
    String? collarId,
    DateTime? selectedDate,
    double? startHour,
    double? endHour,
    HistoryRecord? Function()? selectedRecord,
  }) {
    return HistoryState(
      collarId: collarId ?? this.collarId,
      selectedDate: selectedDate ?? this.selectedDate,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      selectedRecord: selectedRecord != null
          ? selectedRecord()
          : this.selectedRecord,
    );
  }

  @override
  List<Object?> get props => [
    collarId,
    selectedDate,
    startHour,
    endHour,
    selectedRecord,
  ];
}
