import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../providers/connectivity_provider.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/shell_nav.dart';
import '../widgets/common.dart';
import 'assistant_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'risk_test_screen.dart';
import 'tracking_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<ShellNav>();
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            const OfflineBanner(),
            Expanded(
              child: IndexedStack(
                index: nav.index,
                children: const [
                  HomeScreen(),
                  TrackingScreen(),
                  RiskTestScreen(),
                  AssistantScreen(),
                  ProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: nav.index,
        onDestinationSelected: (i) => nav.go(i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.t('nav_home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart),
            label: context.t('nav_tracking'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.fact_check_outlined),
            selectedIcon: const Icon(Icons.fact_check),
            label: context.t('nav_risk'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.smart_toy_outlined),
            selectedIcon: const Icon(Icons.smart_toy),
            label: context.t('nav_assistant'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: context.t('nav_profile'),
          ),
        ],
      ),
    );
  }
}

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final data = context.watch<DataProvider>();
    final online = context.watch<ConnectivityProvider>().online;

    Widget syncIcon;
    if (data.syncing) {
      syncIcon = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else if (!online) {
      syncIcon = const Icon(Icons.cloud_off, color: AppColors.deepOrange);
    } else if (data.pendingCount > 0) {
      syncIcon = const Icon(
        Icons.cloud_upload_outlined,
        color: AppColors.orange,
      );
    } else {
      syncIcon = const Icon(Icons.cloud_done_outlined, color: AppColors.green);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.water_drop, color: AppColors.primary),
          const SizedBox(width: 6),
          const Text(
            'SunuDiab',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const Spacer(),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            segments: const [
              ButtonSegment(value: 'fr', label: Text('FR')),
              ButtonSegment(value: 'wo', label: Text('WO')),
            ],
            selected: {settings.lang},
            onSelectionChanged: (s) => settings.setLang(s.first),
          ),
          IconButton(
            tooltip: context.t('sync_now'),
            icon: syncIcon,
            onPressed: () async {
              if (!online) {
                toast(context, context.t('offline_banner'));
                return;
              }
              final err = await data.syncNow();
              if (context.mounted)
                toast(context, err ?? context.t('sync_done'));
            },
          ),
        ],
      ),
    );
  }
}
