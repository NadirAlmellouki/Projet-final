import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/studysync_widgets.dart';
import '../chat/chat_list_screen.dart';
import '../home/home_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../stats/stats_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  late int _index;

  static const _screens = [
    HomeScreen(),
    MapScreen(),
    ChatListScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    switch (i) {
      case 1:
        ref.read(mapSessionsProvider.notifier).load();
      case 2:
        ref.read(chatListProvider.notifier).load();
      case 3:
        final userId = ref.read(authProvider).user?.id;
        if (userId != null) {
          ref.read(statsProvider.notifier).load(userId);
        }
      case 4:
        ref.read(profileStatsProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onTap: _onTabChanged,
      ),
    );
  }
}
