import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageConfig {
  static const FlutterSecureStorage storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
}
