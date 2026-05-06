import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../services/api_service.dart';
import '../utils/app_constants.dart';

class MovimientosController extends ChangeNotifier {
  WebSocketChannel? _channel;
  List<Map<String, dynamic>> movimientos = [];
  bool isLoading = true;
  String? error;

  void init() async {
    isLoading = true;
    error = null;
    notifyListeners();
    await _connect();
  }

  Future<void> _connect() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        error = 'Error crítico: No tienes permisos para ver esto (Token nulo)';
        isLoading = false;
        notifyListeners();
        return;
      }

      final baseUrl = AppConstants.baseUrl;
      final wsUrl = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      final uri = Uri.parse('$wsUrl/movements?token=$token');
      
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            
            if (data['tipo'] == 'historial') {
              final payload = data['payload'] as List;
              movimientos = payload.cast<Map<String, dynamic>>();
              isLoading = false;
              notifyListeners();
            } else if (data['tipo'] == 'movimientos') {
              final payload = data['payload'] as Map<String, dynamic>;
              movimientos.insert(0, payload);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error decodificando socket de movimientos: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket de Movimientos cerrado naturalmente.');
        },
        onError: (e) {
          debugPrint('Error en WebSocket de Movimientos: $e');
          if (isLoading) {
             error = 'Error de conexión o el rol actual no tiene acceso de Dueño.';
             isLoading = false;
             notifyListeners();
          }
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
