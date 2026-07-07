import 'package:equatable/equatable.dart';
import 'package:fynans/models/monthly_analytics.dart';

abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoadInProgress extends AnalyticsState {}

class AnalyticsLoadSuccess extends AnalyticsState {
  final MonthlyAnalytics analytics;

  const AnalyticsLoadSuccess(this.analytics);

  @override
  List<Object> get props => [analytics];
}

class AnalyticsLoadFailure extends AnalyticsState {
  final String error;

  const AnalyticsLoadFailure(this.error);

  @override
  List<Object> get props => [error];
}
