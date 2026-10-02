import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'browse_screen.dart';
import 'playlist_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _exp = '...';

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  String _fmtExp(dynamic e) {
    if (e == null || e.toString() == 'null' || e.toString().isEmpty) {
      return tr('unlimited');
    }
    final s = int.tryParse(e.toString());
    if (s == null) return e.toString();
    final d = DateTime.fromMillisecondsSinceEpoch(s * 1000);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadAccount() async {
    final p = Store.active;
    if (p == null) return;
    if (!p.isXtream) {
      setState(() => _exp = tr('unlimited'));
      return;
    }
    try {
      final a = await Session.repo.account();
      if (mounted) setState(() => _exp = _fmtExp(a?['exp_date']));
    } catch (_) {
      if (mounted) setState(() => _exp = '-');
    }
  }

  void _open(String type) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => BrowseScreen(type: type)));

  Future<void> _account() async {
    final p = Store.active!;
    Map<String, dynamic>? a;
    try {
      a = await Session.repo.account();
    } catch (_) {}
    if (!mounted) return;
    final rows = <MapEntry<String, String>>[
      MapEntry(tr('Playlist'), p.name),
      MapEntry(tr('Type'), p.isXtream ? 'Xtream Codes' : 'M3U'),
      if (a != null) ...[
        MapEntry(tr('Status'), (a['status'] ?? '-').toString()),
        MapEntry(tr('Expires'), _fmtExp(a['exp_date'])),
        MapEntry(tr('Connections'),
            '${a['active_cons'] ?? '-'} / ${a['max_connections'] ?? '-'}'),
      ],
    ];
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1840),
        title: Text(tr('Account')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text(r.key, style: const TextStyle(color: Colors.white60))),
                  Text(r.value),
                ]),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('Close'))),
        ],
      ),
    );
  }

  void _reload() {
    Session.reset();
    setState(() => _exp = '...');
    _loadAccount();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(tr('Reloaded')), duration: const Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: GradientBg(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
              child: Column(children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('${tr('Current playlist expires')}: $_exp',
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                const SizedBox(height: 2),
                const BrandLogo(height: 64),
                const SizedBox(height: 10),
                Expanded(
                  child: Row(children: [
                    Expanded(
                      flex: 5,
                      child: _Tile(
                          icon: Icons.live_tv_rounded,
                          label: tr('Live'),
                          big: true,
                          onTap: () => _open('live')),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: Column(children: [
                        Expanded(
                          child: Row(children: [
                            Expanded(
                                child: _Tile(
                                    icon: Icons.play_circle_outline,
                                    label: tr('Movies'),
                                    onTap: () => _open('movie'))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _Tile(
                                    icon: Icons.movie_creation_outlined,
                                    label: tr('Series'),
                                    onTap: () => _open('series'))),
                          ]),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Row(children: [
                            Expanded(
                                child: _Tile(
                                    icon: Icons.people_alt_outlined,
                                    label: tr('Account'),
                                    onTap: _account)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: _Tile(
                                    icon: Icons.switch_account_outlined,
                                    label: tr('Change Playlist'),
                                    onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const PlaylistsScreen())))),
                          ]),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(children: [
                        Expanded(
                            child: _Tile(
                                icon: Icons.settings_outlined,
                                label: tr('Settings'),
                                horizontal: true,
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const SettingsScreen())))),
                        const SizedBox(height: 10),
                        Expanded(
                            child: _Tile(
                                icon: Icons.refresh,
                                label: tr('Reload'),
                                horizontal: true,
                                onTap: _reload)),
                        const SizedBox(height: 10),
                        Expanded(
                            child: _Tile(
                                icon: Icons.logout,
                                label: tr('Exit'),
                                horizontal: true,
                                onTap: () => SystemNavigator.pop())),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text('v1.0.0', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ]),
            ),
          ),
        ),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool big, horizontal;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.big = false,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xCC7A0E22), Color(0xCC4B0A18)],
            ),
            border: horizontal ? Border.all(color: const Color(0x99B71C3A)) : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: horizontal
                      ? Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: 26),
                          const SizedBox(width: 10),
                          Text(label, style: const TextStyle(fontSize: 16)),
                        ])
                      : Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(icon, size: big ? 72 : 34),
                          const SizedBox(height: 6),
                          Text(label, style: TextStyle(fontSize: big ? 22 : 14)),
                        ]),
                ),
              ),
            ),
          ),
        ),
      );
}
