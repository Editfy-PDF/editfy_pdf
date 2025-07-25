import 'dart:async';
import 'package:flutter/material.dart';

import 'package:editfy_pdf/config_page.dart';
import 'package:editfy_pdf/chat_page.dart';
import 'package:editfy_pdf/db_service.dart';
import 'package:editfy_pdf/colections/chat.dart';

import 'package:file_picker/file_picker.dart';

class HomePage extends StatefulWidget {
  final String? bdPath;
  
  const HomePage({super.key, required this.bdPath});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  late DbService _dbService;
  final StreamController _streamController = StreamController.broadcast();

  @override
  void initState(){
    super.initState();
    _dbService = DbService(widget.bdPath);
    _streamController.addStream(_dbService.listenToChat());
  }

  @override
  void dispose(){
    _streamController.close();
    _dbService.dispose();
    super.dispose();
  }

  void submitDocument(List<Chat> chatList) async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf']
    );
    
    if (result != null) {
      if(!chatList.any((key)=> key.docPath == result.files.first.path!)){
        _dbService.saveChat(
          result.files.first.name,
          result.files.first.path!
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        title: const Text('Recentes'),
        actions: <Widget> [
          SafeArea(
            child: Container(
              padding: const EdgeInsets.only(right: 10),
              alignment: Alignment.center,
              child: Row(
                children: <Widget> [
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return ConfigPage();
                      }));
                    },
                  )
                ]
              ),
            ),
          ),
        ]
      ),

      body: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, asyncSnapshot) {
          if(!asyncSnapshot.hasData){
            return const Center(child: CircularProgressIndicator());
          }

          if(asyncSnapshot.data!.isEmpty){
            return Center(
              child: const Text('Nenhum documento foi selecionado')
            );
          }
          
          return ListView.builder(
            itemCount: asyncSnapshot.data!.length,
            itemBuilder: (BuildContext context, int index){
              return ListTile( // Adicionar imagem do arquivo
                leading: CircularProgressIndicator(),
                title: Text(asyncSnapshot.data![index].chatName),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _dbService.deleteChat(asyncSnapshot.data![index].chatName);
                  },
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return ChatPage(metadata: asyncSnapshot.data![index], bdPath: widget.bdPath);
                  }));
                }
              );
            },
          );
        }
      ),

      floatingActionButton: StreamBuilder(
        stream: _streamController.stream,
        builder: (context, asyncSnapshot) {
          return FloatingActionButton(
            onPressed: () async{
              asyncSnapshot.hasData ? submitDocument(
                asyncSnapshot.data!
              ) : null;
            },
            child: Icon(Icons.arrow_upward),
          );
        }
      ),
    );
  }
}
