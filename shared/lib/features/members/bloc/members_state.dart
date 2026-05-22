part of 'members_bloc.dart';

sealed class MembersState extends Equatable {
  const MembersState();
  @override
  List<Object?> get props => [];
}

final class MembersInitial extends MembersState {
  const MembersInitial();
}

final class MembersLoading extends MembersState {
  const MembersLoading();
}

final class MembersLoaded extends MembersState {
  const MembersLoaded({required this.members});
  final List<User> members;
  @override
  List<Object?> get props => [members];
}

final class MembersError extends MembersState {
  const MembersError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
