import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:manitoscliente_new/request/resquest.dart';
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
  final CollectionReference _chatsCollection =
  FirebaseFirestore.instance.collection('chats');

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
        title: Text('Chat con ${widget.workerId}'),
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
                    final isSentByMe = message['senderId'] == widget.userId;

                    return Align(
                      alignment: isSentByMe
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      child: Container(
                        padding: EdgeInsets.all(12.0),
                        margin: EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: isSentByMe ? Colors.blue[200] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(message['text'] ?? ''),
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