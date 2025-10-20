//import 'package:editfy_pdf/main.dart';
import 'package:editfy_pdf/colections/chat.dart';
import 'package:flutter/material.dart';

//import 'package:pdfrx/pdfrx.dart';

class DocViewer extends StatefulWidget {
  final Chat metadata;
  const DocViewer({super.key, required this.metadata});

  @override
  State<DocViewer> createState() => _DocViewerState();
}

class _DocViewerState extends State<DocViewer> {
  @override
  Widget build(BuildContext context){
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
        title: Text(widget.metadata.chatName),
      ),

      body: InteractiveViewer(
        panEnabled: true,
        child: Placeholder(), /*PdfViewer.asset(
          widget.metadata.docPath,
          params: PdfViewerParams(
            enableTextSelection: true,
          ),
        ),*/
      )
    );
  }
}