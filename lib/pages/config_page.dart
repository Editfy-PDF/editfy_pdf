import 'package:flutter/material.dart';

import 'package:editfy_pdf/main.dart';

import 'package:provider/provider.dart';

// adicionar integração com Gemini

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

    if(definitions.cfgService.config['backend'] == 'openai'){
      txtController.text = definitions.cfgService.config['openaikey'];
    } else if(definitions.cfgService.config['backend'] == 'lan'){
      txtController.text = definitions.cfgService.config['lanurl'];
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
              ListTile(
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
                        style: TextStyle(color: theme.colorScheme.onSurface)
                      ));
                  }),
              ),
          
              Divider(),
          
              ListTile(
                leading: Icon(Icons.account_tree_sharp),
                title: Text('Backend'),
                trailing: MenuAnchor(
                  menuChildren: [
                    MenuItemButton(
                      child: Text('OpenAI'),
                      onPressed: () {
                        setState(() {
                          definitions.cfgService.modfyCfgTable('backend', 'openai');
                        });
                      }
                    ),
          
                    MenuItemButton(
                      child: Text('Rede Local'),
                      onPressed: () {
                        setState(() {
                          definitions.cfgService.modfyCfgTable('backend', 'lan');
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
                        definitions.cfgService.config['backend'] == 'openai' ? 'OpenAI' : 'Rede Local',
                        style: TextStyle(color: theme.colorScheme.onSurface)
                      ),
                    );
                  },
                ),
              ),

              if(definitions.cfgService.config['backend'] == 'openai')
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: txtController,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (txt) {
                    definitions.cfgService.modfyCfgTable('openaikey', txt.trim());
                  }
                ),
              ),

              if(definitions.cfgService.config['backend'] == 'lan')
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  autofocus: false,
                  controller: txtController,
                  maxLines: 1,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (txt) {
                    definitions.cfgService.modfyCfgTable('lanurl', txt.trim());
                  }
                ),
              ),
          
              Divider(),
              // Proxímo widget de configuração
            ]
          ),
        ]
      )
    );
  }
}
