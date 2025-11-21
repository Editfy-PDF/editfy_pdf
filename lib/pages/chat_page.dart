import 'dart:async';
import 'dart:isolate';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:editfy_pdf/pages/doc_viewer.dart';
import 'package:editfy_pdf/services/db_service.dart';
//import 'package:editfy_pdf/background_service.dart';
import 'package:editfy_pdf/services/llm_service.dart';
import 'package:editfy_pdf/services/config_service.dart';
import 'package:flutter/services.dart';

//import 'package:flutter_background_service/flutter_background_service.dart';

class ChatPage extends StatefulWidget{
  final Chat metadata;
  const ChatPage({super.key, required this.metadata});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StreamController _streamController = StreamController.broadcast();
  final DbService _dbService = DbService();
  final ConfigService configTable = ConfigService();
  StreamSubscription? _sub;

  bool _isBtnEnabled = false;

  @override
  void initState(){
    super.initState();
    _textEditingController.addListener(_onPromptChange);
    _streamController.addStream(_dbService.listenToMessage(widget.metadata));
    _reciveMessage();
  }

  @override
  void dispose(){
    _textEditingController.removeListener(_onPromptChange);
    _textEditingController.dispose();
    _streamController.close();
    _sub?.cancel();
    super.dispose();
  }

  void _onPromptChange(){
    setState((){
    _isBtnEnabled = _textEditingController.text.trim().isNotEmpty;
    });
  }

  void _reciveMessage(){
    _sub?.cancel();
    /*_sub = FlutterBackgroundService().on('return').listen((data){
      if(data != null && data.values.first is String && data.values.first != ''){}
      _dbService.saveMessage(false, data!.values.first, widget.metadata);
    });*/
  }
  
  void _sendMessage(){
    final msg = _textEditingController.text.trim();
    msg.isEmpty ? null : setState(() {
      _sendMessageIsolated(msg);
      //FlutterBackgroundService().invoke('request', {'prompt': msg});

      _dbService.saveMessage(true, msg, widget.metadata);

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      _textEditingController.clear();
    });
  }

  Future<void> _sendMessageIsolated(String text) async{
    final ReceivePort receivePort = ReceivePort();
    late SendPort isolatePort;
    bool portReady = false;
    bool isEOG = false;

    await Isolate.spawn(
      isolatedWorker,
      {
        'port': receivePort.sendPort,
        'token': RootIsolateToken.instance!
      }
    );

    receivePort.listen((data){
      if(data is SendPort){
        isolatePort = data;
        portReady = true;
      }

      if(data is Map<String, String>){
        if(data.containsKey('answer') && data['answer']!.isNotEmpty){
          _dbService.saveMessage(false, data['answer']!, widget.metadata);
        }

        if(data.containsKey('error') && data['error']!.isNotEmpty){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error']!))
          );
          
          // Remover ultimo texto do usuário depois do erro
        }
      }

      if(data is String){
        if(data == 'EOG'){
          isEOG = true;
        }
      }
    });

    while(!portReady){
      await Future.delayed(const Duration(milliseconds: 10));
    }

    isolatePort.send({
      'chatName': widget.metadata.chatName,
      'docPath': widget.metadata.docPath,
      'config': jsonEncode(configTable.config),
      'prompt': text
    });

    if(isEOG){
      receivePort.close();
    }
  }

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
        title: Text(widget.metadata.chatName),
        
        actions: <Widget> [
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(right: 10),
              child: Row(
                children: <Widget> [
                  IconButton(
                    icon: Icon(Icons.document_scanner),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return DocViewer(metadata: widget.metadata);
                      }));
                    },
                  )
                ]
              ),
            )
          )
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: _streamController.stream,
              builder: (context, asyncSnapshot) {
                if(!asyncSnapshot.hasData){
                  return const Center(child: CircularProgressIndicator());
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  controller: _scrollController,
                  itemCount: asyncSnapshot.data!.length,
                  itemBuilder: (context, index){
                    final message = asyncSnapshot.data![index];

                    if(message == null) return null;

                    return Align(
                      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: message.isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
                        ),
                        child: Text(
                          message.content!.trim(),
                        )
                      )
                    );
                  }
                );
              }
            )
          ),

          Align(
            alignment: Alignment.bottomLeft,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textEditingController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      enableInteractiveSelection: true,
                      decoration: InputDecoration(
                        labelText: 'Faça uma pergunda'
                      ),
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: _isBtnEnabled ? _sendMessage : null
                  )
                ],
              ),
            ),
          )
        ]
      )
    );
  }
}

void isolatedWorker(Map args) async{
  final SendPort sendPort = args['port'];
  final RootIsolateToken token = args['token'];
  final port = ReceivePort();
  sendPort.send(port.sendPort);
  LlmService? llm;

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  await for(final data in port){
    if (data is Map<String, String> ){
      if (data.containsKey('chatName') && data.containsKey('docPath') && data.containsKey('config')) {
        llm = LlmService(
          config: jsonDecode(data['config']!),
          chatName: data['chatName']!,
          docPath: data['docPath']!,
        );
      }

      if (data.containsKey('prompt') && llm != null) {
        try{
          final res = await llm.sendMsgToModel(data['prompt']!);

          final text = res?.output.content.trim() ?? '';
          sendPort.send({'answer': text});
          
          llm.dispose();
        } catch(e){
          sendPort.send({'error': 'Erro => $e'});
        }

        await Future.delayed(Duration(milliseconds: 10));
        sendPort.send('EOG');
        port.close();
        Isolate.exit();
      }
    }

    if(data is String){
      if(data == 'close'){
        sendPort.send('EOG');
        port.close();
        Isolate.exit();
      }
    }
  }
}