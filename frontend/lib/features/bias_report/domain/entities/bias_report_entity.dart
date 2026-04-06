import 'package:equatable/equatable.dart';

class BiasReportEntity extends Equatable {
  final double politicalLean;
  final double emotionalLanguageScore;
  final List<String> framingNotes;
  final DateTime? analyzedAt;

  const BiasReportEntity({
    required this.politicalLean,
    required this.emotionalLanguageScore,
    required this.framingNotes,
    this.analyzedAt,
  });

  @override
  List<Object?> get props =>
      [politicalLean, emotionalLanguageScore, framingNotes, analyzedAt];
}
