import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class JarvisService {
  static const String _savedIpKey = 'jarvis_pc_ip';
  static const String _savedPortKey = 'jarvis_pc_port';

  String _pcIp = '192.168.1.100';
  int _port = 8000;
  bool _isConnected = false;

  JarvisService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _pcIp = prefs.getString(_savedIpKey) ?? '192.168.1.100';
    _port = prefs.getInt(_savedPortKey) ?? 8000;
  }

  Future<void> saveSettings(String ip, int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedIpKey, ip);
    await prefs.setInt(_savedPortKey, port);
    _pcIp = ip;
    _port = port;
  }

  String get baseUrl => 'http://$_pcIp:$_port';
  String get currentIp => _pcIp;
  int get currentPort => _port;
  bool get isConnected => _isConnected;

  Future<bool> checkConnection() async {
    try {
      final url = Uri.parse('$baseUrl/status');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      _isConnected = response.statusCode == 200;
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<Map<String, dynamic>> sendCommand(String command, {Map<String, dynamic>? params}) async {
    try {
      final url = Uri.parse('$baseUrl/execute');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'command': command,
          'parameters': params ?? {},
        }),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'error': 'HTTP ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Не удалось подключиться: $e'};
    }
  }

  Future<Map<String, dynamic>> getStatus() async {
    try {
      final url = Uri.parse('$baseUrl/status');
      final response = await http.get(url).timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      return {'error': 'Нет соединения'};
    }
    return {'error': 'Неизвестная ошибка'};
  }
}