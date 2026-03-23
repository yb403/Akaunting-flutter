import 'package:equatable/equatable.dart';

abstract class CreateInvoiceState extends Equatable {
  const CreateInvoiceState();

  @override
  List<Object?> get props => [];
}

class CreateInvoiceInitial extends CreateInvoiceState {}

class CreateInvoiceLoading extends CreateInvoiceState {}

class CreateInvoiceSuccess extends CreateInvoiceState {
  final String message;

  const CreateInvoiceSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class CreateInvoiceError extends CreateInvoiceState {
  final String message;

  const CreateInvoiceError(this.message);

  @override
  List<Object?> get props => [message];
}
