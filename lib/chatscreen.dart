import 'dart:math';
import 'package:flutter/material.dart';

import 'Styles/stilo.dart';

class ChatMessage {
  final String text;
  final bool isSentByMe;
  final String username;
  final String userImage;

  ChatMessage({
    required this.text,
    required this.isSentByMe,
    required this.username,
    required this.userImage,
  });
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  final List<String> _usernames = ['Alex', 'Jamie', 'Chris', 'Sam', 'Jessie'];
  final List<String> _userImages = [
    'https://i.imgur.com/kYR0V6J.png',
    'https://i.imgur.com/1qPhnSi.png',
    'https://i.imgur.com/jyGykv1.png',
    // ... more image urls
  ];

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final random = Random();
      final username = _usernames[random.nextInt(_usernames.length)];
      final userImage = _userImages[random.nextInt(_userImages.length)];

      setState(() {
        _messages.add(ChatMessage(
            text: _controller.text,
            isSentByMe: true,
            username: username,
            userImage: userImage));
        Future.delayed(Duration(seconds: 1), () {
          final autoUsername = _usernames[random.nextInt(_usernames.length)];
          final autoUserImage = _userImages[random.nextInt(_userImages.length)];
          setState(() {
            _messages.add(ChatMessage(
                text: 'Hola, soy el otro usuario.',
                isSentByMe: false,
                username: autoUsername,
                userImage: autoUserImage));
          });
        });
      });

      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat',
          style: MyTextStyles.buttonTextStyle,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Align(
                    alignment: message.isSentByMe
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize
                          .min, // Asegúrate de que la fila tome el espacio mínimo necesario
                      children: [
                        if (!message.isSentByMe)
                          Image.network(
                            message.userImage,
                            width: 50,
                            height: 50,
                          ),
                        Container(
                          padding: EdgeInsets.all(16.0),
                          margin: EdgeInsets.symmetric(
                              horizontal:
                                  8.0), // Añade un margen para separar la imagen y el mensaje
                          decoration: BoxDecoration(
                            color: message.isSentByMe
                                ? Colors.blue[200]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(message.text),
                            ],
                          ),
                        ),
                        if (message.isSentByMe)
                          Image.network(
                            message.userImage,
                            width: 50,
                            height: 50,
                          ),
                      ],
                    ),
                  ),
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

void main() => runApp(MaterialApp(
      home: ChatScreen(),
    ));
