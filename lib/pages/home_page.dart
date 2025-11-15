import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';

import 'package:editfy_pdf/pages/config_page.dart';
import 'package:editfy_pdf/pages/chat_page.dart';
import 'package:editfy_pdf/db_service.dart';
import 'package:editfy_pdf/colections/chat.dart';

import 'package:pdfium_dart/pdfium_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}


class _HomePageState extends State<HomePage> {
  final DbService _dbService = DbService();
  final StreamController _streamController = StreamController.broadcast();
  final Map<int, Uint8List?> _thumbCache = {};

  @override
  void initState(){
    super.initState();
    _streamController.addStream(_dbService.listenToChat());
  }

  @override
  void dispose(){
    _streamController.close();
    _dbService.dispose();
    super.dispose();
  }

  Uint8List? renderThumb(String path){
    final pdfium = Pdfium(null);
    final res = pdfium.openDocument(path);
    if(res != 0) throw Exception('Erro ao abrir documento -> ${pdfium.getLastError()}');

    final rawData = pdfium.renderPage(0, 400, 600);
    if(rawData == null) throw Exception('Erro ao renderizar thumbnail');

    final rawImage = img.Image.fromBytes(width: 400, height: 600, bytes: rawData.buffer);
    if(!rawImage.isValid) throw Exception('Erro ao converter thumbnail');

    return img.encodePng(rawImage);
  }

  void submitDocument(List<Chat>? chatList) async{
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) return;

    final pickedFile = result.files.first;
    final path = pickedFile.path!;
    final name = pickedFile.name;

    if (chatList == null || chatList.isEmpty || 
        !chatList.any((chat) => chat.chatName == name)) {
      _dbService.saveChat(name, path);
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

          final datalen = asyncSnapshot.data!.length;
          if(datalen > _thumbCache.keys.length){
            for(var i=0; i < datalen; i++){
              if(!_thumbCache.keys.contains(asyncSnapshot.data![i].id)){
                _thumbCache[asyncSnapshot.data![i].id] = renderThumb(asyncSnapshot.data![i].docPath);
              }
            }
          }
          
          return ListView.builder(
            itemCount: datalen,
            itemBuilder: (BuildContext context, int index){
              final chat = asyncSnapshot.data![index];
              return ListTile(
                leading: _thumbCache.keys.contains(chat.id)
                  ? Image.memory(
                      _thumbCache[chat.id]!,
                      width: 80,
                      height: 100,
                      fit: BoxFit.contain,
                    )
                  : Icon(Icons.picture_as_pdf, color: Colors.red),
                title: Text(chat.chatName),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    _dbService.deleteChat(chat.chatName);
                    _thumbCache.remove(chat.id);
                  },
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return ChatPage(metadata: chat);
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
              submitDocument(
                asyncSnapshot.data
              );
            },
            child: Icon(Icons.arrow_upward),
          );
        }
      ),
    );
  }
}
