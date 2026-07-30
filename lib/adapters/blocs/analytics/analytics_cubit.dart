import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fynans/entities/monthly_analytics.dart';
import 'package:fynans/use_cases/get_monthly_analytics.dart';
import 'analytics_state.dart';

/// Streams a month's analytics, recomputing whenever the stored transactions
/// change — so an SMS import or a new manual entry shows up without the user
/// having to re-pick the month.
class AnalyticsCubit extends Cubit<AnalyticsState> {
  final GetMonthlyAnalytics _getMonthlyAnalytics;
  StreamSubscription<MonthlyAnalytics>? _subscription;

  /// Bumped per load so a late event from a superseded month is discarded.
  int _generation = 0;

  AnalyticsCubit(this._getMonthlyAnalytics) : super(AnalyticsInitial());

  /// Subscribes to [month]'s analytics, replacing any previous subscription.
  Future<void> loadAnalytics(DateTime month) async {
    final generation = ++_generation;
    await _subscription?.cancel();
    emit(AnalyticsLoadInProgress());

    _subscription = _getMonthlyAnalytics.watch(month).listen(
      (analytics) {
        if (isClosed || generation != _generation) return;
        emit(AnalyticsLoadSuccess(analytics));
      },
      onError: (Object error) {
        if (isClosed || generation != _generation) return;
        emit(AnalyticsLoadFailure(error.toString()));
      },
    );
  }

  @override
  Future<void> close() async {
    _generation++;
    await _subscription?.cancel();
    return super.close();
  }
}
