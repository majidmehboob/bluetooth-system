// widgets/no_classes_found.dart
import 'package:flutter/material.dart';
import 'package:smart_track/utils/colors.dart';

class NoClassesFound extends StatelessWidget {
  final VoidCallback onRefresh;
  final String parameter;
  final String message;

  const NoClassesFound({
    super.key,
    required this.message,
    required this.onRefresh,
    required this.parameter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset('assets/images/not_found.png', width: 140),
                const SizedBox(height: 4),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 230),
                      child: Text(
                        message,
                        style: TextStyle(color: Colors.black, fontSize: 18),
                        textAlign: TextAlign.start,
                        softWrap: true,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Refresh the page"),
                        Icon(Icons.refresh, color: ColorStyle.BlueStatic),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Text(
              textAlign: TextAlign.center,
              'No $parameter Found',
              style: TextStyle(color: Colors.black26, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
