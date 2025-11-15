import 'package:arber/data/enums.dart';
import 'package:arber/data/models/bookmark.dart';
import 'package:arber/services/storage_service.dart';
import 'package:flutter/services.dart';

class BookmarkService {
  const BookmarkService(this._storageService);

  final StorageService _storageService;

  static const _channel = MethodChannel('com.shakle.secure_bookmarks');

  Future<void> createBookmark({
    required ArtifactType id,
    required String path,
  }) async {
    String? base64 = await _channel.invokeMethod<String>(
      'createBookmark',
      {'path': path},
    );

    if (base64 == null) {
      throw Exception('Failed to create bookmark for $path');
    }

    Bookmark bookmark = Bookmark(id: id, path: path, base64: base64);
    await _storageService.saveBookmark(bookmark);
  }

  /// Start accessing all saved bookmarks (should be called on app startup).
  Future<void> restoreAllAccess() async {
    List<Bookmark> bookmarks = await _storageService.getAllBookmarks();

    await Future.wait(bookmarks.map((bookmark) {
      return _channel.invokeMethod<bool>(
        'startAccessing',
        {'bookmark': bookmark.base64},
      );
    }));
  }
}
