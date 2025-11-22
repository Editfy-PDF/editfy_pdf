import 'package:flutter/material.dart';

import 'package:editfy_pdf/main.dart';
import 'package:editfy_pdf/services/crypto_service.dart';

import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

class ConfigPage extends StatefulWidget{
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final TextEditingController txtController = TextEditingController();

  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final definitions = Provider.of<DefinitionsProvider>(context);

    if(definitions.cfgService.config['service'] == 'openai'){
      txtController.text = definitions.cfgService.config['openaikey'];
    } 
    else if(definitions.cfgService.config['service'] == 'custom'){
      txtController.text = definitions.cfgService.config['lanurl'];
    }
    else if(definitions.cfgService.config['service'] == 'gemini'){
      txtController.text = definitions.cfgService.config['geminikey'];
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: const Text('Configurações'),
      ),
      
      body: ListView(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Card(
                  color: theme.colorScheme.secondary,
                  child: ListTile(
                    iconColor: theme.colorScheme.onSecondary,
                    textColor: theme.colorScheme.onSecondary,
                    leading: Icon(
                      definitions.themeState == ThemeMode.system ? Icons.brightness_auto_sharp :
                      (definitions.themeState == ThemeMode.light ? Icons.brightness_low_sharp : Icons.brightness_3_sharp)
                    ),
                    title: Text('Theme'),
                    trailing: MenuAnchor(
                      menuChildren: [
                        MenuItemButton(
                          child: const Text('system'),
                          onPressed: (){
                            setState(() {
                              definitions.changeTheme('system');
                              definitions.cfgService.modfyCfgTable('theme', 'system');
                            });
                          },
                        ),
                        MenuItemButton(
                          child: const Text('dark'),
                          onPressed: (){
                            setState(() {
                              definitions.changeTheme('dark');
                              definitions.cfgService.modfyCfgTable('theme', 'dark');
                            });
                          },
                        ),
                        MenuItemButton(
                          child: Text('light'),
                          onPressed: (){
                            setState(() {
                              definitions.changeTheme('light');
                              definitions.cfgService.modfyCfgTable('theme', 'light');
                            });
                          }
                        )
                      ],
                      builder: (BuildContext context, MenuController controller, Widget? child){
                        return TextButton(
                          onPressed: (){
                            if(controller.isOpen){
                              controller.close();
                            } else{
                              controller.open();
                            }
                          },
                          child: Text(
                            definitions.themeState == ThemeMode.system ? 'system' :
                            (definitions.themeState == ThemeMode.light ? 'light' : 'dark'),
                            style: TextStyle(color: theme.colorScheme.onSecondary)
                          )
                        );
                      }
                    ),
                  ),
                ),
              ),
          
              //Divider(),
          
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Card(
                  elevation: 3,
                  color: theme.colorScheme.secondary,
                  child: Column(
                    children: [
                      ListTile(
                        iconColor: theme.colorScheme.onSecondary,
                        textColor: theme.colorScheme.onSecondary,
                        leading: Icon(Icons.account_tree_sharp),
                        title: Text('Service'),
                        trailing: MenuAnchor(
                          menuChildren: [
                            MenuItemButton(
                              child: Text('OpenAI'),
                              onPressed: () {
                                setState(() {
                                  definitions.cfgService.modfyCfgTable('service', 'openai');
                                });
                              }
                            ),
                      
                            MenuItemButton(
                              child: Text('Gemini'),
                              onPressed: () {
                                setState(() {
                                  definitions.cfgService.modfyCfgTable('service', 'gemini');
                                });
                              }
                            ),
                                
                            MenuItemButton(
                              child: Text('Servidor Personalizado'),
                              onPressed: () {
                                setState(() {
                                  definitions.cfgService.modfyCfgTable('service', 'custom');
                                });  
                              }
                            ),
                      
                            MenuItemButton(
                              child: Text('Llama.cpp'),
                              onPressed: () {
                                setState(() {
                                  definitions.cfgService.modfyCfgTable('service', 'local');
                                });  
                              }
                            ),
                          ],
                                
                          builder: (context, controller, child) {
                            return TextButton(
                              onPressed: () {
                                if(controller.isOpen){
                                  controller.close();
                                } else{
                                  controller.open();
                                }
                              },
                                
                              child: Text(
                                switch(definitions.cfgService.config['service']){
                                  'openai' => 'OpenAI',
                                  'gemini' => 'Gemini',
                                  'local' => 'Llama.cpp',
                                  _ => 'Servidor Personalizado'
                      
                                },
                                style: TextStyle(color: theme.colorScheme.onSecondary)
                              ),
                            );
                          },
                        ),
                      ),
                  
                      if(definitions.cfgService.config['service'] == 'openai')
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          controller: txtController,
                          maxLines: 1,
                          style: TextStyle(color: theme.colorScheme.onSecondary),
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          obscuringCharacter: '*',
                          onSubmitted: (txt) async{
                            final crypted = await encryptAES(txt);
                            definitions.cfgService.modfyCfgTable('openaikey', crypted.trim());
                            setState((){});
                          }
                        ),
                      ),
                  
                      if(definitions.cfgService.config['service'] == 'gemini')
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          controller: txtController,
                          maxLines: 1,
                          style: TextStyle(color: theme.colorScheme.onSecondary),
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          obscuringCharacter: '*',
                          onSubmitted: (txt) async{
                            final crypted = await encryptAES(txt);
                            definitions.cfgService.modfyCfgTable('geminikey', crypted.trim());
                            setState(() {});
                          }
                        ),
                      ),
                  
                      if(definitions.cfgService.config['service'] == 'custom')
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: TextField(
                          autofocus: false,
                          controller: txtController,
                          maxLines: 1,
                          cursorColor: Colors.blue,
                          style: TextStyle(color: theme.colorScheme.onSecondary),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (txt) {
                            definitions.cfgService.modfyCfgTable('lanurl', txt.trim());
                          }
                        ),
                      ),
                  
                      if(definitions.cfgService.config['service'] == 'local')
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              (definitions.cfgService.config['modelpath'] as String).split('/').last,
                              style: TextStyle(color: theme.colorScheme.onSecondary)
                            ),
                          ),
                  
                          ElevatedButton.icon(
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Carregar modelo'),
                            onPressed: () async{
                              final result = await FilePicker.platform.pickFiles(type: FileType.any);
                              
                              if(result == null || result.files.isEmpty){
                                return;
                              }
                  
                              final filePath = result.files.single.path;
                              if(filePath == null || !filePath.endsWith('.gguf')){
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Arquivo inválido.')),
                                );
                                return;
                              }
                              
                              setState(() => definitions.cfgService.modfyCfgTable('modelpath', filePath));
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Modelo carregado com sucesso.')),
                              );
                            }
                          )
                        ]
                      ),
                    ],
                  ),
                ),
              ),

              // Proxímo widget de configuração
            ]
          ),
        ]
      )
    );
  }
}
