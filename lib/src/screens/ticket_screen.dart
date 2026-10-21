import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../routes.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class TicketScreen extends StatefulWidget {
  const TicketScreen({super.key});

  @override
  State<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends State<TicketScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  var _jumped = false;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _reveal.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_jumped && MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
      _jumped = true;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final place =
        rankDestinations(trip).leader?.title ?? trip.places.first.name;
    final stay = chosenStay(trip)?.name ?? 'Stay to book';
    final anchors = anchorActivities(trip);
    final days = daysUntil(controller.now, trip.start);
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _reveal, curve: Curves.easeOutCubic));
    final text = Theme.of(context).textTheme;
    return ProductScaffold(
      showBack: false,
      body: FadeTransition(
        opacity: _reveal,
        child: SlideTransition(
          position: slide,
          child: ListView(
            key: const Key('ticket-screen'),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            children: [
              Text(_when(days), style: text.labelMedium),
              const SizedBox(height: 8),
              Text('${trip.name} is on', style: text.displaySmall),
              if (trip.arrivalNote != null) ...[
                const SizedBox(height: 8),
                Text(trip.arrivalNote!, style: text.titleSmall),
              ],
              const SizedBox(height: 16),
              PaperCard(
                color: JourneyColors.ink,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place,
                      style: text.headlineSmall?.copyWith(
                        color: JourneyColors.onAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      compactRange(trip.start, trip.end),
                      style: text.titleMedium?.copyWith(
                        color: JourneyColors.dune,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      stay,
                      style: text.titleSmall?.copyWith(
                        color: JourneyColors.onAccent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      anchors.map((item) => item.title).join(' · '),
                      style: text.bodyMedium?.copyWith(
                        color: JourneyColors.dune,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'About ${money(sharedEstimate(trip))} each',
                      style: text.titleLarge?.copyWith(
                        color: JourneyColors.onAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      codeLabel(trip.code),
                      style: text.labelMedium?.copyWith(
                        color: JourneyColors.dune,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text('Before you go', style: text.titleMedium),
              const SizedBox(height: 4),
              CheckboxListTile(
                key: const Key('book-stay'),
                contentPadding: EdgeInsets.zero,
                value: trip.booked,
                title: const Text('Book the stay'),
                subtitle: Text(
                  trip.viewerIsOrganiser
                      ? 'You\'re the one who books.'
                      : '${trip.organiser.name} is booking the stay.',
                ),
                onChanged: (value) => controller.markBooked(value ?? false),
              ),
              ListTile(
                key: const Key('pick-drivers'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Pick drivers'),
                subtitle: Text(_driverLine(trip)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _drivers(context, trip),
              ),
              ListTile(
                key: const Key('settle-up'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Settle up'),
                subtitle: const Text('Possible v2'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.costs),
              ),
              ListTile(
                key: const Key('add-calendar'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Add to calendar'),
                subtitle: const Text('Copies the dates for your calendar'),
                onTap: () => _calendar(context, trip, place),
              ),
            ],
          ),
        ),
      ),
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PrimaryButton(
            key: const Key('share-ticket'),
            label: 'Share the ticket',
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: controller.ticketText()),
              );
              controller.note('Ticket copied. Drop it in the group chat.');
            },
          ),
          QuietButton(
            key: const Key('back-to-trip'),
            label: 'Back to trip',
            onPressed: () {
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.hub, (route) => false);
            },
          ),
        ],
      ),
    );
  }

  String _when(int days) {
    if (days > 1) {
      return '$days days to go';
    }
    if (days == 1) {
      return 'Tomorrow';
    }
    if (days == 0) {
      return 'Today';
    }
    return 'The trip has started';
  }

  String _driverLine(TripSession trip) {
    if (trip.drivers.isEmpty) {
      return 'Nobody named yet';
    }
    return [for (final id in trip.drivers) trip.member(id)?.name ?? id]
        .join(', ');
  }

  Future<void> _calendar(
    BuildContext context,
    TripSession trip,
    String place,
  ) async {
    final body = '${trip.name}\n$place\n${sentenceRange(trip.start, trip.end)}';
    await Clipboard.setData(ClipboardData(text: body));
    if (context.mounted) {
      PlanningScope.read(context).note('Dates copied.');
    }
  }

  Future<void> _drivers(BuildContext context, TripSession trip) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => _DriverSheet(trip: trip),
    );
  }
}

class _DriverSheet extends StatelessWidget {
  const _DriverSheet({required this.trip});

  final TripSession trip;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final current = controller.trip ?? trip;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'Who\'s driving?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final member in current.joined)
              CheckboxListTile(
                value: current.drivers.contains(member.id),
                title: Text(member.name),
                onChanged: (value) {
                  final next = [...current.drivers];
                  if (value ?? false) {
                    next.add(member.id);
                  } else {
                    next.remove(member.id);
                  }
                  controller.setDrivers(next);
                },
              ),
          ],
        ),
      ),
    );
  }
}
