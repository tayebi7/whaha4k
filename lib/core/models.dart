/// عنصر واحد: قناة / فيلم / مسلسل / حلقة
class Item {
  final String id, name, logo, stream, category;

  /// live | movie | series | episode
  final String type;

  const Item({
    required this.id,
    required this.name,
    this.logo = '',
    required this.stream,
    this.category = '',
    required this.type,
  });

  String get key => '$type:$id';

  Map<String, String> toJson() => {
        'id': id,
        'name': name,
        'logo': logo,
        'stream': stream,
        'category': category,
        'type': type,
      };

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        logo: (j['logo'] ?? '').toString(),
        stream: (j['stream'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        type: (j['type'] ?? 'live').toString(),
      );
}

/// قائمة تشغيل: Xtream Codes أو M3U (رابط أو ملف)
class Playlist {
  final String name, kind, url, user, pass, data;

  /// kind: xtream | m3u
  const Playlist({
    required this.name,
    required this.kind,
    this.url = '',
    this.user = '',
    this.pass = '',
    this.data = '',
  });

  bool get isXtream => kind == 'xtream';

  String get base {
    var u = url.trim();
    if (u.isNotEmpty && !u.startsWith('http')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  Map<String, String> toJson() => {
        'name': name,
        'kind': kind,
        'url': url,
        'user': user,
        'pass': pass,
        'data': data,
      };

  factory Playlist.fromJson(Map<String, dynamic> j) => Playlist(
        name: (j['name'] ?? '').toString(),
        kind: (j['kind'] ?? 'xtream').toString(),
        url: (j['url'] ?? '').toString(),
        user: (j['user'] ?? '').toString(),
        pass: (j['pass'] ?? '').toString(),
        data: (j['data'] ?? '').toString(),
      );
}
