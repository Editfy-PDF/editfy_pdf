import 'package:editfy_pdf/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:file_picker/file_picker.dart';

void main() async{
  final dbPath = await FilePicker.platform.getDirectoryPath();
  
  runApp(ChangeNotifierProvider(
    create: (_) => DefinitionsProvider(dbPath),
    child: EditfyPDF()
  ));
}

class DefinitionsProvider extends ChangeNotifier{
  var themeState = ThemeMode.system;
  late String? dbPath;

  DefinitionsProvider(this.dbPath);
  
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
    final definitions = Provider.of<DefinitionsProvider>(context);

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
      themeMode: definitions.themeState,
      theme: ThemeData.from(colorScheme: lightTheme),
      darkTheme: ThemeData.from(colorScheme: darkTheme),
      home: HomePage(bdPath: definitions.dbPath),
    );
  }
}

