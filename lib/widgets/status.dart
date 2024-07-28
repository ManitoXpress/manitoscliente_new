import 'package:flutter/material.dart';

Widget buildStatusIndicator(String estado) {
  Color indicatorColor;
  IconData iconData;

  switch (estado.toLowerCase()) {
    case "completado":
      indicatorColor = Colors.green;
      iconData = Icons.check_circle;
      break;
    case "en curso":
      indicatorColor = Colors.red;
      iconData = Icons.hourglass_bottom;
      break;
    default:
      indicatorColor = Colors.grey;
      iconData = Icons.help;
  }

  return Row(
    children: [
      Icon(
        iconData,
        color: indicatorColor,
      ),
      SizedBox(width: 5),
      Text(estado, style: TextStyle(color: indicatorColor)),
    ],
  );
}
