part of 'onboarding_bloc.dart';

sealed class OnboardingEvent {}

final class OnboardingNextTapped extends OnboardingEvent {}

final class OnboardingNameChanged extends OnboardingEvent {
  OnboardingNameChanged(this.name);
  final String name;
}

final class OnboardingCompleted extends OnboardingEvent {}
