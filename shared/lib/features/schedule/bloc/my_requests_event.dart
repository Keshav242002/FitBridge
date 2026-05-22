import 'package:equatable/equatable.dart';

sealed class MyRequestsEvent extends Equatable {
  const MyRequestsEvent();
  @override
  List<Object?> get props => [];
}

final class LoadMyRequests extends MyRequestsEvent {
  const LoadMyRequests();
}
