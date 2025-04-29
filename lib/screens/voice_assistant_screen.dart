import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

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
  List<String> _history = [];
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _prefs = await SharedPreferences.getInstance();
    _history = _prefs.getStringList('voice_history') ?? [];
    setState(() {});
  }

  Future<void> _listen() async {
    if (!_isListening) {
      // initialize() will prompt for RECORD_AUDIO permission
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done') setState(() => _isListening = false);
        },
        onError: (err) => print('Speech error: $err'),
      );
      if (!available) {
        setState(() => _responseText = 'Speech recognition unavailable.');
        return;
      }
      setState(() {
        _isListening = true;
        _recognizedText = '';
        _responseText = '';
        _suggestions = [];
      });
      _speech.listen(onResult: (res) {
        setState(() => _recognizedText = res.recognizedWords);
      });
    } else {
      await _speech.stop();
      setState(() => _isListening = false);
      await _processCommand(_recognizedText.trim());
    }
  }

  Future<void> _processCommand(String cmd) async {
    if (cmd.isEmpty) return;

    // Save to history
    _history.insert(0, cmd);
    if (_history.length > 50) _history.removeLast();
    await _prefs.setStringList('voice_history', _history);

    setState(() {
      _responseText = 'Processing…';
      _suggestions = [];
    });

    // If user asked about “report … from …”
    if (RegExp(r'\breport\b.*\bfrom\b', caseSensitive: false).hasMatch(cmd)) {
      await _handleReportByDate();
      return;
    }

    // Otherwise forward to ChatGPT
    String? reply = await ChatGPTService.sendMessage(cmd);
    if (reply == null || reply.toLowerCase().contains('sorry')) {
      _responseText = 'I didn’t catch that. You could try:';
      _suggestions = [
        'Show my blood_test report',
        'Give me reports from March 1, 2025',
        'What is my last appointment?',
      ];
    } else {
      _responseText = reply;
    }
    await _tts.speak(_responseText);
    setState(() {});
  }

  Future<void> _handleReportByDate() async {
    // Ask for date
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked == null) {
      setState(() => _responseText = 'Okay, canceled.');
      return;
    }

    final docs = await getApplicationDocumentsDirectory();
    final files = docs
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
      final m = f.lastModifiedSync();
      return m.year == picked.year &&
          m.month == picked.month &&
          m.day == picked.day;
    })
        .toList();

    if (files.isEmpty) {
      _responseText =
      'No reports found from ${DateFormat.yMMMd().format(picked)}.';
      await _tts.speak(_responseText);
      setState(() {});
      return;
    }

    _responseText =
    'Found ${files.length} report(s) from ${DateFormat.yMMMd().format(picked)}.';
    await _tts.speak(_responseText);
    setState(() {});

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_responseText),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: files.length,
            itemBuilder: (_, i) {
              final file = files[i];
              final name = file.path.split(Platform.pathSeparator).last;
              final sizeKB =
              (file.lengthSync() / 1024).toStringAsFixed(1);
              return ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: Text(name),
                subtitle: Text('$sizeKB KB'),
                trailing: PopupMenuButton<String>(
                  onSelected: (opt) => _handleFileOption(opt, file),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'preview', child: Text('Preview')),
                    const PopupMenuItem(
                        value: 'download', child: Text('Download')),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleFileOption(String opt, File file) async {
    switch (opt) {
      case 'preview':
        await OpenFile.open(file.path);
        break;
      case 'download':
      // Attempt to copy to Downloads; manifest must declare WRITE_EXTERNAL_STORAGE
        final dl = Directory('/storage/emulated/0/Download');
        final dest = File(
            '${dl.path}/${file.path.split(Platform.pathSeparator).last}');
        try {
          await file.copy(dest.path);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to Downloads')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download failed: $e')),
          );
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Voice Health Assistant')),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _recognizedText.isEmpty
                      ? 'Tap mic and speak…'
                      : _recognizedText,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                onPressed: _listen,
                backgroundColor:
                _isListening ? Colors.redAccent : Colors.white,
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
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_responseText,
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      if (_suggestions.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          children:
                          _suggestions.map((s) {
                            return ActionChip(
                              label: Text(s),
                              onPressed: () => _processCommand(s),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white70),
              Expanded(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color.fromRGBO(255, 255, 255, 0.7),
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24)),
                  ),
                  child: ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (_, i) {
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(_history[i]),
                      );
                    },
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
