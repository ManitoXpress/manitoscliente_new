import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import '../request/ResponseGet.dart';

class ConversationsProvider extends ChangeNotifier {
  final String serviceId;
  final ApiService2 apiService2;

  ConversationsProvider({
    required this.serviceId,
    required this.apiService2,
  });

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Estado del chat ────────────────────────────────────────────────────────
  String? conversationId;
  ConversationModel? currentConversation;

  // true desde el inicio → IndexedStack abre directo en spinner (índice 0)
  // sin pasar ni un frame por el estado "vacío" (índice 2).
  bool isLoadingChat = true;
  String? chatError;
  bool _initStarted = false; // guard contra doble inicialización

  // ── Mensajes en memoria ────────────────────────────────────────────────────
  List<MessageModel> _messages = [];
  List<MessageModel> get messages => _messages;

  Timer? _pollTimer;

  // ── Inicia el chat ─────────────────────────────────────────────────────────
  Future<void> initChat(String workerId) async {
    if (_initStarted) return;
    _initStarted = true;
    chatError = null;
    // isLoadingChat ya es true → no hace falta notificar aquí.

    try {
      final data = await apiService2.createConversation(serviceId, workerId);
      currentConversation = ConversationModel.fromMap(data['id'], data);
      conversationId = data['id'];

      // Carga mensajes en SILENCIO (notify:false).
      // El único notifyListeners() ocurre en el bloque finally, cuando
      // isLoadingChat ya es false y _messages ya está poblado.
      // Así IndexedStack hace UNA SOLA transición: spinner → mensajes.
      await _fetchMessages(notify: false);

      // Polling cada 3 s (aquí sí notifica si hay cambios nuevos)
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
        await _fetchMessages(notify: true);
      });
    } catch (e) {
      chatError = 'No se pudo iniciar el chat.\n\nDetalle: ${e.toString()}';
      debugPrint('Error initChat: $e');
      _initStarted = false; // permite reintentar
    } finally {
      // ← UN SOLO notifyListeners con el estado COMPLETO:
      //   isLoadingChat=false  +  _messages ya poblado (o vacío si no hay)
      isLoadingChat = false;
      notifyListeners();
    }
  }

  // ── Obtiene los mensajes desde el backend REST ─────────────────────────────
  // notify=false → durante initChat (evita el doble rebuild / parpadeo).
  // notify=true  → durante el polling (notifica solo si hay cambios reales).
  Future<void> _fetchMessages({bool notify = true}) async {
    if (conversationId == null) return;
    try {
      final rawList = await apiService2.getConversationMessages(conversationId!);
      final newMessages = rawList
          .map((m) => MessageModel.fromMap(m['id'] as String? ?? '', m))
          .toList();

      final lastOldId = _messages.isNotEmpty ? _messages.last.id : '';
      final lastNewId = newMessages.isNotEmpty ? newMessages.last.id : '';
      final changed =
          newMessages.length != _messages.length || lastOldId != lastNewId;

      if (changed) {
        _messages = newMessages;
        if (notify) notifyListeners();
      }
    } catch (e) {
      debugPrint('Error _fetchMessages: $e');
    }
  }

  // ── Enviar mensaje ─────────────────────────────────────────────────────────
  Future<void> sendMessage(String convId, String text) async {
    await apiService2.sendConversationMessage(convId, text);
    await _fetchMessages(notify: true);
  }

  // ── Marcar como leído ──────────────────────────────────────────────────────
  Future<void> markAsRead(String convId) async {
    try {
      await apiService2.markConversationAsRead(convId);
    } catch (e) {
      debugPrint('Error markAsRead: $e');
    }
  }

  // ── Limpieza ───────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
