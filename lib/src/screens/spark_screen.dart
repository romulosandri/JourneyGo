import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class SparkScreen extends StatelessWidget {
  const SparkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final vibe = controller.vibe;
    final wash = vibe == null ? JourneyColors.paper : vibeWash(vibe);
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      showBack: false,
      background: wash,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Close',
              onPressed: controller.startOver,
              icon: const Icon(Icons.close),
            ),
          ),
          const Eyebrow(text: 'New getaway'),
          const SizedBox(height: 10),
          const SetupStepper(index: 0),
          const SizedBox(height: 22),
          Text('What kind of escape?', style: text.displaySmall),
          const SizedBox(height: 8),
          Text(
            vibe == null
                ? 'Pick a vibe and we\'ll draft the rest.'
                : 'We\'ll suggest places, a weekend, and a rough cost.',
            style: text.bodyLarge?.copyWith(color: JourneyColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in Vibe.values)
                _Choice(
                  key: Key('vibe-${item.name}'),
                  label: '${vibeEmoji(item)} ${vibeLabel(item)}',
                  selected: vibe == item,
                  color: vibeInk(item),
                  onTap: () => controller.selectVibe(item),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('When?', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in Timing.values)
                _Choice(
                  label: timingLabel(item),
                  selected: controller.timing == item,
                  color: JourneyColors.ink,
                  onTap: () => controller.selectTiming(item),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Text('Roughly how many?', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in PartySize.values)
                _Choice(
                  label: partyLabel(item),
                  selected: controller.party == item,
                  color: JourneyColors.ink,
                  onTap: () => controller.selectParty(item),
                ),
            ],
          ),
          const SizedBox(height: 28),
          TextButton(
            key: const Key('preview-sunny'),
            onPressed: () => controller.openPreview(PreviewKind.basics),
            child: const Text('Preview the Sunny Escape trip'),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('spark-continue'),
            label: 'Draft my trip',
            onPressed: vibe == null
                ? null
                : () {
                    controller.requestDraft(knowWhere: false);
                    Navigator.of(context).pushNamed(AppRoutes.draft);
                  },
          ),
          QuietButton(
            label: 'I already know where',
            onPressed: vibe == null
                ? null
                : () {
                    controller.requestDraft(knowWhere: true);
                    Navigator.of(context).pushNamed(AppRoutes.draft);
                  },
          ),
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedScale(
      scale: selected && !reduce ? 1.04 : 1,
      duration: const Duration(milliseconds: 180),
      child: Material(
        color: selected ? color : JourneyColors.card,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: selected ? color : JourneyColors.line),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? JourneyColors.onAccent : JourneyColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
