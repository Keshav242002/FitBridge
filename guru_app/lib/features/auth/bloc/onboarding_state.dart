part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();
  @override
  List<Object?> get props => [];
}

final class OnboardingSlide1 extends OnboardingState {
  const OnboardingSlide1();
}

final class OnboardingSlide2 extends OnboardingState {
  const OnboardingSlide2();
}

final class OnboardingProfileSetup extends OnboardingState {
  const OnboardingProfileSetup({this.name = 'DK', this.isLoading = false});
  final String name;
  final bool isLoading;
  @override
  List<Object?> get props => [name, isLoading];
}

final class OnboardingSuccess extends OnboardingState {
  const OnboardingSuccess(this.user);
  final User user;
  @override
  List<Object?> get props => [user];
}
