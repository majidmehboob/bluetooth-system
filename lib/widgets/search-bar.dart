import 'package:flutter/material.dart';

Widget searchbar(
  String text,
  Color bgcolor,
  IconData icon,
  ValueChanged<String>? onChanged,
) {
  return Container(
    height: 45,
    decoration: BoxDecoration(
      color: bgcolor,
      // color: Colors.white,
      borderRadius: BorderRadius.circular(25),
    ),
    child: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: TextField(
                textAlign: TextAlign.start,
                decoration: InputDecoration(
                  hintText: text,
                  hintStyle: TextStyle(
                    color: Color.fromARGB(136, 65, 65, 62),
                    fontSize: 20,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                ),
                onChanged: onChanged, // Use the provided callback
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Icon(icon, color: Colors.black, size: 30),
        ),
      ],
    ),
  );
}
