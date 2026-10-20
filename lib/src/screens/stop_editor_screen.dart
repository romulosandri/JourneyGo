import 'package:flutter/material.dart';

import '../app.dart';
import '../models/ids.dart';
import '../models/journey.dart';
import '../widgets/layout.dart';

class StopEditorScreen extends StatefulWidget {
  const StopEditorScreen({super.key, required this.journeyId, this.stop});

  final String journeyId;
  final Stop? stop;

  @override
  State<StopEditorScreen> createState() => _StopEditorScreenState();
}

class _StopEditorScreenState extends State<StopEditorScreen> {
  late final TextEditingController _name;
  late final TextEditingController _detail;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.stop?.name ?? '');
    _detail = TextEditingController(text: widget.stop?.detail ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.stop != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit stop' : 'New stop')),
      body: CenteredColumn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              key: const Key('stop-name'),
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofocus: widget.stop == null,
              maxLength: 80,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Place',
                hintText: 'A market, a trail, a station',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('stop-detail'),
              controller: _detail,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 160,
              maxLines: 3,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional. Why this stop is on the route.',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('save-stop'),
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Save stop'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) {
    return null;
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name the place.');
      return;
    }
    final stop = Stop(
      id: widget.stop?.id ?? createId(),
      name: name,
      detail: _detail.text.trim(),
      done: widget.stop?.done ?? false,
    );
    await JourneyScope.read(context).saveStop(widget.journeyId, stop);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}
