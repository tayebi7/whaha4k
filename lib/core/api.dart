import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';
import 'store.dart';

/// جلب البيانات من Xtream Codes أو M3U مع تخزين مؤقت في الذاكرة.
class Repo {
  final Playlist p;
  Repo(this.p);

  final Map<String, List<Item>> _cache = {};

  String get _base => p.base;
  String get _u => Uri.encodeComponent(p.user);
  String get _pw => Uri.encodeComponent(p.pass);

  Future<dynamic> _api(String query) async {
    final uri = Uri.parse('$_base/player_api.php?username=$_u&password=$_pw$query');
    final r = await http.get(uri).timeout(const Duration(seconds: 40));
    if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  /// معلومات الحساب (Xtream فقط)
  Future<Map<String, dynamic>?> account() async {
    if (!p.isXtream) return null;
    final d = await _api('');
    if (d is Map && d['user_info'] is Map) {
      return Map<String, dynamic>.from(d['user_info'] as Map);
    }
    return null;
  }

  /// اختبار صحة القائمة قبل الحفظ
  Future<void> test() async {
    if (p.isXtream) {
      final a = await account();
      if (a == null || a['auth'].toString() == '0') {
        throw Exception('auth');
      }
    } else {
      final l = await load('live');
      if (l.isEmpty) throw Exception('empty');
    }
  }

  Future<List<Item>> load(String type) async {
    final cached = _cache[type];
    if (cached != null) return cached;

    List<Item> items;
    if (!p.isXtream) {
      items = type == 'live' ? await _loadM3u() : <Item>[];
    } else {
      final a = type == 'live' ? 'live' : (type == 'movie' ? 'vod' : 'series');
      final catsRaw = await _api('&action=get_${a}_categories');
      final cats = <String, String>{};
      if (catsRaw is List) {
        for (final c in catsRaw) {
          if (c is Map) {
            cats[c['category_id'].toString()] = (c['category_name'] ?? '').toString();
          }
        }
      }
      final act = type == 'live'
          ? 'get_live_streams'
          : (type == 'movie' ? 'get_vod_streams' : 'get_series');
      final data = await _api('&action=$act');
      items = <Item>[];
      if (data is List) {
        for (final e in data) {
          if (e is! Map) continue;
          final idv = (type == 'series' ? e['series_id'] : e['stream_id']).toString();
          String stream = '';
          String logo = '';
          if (type == 'live') {
            stream = '$_base/live/$_u/$_pw/$idv.${Store.liveFormat}';
            logo = (e['stream_icon'] ?? '').toString();
          } else if (type == 'movie') {
            final ext = (e['container_extension'] ?? 'mp4').toString();
            stream = '$_base/movie/$_u/$_pw/$idv.$ext';
            logo = (e['stream_icon'] ?? '').toString();
          } else {
            logo = (e['cover'] ?? '').toString();
          }
          items.add(Item(
            id: idv,
            name: (e['name'] ?? '').toString(),
            logo: logo,
            stream: stream,
            category: cats[e['category_id'].toString()] ?? 'Other',
            type: type,
          ));
        }
      }
    }
    _cache[type] = items;
    return items;
  }

  /// حلقات مسلسل: الموسم → قائمة الحلقات
  Future<Map<String, List<Item>>> episodes(Item s) async {
    final d = await _api('&action=get_series_info&series_id=${s.id}');
    final out = <String, List<Item>>{};
    final eps = d is Map ? d['episodes'] : null;

    void addSeason(String season, dynamic list) {
      if (list is! List) return;
      out[season] = [
        for (final e in list)
          if (e is Map)
            Item(
              id: e['id'].toString(),
              name: (e['title'] ?? 'Episode ${e['episode_num'] ?? ''}').toString(),
              logo: s.logo,
              stream:
                  '$_base/series/$_u/$_pw/${e['id']}.${(e['container_extension'] ?? 'mp4')}',
              category: 'S$season',
              type: 'episode',
            ),
      ];
    }

    if (eps is Map) {
      eps.forEach((k, v) => addSeason(k.toString(), v));
    } else if (eps is List) {
      for (var i = 0; i < eps.length; i++) {
        addSeason('${i + 1}', eps[i]);
      }
    }
    return out;
  }

  Future<List<Item>> _loadM3u() async {
    var text = p.data;
    if (text.isEmpty) {
      final r = await http.get(Uri.parse(p.base)).timeout(const Duration(seconds: 60));
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      text = utf8.decode(r.bodyBytes, allowMalformed: true);
    }
    return parseM3u(text);
  }
}

List<Item> parseM3u(String text) {
  final out = <Item>[];
  final logoRe = RegExp(r'tvg-logo="([^"]*)"');
  final groupRe = RegExp(r'group-title="([^"]*)"');
  String? name;
  var logo = '', group = '';
  for (final raw in const LineSplitter().convert(text)) {
    final l = raw.trim();
    if (l.isEmpty) continue;
    if (l.startsWith('#EXTINF')) {
      name = l.contains(',') ? l.substring(l.lastIndexOf(',') + 1).trim() : 'Channel';
      logo = logoRe.firstMatch(l)?.group(1) ?? '';
      group = groupRe.firstMatch(l)?.group(1) ?? '';
    } else if (!l.startsWith('#') && name != null) {
      out.add(Item(
        id: l,
        name: name.isEmpty ? 'Channel ${out.length + 1}' : name,
        logo: logo,
        stream: l,
        category: group.isEmpty ? 'Uncategorized' : group,
        type: 'live',
      ));
      name = null;
    }
  }
  return out;
}

/// الجلسة الحالية: مستودع القائمة النشطة
class Session {
  static Repo? _r;
  static Repo get repo => _r ??= Repo(Store.active!);
  static void reset() => _r = null;
}
