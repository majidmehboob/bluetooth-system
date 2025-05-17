import 'package:flutter/material.dart';
import 'package:smart_track/screens/auth/app-initializer.dart';
import 'package:smart_track/utils/colors.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: ColorStyle.BlueStatic),
      ),
      home: const AppInitializer(),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});
//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final BeaconBroadcast beaconBroadcast = BeaconBroadcast();
//   bool isAdvertising = false;

//   @override
//   void initState() {
//     super.initState();
//     // Listen to advertising state changes
//     beaconBroadcast.getAdvertisingStateChange().listen((state) {
//       setState(() {
//         isAdvertising = state;
//       });
//     });
//   }

//   Future<bool> _checkPermissions() async {
//     if (await Permission.bluetooth.isDenied) {
//       await Permission.bluetooth.request();
//     }
//     if (await Permission.bluetoothAdvertise.isDenied) {
//       await Permission.bluetoothAdvertise.request();
//     }
//     if (await Permission.location.isDenied) {
//       await Permission.location.request();
//     }

//     return await Permission.bluetooth.isGranted &&
//         await Permission.bluetoothAdvertise.isGranted &&
//         await Permission.location.isGranted;
//   }

//   void _toggleBeacon() async {
//     if (!await _checkPermissions()) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Permissions required for beacon broadcasting'),
//         ),
//       );
//       return;
//     }
//     if (!isAdvertising) {
//       // Start broadcasting
//       await beaconBroadcast
//           .setUUID('39ED98FF-2900-441A-802F-9C398FC199D2')
//           .setMajorId(1)
//           .setMinorId(100)
//           .start();
//     } else {
//       // Stop broadcasting
//       await beaconBroadcast.stop();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             Text(
//               'Beacon Status:',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             Text(
//               isAdvertising ? 'Broadcasting' : 'Stopped',
//               style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                 color: isAdvertising ? Colors.green : Colors.red,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'UUID: 39ED98FF-2900-441A-802F-9C398FC199D2\n'
//               'Major: 1, Minor: 100',
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _toggleBeacon,
//         tooltip: isAdvertising ? 'Stop Beacon' : 'Start Beacon',
//         child: Icon(isAdvertising ? Icons.stop : Icons.play_arrow),
//       ),
//     );
//   }
// }
