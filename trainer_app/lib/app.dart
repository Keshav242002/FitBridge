import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wtf_shared/wtf_shared.dart';
import 'core/constants.dart';
import 'core/theme.dart';
import 'features/auth/bloc/login_bloc.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

class TrainerApp extends StatelessWidget {
  const TrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>(
          create: (_) => ApiClient(baseUrl: kApiBaseUrl),
        ),
      ],
      child: MaterialApp(
        title: 'WTF Trainer',
        theme: TrainerTheme.light,
        debugShowCheckedModeBanner: false,
        home: _RootPage(),
      ),
    );
  }
}

class _RootPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser();
    if (user != null && user.role == UserRole.trainer) {
      return HomeScreen(user: user);
    }
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: const LoginScreen(),
    );
  }
}
