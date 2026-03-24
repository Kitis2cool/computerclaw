import 'dart:convert';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  final List<ChatEntry> _messages = const [
    ChatEntry(role: 'assistant', text: 'Hey. I’m here. Talk to me when you’re ready.'),
  ].toList();

  // Swap this later if your address changes.
  final String _baseUrl = 'http://100.89.191.12:8787';

  SpeakState _speakState = SpeakState.idle;
  bool _transcriptVisible = true;
  bool _menuOpen = false;
  bool _speakReplies = true;
  String _statusText = 'Ready';

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatEntry(role: 'user', text: message));
      _controller.clear();
      _speakState = SpeakState.thinking;
      _statusText = 'Thinking...';
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/ask'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(data['error'] ?? 'Request failed');
      }

      final reply = (data['reply'] ?? 'No reply returned.').toString();

      setState(() {
        _messages.add(ChatEntry(role: 'assistant', text: reply));
        _speakState = _speakReplies ? SpeakState.speaking : SpeakState.idle;
        _statusText = _speakReplies ? 'Speaking...' : 'Ready';
      });
      _scrollToBottom();

      // Placeholder: real TTS later.
      if (_speakReplies) {
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
        setState(() {
          _speakState = SpeakState.idle;
          _statusText = 'Ready';
        });
      }
    } catch (error) {
      setState(() {
        _messages.add(ChatEntry(role: 'assistant', text: 'Error: $error'));
        _speakState = SpeakState.idle;
        _statusText = 'Error';
      });
      _scrollToBottom();
    }
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

  void _clearTranscript() {
    setState(() {
      _messages
        ..clear()
        ..add(const ChatEntry(role: 'assistant', text: 'Transcript cleared. Fresh slate.'));
      _menuOpen = false;
      _statusText = 'Ready';
      _speakState = SpeakState.idle;
    });
    _scrollToBottom();
  }

  void _stopTalking() {
    setState(() {
      _speakState = SpeakState.idle;
      _statusText = 'Ready';
    });
  }

  Color _speakColor() {
    switch (_speakState) {
      case SpeakState.idle:
        return const Color(0xFF5EEAD4);
      case SpeakState.listening:
        return const Color(0xFF5EEAD4);
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
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  _actionButton('Upload Image', Icons.image_outlined, null),
                  _actionButton('Stop Talking', Icons.stop_circle_outlined, _stopTalking),
                ],
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
                    onPressed: _sendMessage,
                    child: const Text('Send'),
                  ),
                  const SizedBox(width: 12),
                  Text(_statusText, style: const TextStyle(color: Color(0xFFAAB4D6))),
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
      onTap: () {
        setState(() {
          _speakState = SpeakState.listening;
          _statusText = 'Listening...';
        });
      },
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

  Widget _actionButton(String label, IconData icon, VoidCallback? onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
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
