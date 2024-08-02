
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: FractionallySizedBox(
          widthFactor: 1.0.w,
          heightFactor: 1.2.h,
          child: Image.network(
            'https://i.imgur.com/Dvhc4hW.png',

          ),
        ),
      ),
    );
  }
}
