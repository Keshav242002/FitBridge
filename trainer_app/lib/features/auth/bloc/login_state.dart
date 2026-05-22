part of 'login_bloc.dart';

sealed class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object?> get props => [];
}

final class LoginInitial extends LoginState {
  const LoginInitial({this.email = '', this.password = ''});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

final class LoginLoading extends LoginState {
  const LoginLoading();
}

final class LoginSuccess extends LoginState {
  const LoginSuccess(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}

final class LoginFailure extends LoginState {
  const LoginFailure(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
