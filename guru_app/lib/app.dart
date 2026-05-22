import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';
import 'core/theme.dart';
import 'features/auth/bloc/onboarding_bloc.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/home/presentation/home_screen.dart';

class GuruApp extends StatelessWidget {
  const GuruApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WTF Guru',
      theme: GuruTheme.light,
      debugShowCheckedModeBanner: false,
      home: _RootPage(),
    );
  }
}

class _RootPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser();
    if (user != null && user.role == UserRole.member && AuthService.hasOnboarded()) {
      return HomeScreen(user: user);
    }
    return BlocProvider(
      create: (_) => OnboardingBloc(),
      child: const OnboardingScreen(),
    );
  }
}
