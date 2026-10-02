import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import 'home_screen.dart';

/// قائمة القوائم المحفوظة (تغيير / حذف / إضافة)
class PlaylistsScreen extends StatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  State<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends State<PlaylistsScreen> {
  @override
  Widget build(BuildContext context) {
    final list = Store.playlists;
    final act = Store.activeIndex;
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back)),
                Expanded(
                  child: Center(
                    child: Text(tr('Playlists'), style: const TextStyle(fontSize: 20)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AddPlaylistScreen()));
                    if (mounted) setState(() {});
                  },
                  icon: const Icon(Icons.add),
                  label: Text(tr('Add Playlist')),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: C.btn, foregroundColor: Colors.white),
                ),
              ]),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(child: Text(tr('No playlist yet')))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final p = list[i];
                        return Card(
                          color: i == act ? C.panelSel : C.panel,
                          child: ListTile(
                            leading: Icon(
                              i == act ? Icons.check_circle : Icons.list_alt,
                              color: i == act ? C.accent : Colors.white70,
                            ),
                            title: Text(p.name),
                            subtitle: Text(p.isXtream ? 'Xtream · ${p.url}' : 'M3U',
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await Store.removePlaylist(i);
                                Session.reset();
                                if (!mounted) return;
                                if (Store.active == null) {
                                  Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const AddPlaylistScreen(first: true)),
                                      (_) => false);
                                } else {
                                  setState(() {});
                                }
                              },
                            ),
                            onTap: () async {
                              await Store.setActive(i);
                              Session.reset();
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  (_) => false);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// إضافة قائمة جديدة: Xtream Codes أو M3U (رابط / ملف)
class AddPlaylistScreen extends StatefulWidget {
  final bool first;
  const AddPlaylistScreen({super.key, this.first = false});

  @override
  State<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends State<AddPlaylistScreen> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  String _kind = 'xtream';
  String _data = '';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _msg(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  Future<void> _pickFile() async {
    final r = await FilePicker.platform.pickFiles(withData: true);
    final bytes = r?.files.single.bytes;
    if (bytes == null) return;
    setState(() => _data = utf8.decode(bytes, allowMalformed: true));
    _msg(tr('File loaded'));
  }

  Future<void> _save() async {
    final xt = _kind == 'xtream';
    final ok = _name.text.trim().isNotEmpty &&
        (xt
            ? _url.text.trim().isNotEmpty &&
                _user.text.trim().isNotEmpty &&
                _pass.text.isNotEmpty
            : (_url.text.trim().isNotEmpty || _data.isNotEmpty));
    if (!ok) {
      _msg(tr('Please fill all fields'));
      return;
    }
    final p = Playlist(
      name: _name.text.trim(),
      kind: _kind,
      url: _url.text.trim(),
      user: _user.text.trim(),
      pass: _pass.text,
      data: xt ? '' : _data,
    );
    setState(() => _busy = true);
    try {
      await Repo(p).test();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        _msg('${tr('Login failed')}: $e');
      }
      return;
    }
    await Store.addPlaylist(p);
    Session.reset();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      );

  @override
  Widget build(BuildContext context) {
    final xt = _kind == 'xtream';
    return Scaffold(
      body: GradientBg(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const BrandLogo(height: 54),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'xtream', label: Text('Xtream Codes')),
                      ButtonSegment(value: 'm3u', label: Text('M3U')),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _name, decoration: _dec(tr('Playlist name'))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: _dec(xt ? tr('Server URL (http://host:port)') : tr('M3U URL')),
                  ),
                  if (xt) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(child: TextField(controller: _user, decoration: _dec(tr('Username')))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                            controller: _pass,
                            obscureText: true,
                            decoration: _dec(tr('Password'))),
                      ),
                    ]),
                  ] else ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: Text(_data.isEmpty ? tr('Pick M3U file') : tr('File loaded')),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(children: [
                    if (!widget.first)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => Navigator.pop(context),
                          child: Text(tr('Cancel')),
                        ),
                      ),
                    if (!widget.first) const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _save,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: C.btn, foregroundColor: Colors.white),
                        child: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(tr('Save')),
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
