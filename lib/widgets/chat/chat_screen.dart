import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/message_model.dart';
import '../../provider/conversations_provider.dart';
import '../../request/ResponseGet.dart';

/// Pantalla completa de chat con el trabajador.
/// Reemplaza al bottom sheet para evitar conflictos de overlay y parpadeo.
class ChatFullScreen extends StatefulWidget {
  final String workerId;
  final String serviceId;
  final String workerName;

  const ChatFullScreen({
    Key? key,
    required this.workerId,
    required this.serviceId,
    required this.workerName,
  }) : super(key: key);

  @override
  State<ChatFullScreen> createState() => _ChatFullScreenState();
}

class _ChatFullScreenState extends State<ChatFullScreen> {
  late final ConversationsProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConversationsProvider(
      serviceId: widget.serviceId,
      apiService2: ApiService2(),
    );
    // Inicia el chat justo después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _provider.initChat(widget.workerId).then((_) {
        if (!mounted) return;
        if (_provider.conversationId != null) {
          _provider.markAsRead(_provider.conversationId!);
        }
      });
    });
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ConversationsProvider>.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A819A),
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mensajes al Trabajador',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                widget.workerName.isNotEmpty
                    ? widget.workerName
                    : 'Respuestas usualmente en minutos',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          elevation: 0,
        ),
        body: const _ChatBody(),
      ),
    );
  }
}

// ── Cuerpo del chat (separado para que Consumer sea más fino) ─────────────────
class _ChatBody extends StatefulWidget {
  const _ChatBody();

  @override
  State<_ChatBody> createState() => _ChatBodyState();
}

class _ChatBodyState extends State<_ChatBody> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<String> _predefinedMessages = [
    '👋 Hola, me interesa tu servicio.',
    '⏱️ ¿En cuánto tiempo podrías llegar?',
    '❓ Tengo una consulta sobre tu oferta.',
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? textValue]) async {
    final text = (textValue ?? _msgController.text).trim();
    if (text.isEmpty) return;

    final phoneRegex = RegExp(r'(\+591\d+|\b[67]\d{6,}\b)');
    if (phoneRegex.hasMatch(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por políticas de seguridad, no se permiten números de teléfono.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSending = true);
    final prov = Provider.of<ConversationsProvider>(context, listen: false);
    try {
      if (textValue == null) _msgController.clear();
      if (prov.conversationId != null) {
        await prov.sendMessage(prov.conversationId!, text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Consumer<ConversationsProvider>(
            builder: (context, prov, _) {
              final messages = prov.messages;

              // ── IndexedStack: árbol siempre estable ──
              int pageIndex;
              if (prov.isLoadingChat) {
                pageIndex = 0;
              } else if (prov.chatError != null) {
                pageIndex = 1;
              } else if (messages.isEmpty) {
                pageIndex = 2;
              } else {
                pageIndex = 3;
              }

              return IndexedStack(
                index: pageIndex,
                children: [
                  // 0: Cargando
                  const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1A819A)),
                  ),

                  // 1: Error
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            prov.chatError ?? '',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                color: Colors.red[700], fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A819A),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => prov.initChat(
                                Provider.of<ConversationsProvider>(context,
                                        listen: false)
                                    .conversationId ??
                                    ''),
                            child: const Text('Reintentar',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 2: Vacío / sugerencias
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    children: [
                      Row(children: [
                        const Icon(Icons.auto_awesome,
                            color: Color(0xFF1A819A), size: 18),
                        const SizedBox(width: 8),
                        Text('Sugerencias rápidas:',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700])),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 10,
                        children: _predefinedMessages.map((msg) {
                          return InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _isSending ? null : () => _sendMessage(msg),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: const Color(0xFF1A819A)
                                        .withOpacity(0.3)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(msg,
                                  style: GoogleFonts.poppins(
                                      color: const Color(0xFF1A819A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          'Inicia una conversación\nSelecciona una sugerencia o escribe un mensaje.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              color: Colors.grey[500], fontSize: 15),
                        ),
                      ),
                    ],
                  ),

                  // 3: Lista de mensajes
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[messages.length - 1 - index];
                      final isMe = msg.senderId == prov.currentUid;
                      return _buildBubble(msg, isMe);
                    },
                  ),
                ],
              );
            },
          ),
        ),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildBubble(MessageModel msg, bool isMe) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFF1A819A).withOpacity(0.15),
              child: Text(
                msg.senderName.isNotEmpty
                    ? msg.senderName[0].toUpperCase()
                    : 'W',
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A819A),
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF1A819A) : Colors.white,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  bottomLeft: !isMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(msg.text,
                      style: GoogleFonts.poppins(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(timeStr,
                      style: GoogleFonts.poppins(
                          color: isMe ? Colors.white70 : Colors.grey[500],
                          fontSize: 11)),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _msgController,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: GoogleFonts.poppins(fontSize: 15),
                  decoration: InputDecoration(
                    hintText: 'Escribe tu mensaje aquí...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Color(0xFF1A819A),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white),
                onPressed: _isSending ? null : () => _sendMessage(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
