import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'playlist_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _done(BuildContext c) => ScaffoldMessenger.of(c)
      .showSnackBar(SnackBar(content: Text(tr('Done')), duration: const Duration(seconds: 1)));

  Future<void> _lang(BuildContext c) async {
    final v = await showDialog<String>(
      context: c,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1840),
        title: Text(tr('Change Language')),
        children: [
          SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'ar'), child: const Text('العربية')),
          SimpleDialogOption(
              onPressed: () => Navigator.pop(c, 'en'), child: const Text('English')),
        ],
      ),
    );
    if (v == null) return;
    await Store.setLang(v);
    langNotifier.value = v; // يعيد بناء التطبيق باللغة الجديدة
  }

  Future<void> _format(BuildContext c) async {
    final v = await showDialog<String>(
      context: c,
      builder: (_) => SimpleDialog(
        backgroundColor: const Color(0xFF1E1840),
        title: Text(tr('Live Stream Format')),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'ts'), child: const Text('MPEG-TS (.ts)')),
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'm3u8'), child: const Text('HLS (.m3u8)')),
        ],
      ),
    );
    if (v == null) return;
    await Store.setLiveFormat(v);
    Session.reset(); // الروابط تُبنى من جديد
    if (c.mounted) _done(c);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <_T>[
      _T(Icons.playlist_add, tr('Add Playlist'),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPlaylistScreen()))),
      _T(Icons.switch_account_outlined, tr('Change Playlist'),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistsScreen()))),
      _T(Icons.translate, tr('Change Language'), () => _lang(context)),
      _T(Icons.live_tv, tr('Live Stream Format'), () => _format(context)),
      _T(Icons.delete_sweep_outlined, tr('Clear History Channels'), () async {
        await Store.clearHistory('live');
        if (context.mounted) _done(context);
      }),
      _T(Icons.delete_sweep_outlined, tr('Clear History Movies'), () async {
        await Store.clearHistory('movie');
        if (context.mounted) _done(context);
      }),
      _T(Icons.favorite_border, tr('Clear Favorites'), () async {
        await Store.clearFavorites();
        if (context.mounted) _done(context);
      }),
      _T(Icons.info_outline, tr('About'), () => showAboutDialog(
            context: context,
            applicationName: 'Waha 4K',
            applicationVersion: '1.0.0',
            applicationLegalese: 'IPTV player — no content included.',
          )),
    ];

    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back)),
                Expanded(child: Center(child: Text(tr('Settings'), style: const TextStyle(fontSize: 20)))),
                const SizedBox(width: 48),
              ]),
            ),
            Expanded(
              child: GridView.extent(
                padding: const EdgeInsets.all(14),
                maxCrossAxisExtent: 300,
                childAspectRatio: 3.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  for (final t in tiles)
                    Material(
                      color: const Color(0xCC5A0F2A),
                      borderRadius: BorderRadius.circular(8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: t.onTap,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(children: [
                            Icon(t.icon, color: C.cyan),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(t.label,
                                  maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
                            ),
                          ]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _T {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _T(this.icon, this.label, this.onTap);
}
