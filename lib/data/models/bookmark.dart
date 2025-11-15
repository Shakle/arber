import 'package:arber/data/enums.dart';

class Bookmark {

  const Bookmark({
    required this.id,
    required this.path,
    required this.base64,
  });

  final ArtifactType id;
  final String path;
  final String base64;

  Map<String, dynamic> toJson() => {
    'id': id.name,
    'path': path,
    'base64': base64,
  };

  Bookmark.fromJson(Map<String, dynamic> json)
      : id = ArtifactType.values.byName(json['id']),
        path = json['path'],
        base64 = json['base64'];
}
