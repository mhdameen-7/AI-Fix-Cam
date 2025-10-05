import 'package:flutter/material.dart';
import 'package:aifixcam/widgets/camera_view.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point at the Problem'),
      ),
      body: const CameraScreen(),
    );
  }
}
