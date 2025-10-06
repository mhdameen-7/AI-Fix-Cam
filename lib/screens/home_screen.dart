import 'dart:convert';
import 'dart:io';

import 'package:aifixcam/models/history_model.dart';
import 'package:aifixcam/models/problem_model.dart';
import 'package:aifixcam/screens/result_screen.dart';
import 'package:aifixcam/screens/capture_screen.dart';
import 'package:aifixcam/screens/history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Interpreter? _interpreter;
  List<String> _labels = [];
  Map<String, dynamic> _solutionData = {};
  bool _isProcessing = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([_loadModel(), _loadLabels(), _loadSolutionData()]);
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/model.tflite');
    } catch (e) {
      print('ERROR loading model: $e');
    }
  }

  Future<void> _loadLabels() async {
    try {
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').where((label) => label.isNotEmpty).toList();
    } catch (e) {
      print('ERROR loading labels: $e');
    }
  }

  Future<void> _loadSolutionData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/solution_data.json');
      _solutionData = json.decode(jsonString);
    } catch (e) {
      print('ERROR loading solution data: $e');
    }
  }

  Future<String> _runInference(String imagePath) async {
    if (_interpreter == null || _labels.isEmpty) throw Exception("Model or labels not loaded.");
    final imageData = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageData);
    if (image == null) throw Exception("Could not decode image.");

    final resizedImage = img.copyResize(image, width: 224, height: 224);
    final inputBuffer = resizedImage.getBytes(order: img.ChannelOrder.rgb);
    final input = inputBuffer.reshape([1, 224, 224, 3]);
    final output = List.filled(1 * _labels.length, 0).reshape([1, _labels.length]);

    _interpreter!.run(input, output);

    final outputList = (output[0] as List<num>);
    int maxIndex = 0;
    for (int i = 1; i < outputList.length; i++) {
      if (outputList[i] > outputList[maxIndex]) {
        maxIndex = i;
      }
    }
    return _labels[maxIndex];
  }

  // UPDATED: Now accepts the problemKey
  Future<void> _saveHistoryItem(String title, String tempImagePath, String problemKey) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final permanentImagePath = '${directory.path}/$fileName';
    await File(tempImagePath).copy(permanentImagePath);

    final newItem = HistoryItem(
      title: title,
      imagePath: permanentImagePath,
      date: "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
      problemKey: problemKey, // NEW: Save the key
    );

    final prefs = await SharedPreferences.getInstance();
    final historyList = prefs.getStringList('diagnosis_history') ?? [];
    historyList.add(json.encode(newItem.toJson()));
    await prefs.setStringList('diagnosis_history', historyList);
  }

  Future<void> _pickAndProcessImage() async {
    if (_isProcessing) return;
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() => _isProcessing = true);

    try {
      final problemKey = await _runInference(image.path);
      final solutionJson = _solutionData[problemKey.trim()] ?? _solutionData['default'];
      if (solutionJson == null) throw Exception("Could not find a solution.");

      final solution = ProblemSolution.fromJson(solutionJson);
      
      // UPDATED: Pass the problemKey when saving
      await _saveHistoryItem(solution.title, image.path, problemKey.trim());

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
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Fix Cam"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          )
        ],
      ),
      body: _isInitializing
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.build_circle_outlined, size: 100, color: Colors.lightBlue),
                    const SizedBox(height: 20),
                    const Text('AI Fix Cam', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                      'Identify and fix household problems instantly using your camera.',
                      style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7)),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    if (_isProcessing)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CaptureScreen()),
                              );
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Scan with Camera'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.lightBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _pickAndProcessImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Upload from Gallery'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade800,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
