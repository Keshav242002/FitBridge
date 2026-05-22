import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/error_retry.dart';
import '../../../widgets/skeleton_loader.dart';
import '../bloc/members_bloc.dart';
import 'member_detail_page.dart';

class MembersListPage extends StatelessWidget {
  const MembersListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => MembersBloc(
        api: ctx.read<ApiClient>(),
      )..add(const LoadMembers()),
      child: const _MembersListView(),
    );
  }
}

class _MembersListView extends StatelessWidget {
  const _MembersListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: BlocBuilder<MembersBloc, MembersState>(
        builder: (ctx, state) {
          return switch (state) {
            MembersInitial() || MembersLoading() => const SkeletonLoader(),
            MembersError(:final message) => ErrorRetry(
                message: message,
                onRetry: () => ctx.read<MembersBloc>().add(const LoadMembers()),
              ),
            MembersLoaded(:final members) => members.isEmpty
                ? const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No members yet',
                    subtitle: 'Members will appear here once they sign up.',
                  )
                : RefreshIndicator(
                    onRefresh: () async =>
                        ctx.read<MembersBloc>().add(const LoadMembers()),
                    child: ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (_, i) => _MemberCard(member: members[i]),
                    ),
                  ),
          };
        },
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});
  final User member;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(member.email),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MemberDetailPage(member: member),
          ),
        ),
      ),
    );
  }
}
