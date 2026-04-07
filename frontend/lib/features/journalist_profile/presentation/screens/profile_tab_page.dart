import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/screens/journalist_profile_page.dart';
import 'package:news_lab/injection_container.dart';

/// Profile tab — reads current user from AuthBloc and renders JournalistProfilePage.
class ProfileTabPage extends StatelessWidget {
  const ProfileTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = authState.user;
    final args = JournalistProfileArgs(
      authorId: user.uid,
      displayName: user.displayName ?? user.email,
      email: user.email,
      isOwner: true,
    );
    return BlocProvider(
      create: (_) =>
          sl<JournalistProfileBloc>()..add(LoadJournalistProfile(args.authorId)),
      child: JournalistProfilePage(args: args, isTab: true),
    );
  }
}
