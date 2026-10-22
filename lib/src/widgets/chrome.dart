import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';

Color vibeWash(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return const Color(0xFFE4F2EF);
    case Vibe.city:
      return const Color(0xFFE6E7F2);
    case Vibe.nature:
      return const Color(0xFFE6F0E3);
    case Vibe.surprise:
      return const Color(0xFFF8EBE3);
  }
}

Color vibeInk(Vibe vibe) {
  switch (vibe) {
    case Vibe.beach:
      return JourneyColors.sea;
    case Vibe.city:
      return JourneyColors.night;
    case Vibe.nature:
      return JourneyColors.moss;
    case Vibe.surprise:
      return JourneyColors.terracotta;
  }
}

Color memberColor(String id) {
  switch (id) {
    case 'ana':
      return JourneyColors.terracotta;
    case 'bruno':
      return JourneyColors.sea;
    case 'caio':
      return JourneyColors.night;
    case 'duda':
      return JourneyColors.gold;
    case 'leo':
      return const Color(0xFF6E6256);
    case 'mari':
      return JourneyColors.rose;
    default:
      return JourneyColors.inkSoft;
  }
}

class ProductScaffold extends StatelessWidget {
  const ProductScaffold({
    super.key,
    required this.body,
    this.footer,
    this.title,
    this.background,
    this.showBack = true,
    this.trailing,
  });

  final Widget body;
  final Widget? footer;
  final String? title;
  final Color? background;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    return Scaffold(
      backgroundColor: background ?? JourneyColors.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (controller.offline) const OfflineBanner(),
            if (showBack || title != null || trailing != null)
              SizedBox(
                height: 52,
                child: NavigationToolbar(
                  leading: showBack
                      ? IconButton(
                          tooltip: 'Back',
                          onPressed: () {
                            final navigator = Navigator.of(context);
                            if (navigator.canPop()) {
                              navigator.pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back),
                        )
                      : const SizedBox(width: 8),
                  middle: title == null
                      ? null
                      : Text(
                          title!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                  trailing: trailing ?? const SizedBox(width: 8),
                ),
              ),
            Expanded(child: body),
            if (footer != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: JourneyColors.dune,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        'You\'re offline. You can still swipe and paint dates. We\'ll sync when you\'re back.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: JourneyColors.ink),
      ),
    );
  }
}

class OpenedMarker extends StatefulWidget {
  const OpenedMarker({super.key});

  @override
  State<OpenedMarker> createState() => _OpenedMarkerState();
}

class _OpenedMarkerState extends State<OpenedMarker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        PlanningScope.read(context).markViewerOpened();
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

class QuietButton extends StatelessWidget {
  const QuietButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium,
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.member,
    this.size = 36,
    this.committed = false,
  });

  final Member member;
  final double size;
  final bool committed;

  @override
  Widget build(BuildContext context) {
    final letter = member.name.isEmpty ? '?' : member.name[0];
    final child = member.joined
        ? CircleAvatar(
            radius: size / 2,
            backgroundColor: memberColor(member.id),
            child: Text(
              letter,
              style: TextStyle(
                color: JourneyColors.onAccent,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                fontSize: size * 0.38,
              ),
            ),
          )
        : _DashedAvatar(letter: letter, size: size);
    return Semantics(
      label: member.name,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (committed)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: JourneyColors.card,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: JourneyColors.ink, width: 1.2),
                ),
                child: const Icon(Icons.confirmation_number, size: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _DashedAvatar extends StatelessWidget {
  const _DashedAvatar({required this.letter, required this.size});

  final String letter;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: JourneyColors.inkSoft, width: 1.2),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Outfit',
          color: JourneyColors.inkSoft,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.members, this.onAdd});

  final List<Member> members;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    final shown = members.take(6).toList();
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          for (var index = 0; index < shown.length; index += 1)
            Align(
              widthFactor: 0.72,
              child: PersonAvatar(
                member: shown[index],
                committed: trip?.committed.contains(shown[index].id) ?? false,
              ),
            ),
          if (onAdd != null) ...[
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Invite',
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              style: IconButton.styleFrom(
                backgroundColor: JourneyColors.card,
                side: const BorderSide(color: JourneyColors.line),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CountdownRing extends StatelessWidget {
  const CountdownRing({
    super.key,
    required this.deadline,
    required this.now,
    required this.windowHours,
    this.locked = false,
  });

  final DateTime deadline;
  final DateTime now;
  final int windowHours;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final total = Duration(hours: windowHours);
    final left = deadline.difference(now);
    final remaining = left.inMilliseconds / total.inMilliseconds;
    final sweep = (1 - remaining).clamp(0.0, 1.0);
    final closing = !locked && left <= const Duration(hours: 2);
    final color = locked
        ? JourneyColors.sea
        : closing
        ? JourneyColors.amber
        : JourneyColors.terracotta;
    return SizedBox(
      width: 52,
      height: 52,
      child: CustomPaint(
        painter: _RingPainter(progress: locked ? 1 : sweep, color: color),
        child: Center(
          child: Text(
            locked ? '✓' : ringLabel(deadline, now),
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: color, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..color = JourneyColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(rect.deflate(3), -1.5708, 6.283, false, paint);
    final sweep = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4;
    canvas.drawArc(rect.deflate(3), -1.5708, 6.283 * progress, false, sweep);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class ProgressMeter extends StatelessWidget {
  const ProgressMeter({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final trip = PlanningScope.of(context).trip;
    if (trip == null) {
      return const SizedBox.shrink();
    }
    final locked = trip.locked.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact)
          Text(
            '$locked of 5 locked',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        if (!compact) const SizedBox(height: 8),
        Row(
          children: [
            for (final kind in DecisionKind.values) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: trip.locked.contains(kind)
                            ? JourneyColors.sea
                            : decisionActive(trip, kind) &&
                                  phaseOf(
                                        trip,
                                        kind,
                                        PlanningScope.of(context).now,
                                      ) ==
                                      DecisionPhase.closing
                            ? JourneyColors.amber
                            : JourneyColors.line,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      decisionTitle(kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: trip.locked.contains(kind)
                            ? JourneyColors.ink
                            : JourneyColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (kind != DecisionKind.stay) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class DecisionHeader extends StatelessWidget {
  const DecisionHeader({super.key, required this.kind});

  final DecisionKind kind;

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const SizedBox.shrink();
    }
    final phase = phaseOf(trip, kind, controller.now);
    final deadline = deadlineFor(trip, kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ProgressMeter(compact: true),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(text: decisionTitle(kind)),
                  const SizedBox(height: 4),
                  Text(
                    closesLabel(deadline, controller.now),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: phase == DecisionPhase.closing
                          ? JourneyColors.amber
                          : JourneyColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    defaultLine(trip, kind),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            CountdownRing(
              deadline: deadline,
              now: controller.now,
              windowHours:
                  kind == DecisionKind.activities || kind == DecisionKind.stay
                  ? 24
                  : trip.windowHours,
              locked: phase == DecisionPhase.locked,
            ),
          ],
        ),
      ],
    );
  }
}

class LockedStamp extends StatelessWidget {
  const LockedStamp({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: JourneyColors.sea, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'LOCKED',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: JourneyColors.sea, letterSpacing: 1.4),
        ),
      ),
    );
  }
}

class SetupStepper extends StatelessWidget {
  const SetupStepper({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    const labels = ['Vibe', 'Draft', 'Crew'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var step = 0; step < labels.length; step += 1) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: step <= index ? JourneyColors.ink : JourneyColors.line,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                labels[step],
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: step == index
                      ? JourneyColors.ink
                      : JourneyColors.inkSoft,
                  fontWeight: step == index ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (step != labels.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text('About 2 minutes', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = JourneyColors.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: JourneyColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class NeedTrip extends StatelessWidget {
  const NeedTrip({super.key});

  @override
  Widget build(BuildContext context) {
    return ProductScaffold(
      title: 'JourneyGo',
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Start with a vibe.',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Every trip starts from a draft, never a blank page.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      footer: PrimaryButton(
        label: 'Plan a getaway',
        onPressed: () {
          PlanningScope.read(context).startOver();
        },
      ),
    );
  }
}

String roleLabel(MemberRole role) {
  switch (role) {
    case MemberRole.organiser:
      return 'Organiser';
    case MemberRole.yesPerson:
      return 'Yes-person';
    case MemberRole.reluctant:
      return 'Reluctant friend';
    case MemberRole.budget:
      return 'Budget';
    case MemberRole.planner:
      return 'Planner';
  }
}

String addedByLabel(String? id, TripSession? trip) {
  if (id == null) {
    return 'Suggested';
  }
  final name = trip?.member(id)?.name;
  if (name == null) {
    return 'Added by the group';
  }
  return 'Added by $name';
}

class RollingNumber extends StatefulWidget {
  const RollingNumber({
    super.key,
    required this.value,
    this.style,
    this.prefix = '\$',
  });

  final int value;
  final TextStyle? style;
  final String prefix;

  @override
  State<RollingNumber> createState() => _RollingNumberState();
}

class _RollingNumberState extends State<RollingNumber> {
  late int _from;

  @override
  void initState() {
    super.initState();
    _from = widget.value;
  }

  @override
  void didUpdateWidget(RollingNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    _from = oldWidget.value;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final style = widget.style;
    if (reduce || _from == widget.value) {
      return Text('${widget.prefix}${widget.value}', style: style);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: _from.toDouble(), end: widget.value.toDouble()),
      duration: const Duration(milliseconds: 180),
      builder: (context, value, _) {
        return Text('${widget.prefix}${value.round()}', style: style);
      },
    );
  }
}
