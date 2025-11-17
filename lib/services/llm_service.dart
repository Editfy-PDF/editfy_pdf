import 'dart:async';
import 'dart:io';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/services/crypto_service.dart';

import 'package:pdfium_dart/pdfium_dart.dart';

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_llamacpp/langchain_llamacpp.dart';

class LlmService {
  late Map<String, dynamic> config;
  late  BaseChatModel model;
  final List<ChatMessage> chatMessages = [];
  late Chat? chat;
  final pdfium = Pdfium(null);

  LlmService({required this.config, this.chat, String chatName='', String docPath=''}){
    chat ??= Chat(chatName: chatName, docPath: docPath);
    if(!File(chat!.docPath).existsSync()){
      throw Exception('O caminho de docPath (${chat!.docPath}) não existe!');
    }

    //_startModel();
    //Future.delayed(Duration(seconds: 20));

    chatMessages.add(
      ChatMessage.system('Você é um assistente que responde de forma direta usando o conteúdo de documentos.')
    );

    pdfium.openDocument(chat!.docPath);

    final npages = pdfium.countPages();
    chatMessages.add(ChatMessage.system('Documento PDF: ${chat!.chatName}'));

    // Adicionar algoritmo de busca em páginas PDF (otimização de contexto)
    if(npages > 1){
      for(int i=0; i < npages; i++){
        chatMessages.add(
          ChatMessage.system(
            'Página ${i + 1}\n${pdfium.getText(i)}'
          )
        );
      }

      chatMessages.add(ChatMessage.system('Fim do documento\n'));
    } else{
      chatMessages.addAll([
        ChatMessage.system(pdfium.getText(0)),
        ChatMessage.system('Fim do documento\n')
      ]);
    }
  }

  void dispose(){
    model.close();
  }

  Future<void> _startModel() async{
    if(config['service'] == 'openai'){
      model = ChatOpenAI(apiKey: await decryptAES(config['openaikey']));
    }

    if(config['service'] == 'gemini') {
      model = ChatGoogleGenerativeAI(apiKey: await decryptAES(config['geminikey']));
    }

    else if(config['service'] == 'custom'){
      model = ChatOpenAI(baseUrl: '${config['lanurl']!}/v1');
    }

    else if(config['service'] == 'local'){
      if(!File(config['modelpath']!).existsSync()){
        throw Exception('O caminho do modelo (${config['modelpath']}) não existe!');
      }
      
      final options = ChatLlamaOptions(
        model: config['modelpath'],
        numCtx: 0
      );

      model = ChatLlamacpp(modelPath: config['modelpath'], defaultOptions: options);
    }
  }

  Future<ChatResult?> sendMsgToModel(String text) async{
    try{
      await _startModel();

      chatMessages.add(ChatMessage.humanText(text));

      final resp = await model.invoke(PromptValue.chat(chatMessages));

      return resp;
    } catch(e) {
      rethrow;
    }
  }
}