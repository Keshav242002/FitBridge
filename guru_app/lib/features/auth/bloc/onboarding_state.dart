part of 'onboarding_bloc.dart';

sealed class OnboardingState {}

final class OnboardingSlide1 extends OnboardingState {}

final class OnboardingSlide2 extends OnboardingState {}

final class OnboardingProfileSetup extends OnboardingState {
  OnboardingProfileSetup({this.name = 'DK', this.isLoading = false});
  final String name;
  final bool isLoading;
}

final class OnboardingSuccess extends OnboardingState {
  OnboardingSuccess(this.user);
  final User user;
}
