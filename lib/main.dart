import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:torch_player/record_session_screen.dart';

import 'widgets/custom_snack_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Torch Player',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: const MyHomePage(title: 'Torch Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _torchIsOn = false;
  bool _isPlaying = false;
  int _currentPlayingIndex = 0;
  bool _isStopped = false;
  bool _islooped = false;
  List<int> _flashRecordedSession = [];
  List<int> _cumulativeRecorded = [];

  Future<void> _toggleTorch() async {
    setState(() {
      _torchIsOn = !_torchIsOn;
    });

    try {
      if (_torchIsOn) {
        await TorchLight.enableTorch();
      } else {
        await TorchLight.disableTorch();
      }
    } catch (error) {
      showCustomSnackBar(
        context: context,
        content: "error happend, No Flash Detected!!",
        snackBarCenterd: false,
      );
    }
  }

  void _fetchNewRecording(List<int> newRecording) {
    _flashRecordedSession = newRecording;
    _flashRecordedSession.add(0);
    _cumulativeRecorded = _computeTheCumulativeRecorded(_flashRecordedSession);
    setState(() {});
  }

  List<int> _computeTheCumulativeRecorded(List<int> recordedSession) {
    if (recordedSession.isEmpty) return [];

    List<int> cumulative = [recordedSession.first];
    for (int i = 1; i < recordedSession.length; i++) {
      cumulative.add(cumulative.last + recordedSession[i]);
    }

    return cumulative;
  }

  void _playTheRecordedSession() async {
    if (_flashRecordedSession.isEmpty) {
      showCustomSnackBar(
        context: context,
        content: "you didn't record a session",
        snackBarCenterd: false,
      );
      return;
    }

    if (!(await TorchLight.isTorchAvailable())) {
      if (!mounted) return;
      showCustomSnackBar(
        context: context,
        content: "error happend, No Flash Detected!!",
        snackBarCenterd: false,
      );
      return;
    }

    setState(() {
      _isPlaying = true;
      _isStopped = false;
      _torchIsOn = false;
    });

    for (;
        _currentPlayingIndex < _flashRecordedSession.length;
        setState(() {
      ++_currentPlayingIndex;
    })) {
      if (_isStopped) {
        setState(() {
          _currentPlayingIndex = 0;
        });
        return;
      }
      if (!_isPlaying) {
        return;
      }

      await _toggleTorch();
      await Future.delayed(
          Duration(milliseconds: _flashRecordedSession[_currentPlayingIndex]));

      if (_islooped &&
          _currentPlayingIndex == _flashRecordedSession.length - 1) {
        _currentPlayingIndex = -1;
      }
    }

    _stopAndReset();
  }

  Future<void> _stopAndReset() async {
    _isStopped = true;
    await TorchLight.disableTorch();
    setState(() {
      _isPlaying = false;
      _currentPlayingIndex = 0;
      _torchIsOn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    var topPadding = (MediaQuery.of(context).size.height - 350) / 2;
    if (topPadding < 0) topPadding = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        centerTitle: true,
      ),
      body: ListView(
        children: <Widget>[
          SizedBox(height: topPadding),
          Align(
            child: FloatingActionButton(
              tooltip: _torchIsOn ? "Turn Flash Off" : "Turn Flash On",
              heroTag: "Turn Flash Off or On",
              onPressed: _isPlaying ? null : _toggleTorch,
              child:
                  Icon(_torchIsOn ? Icons.lightbulb : Icons.lightbulb_outline),
            ),
          ),
          const SizedBox(height: 50),
          Slider(
            min: _cumulativeRecorded.isEmpty
                ? 0
                : _cumulativeRecorded.first.toDouble(),
            max: _cumulativeRecorded.isEmpty
                ? 0
                : _cumulativeRecorded.last.toDouble(),
            value: _cumulativeRecorded.isEmpty
                ? 0
                : _cumulativeRecorded[_currentPlayingIndex].toDouble(),
            onChanged: _cumulativeRecorded.isEmpty ? null : (value) {},
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              FloatingActionButton(
                tooltip: 'Stop Playing and reset',
                heroTag: "Stop Playing and reset",
                onPressed: _stopAndReset,
                child: const Icon(Icons.stop),
              ),
              FloatingActionButton(
                tooltip: _isPlaying
                    ? "pause The Flash"
                    : 'Play The Flash With The Recorded Session',
                heroTag: "pause or Play and reset",
                onPressed: _isPlaying
                    ? () {
                        setState(() {
                          _isPlaying = false;
                        });
                      }
                    : _playTheRecordedSession,
                child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              IconButton(
                tooltip: _islooped ? "repeat" : "don't repeat",
                onPressed: () {
                  setState(() {
                    _islooped = !_islooped;
                  });
                },
                icon: Icon(
                  _islooped ? Icons.repeat : Icons.repeat_one,
                  size: 30,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Record A Flash Session',
        heroTag: "Record A Flash Session",
        onPressed: () async {
          final recording = await Navigator.push<List<int>>(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const RecordSessionScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 600),
              reverseTransitionDuration: const Duration(milliseconds: 600),
            ),
          );
          if (recording == null || recording.isEmpty) return;

          if (_isPlaying) {
            _stopAndReset();
            _fetchNewRecording(recording);
            await Future.delayed(const Duration(milliseconds: 300));
            _playTheRecordedSession();
          } else {
            _fetchNewRecording(recording);
          }
        },
        child: const Icon(Icons.mic),
      ),
    );
  }
}
