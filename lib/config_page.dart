import 'package:editfy_pdf/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConfigPage extends StatefulWidget{
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);
    final themeMode = Provider.of<DefinitionsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.backgroundColor,
        centerTitle: true,
        title: const Text('Configurações'),
      ),
      
      body: Column(
        children: [
          ListTile(
            leading: Icon(
              themeMode.themeState == ThemeMode.system ? Icons.brightness_auto_sharp :
              (themeMode.themeState == ThemeMode.light ? Icons.brightness_low_sharp : Icons.brightness_3_sharp)
            ),
            title: Text('Theme'),
            trailing: MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  child: const Text('system'),
                  onPressed: (){
                    setState(() {
                      themeMode.changeTheme('system');
                    });
                  },
                ),
                MenuItemButton(
                  child: const Text('dark'),
                  onPressed: (){
                    setState(() {
                      themeMode.changeTheme('dark');
                    });
                  },
                ),
                MenuItemButton(
                  child: Text('light'),
                  onPressed: (){
                    setState(() {
                      themeMode.changeTheme('light');
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
                    themeMode.themeState == ThemeMode.system ? 'system' :
                    (themeMode.themeState == ThemeMode.light ? 'light' : 'dark'),
                    style: TextStyle(color: theme.colorScheme.onSurface)
                  ));
              }),
          ),

          Divider(),

          // Proxímo widget de configuração
        ]
      )
    );
  }
}
