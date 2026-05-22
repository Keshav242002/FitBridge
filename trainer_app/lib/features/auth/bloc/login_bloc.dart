import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc() : super(const LoginInitial(email: 'aarav@wtf.local')) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    final current = state;
    final password = current is LoginInitial ? current.password : '';
    emit(LoginInitial(email: event.email, password: password));
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    final current = state;
    final email = current is LoginInitial ? current.email : '';
    emit(LoginInitial(email: email, password: event.password));
  }

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    final current = state;
    if (current is! LoginInitial) return;
    if (current.email.trim().isEmpty) {
      emit(LoginFailure('Email is required'));
      emit(LoginInitial(email: current.email, password: current.password));
      return;
    }
    emit(LoginLoading());
    final user = await AuthService.login(current.email, current.password);
    if (user == null) {
      emit(LoginFailure('No account found for that email'));
      emit(LoginInitial(email: current.email, password: current.password));
    } else {
      emit(LoginSuccess(user));
    }
  }
}
