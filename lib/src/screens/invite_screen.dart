import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/catalog.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../widgets/boarding_pass.dart';
import '../widgets/chrome.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final text = Theme.of(context).textTheme;
    final crew = [
      for (final person in freshCrew())
        if (trip.member(person.id) == null) person,
    ];
    final going = trip.joined.length;
    return ProductScaffold(
      title: 'Who\'s coming?',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const SetupStepper(index: 2),
          const SizedBox(height: 16),
          Text('Who\'s coming?', style: text.displaySmall),
          const SizedBox(height: 14),
          BoardingPass(trip: trip),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _share(context),
                  child: const Text('Share pass'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _copy(context),
                  child: const Text('Copy link'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Friends join from the link. No app or account needed.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 18),
          if (crew.isNotEmpty) ...[
            Text('Recent crew', style: text.titleSmall),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final person in crew)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: InkWell(
                        onTap: () => controller.addSavedFriend(person.id),
                        child: Column(
                          children: [
                            PersonAvatar(member: person),
                            const SizedBox(height: 4),
                            Text(person.name, style: text.bodySmall),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          TextButton(
            onPressed: () => _addName(context),
            child: const Text('+ Add someone by name'),
          ),
          Text(
            'They\'ll claim it when they open the link. A saved seat can\'t vote.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          Text(
            going <= 1
                ? 'Trips need you + 1 to confirm.'
                : '${trip.organiser.name} + ${going - 1}',
            style: text.titleSmall,
          ),
          const SizedBox(height: 8),
          AvatarStack(members: trip.members),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.landing),
            child: const Text('Preview the link'),
          ),
        ],
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('go-to-trip'),
            label: 'Go to trip',
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.hub, (route) => false);
            },
          ),
          QuietButton(
            label: 'Invite later',
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.hub, (route) => false);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final controller = PlanningScope.read(context);
    await Clipboard.setData(ClipboardData(text: controller.link));
    controller.note('Link copied. Drop it in your group chat.');
  }

  Future<void> _share(BuildContext context) async {
    final controller = PlanningScope.read(context);
    final trip = controller.trip;
    if (trip == null) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Share pass', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(controller.link),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Copy for the group chat'),
                subtitle: Text('${trip.name} · ${trip.places.first.name}'),
                onTap: () async {
                  await Clipboard.setData(
                    ClipboardData(
                      text: '${controller.statusUpdate()}\n${controller.link}',
                    ),
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                  controller.note('Link copied. Drop it in your group chat.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addName(BuildContext context) async {
    final field = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save a seat'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'First name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Save seat'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name != null && context.mounted) {
      PlanningScope.read(context).addNamedSeat(name);
    }
  }
}
