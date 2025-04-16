import 'dart:io';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../services/chatgpt_service.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({Key? key}) : super(key: key);

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  late SharedPreferences _prefs;

  bool _isListening = false;
  String _recognizedText = '';
  String _responseText = '';
  String _language = 'en_IN';
  List<String> _history = [];

  final Map<String, String> _langs = {
    'English': 'en_IN',
    'Hindi': 'hi_IN',
    'Marathi': 'mr_IN',
  };

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _prefs = await SharedPreferences.getInstance();
    setState(() {});
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool avail = await _speech.initialize(
        onStatus: (s) {
          if (s == 'done') setState(() => _isListening = false);
        },
        onError: (e) => print('Speech error: $e'),
      );
      if (!avail) return;
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _responseText = '';
      });
      _speech.listen(
        onResult: (r) => setState(() => _recognizedText = r.recognizedWords),
        localeId: _language,
      );
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
      _processCommand(_recognizedText.trim());
    }
  }

  Future<void> _processCommand(String cmd) async {
    if (cmd.isEmpty) return;
    // save to history
    _history.insert(0, cmd);
    if (_history.length > 50) _history.removeLast();
    await _prefs.setStringList('voice_history', _history);

    setState(() => _responseText = 'Processing…');

    if (cmd.toLowerCase().startsWith('where is my')) {
      String name = cmd.substring(11).trim();
      await _showReportPicker(name);
    } else {
      String? reply = await ChatGPTService.sendMessage(cmd);
      _responseText = reply ?? 'Sorry, no response.';
      await _tts.speak(_responseText);
      setState(() {});
    }
  }

  Future<void> _showReportPicker(String query) async {
    final docs = await getApplicationDocumentsDirectory();
    final files = docs.listSync(recursive: true).whereType<File>();
    final matches = files
        .where((f) => p.basename(f.path).toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (matches.isEmpty) {
      _responseText = 'No report found named "$query".';
      await _tts.speak(_responseText);
      setState(() {});
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Found ${matches.length} report(s)'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: matches.length,
            itemBuilder: (_, i) {
              final file = matches[i];
              final name = p.basename(file.path);
              return ListTile(
                title: Text(name),
                trailing: PopupMenuButton<String>(
                  onSelected: (opt) => _handleFileOption(opt, file),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'preview', child: Text('Preview')),
                    const PopupMenuItem(value: 'download', child: Text('Download')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _handleFileOption(String opt, File file) async {
    switch (opt) {
      case 'preview':
        OpenFile.open(file.path);
        break;
      case 'download':
        final dl = Directory('/storage/emulated/0/Download');
        final dest = File('${dl.path}/${p.basename(file.path)}');
        try {
          await file.copy(dest.path);
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Saved to Downloads')));
        } catch (e) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Download failed: $e')));
        }
        break;
      case 'share':
        await Share.shareFiles([file.path], text: 'Here is your report');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Text(
                'Voice Health Assistant',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _language,
                dropdownColor: Colors.white,
                iconEnabledColor: Colors.white,
                underline: Container(height: 1, color: Colors.white70),
                style: const TextStyle(color: Colors.white),
                items: _langs.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.value,
                    child: Text(e.key, style: const TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _language = v!),
              ),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _recognizedText.isEmpty ? 'Tap mic and speak…' : _recognizedText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                onPressed: _listen,
                backgroundColor: _isListening ? Colors.redAccent : Colors.white,
                child: Icon(
                  _isListening ? Icons.mic_off : Icons.mic,
                  color: _isListening ? Colors.white : Colors.blueAccent,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              if (_responseText.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _responseText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white70),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(_history[i]),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Share {
  static shareFiles(List<String> list, {required String text}) {}
}

class OpenFile {
  static void open(String path) {}
}

class Permission {
  static var microphone;

  static var storage;
}

class SharedPreferences {
  setStringList(String s, List<String> history) {}

  static getInstance() {}
}
