import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_whiskrkit/flutter_whiskrkit.dart';

void main() {
  runApp(const MaterialApp(home: WhiskrKitExample()));
}

/// Manual test harness for the WhiskrKit Flutter plugin.
///
/// WhiskrKit is fire-and-forget by design: none of the calls report an
/// outcome, so the log below records *actions taken*, plus the one SDK event,
/// a submitted survey. The survey either appears or it doesn't; failure
/// details go to the native log (Console.app / Logcat).
class WhiskrKitExample extends StatefulWidget {
  const WhiskrKitExample({super.key});

  @override
  State<WhiskrKitExample> createState() => _WhiskrKitExampleState();
}

class _WhiskrKitExampleState extends State<WhiskrKitExample> {
  final _whiskrkit = FlutterWhiskrkit();
  final _surveyIdController = TextEditingController(text: 'welcome-toast');
  var _initialized = false;
  final _log = <String>[];

  // Built-in mock survey IDs (withMockedSurveys: true). Toast and sheet IDs
  // exist on both platforms; the fullscreen mock ID differs per platform.
  StreamSubscription<SurveyCompletion>? _completions;

  @override
  void initState() {
    super.initState();
    // The one event WhiskrKit reports: the user submitted a survey.
    _completions = _whiskrkit.onSurveyCompleted.listen((completion) {
      final answers = completion.answers
          .map((answer) => '${answer.questionId}=${answer.value}')
          .join(', ');
      _appendLog(
        'completed "${completion.surveyId}": '
        '${answers.isEmpty ? 'no answers' : answers}',
      );
    });
  }

  late final _presets = <String, String>{
    'Toast': 'welcome-toast',
    'Sheet': 'choice-survey',
    'Fullscreen': Platform.isIOS ? 'satisfaction-survey' : 'full-survey',
    'Unknown ID': 'does-not-exist',
  };

  void _appendLog(String message) {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final time = '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
    setState(() => _log.insert(0, '$time  $message'));
  }

  Future<void> _initialize() async {
    await _whiskrkit.initialize('example-api-key', withMockedSurveys: true);
    await _whiskrkit.setAttribute('example', 'flutter');
    setState(() => _initialized = true);
    _appendLog('initialize(withMockedSurveys: true)');
    _appendLog('setAttribute("example", "flutter")');
  }

  Future<void> _present() async {
    final surveyId = _surveyIdController.text;
    await _whiskrkit.present(surveyId);
    _appendLog('present("$surveyId")');
  }

  Future<void> _checkAndPresent() async {
    final surveyId = _surveyIdController.text;
    await _whiskrkit.checkAndPresent(surveyId);
    _appendLog('checkAndPresent("$surveyId")');
  }

  @override
  Widget build(BuildContext context) {
    final platformNote = Platform.isIOS
        ? ' — sheet/toast placement is iOS-only (iPad, regular width)'
        : '';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'WhiskrKit example',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Running on ${Platform.operatingSystem} '
                '${Platform.operatingSystemVersion}$platformNote',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _initialized ? null : _initialize,
                child: Text(
                  _initialized
                      ? 'Initialized ✓'
                      : 'Initialize (mocked surveys)',
                ),
              ),
              const SizedBox(height: 12),
              Text('Survey ID', style: Theme.of(context).textTheme.labelSmall),
              TextField(
                controller: _surveyIdController,
                autocorrect: false,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final entry in _presets.entries)
                    ChoiceChip(
                      label: Text(entry.key),
                      selected: _surveyIdController.text == entry.value,
                      onSelected: (_) => setState(
                        () => _surveyIdController.text = entry.value,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _initialized ? _present : null,
                child: const Text('Present'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _initialized ? _checkAndPresent : null,
                child: const Text('Check eligibility and present'),
              ),
              const SizedBox(height: 12),
              Text(
                'Log (calls made, and completed surveys reported by WhiskrKit)',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ListView.builder(
                    itemCount: _log.length,
                    itemBuilder: (context, index) => Text(
                      _log[index],
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _completions?.cancel();
    _surveyIdController.dispose();
    super.dispose();
  }
}
