import 'dart:async';

import 'package:editfy_pdf/db_service.dart';
import 'package:editfy_pdf/config_service.dart';
import 'package:editfy_pdf/colections/message.dart';
import 'package:editfy_pdf/colections/chat.dart';

import 'package:pdfium_dart/pdfium_dart.dart';

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';

class LlmService {
  final DbService _dbService = DbService();
  final configTable = ConfigService();
  final _streamController = StreamController();
  late ChatOpenAI model;
  final List<ChatMessage> chatMessages = [];
  late Chat chat;
  final pdfium = Pdfium();

  LlmService(this.chat){
    if(configTable.config['backend'] == 'openai'){
      model = ChatOpenAI(apiKey: configTable.config['openaikey']);
    }

    else if(configTable.config['backend'] == 'lan'){
      model = ChatOpenAI(baseUrl: configTable.config['lanurl']);
    }

    _streamController.addStream(_dbService.listenToMessage(chat));

    chatMessages.add(
      ChatMessage.system('Você é um assistente que responde de forma direta usando o conteúdo de doocumentos.')
    );

    pdfium.openDoc(chat.docPath);

    final npages = pdfium.countPages();
    chatMessages.add(ChatMessage.system('Documento PDF: ${chat.chatName}'));

    for(int i=0; i < npages; i++){
      chatMessages.add(
        ChatMessage.system(
          'Página $i\n${pdfium.getText(i)}'
        )
      );
    }

    chatMessages.add(ChatMessage.system('Fim do documento'));
  }

  void dispose(){
    //_streamController.close(); erro
    model.close();
  } 

  void syncMessages() async{
    List<Message> dbMessages = [];
    final res = await _streamController.stream.first;
      dbMessages = res;

    for(var message in dbMessages){
      if(message.isUser){
        chatMessages.add(
          ChatMessage.humanText(message.content!)
        );
      } else{
        chatMessages.add(
          ChatMessage.ai(message.content!)
        );
      }
    }
  }

  Future<ChatResult?> sendMsgToModel(String text) async{
    // Adicionar try catch
    try{
      chatMessages.add(ChatMessage.humanText(text));

      final resp = await model.invoke(PromptValue.chat(chatMessages));
      chatMessages.add(ChatMessage.ai(resp.output.content));

      //print(resp.output.content.trim());
      _dbService.saveMessage(false, resp.output.content.trim(), chat);

      return resp;
    } catch(e) {
      print('Erro => $e');
      return null;
    }
  }
}