/*import 'dart:async';
import 'dart:isolate';

import 'package:editfy_pdf/llm_service.dart';
import 'package:editfy_pdf/colections/message.dart';

import 'package:flutter_background_service/flutter_background_service.dart';

@pragma('vm:entry-point')
Future<void> initializeBgService(ServiceInstance service) async{
  print('executando initializeBgService...');
  
  final ReceivePort receivePort = ReceivePort();
  late SendPort workerPort;
  
  print('starting bgService thread...');

  await Isolate.spawn(bgWorker, receivePort.sendPort);

  receivePort.listen((data){
    if(data is SendPort) workerPort = data;

    if(data is String) print('bgService: $data');
    
    if(data is Map<String, String> && data.containsKey('answer') && data['answer']!.isNotEmpty){
      service.invoke('return', {'answer': data['answer']});
    }
  });

  if(service is AndroidServiceInstance){
    service.setForegroundNotificationInfo(
      title: "LlmService ativo",
      content: "Executando modelo local em background",
    );
    
    service.on('update').listen((data){
      if(data is Map<String, String> && data.containsKey('chatName') && data.containsKey('docPath')){
        print('update request receved');
        if(data['chatName']!.isNotEmpty && data['docPath']!.isNotEmpty){
          workerPort.send({
            'chatName': data['chatName'],
            'docPath': data['docPath']
          });
        }
      }
    });

    service.on('request').listen((data){
      if(data != null){
        if(data.values.first is List<Message> && data.isNotEmpty){
          print('List<Message> request receved');
          print('messages -> ${data['messages']}');
          //data['messages'] as List<Message>; // Incompatível com Isolate
        }

        if(data.values.first is String && data.isNotEmpty){
          print('prompt received');
          workerPort.send(data['prompt']);
        }
      }
    });

    service.on('stopService').listen((_){
      service.stopSelf();
    });
  }
}

//@pragma('vm:entry-point')
Future<void> bgWorker(SendPort sendPort) async{
  print('bgWorker running...');
  LlmService? llmService;
  final port = ReceivePort();
  sendPort.send(port.sendPort);

  await for(final msg in port){
    if(msg is Map<String, String>){
      if(msg.containsKey('chatName') && msg.containsKey('docPath')){
        sendPort.send('creating llmService...');
        //llmService = LlmService(chatName: msg['chatName'], docPath:  msg['docPath']);
      }

      // adicionar forma de consumir o contexto do chat

      if(msg.containsKey('prompt') && msg['prompt']!.isNotEmpty && llmService != null){
        sendPort.send('procesing prompt...');
        final resp = await Isolate.run(() => llmService!.sendMsgToModel(msg['prompt']!));
        sendPort.send({'answer': resp!.output.content.trim()});
      }
    }
  }
}*/