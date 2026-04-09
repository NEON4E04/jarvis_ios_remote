import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/jarvis_service.dart';
import '../models/ring_settings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late JarvisService _jarvisService;
  late stt.SpeechToText _speech;

  bool _isConnected = false;
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastCommand = '';
  RingSettings _ringSettings = RingSettings();

  final TextEditingController _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadRingSettings();
  }

  Future<void> _initializeServices() async {
    _jarvisService = JarvisService();
    _speech = stt.SpeechToText();

    await _speech.initialize(
      onStatus: (status) {
        setState(() {
          _isListening = status == 'listening';
        });
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
      },
    );

    await _checkConnection();
    Future.delayed(const Duration(seconds: 5), _periodicCheck);
  }

  Future<void> _loadRingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ringSettings = RingSettings(
        ringCount: prefs.getInt('ring_count') ?? 3,
        ringThickness: prefs.getDouble('ring_thickness') ?? 3.0,
        ringSpacing: prefs.getDouble('ring_spacing') ?? 20.0,
      );
    });
  }

  void _periodicCheck() {
    if (mounted) {
      _checkConnection();
      Future.delayed(const Duration(seconds: 5), _periodicCheck);
    }
  }

  Future<void> _checkConnection() async {
    final connected = await _jarvisService.checkConnection();
    if (mounted && _isConnected != connected) {
      setState(() {
        _isConnected = connected;
      });

      if (connected) {
        HapticFeedback.lightImpact();
      }
    }
  }

  Future<void> _startVoiceInput() async {
    bool available = await _speech.initialize();

    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          setState(() {
            _isListening = false;
            _lastCommand = result.recognizedWords;
          });

          if (result.recognizedWords.isNotEmpty) {
            _sendCommand(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 5),
        pauseFor: const Duration(seconds: 2),
        partialResults: true,
        localeId: 'ru_RU',
      );
    } else {
      _showMessage('Голосовой ввод не доступен', isError: true);
    }
  }

  Future<void> _sendCommand(String command) async {
    if (!_isConnected) {
      _showMessage('Нет подключения к ПК', isError: true);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final result = await _jarvisService.sendCommand(command);

    setState(() {
      _isProcessing = false;
    });

    if (result.containsKey('error')) {
      _showMessage('❌ ${result['error']}', isError: true);
    } else {
      _showMessage('✅ Команда выполнена');
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showConnectionSettings() {
    final ipController = TextEditingController(text: _jarvisService.currentIp);
    final portController = TextEditingController(text: _jarvisService.currentPort.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Настройки подключения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              decoration: const InputDecoration(
                labelText: 'IP адрес ПК',
                hintText: '192.168.1.100',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: portController,
              decoration: const InputDecoration(
                labelText: 'Порт',
                hintText: '8000',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 8000;
              await _jarvisService.saveSettings(ip, port);
              await _checkConnection();
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('JARVIS Remote', style: TextStyle(color: Colors.cyan)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Анимированная сфера
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.cyan.withOpacity(0.3),
                      Colors.purple.withOpacity(0.2),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: _isListening ? 200 : 150,
                    height: _isListening ? 200 : 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Colors.cyan,
                          Colors.blue,
                          Colors.purple,
                        ],
                        stops: [0.3, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyan.withOpacity(0.5),
                          blurRadius: _isListening ? 30 : 20,
                          spreadRadius: _isListening ? 10 : 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : _isListening
                              ? const Icon(Icons.mic, size: 50, color: Colors.white)
                              : const Icon(Icons.mic_none, size: 40, color: Colors.white70),
                    ),
                  ),
                ),
              ),
            ),

            // Панель управления
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (_lastCommand.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.cyan.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '🎤 "$_lastCommand"',
                        style: const TextStyle(color: Colors.cyan, fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isConnected ? _startVoiceInput : null,
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none, size: 30),
                      label: Text(
                        _isListening ? 'Слушаю...' : 'Сказать команду',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isListening ? Colors.red : Colors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Или введите команду...',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            enabled: _isConnected,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey[800]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: Colors.grey[800]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: Colors.cyan),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) {
                            if (_commandController.text.isNotEmpty) {
                              _sendCommand(_commandController.text);
                              _commandController.clear();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Colors.cyan,
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _isConnected ? () {
                            if (_commandController.text.isNotEmpty) {
                              _sendCommand(_commandController.text);
                              _commandController.clear();
                            }
                          } : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Быстрые команды
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Быстрые команды', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickCommand('🎤 Активировать', 'wake'),
                      _buildQuickCommand('💤 Спать', 'sleep'),
                      _buildQuickCommand('🔊 Громче', 'volume_up'),
                      _buildQuickCommand('🔉 Тише', 'volume_down'),
                      _buildQuickCommand('⏯ Play/Pause', 'media_play_pause'),
                      _buildQuickCommand('⏭ Следующий', 'media_next'),
                      _buildQuickCommand('⏮ Предыдущий', 'media_previous'),
                      _buildQuickCommand('🌐 YouTube', 'open_site'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showConnectionSettings,
        backgroundColor: Colors.cyan,
        child: const Icon(Icons.settings),
      ),
    );
  }

  Widget _buildQuickCommand(String label, String command) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: _isConnected ? () => _sendCommand(command) : null,
      backgroundColor: Colors.grey[800],
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _speech.stop();
    super.dispose();
  }
}