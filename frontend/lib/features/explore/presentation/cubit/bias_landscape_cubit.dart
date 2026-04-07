import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/features/analytics/domain/use_cases/get_bias_landscape_usecase.dart';
import 'package:news_lab/features/explore/presentation/cubit/bias_landscape_state.dart';

class BiasLandscapeCubit extends Cubit<BiasLandscapeState> {
  final GetBiasLandscapeUseCase _getBiasLandscape;

  BiasLandscapeCubit(this._getBiasLandscape) : super(const BiasLandscapeInitial());

  Future<void> load() async {
    emit(const BiasLandscapeLoading());
    try {
      final landscape = await _getBiasLandscape();
      emit(BiasLandscapeLoaded(landscape: landscape));
    } catch (e) {
      emit(BiasLandscapeError(message: e.toString()));
    }
  }
}
