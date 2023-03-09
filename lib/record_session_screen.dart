import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecordSessionScreen extends StatefulWidget {
  const RecordSessionScreen({super.key});

  @override
  State<RecordSessionScreen> createState() => _RecordSessionScreenState();
}

class _RecordSessionScreenState extends State<RecordSessionScreen> {
  final List<int> _flashRecordedSession = [];
  bool _isClicking = false;
  DateTime? _lastTime;

  void _startRecordingAndAnimating(bool isClicking) {
    if (isClicking) {
      setState(() {
        _isClicking = true;
      });

      if (_lastTime != null) {
        final diff = DateTime.now().difference(_lastTime!).inMilliseconds;
        _flashRecordedSession.add(diff);
      }

      _lastTime = DateTime.now();
    } else {
      setState(() {
        _isClicking = false;
      });

      final diff = DateTime.now().difference(_lastTime!).inMilliseconds;
      _flashRecordedSession.add(diff);
      _lastTime = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    var topPadding = (MediaQuery.of(context).size.height - 400) / 2;
    if (topPadding < 0) topPadding = 0;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_flashRecordedSession);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: const SizedBox(),
          leadingWidth: 0,
          title: const FittedBox(child: Text("Recording a Flash Session")),
          centerTitle: true,
        ),
        body: ListView(
          children: [
            SizedBox(height: topPadding),
            const Text(
              "touch the button with a pattern\n(the longer you keep touching, the longer the flash is on)",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.grey[500]!,
                        Colors.grey[400]!,
                        Colors.grey[300]!,
                        Colors.grey[200]!,
                        Colors.grey[100]!,
                      ],
                    ),
                  ),
                )
                    .animate(target: _isClicking ? 0 : 1)
                    .scaleXY(begin: 1, end: 0.5, duration: 50.ms),
                InkWell(
                  borderRadius: BorderRadius.circular(1000),
                  onTap: () {},
                  onHighlightChanged: _startRecordingAndAnimating,
                  child: const CircleAvatar(
                    radius: 50,
                    child: Hero(
                      tag: "Record A Flash Session",
                      child: Icon(Icons.touch_app),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Align(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(_flashRecordedSession);
                },
                style: const ButtonStyle(
                  padding: MaterialStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 40)),
                ),
                child: const Text("Finish"),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
