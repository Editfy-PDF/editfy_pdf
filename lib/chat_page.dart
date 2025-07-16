import 'dart:async';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:flutter/material.dart';
import 'package:editfy_pdf/doc_viewer.dart';
import 'package:editfy_pdf/db_service.dart';

// Adicionar parser de PDF

class ChatPage extends StatefulWidget{
  final Chat metadata;
  final String? bdPath;
  const ChatPage({super.key, required this.metadata, required this.bdPath});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>{
  final TextEditingController _textEditingController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final StreamController _streamController = StreamController.broadcast();
  late DbService _dbService;

  bool _isBtnEnabled = false;

  @override
  void initState(){
    super.initState();
    _dbService = DbService(widget.bdPath);
    _textEditingController.addListener(_onPromptChange);
    _streamController.addStream(_dbService.listenToMessage(widget.metadata));
  }

  @override
  void dispose(){
    _textEditingController.removeListener(_onPromptChange);
    _textEditingController.dispose();
    _streamController.close();
    super.dispose();
  }

  void _onPromptChange(){
    setState((){
    _isBtnEnabled = _textEditingController.text.trim().isNotEmpty;
    });
  }
  
  void _sendMessage(){
    final msg = _textEditingController.text.trim();
    msg.isEmpty ? null : setState((){
      _dbService.saveMessage(true, msg, '', widget.metadata);

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      _textEditingController.clear();
    });
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
                        labelText: 'Faça uma pergunda',
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: theme.colorScheme.onSurface
                          )
                        ),
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