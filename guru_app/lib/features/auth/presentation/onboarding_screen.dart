import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/onboarding_bloc.dart';
import '../../home/presentation/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'DK');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingSuccess) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => HomeScreen(user: state.user)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<OnboardingBloc, OnboardingState>(
            builder: (context, state) => switch (state) {
              OnboardingSlide1() => _Slide(
                  icon: Icons.fitness_center,
                  title: 'Welcome to WTF',
                  body: 'Your personal training journey starts here. '
                      'Chat with your trainer, schedule sessions, and track your progress.',
                  onNext: () => context.read<OnboardingBloc>().add(const OnboardingNextTapped()),
                ),
              OnboardingSlide2() => _Slide(
                  icon: Icons.video_call_outlined,
                  title: 'Live Video Sessions',
                  body: 'Join face-to-face training sessions with your trainer '
                      'using high-quality video calls.',
                  onNext: () => context.read<OnboardingBloc>().add(const OnboardingNextTapped()),
                ),
              OnboardingProfileSetup(:final isLoading) => _ProfileSetup(
                  nameCtrl: _nameCtrl,
                  isLoading: isLoading,
                  onNameChanged: (v) =>
                      context.read<OnboardingBloc>().add(OnboardingNameChanged(v)),
                  onComplete: () => context.read<OnboardingBloc>().add(const OnboardingCompleted()),
                ),
              OnboardingSuccess() => const SizedBox.shrink(),
            },
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.icon,
    required this.title,
    required this.body,
    required this.onNext,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Text(body, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 48),
          ElevatedButton(onPressed: onNext, child: const Text('Continue')),
        ],
      ),
    );
  }
}

class _ProfileSetup extends StatelessWidget {
  const _ProfileSetup({
    required this.nameCtrl,
    required this.isLoading,
    required this.onNameChanged,
    required this.onComplete,
  });

  final TextEditingController nameCtrl;
  final bool isLoading;
  final ValueChanged<String> onNameChanged;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Set up your profile',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trainer will see this name.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Your trainer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.fitness_center),
            ),
            child: const Text('Aarav'),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: isLoading ? null : onComplete,
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Get Started'),
          ),
        ],
      ),
    );
  }
}
