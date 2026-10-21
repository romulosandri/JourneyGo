import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';
import '../widgets/scenery.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    if (trip.inviteExpired) {
      return ProductScaffold(
        title: 'Invite',
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'This invite has expired. Ask ${trip.organiser.name} for a new pass.',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
      );
    }
    final place = trip.places.isEmpty ? 'somewhere' : trip.places.first.name;
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      title: place,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              Scenery(vibe: trip.vibe, height: 220),
              Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Text(
                  place.toUpperCase(),
                  style: text.headlineMedium?.copyWith(
                    color: JourneyColors.ink,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${trip.organiser.name} is planning a getaway to $place',
                  style: text.headlineSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Chip('${compactRange(trip.start, trip.end)} (suggested)'),
                    _Chip('~\$${trip.draftCost} each'),
                    _Chip('${trip.joined.length} already interested'),
                  ],
                ),
                const SizedBox(height: 16),
                AvatarStack(members: trip.joined),
                const SizedBox(height: 18),
                Text(
                  'Just your first name. No sign-up. Interested isn\'t a commitment.',
                  style: text.bodyMedium,
                ),
                TextButton(
                  onPressed: () => _code(context),
                  child: const Text('Join with the 6-digit code'),
                ),
              ],
            ),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('im-interested'),
            label: 'I\'m interested',
            onPressed: () => _join(context),
          ),
          QuietButton(
            label: 'Not this time',
            onPressed: () => _decline(context),
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context) async {
    final trip = PlanningScope.read(context).trip;
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _NameSheet(
        savedNames: [
          for (final member in trip?.members ?? [])
            if (member.seat == Seat.saved) member.name,
        ],
      ),
    );
    if (name == null || !context.mounted) {
      return;
    }
    final controller = PlanningScope.read(context);
    final error = controller.joinWithName(name);
    if (error != null) {
      controller.note(error);
      return;
    }
    controller.note(
      'You\'re in the planning! 3 quick questions, about 1 minute.',
    );
    if (!context.mounted) {
      return;
    }
    final current = controller.trip;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.hub, (route) => false);
    if (current != null && decisionActive(current, DecisionKind.destination)) {
      Navigator.of(context)
          .pushNamed(AppRoutes.swipe, arguments: SwipeMode.destination);
    }
  }

  Future<void> _decline(BuildContext context) async {
    final controller = PlanningScope.read(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No worries. Want updates if dates change?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Keep me posted',
                onPressed: () {
                  Navigator.pop(context);
                  controller.note('We\'ll only write if the dates move.');
                },
              ),
              QuietButton(
                label: 'No thanks',
                onPressed: () {
                  Navigator.pop(context);
                  controller.note('No worries.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _code(BuildContext context) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CodeSheet(),
    );
    if (code == null || !context.mounted) {
      return;
    }
    final controller = PlanningScope.read(context);
    if (!controller.codeMatches(code)) {
      controller.note('That code doesn\'t match this pass.');
      return;
    }
    await _join(context);
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: JourneyColors.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: JourneyColors.line),
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.savedNames});

  final List<String> savedNames;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.savedNames.cast<String?>().firstWhere(
      (name) => name!.toLowerCase() == _field.text.trim().toLowerCase(),
      orElse: () => null,
    );
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match == null
                ? 'Your first name'
                : 'Are you $match? Claim your seat.',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('join-name'),
            controller: _field,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Leo'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('join-submit'),
            label: match == null ? 'Join' : 'Claim seat',
            onPressed: () => Navigator.pop(context, _field.text.trim()),
          ),
        ],
      ),
    );
  }
}

class _CodeSheet extends StatefulWidget {
  const _CodeSheet();

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _field = TextEditingController();

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trip code', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(
            controller: _field,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: '482 913'),
            onChanged: (value) {
              final digits = value.replaceAll(RegExp(r'\D'), '');
              if (digits.length >= 6) {
                Navigator.pop(context, digits.substring(0, 6));
              }
            },
          ),
        ],
      ),
    );
  }
}
