
import 'dart:math';

import 'package:flutter/material.dart';

class RankingScreen extends StatelessWidget {
  final List<User> users = generateRandomUsers(10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
      ),
      body: Center(
        child: Container(
          alignment: Alignment.center,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      child: Text(users[index].name[0]),
                    ),
                    const SizedBox(width: 2),
                    Text(users[index].name),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.star,
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 2),
                    Text(users[index].rating.toString()),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static List<User> generateRandomUsers(int count) {
    final List<User> users = [];

    for (int i = 0; i < count; i++) {
      final name = getRandomName();
      final rating = Random().nextInt(6); // Generates a random rating from 0 to 5

    }

    return users;
  }

  static String getRandomName() {
    // Generate random names or use a list of predefined names
    // Here's an example using predefined names
    final List<String> names = [
      'John',
      'Jane',
      'Michael',
      'Emma',
      'David',
      'Sarah',
      'Daniel',
      'Olivia',
      'Christopher',
      'Sophia',
    ];

    final random = Random();
    final index = random.nextInt(names.length);

    return names[index];
  }
}


class Service {
  final String title;
  final String imageUrl;

  Service({required this.title, required this.imageUrl, required String description, required List<String> buttonTexts});
}
class User {
  final List<String> history;
  final String name;
  final String imageUrl;
  final double rating;
  final String serviceType;



  User(this.history, {
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.serviceType,
  });
}
