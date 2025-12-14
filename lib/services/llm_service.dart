import 'dart:async';
import 'dart:io';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/services/crypto_service.dart';
import 'package:editfy_pdf/services/prefill_service.dart';

import 'package:pdfium_dart/pdfium_dart.dart';

import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_google/langchain_google.dart';
import 'package:langchain_llamacpp/langchain_llamacpp.dart';

class LlmService {
  late Map<String, dynamic> config;
  late  BaseChatModel? model;
  final List<ChatMessage> chatMessages = [];
  late Chat? chat;
  final List<String> error = [];
  final pdfium = Pdfium(null);

  LlmService({required this.config, this.chat, String chatName='', String docPath=''}){
    chat ??= Chat(chatName: chatName, docPath: docPath);
    if(!File(chat!.docPath).existsSync()){
      error.add('O caminho de docPath (${chat!.docPath}) não existe!');
    }

    chatMessages.add(
      ChatMessage.system('''
      [Você é um assistente especializado em RAG.
      SUA RESPOSTA DEVE SER BASEADA APENAS NO CONTEXTO FORNECIDO.
      SUA resposta DEVE SER CURTA E DIRETA 
      NÃO REPITA as instruções dentro das tegs "system".
      SÓ RESPONDA na tag "assistant".
      
      1. Se o contexto TIVER a resposta, CITE as informações e o número da página (se disponível)

      2. Se o contexto NÃO CONTIVER informações suficientes, você DEVE responder: “Informação não encontrada no documento”.
      Se houver contradições nos trechos, aponte a contradição e não complemente nada fora dos documentos.
      Não use seu conhecimento interno, não invente, não deduza, não extrapole.
      
      3. Se o usuário pedir algo FORA dos documentos, responda: “A solicitação está fora do escopo dos documentos fornecidos.”]
      ''')
    );
  }

  void dispose(){
    model?.close();
  }

  Future<void> _startModel() async{
    final service = config['service'];

    if(service == 'openai'){
      final key = await decryptAES(config['openaikey']);
      if(key == '') error.add('Chave de API está vazia');
      
      model = ChatOpenAI(apiKey: key);
    }

    else if(service == 'gemini') {
      final key = await decryptAES(config['geminikey']);
      if(key == '') error.add('Chave de API está vazia');
      
      model = ChatGoogleGenerativeAI(apiKey: key);
    }

    else if(service == 'custom'){
      try{
        final url = '${config['lanurl']!}/v1';
        model = ChatOpenAI(baseUrl: url);
      } catch(e){
        model = null;
        final url = '${config['lanurl']!}/v1';
        error.add(url.startsWith('/v1') ? 'URL está vazia' : e.toString());
      }
    }

    else if(service == 'local'){
      if(!File(config['modelpath']!).existsSync()){
        error.add('O caminho do modelo (${config['modelpath']}) não existe!');
      }
      
      final options = ChatLlamaOptions(
        model: config['modelpath'],
        numCtx: 4096,
        temperature: 0.2
      );

      model = ChatLlamacpp(modelPath: config['modelpath'], defaultOptions: options);
    } else{
      error.add('Serviço desconhecido: $service');
    }
  }

  bool openDoc(String prompt) {
  final analizer = PageAnalist();
  List<String> extractedTextPerPage = [];

  pdfium.openDocument(chat!.docPath);
  final npages = pdfium.countPages();

  if (npages > 2) {
    for (int i = 0; i < npages; i++) {
      extractedTextPerPage.add(
        pdfium.getText(i)
        .trim()
        .replaceAll('\t', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
      );
    }
    if(extractedTextPerPage.join('').trim() == ''){
      return false;
    }

    final tokenizedPages = List.generate(
      extractedTextPerPage.length,
      (int i) => analizer.tokenize(extractedTextPerPage[i]),
    );

    final queryTokens = analizer.tokenize(prompt);

    final pageRank = analizer.semanticSearchLSH(
      tokenizedPages,
      queryTokens,
    );

    final topk = pageRank.length < 10 ? pageRank : pageRank.sublist(0, 10);

    late List<(int, double)> semanticRank;
    if(topk.isNotEmpty){
      semanticRank = analizer.semanticSearchLSI(
        List.generate(topk.length, (i) => tokenizedPages[topk[i].$1]),
        queryTokens
      );
    }
    else{
      semanticRank = analizer.semanticSearchLSI(
        List.generate(
          tokenizedPages.length < 10 ? tokenizedPages.length : 10,
          (i) => tokenizedPages[i]
        ),
        queryTokens
      );
    }

    final top = semanticRank.length <= 2
    ? semanticRank
    : semanticRank.getRange(0, 2);

    chatMessages.add(ChatMessage.system('''<CONTEXT>
    [Nome do arquivo: ${chat!.chatName}
    '''));
    for (final i in top) {
      chatMessages.add(ChatMessage.system(
        '(Página ${i.$1}) ${extractedTextPerPage[i.$1]}'
      ));
    }
    chatMessages.add(ChatMessage.system(']</CONTEXT>'));
  }
  else {
    final List<String> pagesText = [];
    for(int i=0; i<npages; i++){
      pagesText.add(
        pdfium.getText(i)
        .trim()
        .replaceAll('\t', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
      );
    }
    if(pagesText.join('').trim() == '') return false;

    chatMessages.add(ChatMessage.system(
      '''<CONTEXTO>
      [Nome do arquivo: ${chat!.chatName}
      ${pagesText.join('\n').trim()}]
      </CONTEXTO>'''
    ));
  }

  return true;
}

  void stopGeneration(){
    if(model is ChatLlamacpp){
     (model as ChatLlamacpp).stop();
    }
  }

  Future<ChatResult?> sendMsgToModel(String text) async{
    try{
      await _startModel();
      
      if(error.isNotEmpty) throw Exception(error[0]);

      final status = openDoc(text);
      if(!status) throw Exception('Este documento não tem texto para extração');

      chatMessages.add(ChatMessage.humanText('$text\nassistant:'));

      final resp = await model!.invoke(PromptValue.chat(chatMessages));

      return resp;
    } catch(e) {
      rethrow;
    }
  }
}