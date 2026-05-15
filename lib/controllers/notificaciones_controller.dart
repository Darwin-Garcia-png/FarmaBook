import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../services/api_service.dart';
import '../services/notification_overlay_service.dart';
import '../controllers/dashboard_controller.dart';
import '../controllers/lotes_controller.dart';
import '../router/app_router.dart';

class NotificacionesController extends ChangeNotifier {
  WebSocketChannel? _channel;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, dynamic>> notificaciones = [];
  int unreadCount = 0;
  bool isLoading = true;
  String? error;

  bool isPushEnabled = true;
  Timer? _persistenceTimer;

  // Track already-alerted notifications to prevent duplicates
  final Set<String> _alertedIds = {};
  final Set<String> _readIds = {};
  final Set<String> _contentKeys = {};

  NotificacionesController() {
    _initAudio();
    _startPersistenceTimer();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Error inicializando AudioPlayer: $e');
    }
  }

  void _startPersistenceTimer() {
    _persistenceTimer?.cancel();
  }

  void togglePush(bool value) {
    isPushEnabled = value;
    notifyListeners();
  }

  Future<void> init() async {
    isLoading = true;
    error = null;
    notifyListeners();
    await _connect();
  }

  Future<void> _connect() async {
    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) {
        error = 'Token no disponible';
        isLoading = false;
        notifyListeners();
        return;
      }

      final baseUrl = AppConstants.baseUrl;
      final wsUrl = baseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      final uri = Uri.parse('$wsUrl/notifications?token=$token');

      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);

            if (data['tipo'] == 'historial') {
              final payload = data['payload'] as List;
              notificaciones = payload.cast<Map<String, dynamic>>();
              isLoading = false;

              // Rebuild content keys and read tracking
              _alertedIds.clear();
              _contentKeys.clear();
              for (var n in notificaciones) {
                final id = (n['notificacionId'] ?? n['id'] ?? '').toString();
                if (id.isNotEmpty) _alertedIds.add(id);
                _contentKeys.add(_notificationContentKey(n));
              }
              unreadCount = notificaciones.where((n) => !_readIds.contains(
                  (n['notificacionId'] ?? n['id'] ?? '').toString())).length;

              // Alert only the 3 most recent, but only if not yet alerted
              final recent = notificaciones.take(3).toList();
              for (var n in recent) {
                final id = (n['notificacionId'] ?? n['id'] ?? '').toString();
                if (!_alertedIds.contains(id)) {
                  _alertedIds.add(id);
                  if (isPushEnabled) _triggerAlert(n);
                }
              }

              notifyListeners();
            } else if (data['tipo'] == 'stock_bajo' || data['tipo'] == 'vencimiento') {
              final notification = data['payload'] as Map<String, dynamic>;
              final notifId = (notification['notificacionId'] ?? notification['id'] ?? '').toString();

              // Prevent duplicate alerts by ID
              if (_alertedIds.contains(notifId)) return;

              // Prevent duplicates by content (same product + same type)
              final contentKey = _notificationContentKey(notification);
              if (_contentKeys.contains(contentKey)) return;

              notificaciones.insert(0, notification);
              _contentKeys.add(contentKey);
              if (notifId.isNotEmpty) _alertedIds.add(notifId);
              if (!_readIds.contains(notifId)) unreadCount++;

              if (isPushEnabled) {
                _triggerAlert(notification);
              }

              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error decodificando socket de notificaciones: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket de Notificaciones cerrado. Reintentando...');
          Future.delayed(const Duration(seconds: 5), () => _connect());
        },
        onError: (e) {
          debugPrint('Error en WebSocket de Notificaciones: $e');
          error = 'Error de conexión';
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  void _triggerAlert(Map<String, dynamic> notification) async {
    final tipo = notification['tipo'] ?? 'aviso';
    final mensaje = notification['mensaje'] ?? 'Tienes una nueva notificación';
    final isUrgent = tipo == 'stock_bajo';

    final innerPayload = notification['payload'] as Map<String, dynamic>? ?? {};
    final loteId = innerPayload['loteId']?.toString();
    final nombreLote = innerPayload['nombreLote']?.toString();
    final productoId = innerPayload['productoId']?.toString();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/hey_listen.mp3'));
    } catch (e) {
      debugPrint('Error al reproducir sonido: $e');
    }

    NotificationOverlayService().showNotification(
      isUrgent ? '¡ALERTA DE STOCK!' : 'AVISO DE VENCIMIENTO',
      mensaje,
      isUrgent: isUrgent,
      onTap: () {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        final dashCtrl = Provider.of<DashboardController>(context, listen: false);

        if (loteId != null || nombreLote != null) {
          final lotesCtrl = Provider.of<LotesController>(context, listen: false);
          if (nombreLote != null) {
            lotesCtrl.setExternalSearch(nombreLote);
          }
          dashCtrl.onItemTapped(3);
        } else if (productoId != null) {
          dashCtrl.onItemTapped(1);
        } else {
          dashCtrl.onItemTapped(isUrgent ? 3 : 3);
        }
      },
    );
  }

  String _notificationContentKey(Map<String, dynamic> n) {
    final tipo = n['tipo'] ?? '';
    final payload = n['payload'] as Map<String, dynamic>? ?? {};
    final productoId = payload['productoId']?.toString() ?? '';
    final loteId = payload['loteId']?.toString() ?? '';
    final nombreLote = payload['nombreLote']?.toString() ?? n['nombreLote']?.toString() ?? '';
    return '$tipo|$productoId|$loteId|$nombreLote';
  }

  void markAsRead(String id) {
    _readIds.add(id);
    unreadCount = notificaciones
        .where((n) => !_readIds.contains(
            (n['notificacionId'] ?? n['id'] ?? '').toString()))
        .length;
    notifyListeners();
  }

  void markAllAsRead() {
    for (var n in notificaciones) {
      final id = (n['notificacionId'] ?? n['id'] ?? '').toString();
      if (id.isNotEmpty) _readIds.add(id);
    }
    unreadCount = 0;
    notifyListeners();
  }

  void deleteNotification(String id) {
    notificaciones.removeWhere(
        (n) => (n['notificacionId'] ?? n['id'] ?? '').toString() == id);
    _readIds.remove(id);
    _alertedIds.remove(id);
    // Recalcular content keys
    _contentKeys.clear();
    for (var n in notificaciones) {
      _contentKeys.add(_notificationContentKey(n));
    }
    unreadCount = notificaciones
        .where((n) => !_readIds.contains(
            (n['notificacionId'] ?? n['id'] ?? '').toString()))
        .length;
    notifyListeners();
  }

  bool isRead(Map<String, dynamic> n) {
    final id = (n['notificacionId'] ?? n['id'] ?? '').toString();
    return _readIds.contains(id);
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _audioPlayer.dispose();
    _persistenceTimer?.cancel();
    super.dispose();
  }
}
