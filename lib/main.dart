import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const OLEDEditorApp());
}

class OLEDEditorApp extends StatelessWidget {
  const OLEDEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Hide status bar for full OLED immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OLED Editor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const EditorScreen(),
    );
  }
}

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final TextEditingController _codeController = TextEditingController();
  late final WebViewController _webViewController;
  bool _isSplitView = false;
  double _fontSize = 14.0;

  // Initial Template
  final String _initialCode = '''<!DOCTYPE html>
<html>
<head>
<style>
  body { background-color: #000; color: #00ff9d; font-family: monospace; padding: 20px; }
  h1 { text-align: center; border-bottom: 1px solid #333; padding-bottom: 10px; }
</style>
</head>
<body>
  <h1>OLED Preview</h1>
  <p>Edit the code above to see changes instantly!</p>
</body>
</html>''';

  @override
  void initState() {
    super.initState();
    _codeController.text = _initialCode;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_initialCode);
  }

  void _updatePreview() {
    _webViewController.loadHtmlString(_codeController.text);
  }

  void _insertText(String text) {
    final textSelection = _codeController.selection;
    if (textSelection.isValid) {
      final newText = _codeController.text.replaceRange(
        textSelection.start,
        textSelection.end,
        text,
      );
      _codeController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: textSelection.start + text.length,
        ),
      );
    } else {
      _codeController.text += text;
    }
    _updatePreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "OLED Editor",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          // RUN BUTTON
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
            onPressed: _updatePreview,
          ),
          // SPLIT VIEW TOGGLE
          IconButton(
            icon: Icon(_isSplitView ? Icons.view_agenda : Icons.splitscreen),
            onPressed: () => setState(() => _isSplitView = !_isSplitView),
          ),
          // SETTINGS MENU
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            color: Colors.grey[900],
            onSelected: (value) {
              if (value == 'zoom_in') setState(() => _fontSize += 2);
              if (value == 'zoom_out') setState(() => _fontSize -= 2);
              if (value == 'clear') _codeController.clear();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'zoom_in', child: Text('Zoom In (+)')),
              const PopupMenuItem(
                value: 'zoom_out',
                child: Text('Zoom Out (-)'),
              ),
              const PopupMenuItem(value: 'clear', child: Text('Clear Code')),
            ],
          ),
        ],
      ),
      drawer: _buildSidebar(),
      body: _isSplitView ? _buildSplitView() : _buildTabView(),
    );
  }

  // --- LAYOUTS ---

  Widget _buildTabView() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.greenAccent,
            tabs: [
              Tab(icon: Icon(Icons.code), text: "EDITOR"),
              Tab(icon: Icon(Icons.preview), text: "PREVIEW"),
            ],
          ),
          Expanded(
            child: TabBarView(children: [_buildCodeEditor(), _buildPreview()]),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitView() {
    return Column(
      children: [
        Expanded(flex: 1, child: _buildCodeEditor()),
        Container(height: 1, color: Colors.greenAccent),
        Expanded(flex: 1, child: _buildPreview()),
      ],
    );
  }

  // --- WIDGETS ---

  Widget _buildCodeEditor() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: _codeController,
        maxLines: null,
        expands: true,
        style: TextStyle(
          fontFamily: 'Courier',
          color: const Color(0xFFe0e0e0),
          fontSize: _fontSize,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "Type HTML here...",
          hintStyle: TextStyle(color: Colors.grey),
        ),
        onChanged: (_) => {}, // Optional: Add auto-save logic here
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: Colors.black,
      child: WebViewWidget(controller: _webViewController),
    );
  }

  Widget _buildSidebar() {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.black),
            child: Center(
              child: Text(
                "TOOLS",
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
          ),
          _sidebarItem(
            Icons.code,
            "Insert HTML5 Boilerplate",
            () => _insertText(
              "<!DOCTYPE html>\n<html>\n<body>\n</body>\n</html>",
            ),
          ),
          _sidebarItem(
            Icons.palette,
            "Insert CSS Block",
            () =>
                _insertText("<style>\n  body { background: #000; }\n</style>"),
          ),
          _sidebarItem(
            Icons.javascript,
            "Insert JS Block",
            () => _insertText("<script>\n  console.log('Hi');\n</script>"),
          ),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.greenAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }
}
