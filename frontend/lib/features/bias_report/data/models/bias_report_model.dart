import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';

class BiasReportModel extends BiasReportEntity {
  const BiasReportModel({
    required super.politicalLean,
    required super.emotionalLanguageScore,
    required super.framingNotes,
    super.analyzedAt,
  });

  factory BiasReportModel.fromMap(Map<String, dynamic> map) {
    return BiasReportModel(
      politicalLean: (map['politicalLean'] as num?)?.toDouble() ?? 0.0,
      emotionalLanguageScore:
          (map['emotionalLanguageScore'] as num?)?.toDouble() ?? 0.0,
      framingNotes: (map['framingNotes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      analyzedAt: (map['analyzedAt'] as Timestamp?)?.toDate(),
    );
  }

  BiasReportEntity toEntity() => BiasReportEntity(
        politicalLean: politicalLean,
        emotionalLanguageScore: emotionalLanguageScore,
        framingNotes: framingNotes,
        analyzedAt: analyzedAt,
      );
}
