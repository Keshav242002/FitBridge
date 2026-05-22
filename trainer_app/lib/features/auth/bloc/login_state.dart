part of 'login_bloc.dart';

sealed class LoginState {}

final class LoginInitial extends LoginState {
  LoginInitial({this.email = '', this.password = ''});
  final String email;
  final String password;
}

final class LoginLoading extends LoginState {}

final class LoginSuccess extends LoginState {
  LoginSuccess(this.user);
  final User user;
}

final class LoginFailure extends LoginState {
  LoginFailure(this.message);
  final String message;
}
