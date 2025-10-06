import 'dart:convert';
import 'dart:io';

import 'package:aifixcam/models/history_model.dart';
import 'package:aifixcam/models/problem_model.dart';
import 'package:aifixcam/screens/result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;
  Map<String, dynamic>? _solutionData; // To hold all solutions

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }
  
  // Load both history and the solution data file
  Future<void> _loadAllData() async {
    await _loadSolutionData();
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJsonStringList = prefs.getStringList('diagnosis_history') ?? [];
    
    final items = historyJsonStringList
        .map((jsonString) => HistoryItem.fromJson(json.decode(jsonString)))
        .toList();

    setState(() {
      _historyItems = items.reversed.toList();
      _isLoading = false;
    });
  }
  
  // New method to load the solutions from the JSON file
  Future<void> _loadSolutionData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/solution_data.json');
      _solutionData = json.decode(jsonString);
    } catch (e) {
      print('ERROR: Failed to load solution data in HistoryScreen: $e');
    }
  }

  // NEW: This function is called when a user taps a history item
  void _onHistoryItemTapped(HistoryItem item) {
    if (_solutionData == null || item.problemKey.isEmpty) return;

    final solutionJson = _solutionData![item.problemKey] ?? _solutionData!['default'];
    if (solutionJson == null) return;

    final solution = ProblemSolution.fromJson(solutionJson);
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ResultScreen(solution: solution)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnosis History'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _historyItems.isEmpty
              ? Center(
                  child: Text(
                    'No history found.\nDiagnose a problem to see it here!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _historyItems.length,
                  itemBuilder: (context, index) {
                    final item = _historyItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      // UPDATED: The ListTile is now tappable
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.file(
                            File(item.imagePath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 56),
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.date, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        onTap: () => _onHistoryItemTapped(item), // The tap action
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ),
                    );
                  },
                ),
    );
  }
}
