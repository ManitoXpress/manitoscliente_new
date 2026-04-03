import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String userId;
  final String workerId;

  ChatScreen({
    required this.chatId,
    required this.userId,
    required this.workerId,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference _chatsCollection = FirebaseFirestore.instance.collection('chats');
  String? userDisplayName;
  String? workerDisplayName;

  @override
  void initState() {
    super.initState();
    _fetchDisplayNames();
  }

  // Función para obtener los displayName de worker y user
  void _fetchDisplayNames() async {
    try {
      // Obtener el displayName del user
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (userDoc.exists) {
        setState(() {
          userDisplayName = userDoc['displayName'];
        });
      }

      // Obtener el displayName del worker
      final workerDoc = await FirebaseFirestore.instance.collection('workers').doc(widget.workerId).get();
      if (workerDoc.exists) {
        setState(() {
          workerDisplayName = workerDoc['displayName'];
        });
      }
    } catch (e) {
      null;
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = {
        'text': _controller.text,
        'senderId': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      _chatsCollection
          .doc(widget.chatId)
          .collection('messages')
          .add(message)
          .then((_) => _controller.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat con ${workerDisplayName ?? "Trabajador"}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatsCollection
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true, // Los mensajes más recientes van al final
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isSentByUser = message['senderId'] == widget.userId;
                    final senderName = isSentByUser
                        ? userDisplayName ?? "Usuario"
                        : workerDisplayName ?? "Trabajador";

                    return Align(
                      alignment: isSentByUser
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      child: Container(
                        padding: EdgeInsets.all(12.0),
                        margin: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isSentByUser
                              ? Colors.blue[200]  // Color para mensajes del usuario
                              : Colors.green[200],  // Color para mensajes del trabajador
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              senderName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(message['text'] ?? ''),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    onSubmitted: (value) {
                      _sendMessage();
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}