import 'package:equatable/equatable.dart';
import '../models/report_summary.dart';
import '../../transactions/models/transaction.dart';

abstract class ReportState extends Equatable {
  const ReportState();

  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportLoaded extends ReportState {
  final ReportSummary summary;
  final List<Transaction> recentTransactions;

  const ReportLoaded(this.summary, this.recentTransactions);

  @override
  List<Object?> get props => [summary, recentTransactions];
}

class ReportError extends ReportState {
  final String message;

  const ReportError(this.message);

  @override
  List<Object?> get props => [message];
}
