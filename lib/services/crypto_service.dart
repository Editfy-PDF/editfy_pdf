import 'dart:math';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cryptography/cryptography.dart';

Future<bool> keyExists(String key) async{
  final storage = FlutterSecureStorage();
  final keyExists = await storage.read(key: key);

  if(keyExists == null) return false;

  return true;
}

Future<String> getAESKey() async{
  final storage = FlutterSecureStorage();
  final keyExists = await storage.read(key: 'aeskey');
  if(keyExists != null) return keyExists;

  final rand = Random.secure();
  final baseKey = List<int>.generate(32, (_) => rand.nextInt(256));
  final finalKey = base64.encode(baseKey);

  await storage.write(key: 'aeskey', value: finalKey);

  return finalKey;
}

Future<String> encryptAES(String value) async{
  final baseKey = await getAESKey();

  final algorithm = AesGcm.with256bits();
  final secretKey = SecretKey(base64.decode(baseKey));

  final encrypted = await algorithm.encrypt(
    utf8.encode(value),
    secretKey: secretKey
  );

  return '${encrypted.cipherText};${encrypted.nonce};${encrypted.mac.bytes}';
}

Future<String> decryptAES(String crypted) async{
  try{
    final serialized = crypted.split(';');

    final secretBox = SecretBox(
      List<int>.from(jsonDecode(serialized[0])),
      nonce: List<int>.from(jsonDecode(serialized[1])),
      mac: Mac(
        List<int>.from(jsonDecode(serialized[2]))
      )
    );

    final baseKey = await getAESKey();

    final algorithm = AesGcm.with256bits();
    final secretKey = SecretKey(base64.decode(baseKey));

    final decripted = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey
    );

    return utf8.decode(decripted);
  } catch(e){
    return '';
  }
}