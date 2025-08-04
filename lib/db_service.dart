import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/colections/message.dart';
import 'package:editfy_pdf/objectbox.g.dart';

import 'package:path_provider/path_provider.dart';


class DbService {
  static DbService? _instance;
  static Future<Store>? _db;

  DbService._internal(){
    _db ??= _openDb();
  }

  factory DbService(){
    return _instance ??= DbService._internal();
  }

  Future<Store> get db => _db!;

  //  FUNÇÕES GERAIS
  //---------------------------------------------------------------

  Future<void> dispose() async{
    final box = await db;
    box.close();

    _db = null;
    _instance = null;
  }

  Future<Store> _openDb() async{
    final dbPath = await getApplicationDocumentsDirectory();
    
    return await openStore(directory: "${dbPath.path}/openbox.db"); 
  }

  Future<bool> isLoaded() async{
    final box = await db;

    return box.isClosed();
  }

  Future<void> deleteAll() async{
    final box = await db;
    
    await box.box().removeAllAsync();
  }

// FUNÇÕES PARA CHAT
//---------------------------------------------------------------------

  Future<void> saveChat(String title, String path) async{
    final newChat = Chat(
      chatName: title,
      docPath: path
    );

    final box = await db;

    box.box<Chat>().put(newChat);
  }

  Future<bool> chatIsEmpty() async{
    final box = await db;
    return box.box<Chat>().isEmpty();
  }

  Stream<List<Chat>> listenToChat() async*{
    final box = await db;
    final content = box.box<Chat>();
    
    yield* content.query()
    .watch(triggerImmediately: true)
    .map((q) => q.find());
  }

  Future<void> deleteChat(String name) async{
    final box = await db;
    final chats = box.box<Chat>();

    late Chat? chat;
    try{
      final cQuery = chats.query(
        Chat_.chatName.equals(name)
      ).build();
      chat = cQuery.find().first;
      cQuery.close();
    } catch(e){
      chat = null;
    }
      
    if(chat != null){
      final mQuery = box.box<Message>().query(
        Message_.chatId.equals(chat.id)
      ).build();
      final messages = mQuery.find();
      if(messages.isNotEmpty){
        final List<int> ids = [];
        for(var i in messages){
          ids.add(i.chatId);
        }
        box.box<Message>().removeMany(ids);
      }
      mQuery.close();
      
      await box.box<Chat>().removeAsync(chat.id);
    }
  }

  //  FUNÇÕES PARA MESSAGE
  //----------------------------------------------------------------------------------------

  Future<void> saveMessage(bool isUser, String  content, Chat chat) async{
    final newMsg = Message(
      isUser: isUser,
      content: content,
      dateTime: DateTime.now(),
      chatId: chat.id
    );
    
    final box = await db;

    box.box<Message>().put(newMsg);
  }

  Future<bool> messageIsEmpty() async{
    final box = await db;
    return box.box<Message>().isEmpty();
  }

  Stream<List<Message>> listenToMessage(Chat chat) async*{
    final box = await db;
    final content = box.box<Message>();
    
    yield* content.query(Message_.chatId.equals(chat.id))
    .watch(triggerImmediately: true)
    .map((q) => q.find());
  }
}