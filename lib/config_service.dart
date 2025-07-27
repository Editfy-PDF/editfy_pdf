import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

class ConfigService {
  static ConfigService? _instance;
  
  Map<String, dynamic>? _configTable;

  static final Map<String, dynamic> _cfgTemplate = {
    'theme': 'system',
    'dbPath': '',
    'backend': 'openai',
    'openaikey': '',
    'lanurl': ''
  };

  Map<String, dynamic> get config => _configTable!;

  ConfigService._internal(){
    _configTable ??= readFromFile();
  }

  factory ConfigService(){
    return _instance ??= ConfigService._internal();
  }

  void modfyCfgTable(String key, dynamic value){
    _configTable![key] = value;
    saveToFile();
  }
    
  void saveToFile() async{
    while(config['dbpath'] == '' || config['dbpath'] == null){
      _cfgTemplate['dbpath'] = await FilePicker.platform.getDirectoryPath();
    }

    final dir = config['dbpath'];
    final file = File('$dir/config.json');

    await file.writeAsString(jsonEncode(config));
  }

  Map<String, dynamic> readFromFile(){
    if(_configTable == null){
      return _cfgTemplate;
    }
    
    final dir = _cfgTemplate['dbpath'];
    final file = File('$dir/config.json');
    
    if(file.existsSync()){
      final data = file.readAsStringSync();
      return jsonDecode(data);
    }

    file.writeAsStringSync(jsonEncode(_configTable));

    return _configTable!;
  }
}
