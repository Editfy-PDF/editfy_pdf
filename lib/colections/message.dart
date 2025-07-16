// Para construir as coleções do DB
// flutter pub run build_runner build --delete-conflicting-outputs

import 'package:isar/isar.dart';

import 'chat.dart';

part 'message.g.dart';


@Collection()
class Message{
  Id id = Isar.autoIncrement;
  
  final chat = IsarLink<Chat>();
  
  late bool isUser;
  String? content;
  late String dateTime;
}