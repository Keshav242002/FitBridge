part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();
  @override
  List<Object?> get props => [];
}

final class OnboardingNextTapped extends OnboardingEvent {
  const OnboardingNextTapped();
}

final class OnboardingNameChanged extends OnboardingEvent {
  const OnboardingNameChanged(this.name);
  final String name;
  @override
  List<Object?> get props => [name];
}

final class OnboardingCompleted extends OnboardingEvent {
  const OnboardingCompleted();
}
