import 'dart:io';

import 'package:editfy_pdf/colections/chat.dart';
import 'package:flutter/material.dart';
import 'package:pdfium_dart/pdfium_dart.dart';

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
    final hasDoc = File(widget.metadata.docPath).path.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        centerTitle: true,
        title: Text(widget.metadata.chatName),
      ),

      body: InteractiveViewer(
        panEnabled: true,
        child: hasDoc ? PdfView(path: widget.metadata.docPath) : Placeholder()
      )
    );
  }
}