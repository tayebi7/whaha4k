import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/models.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../core/theme.dart';

/// مشغل ملء الشاشة: تبديل القنوات، مفضلة، شريط تقديم للأفلام، ملاءمة الصورة.
class PlayerPage extends StatefulWidget {
  final List<Item> items;
  final int index;
  const PlayerPage({super.key, required this.items, required this.index});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final Player _p = Player();
  late final VideoController _vc = VideoController(_p);
  late int _i = widget.index;
  bool _show = true;
  Timer? _t;
  BoxFit _fit = BoxFit.contain;
  bool _fav = false;

  Item get _it => widget.items[_i];
  bool get _isLive => _it.type == 'live';

  @override
  void initState() {
    super.initState();
    _start();
    _arm();
  }

  @override
  void dispose() {
    _t?.cancel();
    _p.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    _p.open(Media(_it.stream));
    await Store.addHistory(_it);
    final f = Store.isFav(_it);
    if (mounted) setState(() => _fav = f);
  }

  void _arm() {
    _t?.cancel();
    _t = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _show = false);
    });
  }

  void _toggle() {
    if (_show) {
      _t?.cancel();
      setState(() => _show = false);
    } else {
      setState(() => _show = true);
      _arm();
    }
  }

  void _go(int d) {
    final n = _i + d;
    if (n < 0 || n >= widget.items.length) return;
    setState(() => _i = n);
    _start();
    _arm();
  }

  Future<void> _toggleFav() async {
    await Store.toggleFav(_it);
    final f = Store.isFav(_it);
    if (mounted) setState(() => _fav = f);
    _arm();
  }

  void _cycleFit() {
    setState(() {
      _fit = _fit == BoxFit.contain
          ? BoxFit.cover
          : (_fit == BoxFit.cover ? BoxFit.fill : BoxFit.contain);
    });
    _arm();
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    return '${h > 0 ? '$h:' : ''}${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v > 300) _go(-1);
            if (v < -300) _go(1);
          },
          child: Stack(children: [
            Positioned.fill(
              child: Video(controller: _vc, controls: NoVideoControls, fit: _fit),
            ),
            // مؤشر التحميل
            Center(
              child: StreamBuilder<bool>(
                stream: _p.stream.buffering,
                builder: (_, s) => (s.data ?? false)
                    ? const CircularProgressIndicator(color: C.cyan)
                    : const SizedBox.shrink(),
              ),
            ),
            // رسالة الخطأ
            Positioned(
              bottom: 70,
              left: 16,
              right: 16,
              child: StreamBuilder<String>(
                stream: _p.stream.error,
                builder: (_, s) => (s.data ?? '').isEmpty
                    ? const SizedBox.shrink()
                    : Text(s.data!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
            ),
            if (_show) ...[
              // الشريط العلوي
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: SafeArea(
                    bottom: false,
                    child: Row(children: [
                      IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back)),
                      Expanded(
                        child: Text(_it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      IconButton(
                          tooltip: tr('Fit'),
                          onPressed: _cycleFit,
                          icon: const Icon(Icons.aspect_ratio)),
                      IconButton(
                        onPressed: _toggleFav,
                        icon: Icon(_fav ? Icons.favorite : Icons.favorite_border,
                            color: _fav ? Colors.redAccent : Colors.white),
                      ),
                    ]),
                  ),
                ),
              ),
              // أزرار الوسط
              Center(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                      iconSize: 40,
                      onPressed: _i > 0 ? () => _go(-1) : null,
                      icon: const Icon(Icons.skip_previous)),
                  const SizedBox(width: 16),
                  StreamBuilder<bool>(
                    stream: _p.stream.playing,
                    builder: (_, s) => IconButton(
                      iconSize: 56,
                      onPressed: () {
                        _p.playOrPause();
                        _arm();
                      },
                      icon: Icon((s.data ?? true) ? Icons.pause_circle : Icons.play_circle),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                      iconSize: 40,
                      onPressed: _i < widget.items.length - 1 ? () => _go(1) : null,
                      icon: const Icon(Icons.skip_next)),
                ]),
              ),
              // شريط التقديم (للأفلام والمسلسلات فقط)
              if (!_isLive)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 6,
                  child: Container(
                    color: Colors.black54,
                    child: StreamBuilder<Duration>(
                      stream: _p.stream.position,
                      builder: (_, s) {
                        final pos = s.data ?? Duration.zero;
                        final dur = _p.state.duration;
                        final max = dur.inMilliseconds.toDouble();
                        return Row(children: [
                          const SizedBox(width: 8),
                          Text(_fmt(pos), style: const TextStyle(fontSize: 12)),
                          Expanded(
                            child: Slider(
                              value: max <= 0
                                  ? 0
                                  : pos.inMilliseconds.toDouble().clamp(0, max),
                              max: max <= 0 ? 1 : max,
                              onChanged: (v) => _p.seek(Duration(milliseconds: v.toInt())),
                              onChangeEnd: (_) => _arm(),
                            ),
                          ),
                          Text(_fmt(dur), style: const TextStyle(fontSize: 12)),
                          const SizedBox(width: 8),
                        ]);
                      },
                    ),
                  ),
                ),
            ],
          ]),
        ),
      );
}
