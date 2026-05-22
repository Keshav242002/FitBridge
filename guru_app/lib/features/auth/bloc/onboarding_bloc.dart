import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc() : super(const OnboardingSlide1()) {
    on<OnboardingNextTapped>(_onNext);
    on<OnboardingNameChanged>(_onNameChanged);
    on<OnboardingCompleted>(_onCompleted);
  }

  void _onNext(OnboardingNextTapped event, Emitter<OnboardingState> emit) {
    switch (state) {
      case OnboardingSlide1():
        emit(OnboardingSlide2());
      case OnboardingSlide2():
        emit(OnboardingProfileSetup());
      case OnboardingProfileSetup():
      case OnboardingSuccess():
        break;
    }
  }

  void _onNameChanged(OnboardingNameChanged event, Emitter<OnboardingState> emit) {
    if (state is OnboardingProfileSetup) {
      emit(OnboardingProfileSetup(name: event.name));
    }
  }

  Future<void> _onCompleted(OnboardingCompleted event, Emitter<OnboardingState> emit) async {
    final current = state;
    if (current is! OnboardingProfileSetup) return;
    emit(OnboardingProfileSetup(name: current.name, isLoading: true));
    await AuthService.setOnboarded(true);
    final user = AuthService.seededMember;
    await AuthService.login(user.email, '');
    emit(OnboardingSuccess(user));
  }
}
