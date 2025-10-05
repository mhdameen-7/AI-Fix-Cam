import 'dart:convert';
import 'dart:io';

import 'package:aifixcam/widgets/camera_view.dart';
import 'package:aifixcam/models/problem_model.dart';
import 'package:aifixcam/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; // Import the image_picker
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

// We convert HomeScreen to a StatefulWidget to manage the loading state and AI model.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // We move the AI and data variables here
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _solutionData = {};
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Load everything when the app starts
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // This is the same logic from the old camera screen, now centralized here.
    await Future.wait([_loadModel(), _loadLabels(), _loadSolutionData()]);
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    } catch (e) {
      print('FATAL ERROR: Failed to load TFLite model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('FATAL ERROR: Failed to load labels: $e');
    }
  }

  Future<void> _loadSolutionData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/solution_data.json');
      _solutionData = json.decode(jsonString);
    } catch (e) {
      print('FATAL ERROR: Failed to load solution data: $e');
    }
  }

  // --- THIS IS THE NEW FUNCTION FOR THE GALLERY ---
  Future<void> _pickAndProcessImage() async {
    if (_isProcessing) return;

    final picker = ImagePicker();
    // Open the gallery and wait for the user to pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return; // User cancelled the picker

    setState(() { _isProcessing = true; });

    try {
      // We use the same AI inference logic as the camera
      final problemKey = await _runInference(image.path);
      final solutionJson = _solutionData[problemKey.trim()] ?? _solutionData['default'];
      if (solutionJson == null) throw Exception("Could not find a solution.");
      
      final solution = ProblemSolution.fromJson(solutionJson);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => ResultScreen(solution: solution)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error processing image: ${e.toString()}"),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() { _isProcessing = false; });
    }
  }

  // This is the same AI logic, now available directly on the home screen.
  Future<String> _runInference(String imagePath) async {
    // ... (This function's code is exactly the same as the working version in camera_screen.dart)
    if (_interpreter == null || _labels.isEmpty) throw Exception("Model or labels not loaded.");
    final imageData = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception("Could not decode image.");
    final resizedImage = img.copyResize(image, width: 224, height: 224);
    var inputBuffer = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final input = inputBuffer.reshape([1, 224, 224, 3]);
    final output = List.filled(1 * _labels.length, 0).reshape([1, _labels.length]);
    _interpreter!.run(input, output);
    final outputList = output[0] as List<int>;
    int maxIndex = 0;
    for (int i = 1; i < outputList.length; i++) {
      if (outputList[i] > outputList[maxIndex]) {
        maxIndex = i;
      }
    }
    return _labels[maxIndex];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.build_circle_outlined, size: 120, color: Color(0xFF00BFA5)),
              const SizedBox(height: 20),
              const Text(
                'AI Fix Cam',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Identify household problems instantly and get step-by-step solutions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 60),

              // --- NEW BUTTON LAYOUT ---
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                )
              else
                Column(
                  children: [
                    // Button to open the live camera
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const CameraScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Scan with Camera', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Button to open the gallery
                    ElevatedButton.icon(
                      onPressed: _pickAndProcessImage, // Calls our new function
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload from Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade800, // Different style
                        minimumSize: const Size(double.infinity, 56),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
