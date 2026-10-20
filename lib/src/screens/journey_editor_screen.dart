import 'package:flutter/material.dart';

import '../app.dart';
import '../format.dart';
import '../models/ids.dart';
import '../models/journey.dart';
import '../theme/journey_theme.dart';
import '../widgets/layout.dart';

class JourneyEditorScreen extends StatefulWidget {
  const JourneyEditorScreen({super.key, this.journey});

  final Journey? journey;

  @override
  State<JourneyEditorScreen> createState() => _JourneyEditorScreenState();
}

class _JourneyEditorScreenState extends State<JourneyEditorScreen> {
  late final TextEditingController _title;
  late final TextEditingController _place;
  late final TextEditingController _note;
  late DateTime _start;
  late DateTime _end;
  late JourneyAccent _accent;
  String? _error;
  var _datesReady = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.journey;
    _title = TextEditingController(text: existing?.title ?? '');
    _place = TextEditingController(text: existing?.place ?? '');
    _note = TextEditingController(text: existing?.note ?? '');
    _accent = existing?.accent ?? JourneyAccent.terracotta;
    final today = dateOnly(DateTime.now());
    _start = existing == null ? today : dateOnly(existing.start);
    _end = existing == null
        ? today.add(const Duration(days: 2))
        : dateOnly(existing.end);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_datesReady || widget.journey != null) {
      _datesReady = true;
      return;
    }
    final today = dateOnly(JourneyScope.read(context).today);
    _start = today;
    _end = today.add(const Duration(days: 2));
    _datesReady = true;
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.journey != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit journey' : 'New journey')),
      body: CenteredColumn(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              key: const Key('journey-title'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 80,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What this trip is about',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('journey-place'),
              controller: _place,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 60,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Place',
                hintText: 'City or region',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'First day',
                    date: _start,
                    onPick: () => _pickDate(first: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Last day',
                    date: _end,
                    onPick: () => _pickDate(first: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 280,
              maxLines: 4,
              buildCounter: _hideCounter,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Optional. A line you want to remember.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            Text('Color', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final accent in JourneyAccent.values)
                  _AccentChoice(
                    accent: accent,
                    selected: _accent == accent,
                    onSelected: () => setState(() => _accent = accent),
                  ),
              ],
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
              key: const Key('save-journey'),
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Save journey'),
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

  Future<void> _pickDate({required bool first}) async {
    final current = first ? _start : _end;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: first ? 'First day' : 'Last day',
    );
    if (picked == null) {
      return;
    }
    final day = dateOnly(picked);
    setState(() {
      if (first) {
        _start = day;
        if (_end.isBefore(_start)) {
          _end = _start;
        }
      } else {
        _end = day;
        if (_end.isBefore(_start)) {
          _start = _end;
        }
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    final place = _place.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this journey a name.');
      return;
    }
    if (place.isEmpty) {
      setState(() => _error = 'Where is it?');
      return;
    }
    if (dateOnly(_end).isBefore(dateOnly(_start))) {
      setState(() => _error = 'The last day has to be the first day or later.');
      return;
    }
    final journey = Journey(
      id: widget.journey?.id ?? createId(),
      title: title,
      place: place,
      start: dateOnly(_start),
      end: dateOnly(_end),
      note: _note.text.trim(),
      accent: _accent,
      stops: widget.journey?.stops ?? const [],
    );
    await JourneyScope.read(context).saveJourney(journey);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: JourneyColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: JourneyColors.line),
      ),
      child: InkWell(
        onTap: onPick,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                formatDay(date),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccentChoice extends StatelessWidget {
  const _AccentChoice({
    required this.accent,
    required this.selected,
    required this.onSelected,
  });

  final JourneyAccent accent;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: accent.label,
      child: InkWell(
        onTap: onSelected,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? JourneyColors.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.color,
            ),
          ),
        ),
      ),
    );
  }
}
