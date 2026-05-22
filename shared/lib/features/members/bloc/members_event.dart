part of 'members_bloc.dart';

sealed class MembersEvent extends Equatable {
  const MembersEvent();
  @override
  List<Object?> get props => [];
}

final class LoadMembers extends MembersEvent {
  const LoadMembers();
}
