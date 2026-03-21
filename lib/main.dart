import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

void main() {
  runApp(const ComputerClawApp());
}

class ComputerClawApp extends StatelessWidget {
  const ComputerClawApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ComputerClaw',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C9CFF),
          secondary: Color(0xFF5EEAD4),
          surface: Color(0xFF121930),
        ),
        useMaterial3: true,
      ),
      home: const KitisHomePage(),
    );
  }
}

class KitisHomePage extends StatefulWidget {
  const KitisHomePage({super.key});

  @override
  State<KitisHomePage> createState() => _KitisHomePageState();
}

enum SpeakState { idle, listening, thinking, speaking }

class ChatEntry {
  const ChatEntry({required this.role, required this.text});

  final String role;
  final String text;
}

class _KitisHomePageState extends State<KitisHomePage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  final ImagePicker _imagePicker = ImagePicker();

  final List<ChatEntry> _messages = <ChatEntry>[
    const ChatEntry(role: 'assistant', text: 'Hey. I’m here. Talk to me when you’re ready.'),
  ];

  final String _baseUrl = 'http://localhost:8787';

  SpeakState _speakState = SpeakState.idle;
  bool _transcriptVisible = true;
  bool _menuOpen = false;
  bool _speakReplies = true;
  bool _speechReady = false;
  bool _sending = false;
  bool _autoSendAfterSpeech = true;
  String _statusText = 'Ready';
  String _liveTranscript = '';
  String _draftText = '';
  XFile? _selectedImage;
  Timer? _autoSendTimer;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _statusText = 'Mic error: ${error.errorMsg}';
          _speakState = SpeakState.idle;
        });
      },
      onStatus: (status) {
        if (!mounted) return;
        if (status == 'listening') {
          setState(() {
            _speakState = SpeakState.listening;
            _statusText = 'Listening...';
          });
          return;
        }
        if (status == 'done' || status == 'notListening') {
          setState(() {
            _speakState = SpeakState.idle;
            _statusText = _liveTranscript.isEmpty ? 'Ready' : 'Transcript captured';
          });
          _maybeAutoSendSpeech();
          return;
        }
        setState(() {
          _statusText = 'Mic status: $status';
        });
      },
    );

    if (!mounted) return;
    setState(() {
      _speechReady = available;
      _statusText = available ? 'Ready' : 'Mic unavailable';
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.46);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      if (!mounted) return;
      setState(() {
        _speakState = SpeakState.speaking;
        _statusText = 'Speaking...';
      });
    });

    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _speakState = SpeakState.idle;
        _statusText = 'Ready';
      });
    });

    _tts.setErrorHandler((message) {
      if (!mounted) return;
      setState(() {
        _speakState = SpeakState.idle;
        _statusText = 'TTS error';
      });
    });
  }

  @override
  void dispose() {
    _autoSendTimer?.cancel();
    _speech.stop();
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_sending) return;

    if (_speech.isListening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() {
        _speakState = SpeakState.idle;
        _statusText = _liveTranscript.isEmpty ? 'Ready' : 'Transcript captured';
      });
      _maybeAutoSendSpeech();
      return;
    }

    if (!_speechReady) {
      await _initSpeech();
      if (!_speechReady) return;
    }

    setState(() {
      _liveTranscript = '';
      _speakState = SpeakState.listening;
      _statusText = 'Listening...';
    });

    await _speech.listen(
      onResult: _onSpeechResult,
      partialResults: true,
      cancelOnError: true,
      listenFor: const Duration(seconds: 20),
    );
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;
    setState(() {
      _liveTranscript = result.recognizedWords;
    });
  }

  void _maybeAutoSendSpeech() {
    _autoSendTimer?.cancel();
    if (!_autoSendAfterSpeech || _sending) return;

    final message = _liveTranscript.trim().isNotEmpty
        ? _liveTranscript.trim()
        : _controller.text.trim().isNotEmpty
            ? _controller.text.trim()
            : _draftText.trim();
    if (message.isEmpty) return;

    _autoSendTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _sending) return;
      final pending = _liveTranscript.trim().isNotEmpty
          ? _liveTranscript.trim()
          : _controller.text.trim().isNotEmpty
              ? _controller.text.trim()
              : _draftText.trim();
      if (pending.isEmpty) return;
      _sendMessage();
    });
  }

  Future<void> _sendMessage() async {
    _autoSendTimer?.cancel();
    final message = _controller.text.trim().isNotEmpty
        ? _controller.text.trim()
        : _liveTranscript.trim().isNotEmpty
            ? _liveTranscript.trim()
            : _draftText.trim();
    if (message.isEmpty || _sending) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _messages.add(ChatEntry(role: 'user', text: message));
      _controller.clear();
      _draftText = '';
      _liveTranscript = '';
      _speakState = SpeakState.thinking;
      _statusText = 'Thinking...';
    });
    _scrollToBottom();

    try {
      http.Response response;

      if (_selectedImage != null && !kIsWeb) {
        final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/ask'));
        request.fields['message'] = message;
        request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
        final streamed = await request.send();
        response = await http.Response.fromStream(streamed);
      } else {
        response = await http.post(
          Uri.parse('$_baseUrl/ask'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': message,
            if (_selectedImage != null) 'imageName': _selectedImage!.name,
          }),
        );
      }

      final dynamic decoded = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body);
      final Map<String, dynamic> data = decoded is Map<String, dynamic>
          ? decoded
          : <String, dynamic>{'reply': decoded.toString()};

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = data['detail']?.toString();
        final errorText = data['error']?.toString() ?? 'Request failed (${response.statusCode})';
        throw Exception(detail == null || detail.isEmpty ? errorText : '$errorText — $detail');
      }

      final reply = (data['reply'] ?? 'No reply returned.').toString();

      setState(() {
        _messages.add(ChatEntry(role: 'assistant', text: reply));
        _selectedImage = null;
        _statusText = _speakReplies ? 'Speaking...' : 'Ready';
        _speakState = _speakReplies ? SpeakState.speaking : SpeakState.idle;
      });
      _scrollToBottom();

      if (_speakReplies) {
        await _tts.stop();
        await _tts.speak(reply);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatEntry(role: 'assistant', text: 'Error: $error'));
        _statusText = 'Error';
        _speakState = SpeakState.idle;
      });
      _scrollToBottom();
    } finally {
      if (!mounted) return;
      setState(() {
        _sending = false;
        if (!_speakReplies) {
          _statusText = 'Ready';
          _speakState = SpeakState.idle;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null || !mounted) return;
      setState(() {
        _selectedImage = file;
        _statusText = 'Image ready';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _statusText = 'Image picker error';
      });
    }
  }

  Future<void> _stopTalking() async {
    await _speech.stop();
    await _tts.stop();
    if (!mounted) return;
    setState(() {
      _speakState = SpeakState.idle;
      _statusText = 'Ready';
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
    });
  }

  void _toggleTranscript() {
    setState(() {
      _transcriptVisible = !_transcriptVisible;
      _menuOpen = false;
    });
  }

  Future<void> _clearTranscript() async {
    await _stopTalking();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..add(const ChatEntry(role: 'assistant', text: 'Transcript cleared. Fresh slate.'));
      _selectedImage = null;
      _menuOpen = false;
      _liveTranscript = '';
    });
    _scrollToBottom();
  }

  Color _speakColor() {
    switch (_speakState) {
      case SpeakState.idle:
        return const Color(0xFF5EEAD4);
      case SpeakState.listening:
        return const Color(0xFF14B8A6);
      case SpeakState.thinking:
        return const Color(0xFFFACC15);
      case SpeakState.speaking:
        return const Color(0xFFEF4444);
    }
  }

  String _speakLabel() {
    switch (_speakState) {
      case SpeakState.idle:
        return 'SPEAK';
      case SpeakState.listening:
        return 'LISTENING';
      case SpeakState.thinking:
        return 'THINKING';
      case SpeakState.speaking:
        return 'SPEAKING';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _menuOpen = false),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _leftRail(),
                    const SizedBox(width: 12),
                    Expanded(child: _mainShell()),
                  ],
                ),
              ),
              if (_menuOpen) _menuOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leftRail() {
    return Container(
      width: 56,
      decoration: _panelDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          _railButton(Icons.menu, _toggleMenu),
          const SizedBox(height: 12),
          _railButton(Icons.backspace_outlined, _clearTranscript),
        ],
      ),
    );
  }

  Widget _mainShell() {
    return Column(
      children: [
        Container(
          decoration: _panelDecoration(),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          child: Column(
            children: const [
              Text(
                'ComputerClaw',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: Color(0xFFAAB4D6),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'KITIS',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Voice first. Transcript second.',
                style: TextStyle(color: Color(0xFFAAB4D6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: _panelDecoration(panel2: true),
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _statusPill(),
              const SizedBox(height: 18),
              _speakButton(),
              const SizedBox(height: 12),
              if (_liveTranscript.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _liveTranscript,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFAAB4D6)),
                  ),
                ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _actionButton('Upload Image', Icons.image_outlined, _pickImage),
                  _actionButton('Stop Talking', Icons.stop_circle_outlined, _stopTalking),
                ],
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Image ready: ${_selectedImage!.name}',
                    style: const TextStyle(color: Color(0xFFFDA4AF)),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: _speakReplies,
                    onChanged: (value) => setState(() => _speakReplies = value),
                  ),
                  const Text('Speak replies'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Switch(
                    value: _autoSendAfterSpeech,
                    onChanged: (value) => setState(() => _autoSendAfterSpeech = value),
                  ),
                  const Text('Auto-send after speech'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_transcriptVisible)
          Expanded(
            child: Container(
              decoration: _panelDecoration(),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRANSCRIPT',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 2,
                      color: Color(0xFFAAB4D6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.role == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            constraints: const BoxConstraints(maxWidth: 520),
                            decoration: BoxDecoration(
                              color: isUser ? const Color(0xFF1E3A8A) : const Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Text(message.text),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        Container(
          decoration: _panelDecoration(panel2: true),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                minLines: 2,
                maxLines: 4,
                onChanged: (value) => _draftText = value,
                decoration: InputDecoration(
                  hintText: 'Optional typed note...',
                  filled: true,
                  fillColor: const Color(0xFF08111A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    child: Text(_sending ? 'Sending...' : 'Send'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusText,
                      style: const TextStyle(color: Color(0xFFAAB4D6)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menuOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _menuOpen = false),
        child: Container(
          color: Colors.black.withOpacity(0.35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Center(
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 260,
                  decoration: _panelDecoration(),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _menuButton('Show / Hide Transcript', _toggleTranscript),
                      const SizedBox(height: 8),
                      _menuButton('Clear Transcript', _clearTranscript),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(_statusText, style: const TextStyle(color: Color(0xFFAAB4D6))),
    );
  }

  Widget _speakButton() {
    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _speakColor(),
          boxShadow: [
            BoxShadow(
              color: _speakColor().withOpacity(0.30),
              blurRadius: 32,
              spreadRadius: 6,
            ),
          ],
        ),
        child: Center(
          child: Text(
            _speakLabel(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _speakState == SpeakState.thinking ? const Color(0xFF1F1300) : Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Future<void> Function()? onTap) {
    return OutlinedButton.icon(
      onPressed: onTap == null ? null : () => onTap(),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        backgroundColor: label == 'Upload Image'
            ? const Color(0xFFFB7185).withOpacity(0.18)
            : Colors.white.withOpacity(0.04),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _railButton(IconData icon, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        backgroundColor: Colors.white.withOpacity(0.04),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Icon(icon, color: Colors.white),
    );
  }

  Widget _menuButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          alignment: Alignment.centerLeft,
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
          backgroundColor: Colors.white.withOpacity(0.04),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label),
      ),
    );
  }

  BoxDecoration _panelDecoration({bool panel2 = false}) {
    return BoxDecoration(
      color: panel2 ? const Color(0xE61B2647) : const Color(0xD1121930),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ],
    );
  }
}
