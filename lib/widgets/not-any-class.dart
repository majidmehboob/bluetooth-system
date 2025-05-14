import 'package:flutter/material.dart';

Widget noClassDetail(Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "There is no class ",
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          " for Today 😊",
          style: TextStyle(
            color: color,
            fontSize: 23,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w200,
          ),
        ),
      ],
    ),
  );
}
