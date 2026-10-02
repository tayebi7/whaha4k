import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import 'models.dart';

/// تخزين محلي (Hive) للقوائم والمفضلة والسجل والإعدادات.
/// كل الدوال التي تكتب async ويجب انتظارها (await).
class Store {
  static late Box _b;

  static Future<void> init() async {
    _b = await Hive.openBox('waha4k');
  }

  static List<String> _list(String k) =>
      List<String>.from(_b.get(k, defaultValue: <String>[]) as List);

  static Map<String, String> _map(String k) =>
      Map<String, String>.from(_b.get(k, defaultValue: <String, String>{}) as Map);

  // ---------- الإعدادات ----------
  static String get lang => _b.get('lang', defaultValue: 'ar') as String;
  static Future<void> setLang(String v) => _b.put('lang', v);

  /// صيغة البث المباشر: ts أو m3u8
  static String get liveFormat => _b.get('fmt', defaultValue: 'ts') as String;
  static Future<void> setLiveFormat(String v) => _b.put('fmt', v);

  // ---------- قوائم التشغيل ----------
  static List<Playlist> get playlists => _list('playlists')
      .map((e) => Playlist.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .toList();

  static int get activeIndex => _b.get('active', defaultValue: 0) as int;

  static Playlist? get active {
    final l = playlists;
    if (l.isEmpty) return null;
    return l[activeIndex.clamp(0, l.length - 1)];
  }

  static Future<void> addPlaylist(Playlist p) async {
    final l = _list('playlists')..add(jsonEncode(p.toJson()));
    await _b.put('playlists', l);
    await _b.put('active', l.length - 1);
  }

  static Future<void> setActive(int i) => _b.put('active', i);

  static Future<void> removePlaylist(int i) async {
    final l = _list('playlists');
    if (i >= 0 && i < l.length) l.removeAt(i);
    await _b.put('playlists', l);
    await _b.put('active', 0);
  }

  // ---------- المفضلة ----------
  static List<Item> favorites(String type) => _map('fav')
      .values
      .map((e) => Item.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .where((e) => e.type == type)
      .toList();

  static bool isFav(Item i) => _map('fav').containsKey(i.key);

  static Future<void> toggleFav(Item i) async {
    final m = _map('fav');
    if (m.containsKey(i.key)) {
      m.remove(i.key);
    } else {
      m[i.key] = jsonEncode(i.toJson());
    }
    await _b.put('fav', m);
  }

  static Future<void> clearFavorites() => _b.put('fav', <String, String>{});

  // ---------- السجل (شوهد مؤخراً) ----------
  static List<Item> history(String type) => _list('hist')
      .map((e) => Item.fromJson(jsonDecode(e) as Map<String, dynamic>))
      .where((e) => e.type == type)
      .toList();

  static Future<void> addHistory(Item i) async {
    final l = _list('hist');
    l.removeWhere((e) => (jsonDecode(e) as Map)['id'] == i.id && (jsonDecode(e) as Map)['type'] == i.type);
    l.insert(0, jsonEncode(i.toJson()));
    if (l.length > 80) l.removeRange(80, l.length);
    await _b.put('hist', l);
  }

  static Future<void> clearHistory(String type) async {
    final l = _list('hist')
        .where((e) => (jsonDecode(e) as Map)['type'] != type)
        .toList();
    await _b.put('hist', l);
  }
}
