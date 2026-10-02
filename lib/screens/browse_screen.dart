import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'player_page.dart';

/// شاشة التصفح: مباشر (3 أعمدة) أو أفلام/مسلسلات (فئات + شبكة)
class BrowseScreen extends StatefulWidget {
  final String type; // live | movie | series
  const BrowseScreen({super.key, required this.type});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  List<Item> _all = [], _shown = [], _recent = [], _favs = [];
  List<String> _cats = [];
  Map<String, int> _counts = {};
  String _cat = '@all', _q = '';
  bool _loading = true;
  String? _error;
  Item? _sel;
  Player? _player;
  VideoController? _vc;

  bool get _live => widget.type == 'live';

  @override
  void initState() {
    super.initState();
    if (_live) {
      _player = Player();
      _vc = VideoController(_player!);
    }
    _load();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final items = await Session.repo.load(widget.type);
      final counts = <String, int>{};
      for (final i in items) {
        counts[i.category] = (counts[i.category] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _all = items;
        _counts = counts;
        _cats = counts.keys.toList();
        _loading = false;
        _error = null;
        _apply();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  void _apply() {
    _recent = Store.history(widget.type);
    _favs = Store.favorites(widget.type);
    Iterable<Item> l;
    switch (_cat) {
      case '@recent':
        l = _recent;
        break;
      case '@all':
        l = _all;
        break;
      case '@fav':
        l = _favs;
        break;
      default:
        l = _all.where((e) => e.category == _cat);
    }
    if (_q.isNotEmpty) {
      final q = _q.toLowerCase();
      l = l.where((e) => e.name.toLowerCase().contains(q));
    }
    _shown = l.toList();
  }

  // ---------- الإجراءات ----------
  Future<void> _play(Item it) async {
    _player!.open(Media(it.stream));
    await Store.addHistory(it);
    if (!mounted) return;
    setState(() {
      _sel = it;
      _apply();
    });
  }

  Future<void> _toggleFav() async {
    if (_sel == null) return;
    await Store.toggleFav(_sel!);
    if (mounted) setState(_apply);
  }

  void _openFull() {
    if (_sel == null) return;
    final idx = _shown.indexWhere((e) => e.key == _sel!.key);
    final list = idx >= 0 ? _shown : [_sel!];
    _player?.pause();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerPage(items: list, index: idx >= 0 ? idx : 0)),
    ).then((_) {
      if (!mounted) return;
      _player?.play();
      setState(_apply);
    });
  }

  Future<void> _tap(Item it) async {
    if (_live) {
      if (_sel?.key == it.key) {
        _openFull();
      } else {
        await _play(it);
      }
    } else if (widget.type == 'movie') {
      await Store.addHistory(it);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlayerPage(items: [it], index: 0)),
      ).then((_) {
        if (mounted) setState(_apply);
      });
    } else {
      _openSeries(it);
    }
  }

  void _openSeries(Item s) {
    final fut = Session.repo.episodes(s);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1840),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.9,
        child: FutureBuilder<Map<String, List<Item>>>(
          future: fut,
          builder: (c, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
              return Center(child: Text(tr('No episodes')));
            }
            final seasons = snap.data!.entries.toList();
            return ListView(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(s.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              for (final se in seasons)
                ExpansionTile(
                  title: Text('${tr('Season')} ${se.key}'),
                  children: [
                    for (var i = 0; i < se.value.length; i++)
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.play_arrow),
                        title: Text(se.value[i].name),
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                              builder: (_) => PlayerPage(items: se.value, index: i)),
                        ),
                      ),
                  ],
                ),
            ]);
          },
        ),
      ),
    );
  }

  void _nav(String k) {
    if (k == widget.type) return;
    if (k == 'home') {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else {
      Navigator.of(context)
          .pushReplacement(MaterialPageRoute(builder: (_) => BrowseScreen(type: k)));
    }
  }

  // ---------- الواجهة ----------
  @override
  Widget build(BuildContext context) => Scaffold(
        body: GradientBg(
          child: SafeArea(
            child: Column(children: [
              _topBar(),
              const Divider(height: 1, color: Colors.white24),
              Expanded(child: _body()),
            ]),
          ),
        ),
      );

  Widget _topBar() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
        child: Row(children: [
          for (final t in const [
            ['home', 'Home'],
            ['live', 'Live'],
            ['movie', 'Movies'],
            ['series', 'Series'],
          ])
            _tab(t[0], t[1]),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                onChanged: (v) => setState(() {
                  _q = v;
                  _apply();
                }),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: tr('Search'),
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: Colors.white10,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.white38),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const BrandLogo(height: 30, text: false),
        ]),
      );

  Widget _tab(String k, String label) {
    final sel = k == widget.type;
    return InkWell(
      onTap: () => _nav(k),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          tr(label),
          style: TextStyle(
            fontSize: 16,
            color: sel ? C.accent : Colors.white,
            fontWeight: sel ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(_error!, textAlign: TextAlign.center, maxLines: 4),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _error = null;
              });
              _load();
            },
            child: Text(tr('Retry')),
          ),
        ]),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: 190, child: _catPanel()),
      const VerticalDivider(width: 1, color: Colors.white24),
      if (_live) ...[
        Expanded(flex: 4, child: _liveList()),
        const VerticalDivider(width: 1, color: Colors.white24),
        Expanded(flex: 5, child: _preview()),
      ] else
        Expanded(child: _grid()),
    ]);
  }

  Widget _catPanel() {
    final entries = <MapEntry<String, String>>[
      MapEntry('@recent', tr('Recently Viewed')),
      MapEntry('@all', tr('All')),
      MapEntry('@fav', tr('Favorite')),
      ..._cats.map((c) => MapEntry(c, c)),
    ];
    int count(String k) => k == '@recent'
        ? _recent.length
        : k == '@all'
            ? _all.length
            : k == '@fav'
                ? _favs.length
                : (_counts[k] ?? 0);
    return ListView.builder(
      padding: const EdgeInsets.all(6),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final sel = e.key == _cat;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: sel ? C.panelSel : C.panel,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => setState(() {
                _cat = e.key;
                _apply();
              }),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                child: Row(children: [
                  Expanded(
                    child: Text(e.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: sel ? C.accent : Colors.white)),
                  ),
                  Text('${count(e.key)}',
                      style: const TextStyle(fontSize: 13, color: Colors.white70)),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _empty() => Center(
      child: Text(tr('No items'), style: const TextStyle(color: Colors.white54)));

  Widget _liveList() {
    if (_shown.isEmpty) return _empty();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      itemCount: _shown.length,
      itemBuilder: (_, i) {
        final it = _shown[i];
        final sel = _sel?.key == it.key;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Material(
            color: sel ? C.panelSel : C.panel,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () => _tap(it),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(children: [
                  SizedBox(
                    width: 28,
                    child: Text('${i + 1}',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ),
                  SizedBox(width: 30, height: 26, child: _img(it.logo, BoxFit.contain, icon: Icons.live_tv)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(it.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: sel ? C.accent : Colors.white)),
                  ),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _preview() {
    final isFav = _sel != null && _favs.any((e) => e.key == _sel!.key);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: GestureDetector(
            onTap: _openFull,
            child: Container(
              color: Colors.black,
              child: _sel == null
                  ? const Center(child: Icon(Icons.live_tv, size: 40, color: Colors.white24))
                  : Video(controller: _vc!, controls: NoVideoControls),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(_sel?.name ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Spacer(),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _btn(Icons.fullscreen, tr('Full screen'), _sel == null ? null : _openFull),
          _btn(isFav ? Icons.favorite : Icons.favorite_border,
              isFav ? tr('Remove from Favorite') : tr('Add to Favorite'),
              _sel == null ? null : _toggleFav),
        ]),
      ]),
    );
  }

  Widget _btn(IconData i, String t, VoidCallback? f) => ElevatedButton.icon(
        onPressed: f,
        icon: Icon(i, size: 18),
        label: Text(t, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: C.btn,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  Widget _grid() {
    if (_shown.isEmpty) return _empty();
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 120,
        childAspectRatio: 0.58,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _shown.length,
      itemBuilder: (_, i) {
        final it = _shown[i];
        return InkWell(
          onTap: () => _tap(it),
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox.expand(child: _img(it.logo, BoxFit.cover, icon: Icons.movie)),
              ),
            ),
            const SizedBox(height: 4),
            Text(it.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11)),
          ]),
        );
      },
    );
  }

  Widget _img(String url, BoxFit fit, {required IconData icon}) {
    Widget ph() => Container(
          color: C.panel,
          child: Center(child: Icon(icon, color: Colors.white38, size: 22)),
        );
    if (url.isEmpty) return ph();
    return CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      memCacheWidth: 240,
      placeholder: (_, __) => ph(),
      errorWidget: (_, __, ___) => ph(),
    );
  }
}
