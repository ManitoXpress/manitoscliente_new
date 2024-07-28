
import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: 1.2,
          child: Image.network(
            'https://i.imgur.com/Dvhc4hW.png',

          ),
        ),
      ),
    );
  }
}
