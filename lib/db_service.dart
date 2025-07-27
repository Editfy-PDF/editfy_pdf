import 'package:editfy_pdf/config_service.dart';
import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/colections/message.dart';

import 'package:isar/isar.dart';
import 'package:file_picker/file_picker.dart';


class DbService {
  static DbService? _instance;
  static Future<Isar>? _db;
  final ConfigService _cfgService = ConfigService();

  DbService._internal(){
    _db ??= _openDb();
  }

  factory DbService(){
    return _instance ??= DbService._internal();
  }

  Future<Isar> get db => _db!;

  //  FUNÇÕES GERAIS
  //---------------------------------------------------------------

  Future<void> dispose() async{
    final isar = await db;
    isar.close();

    _db = null;
    _instance = null;
  }

  Future<Isar> _openDb() async{
    try{
      if(_cfgService.config['dbpath'] == '' || _cfgService.config['dbpath'] == null){
        final dbPath = await FilePicker.platform.getDirectoryPath();
        _cfgService.modfyCfgTable('dbpath', dbPath);
      }

      if(Isar.instanceNames.isEmpty){
        return await Isar.open(
          [ChatSchema, MessageSchema],
          directory: _cfgService.config['dbpath']
        );
      }

      return Future.value(Isar.getInstance());
    } catch(e){
      return _openDb();
    }
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