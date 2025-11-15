import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class ConfigService {
  static ConfigService? _instance;
  
  Map<String, dynamic>? _configTable;

  static final Map<String, dynamic> _cfgTemplate = {
    'theme': 'system',
    'service': 'local',
    'openaikey': '',
    'geminikey': '',
    'lanurl': '',
    'modelpath': ''
  };

  Map<String, dynamic> get config => _configTable!;

  ConfigService._internal(){
    _configTable = _cfgTemplate;
    readFromFile();
  }

  factory ConfigService(){
    return _instance ??= ConfigService._internal();
  }

  void modfyCfgTable(String key, dynamic value){
    _configTable![key] = value;
    saveToFile();
  }
    
  void saveToFile() async{
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/config.json');

    await file.writeAsString(jsonEncode(config));
  }

  void readFromFile() async{ 
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/config.json');
    
    if(file.existsSync()){
      final data = file.readAsStringSync();
      _configTable = jsonDecode(data);
    } else{
      _configTable = _cfgTemplate;
      saveToFile();
    }
  }
}
