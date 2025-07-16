// Para construir as coleções do DB
// flutter pub run build_runner build --delete-conflicting-outputs

import 'package:isar/isar.dart';

import 'message.dart';

part 'chat.g.dart';

@Collection()
class Chat{
  Id id = Isar.autoIncrement;
  late String docPath;

  @Index()
  late String chatName;

  @Backlink(to: 'chat')
  final messages = IsarLinks<Message>();
}