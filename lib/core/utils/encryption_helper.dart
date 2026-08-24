import 'package:encrypt/encrypt.dart';

class EncryptionHelper {
  // 32-character key for AES-256
  static final _key = Key.fromUtf8('waypointsafecheckinsecurekey2026');
  // 16-character IV
  static final _iv = IV.fromUtf8('waypointsecureiv');
  
  static final _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));

  /// Encrypts plain text using AES-256 CBC.
  static String encrypt(String plainText) {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (_) {
      return plainText;
    }
  }

  /// Decrypts cipher text back into plain text.
  static String decrypt(String cipherText) {
    try {
      final decrypted = _encrypter.decrypt(Encrypted.fromBase64(cipherText), iv: _iv);
      return decrypted;
    } catch (_) {
      return cipherText;
    }
  }
}
