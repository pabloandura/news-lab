import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:news_lab/core/constants/constants.dart';
import 'package:uuid/uuid.dart';

abstract class ArticlesStorageDataSource {
  Future<String> uploadThumbnail(String localImagePath);
}

class ArticlesStorageDataSourceImpl implements ArticlesStorageDataSource {
  final FirebaseStorage _storage;

  ArticlesStorageDataSourceImpl(this._storage);

  @override
  Future<String> uploadThumbnail(String localImagePath) async {
    final fileName = const Uuid().v4();
    final ref = _storage.ref('$articlesThumbnailStoragePath/$fileName');
    await ref.putFile(File(localImagePath));
    return ref.getDownloadURL();
  }
}
