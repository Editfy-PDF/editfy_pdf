// Para gerar o modelo
// dart run build_runner build

import 'package:objectbox/objectbox.dart';

@Entity()
class Chat{
  @Id()
  int id;

  final String docPath;

  @Index()
  final String chatName;

  Chat({this.id=0, required this.chatName, required this.docPath});
}