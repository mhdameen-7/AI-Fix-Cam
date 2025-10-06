import 'dart:convert';
import 'dart:io';

import 'package:aifixcam1/models/history_model.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryItem> _historyItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  /// Loads the saved history from local storage.
  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    // Get the saved history list (it's a list of JSON strings).
    final historyJsonStringList = prefs.getStringList('diagnosis_history') ?? [];
    
    // Decode each JSON string back into a HistoryItem object.
    final items = historyJsonStringList
        .map((jsonString) => HistoryItem.fromJson(json.decode(jsonString)))
        .toList();

    if (mounted) {
      setState(() {
        // We reverse the list so the newest items appear at the top.
        _historyItems = items.reversed.toList();
        _isLoading = false;
      });
    }
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
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          // Use Image.file to load the image from the phone's storage
                          child: Image.file(
                            File(item.imagePath),
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            // Show an error icon if the image file was somehow deleted
                            errorBuilder: (context, error, stack) =>
                                const Icon(Icons.broken_image, size: 56),
                          ),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(item.date, style: TextStyle(color: Colors.white.withOpacity(0.7))),
                      ),
                    );
                  },
                ),
    );
  }
}

