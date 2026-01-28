import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/xml.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

void main() {
  runApp(const ProEditorApp());
}

class ProEditorApp extends StatelessWidget {
  const ProEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OLED Pro',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
      ),
      home: const EditorHome(),
    );
  }
}

class EditorHome extends StatefulWidget {
  const EditorHome({super.key});

  @override
  State<EditorHome> createState() => _EditorHomeState();
}

class _EditorHomeState extends State<EditorHome> {
  late CodeController _codeCtrl;
  late WebViewController _webCtrl;
  final TextEditingController _searchCtrl = TextEditingController();

  bool _showPreview = false;
  bool _showSearchBar = false;
  String _currentFileName = "index.html";
  List<FileSystemEntity> _files = [];

  // Theme Colors
  final Color _accentColor = const Color(0xFF00FF9D);
  final Color _bgDark = const Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _codeCtrl = CodeController(
      text:
          "\n<h1>Hello World</h1>\n<script>\n  console.log('Ready');\n</script>",
      language: xml,
      theme: monokaiSublimeTheme,
    );
    _initWebView();
    _refreshFileList();
  }

  void _initWebView() {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_codeCtrl.text);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;
    final text = _codeCtrl.text;
    final index = text.indexOf(query, _codeCtrl.selection.end);

    if (index != -1) {
      _codeCtrl.selection =
          TextSelection(baseOffset: index, extentOffset: index + query.length);
    } else {
      final resetIndex = text.indexOf(query);
      if (resetIndex != -1) {
        _codeCtrl.selection = TextSelection(
            baseOffset: resetIndex, extentOffset: resetIndex + query.length);
      }
    }
  }

  Future<void> _refreshFileList() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() {
      _files = dir.listSync().where((e) => e.path.endsWith('.html')).toList();
    });
  }

  Future<void> _saveInternal() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_currentFileName');
    await file.writeAsString(_codeCtrl.text);
    _refreshFileList();
  }

  Future<void> _exportAsHtml() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_currentFileName');
    await file.writeAsString(_codeCtrl.text);
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles([XFile(file.path)],
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withOpacity(0.5)),
          ),
        ),
        title: Text(_currentFileName,
            style:
                GoogleFonts.jetbrainsMono(color: _accentColor, fontSize: 14)),
        centerTitle: true,
        leading: Builder(
            builder: (c) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                  onPressed: () => Scaffold.of(c).openDrawer(),
                )),
        actions: [
          IconButton(
            icon: Icon(_showSearchBar ? Icons.close : Icons.search,
                color: Colors.white70),
            onPressed: () => setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) _searchCtrl.clear();
            }),
          ),
          IconButton(
            icon: Icon(_showPreview ? Icons.code : Icons.play_circle_filled,
                color: _showPreview ? Colors.white : _accentColor),
            onPressed: () {
              if (!_showPreview) _webCtrl.loadHtmlString(_codeCtrl.text);
              setState(() => _showPreview = !_showPreview);
            },
          ),
        ],
      ),
      drawer: _buildModernDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            if (_showSearchBar)
              Container(
                color: const Color(0xFF252526),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Find in file...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onSubmitted: _performSearch,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_downward,
                          color: Colors.white, size: 20),
                      onPressed: () => _performSearch(_searchCtrl.text),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _showPreview
                  ? WebViewWidget(controller: _webCtrl)
                  : CodeTheme(
                      data: CodeThemeData(styles: monokaiSublimeTheme),
                      child: SingleChildScrollView(
                        child: CodeField(
                          controller: _codeCtrl,
                          textStyle: GoogleFonts.jetbrainsMono(
                              fontSize: 14, height: 1.5),
                          gutterStyle: const GutterStyle(
                            textStyle:
                                TextStyle(color: Colors.grey, fontSize: 12),
                            width: 50,
                            margin: 0,
                            showLineNumbers: true,
                          ),
                          onChanged: (v) => _saveInternal(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernDrawer() {
    return Drawer(
      backgroundColor: _bgDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_bgDark, const Color(0xFF1E1E1E)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.terminal, color: _accentColor, size: 40),
                const SizedBox(height: 10),
                Text("OLED EDITOR",
                    style: GoogleFonts.jetbrainsMono(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text("v1.0 • Pro Build",
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ..._files.map((f) {
                  final name = f.uri.pathSegments.last;
                  return ListTile(
                    dense: true,
                    leading: Icon(Icons.html,
                        color: name == _currentFileName
                            ? _accentColor
                            : Colors.grey),
                    title: Text(name,
                        style: TextStyle(
                            color: name == _currentFileName
                                ? Colors.white
                                : Colors.grey)),
                    onTap: () async {
                      _codeCtrl.text = await (f as File).readAsString();
                      setState(() => _currentFileName = name);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.ios_share, color: Colors.blueAccent),
            title: const Text("Export Project",
                style: TextStyle(color: Colors.white)),
            onTap: _exportAsHtml,
          ),
        ],
      ),
    );
  }
}
