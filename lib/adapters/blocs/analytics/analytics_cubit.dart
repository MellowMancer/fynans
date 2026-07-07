import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';
import 'analytics_state.dart';

/// Loads a single month's analytics on demand and emits loading/success/failure.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  final GetMonthlyAnalytics _getMonthlyAnalytics;

  AnalyticsCubit(this._getMonthlyAnalytics) : super(AnalyticsInitial());

  /// Fetches and computes analytics for [month], emitting progress then result.
  Future<void> loadAnalytics(DateTime month) async {
    emit(AnalyticsLoadInProgress());
    try {
      final analytics = await _getMonthlyAnalytics(month);
      emit(AnalyticsLoadSuccess(analytics));
    } catch (error) {
      emit(AnalyticsLoadFailure(error.toString()));
    }
  }
}
