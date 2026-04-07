import 'package:equatable/equatable.dart';

class DailyViewsEntity extends Equatable {
  final String date; // YYYY-MM-DD
  final int count;

  const DailyViewsEntity({required this.date, required this.count});

  @override
  List<Object?> get props => [date, count];
}
