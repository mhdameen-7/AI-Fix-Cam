import 'package:aifixcam/widgets/camera_view.dart';
import 'package:flutter/material.dart';

class CaptureScreen extends StatelessWidget {
  const CaptureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // This screen provides the main Scaffold and the first AppBar.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point at the Problem'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // The body is our camera view widget.
      body: const CameraView(),
    );
  }
}
