import 'package:equatable/equatable.dart';

class BiasLandscapeEntity extends Equatable {
  final int leftCount;
  final int centerCount;
  final int rightCount;
  final int totalCount;

  const BiasLandscapeEntity({
    required this.leftCount,
    required this.centerCount,
    required this.rightCount,
    required this.totalCount,
  });

  double get leftPercent =>
      totalCount > 0 ? leftCount / totalCount : 0;
  double get centerPercent =>
      totalCount > 0 ? centerCount / totalCount : 0;
  double get rightPercent =>
      totalCount > 0 ? rightCount / totalCount : 0;

  @override
  List<Object?> get props => [leftCount, centerCount, rightCount, totalCount];
}
