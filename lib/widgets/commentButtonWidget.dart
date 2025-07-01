import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../constants/service_constants.dart';
import '../provider/serviceDetails_providers.dart';

/// Modal para mostrar y enviar comentarios en el servicio (lado socio).
class CommentsBottomSheet extends StatefulWidget {
  final ServiceDetailsProvider provider;

  const CommentsBottomSheet({Key? key, required this.provider}) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _comentarioController = TextEditingController();
  bool _isSending = false;

  /// Regex que detecta:
  /// - cualquier cadena que empiece con “+591” seguido de dígitos
  /// - o cualquier palabra que comience con “6” o “7” y tenga al menos 7 dígitos
  final RegExp _phoneBlacklistRegex = RegExp(r'(\+591\d+|\b[67]\d{6,}\b)');

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final comentarios = provider.comments;

    return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: DraggableScrollableSheet(
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Comentarios (${comentarios.length})',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Karla',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: comentarios.length,
                        itemBuilder: (ctx, i) {
                          final c = comentarios[i];
                          final isClient = c.rol == 'cliente';
                          final alignment =
                          isClient ? MainAxisAlignment.end : MainAxisAlignment.start;
                          final color = isClient ? AppColors.secondary : AppColors.primary;
                          final textAlign = isClient ? TextAlign.end : TextAlign.start;
                          final nombre = isClient ? 'Cliente' : 'Trabajador';

                          return ListTile(
                            title: Row(
                              mainAxisAlignment: alignment,
                              children: [
                                Text(
                                  nombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  c.hora,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              c.mensaje,
                              textAlign: textAlign,
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _comentarioController,
                              decoration: InputDecoration(
                                hintText: 'Escribe un comentario...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _isSending
                              ? const CircularProgressIndicator()
                              : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () async {
                              final texto = _comentarioController.text.trim();
                              if (texto.isEmpty) return;

                              // Validación contra la regex de teléfonos
                              if (_phoneBlacklistRegex.hasMatch(texto)) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Error'),
                                    content: const Text(
                                      'No se puede enviar números de teléfono en los comentarios.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Aceptar'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              // Envío del comentario
                              setState(() {
                                _isSending = true;
                              });
                              await provider.addComment(texto);
                              if (provider.errorMessage != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(provider.errorMessage!),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                              _comentarioController.clear();
                              setState(() {
                                _isSending = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
            ),
        );
    }
}