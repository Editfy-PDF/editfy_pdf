import 'package:isar/isar.dart';
import 'package:file_picker/file_picker.dart';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/colections/message.dart';

class DbService {
  late Future<Isar> db;
  final String? dbPath;

  DbService(this.dbPath){
    db = openDb(dbPath);
  }

  //  FUNÇÕES GERAIS
  //---------------------------------------------------------------

  Future<void> dispose() async{
    final isar = await db;

    isar.close();
  }

  Future<Isar> openDb(String? path) async{
    final dir = path ?? await FilePicker.platform.getDirectoryPath();

    if(Isar.instanceNames.isEmpty){
      return await Isar.open(
        [ChatSchema, MessageSchema],
        directory: dir!
      );
    }

    return Future.value(Isar.getInstance());
  }

  Future<bool> isLoaded() async{
    final isar = await db;

    return isar.isOpen;
  }

  Future<void> deleteAll() async{
    final isar = await db;
    
    await isar.writeTxn(() => isar.clear());
  }

// FUNÇÕES PARA CHAT
//---------------------------------------------------------------------

  Future<void> saveChat(String title, String path) async{
    final newChat = Chat()
    ..chatName = title
    ..docPath = path;

    final isar = await db;

    await isar.writeTxn(() async{
      await isar.chats.put(newChat);
    });
  }

  Future<bool> chatIsEmpty() async{
    final isar = await db;
    return (isar.chats.countSync() > 0);
  }

  Stream<List<Chat>> listenToChat() async*{
    final isar = await db;
    
    yield* isar.chats.where().watch(fireImmediately: true);
  }

  Future<void> deleteChat(String name) async{
    final isar = await db;

    await isar.writeTxn(() async{
      final chat = await isar.chats
      .where()
      .chatNameEqualTo(name)
      .findFirst();
      
      if(chat != null){
        chat.messages.filter().deleteAll();

        await isar.chats.delete(chat.id);
      }
    });
  }

  //  FUNÇÕES PARA MESSAGE
  //----------------------------------------------------------------------------------------

  Future<void> saveMessage(bool isUser, String  content, Chat chat) async{
    final newMsg = Message()
    ..isUser = isUser
    ..content = content
    ..dateTime = DateTime.now()
    ..chat.value = chat;
    
    final isar = await db;

    await isar.writeTxn(() async{
      await isar.messages.put(newMsg);
      await newMsg.chat.save();
    });
  }

  Future<bool> messageIsEmpty() async{
    final isar = await db;
    return (isar.chats.countSync() > 0);
  }

  Stream<List<Message>> listenToMessage(Chat chat) async*{
    final isar = await db;

    yield* isar.messages.filter()
    .chat((q) => q.idEqualTo(chat.id))
    .watch(fireImmediately: true);
  }
}