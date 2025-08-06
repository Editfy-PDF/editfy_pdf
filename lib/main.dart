import 'package:flutter/material.dart';

import 'package:editfy_pdf/db_service.dart';
import 'package:editfy_pdf/pages/home_page.dart';
import 'package:editfy_pdf/config_service.dart';

import 'package:provider/provider.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  DbService();
  ConfigService();

  runApp(ChangeNotifierProvider(
    create: (_) => DefinitionsProvider(),
    child: EditfyPDF()
  ));
}

class DefinitionsProvider extends ChangeNotifier{
  var themeState = ThemeMode.system;
  final cfgService = ConfigService();

  DefinitionsProvider(){
    changeTheme(cfgService.config['theme']);
  }
  
  Future<void> changeTheme(String theme) async{
    theme == 'system' ? themeState = ThemeMode.system :
    (theme == 'dark' ? themeState = ThemeMode.dark : themeState = ThemeMode.light);
    
    notifyListeners();
  }
}


class EditfyPDF extends StatelessWidget {
  const EditfyPDF({super.key});

  @override
  Widget build(BuildContext context){
    final theme = Provider.of<DefinitionsProvider>(context).themeState;

    final textFieldDecoration = InputDecorationTheme(
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey),
      ),
      isDense: true,
      contentPadding: EdgeInsets.all(12),
    );

    final lightTheme = ColorScheme.light(
      primary: const Color(0xFFD6D6D6), // usado para AppBar ou fundo principal
      onPrimary: Colors.black,          // Cor do texto ou ícones sobre o primary
      secondary: Colors.black,          // Usado para botões flutuantes, ícones
      onSecondary: Colors.white,        // Cor sobre o botão/flutuante preto
      error: Colors.red,
      onError: Colors.white,            // Texto sobre o vermelho
      surface: Colors.white,            // Cor de fundo da tela
      onSurface: Colors.black,          // Texto sobre o fundo cinza
    );

    final darkTheme = ColorScheme.dark(
      primary: const Color(0xFF1E1E1E),
      onPrimary: Colors.white,
      secondary: Colors.white,
      onSecondary: Colors.black,
      error: Colors.red.shade400,
      onError: Colors.black,
      surface: Colors.black,
      onSurface: Colors.white,
    );

    return MaterialApp(
      title: 'Editfy PDF',
      themeMode: theme,
      theme: ThemeData.from(colorScheme: lightTheme).copyWith(
        inputDecorationTheme: textFieldDecoration
      ),
      darkTheme: ThemeData.from(colorScheme: darkTheme).copyWith(
        inputDecorationTheme: textFieldDecoration
      ),
      home: HomePage(),
    );
  }
}

