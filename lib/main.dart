import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ModernOLEDApp());
}

class ModernOLEDApp extends StatelessWidget {
  const ModernOLEDApp({super.key});

  @override
  Widget build(BuildContext context) {
    // OLED Immersion
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OLED IDE',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FF9D), // Neo Green
          secondary: Color(0xFF2979FF), // Neo Blue
          surface: Color(0xFF111111),
        ),
        appBarTheme:
            const AppBarTheme(backgroundColor: Colors.black, elevation: 0),
        drawerTheme: const DrawerThemeData(backgroundColor: Color(0xFF111111)),
      ),
      home: const IDEHome(),
    );
  }
}

class IDEHome extends StatefulWidget {
  const IDEHome({super.key});

  @override
  State<IDEHome> createState() => _IDEHomeState();
}

class _IDEHomeState extends State<IDEHome> {
  final TextEditingController _codeCtrl = TextEditingController();
  late WebViewController _webCtrl;

  // State
  bool _showPreview = false;
  String _currentFileName = "untitled.html";
  List<FileSystemEntity> _files = [];
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _codeCtrl.text = "\n<h1>Hello World</h1>";
    _initWebView();
    _refreshFileList();
  }

  void _initWebView() {
    _webCtrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadHtmlString(_codeCtrl.text);
  }

  // --- FILE SYSTEM LOGIC ---

  Future<void> _refreshFileList() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() {
      _files = dir
          .listSync()
          .where((e) =>
              e.path.endsWith('.html') ||
              e.path.endsWith('.js') ||
              e.path.endsWith('.css'))
          .toList();
    });
  }

  Future<void> _saveInternal() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$_currentFileName');
    await file.writeAsString(_codeCtrl.text);
    _refreshFileList();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Saved $_currentFileName"),
        duration: const Duration(milliseconds: 800)));
  }

  Future<void> _createNew() async {
    TextEditingController nameCtrl = TextEditingController();
    await showDialog(
        context: context,
        builder: (c) => AlertDialog(
              backgroundColor: const Color(0xFF222222),
              title: const Text("New File Name",
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      hintText: "index.html",
                      hintStyle: TextStyle(color: Colors.grey))),
              actions: [
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(c)),
                TextButton(
                    child: const Text("Create"),
                    onPressed: () {
                      if (nameCtrl.text.isNotEmpty) {
                        setState(() {
                          _currentFileName = nameCtrl.text;
                          _codeCtrl.clear();
                          _saveInternal();
                        });
                        Navigator.pop(c);
                      }
                    }),
              ],
            ));
  }

  Future<void> _importFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['html', 'css', 'js', 'txt'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      setState(() {
        _currentFileName = result.files.single.name;
        _codeCtrl.text = content;
        _saveInternal(); // Save copy to internal storage
      });
    }
  }

  Future<void> _exportFile() async {
    // Save current state first
    await _saveInternal();
    final dir = await getApplicationDocumentsDirectory();
    final box = context.findRenderObject() as RenderBox?;

    // Share the file
    await Share.shareXFiles(
      [XFile('${dir.path}/$_currentFileName')],
      text: 'Exported from OLED IDE',
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  Future<void> _loadFile(FileSystemEntity file) async {
    if (file is File) {
      String content = await file.readAsString();
      setState(() {
        _currentFileName = file.uri.pathSegments.last;
        _codeCtrl.text = content;
      });
      Navigator.pop(context); // Close Drawer
    }
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    await file.delete();
    _refreshFileList();
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern App Bar
      appBar: AppBar(
        leading: Builder(
            builder: (c) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(c).openDrawer())),
        title: Text(_currentFileName,
            style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontFamily: 'Courier')),
        centerTitle: true,
        actions: [
          IconButton(
              icon: Icon(_showPreview ? Icons.code : Icons.play_arrow_rounded,
                  color: _showPreview ? Colors.grey : Colors.greenAccent),
              onPressed: () {
                if (!_showPreview)
                  _webCtrl.loadHtmlString(_codeCtrl.text); // Reload on play
                setState(() => _showPreview = !_showPreview);
              }),
          IconButton(
              icon: const Icon(Icons.ios_share, color: Colors.blueAccent),
              onPressed: _exportFile),
        ],
      ),

      // File Manager Drawer
      drawer: Drawer(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              color: Colors.black,
              width: double.infinity,
              child: Column(children: [
                const Icon(Icons.folder_open,
                    size: 40, color: Colors.greenAccent),
                const SizedBox(height: 10),
                const Text("WORKSPACE",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text("${_files.length} Files",
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ]),
            ),
            ListTile(
                leading:
                    const Icon(Icons.add_circle, color: Colors.greenAccent),
                title: const Text("New File"),
                onTap: _createNew),
            ListTile(
                leading:
                    const Icon(Icons.cloud_download, color: Colors.blueAccent),
                title: const Text("Import File"),
                onTap: _importFile),
            const Divider(color: Colors.grey),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  String name = _files[index].uri.pathSegments.last;
                  return ListTile(
                    leading: const Icon(Icons.description,
                        color: Colors.white54, size: 20),
                    title:
                        Text(name, style: const TextStyle(color: Colors.white)),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _deleteFile(_files[index])),
                    onTap: () => _loadFile(_files[index]),
                    selected: name == _currentFileName,
                    selectedTileColor: Colors.white10,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text("OLED IDE v2.0",
                  style: TextStyle(color: Colors.grey[800], fontSize: 10)),
            )
          ],
        ),
      ),

      // Main Body
      body: _showPreview
          ? WebViewWidget(controller: _webCtrl)
          : Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _codeCtrl,
                maxLines: null,
                expands: true,
                style: TextStyle(
                    fontFamily: 'Courier',
                    color: const Color(0xFFE0E0E0),
                    fontSize: _fontSize,
                    height: 1.4),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (v) => _saveInternal(), // Auto-save on type
              ),
            ),

      // Floating Tools
      floatingActionButton: !_showPreview
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.small(
                  backgroundColor: const Color(0xFF222222),
                  child: const Icon(Icons.remove, color: Colors.white),
                  onPressed: () => setState(
                      () => _fontSize = (_fontSize - 1).clamp(10.0, 30.0)),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  backgroundColor: const Color(0xFF222222),
                  child: const Icon(Icons.add, color: Colors.white),
                  onPressed: () => setState(
                      () => _fontSize = (_fontSize + 1).clamp(10.0, 30.0)),
                ),
              ],
            )
          : null,
    );
  }
}
