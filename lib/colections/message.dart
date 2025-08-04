// Para gerar o modelo
// dart run build_runner build

import 'package:objectbox/objectbox.dart';

@Entity()
class Message{
  @Id()
  int id;

  int chatId;
  
  bool isUser;
  String? content;
  DateTime dateTime;

  Message({this.id=0, required this.isUser, this.content, required this.dateTime, required this.chatId});
}