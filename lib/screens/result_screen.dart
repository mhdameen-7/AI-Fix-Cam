import 'package:aifixcam/models/problem_model.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ResultScreen extends StatefulWidget {
  final ProblemSolution solution;

  const ResultScreen({super.key, required this.solution});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.solution.videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: widget.solution.videoId!,
        // --- THIS IS THE FIX ---
        // We are explicitly telling the player:
        // 1. autoPlay: false -> Don't start immediately, giving it time to buffer.
        // 2. forceHD: false -> Do NOT request the HD version. Let YouTube's
        //    player choose a quality suitable for the user's network speed.
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          forceHD: false, 
          mute: false,
        ),
      );
    } else {
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // Helper widget to create consistent section titles
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.lightBlue, size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.solution.title),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Safety Section ---
              _buildSectionTitle('Safety First', Icons.warning_amber_rounded),
              Card(
                color: const Color.fromARGB(255, 66, 33, 33),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: widget.solution.safetyNotes.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${entry.key + 1}. ", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                            Expanded(child: Text(entry.value, style: const TextStyle(color: Colors.white, height: 1.4))),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Tools Section ---
              _buildSectionTitle('Tools You’ll Need', Icons.build_rounded),
              Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: widget.solution.tools.map((tool) => ListTile(
                      leading: const Icon(Icons.check_box_outline_blank_rounded, color: Colors.lightBlue),
                      title: Text(tool),
                    )).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- Steps Section ---
              _buildSectionTitle('Step-by-Step Repair', Icons.list_alt_rounded),
              ...widget.solution.instructions.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final step = entry.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: const Color(0xFF1E1E1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("$index. ${step.title}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.lightBlue)),
                        const SizedBox(height: 8),
                        Text(step.description, style: const TextStyle(height: 1.5)),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // --- Video Section ---
              if (_controller != null) ...[
                _buildSectionTitle('Video Tutorial', Icons.play_circle_fill_rounded),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: YoutubePlayer(
                    controller: _controller!,
                    showVideoProgressIndicator: true,
                    onReady: () => print('Player is ready.'),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
