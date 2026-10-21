import 'package:flutter/material.dart';

import '../format.dart';
import '../logic/planning_rules.dart';
import '../models/planning.dart';
import '../state/planning_controller.dart';
import '../state/planning_scope.dart';
import '../theme/journey_theme.dart';
import '../widgets/chrome.dart';

class CostLogScreen extends StatefulWidget {
  const CostLogScreen({super.key});

  @override
  State<CostLogScreen> createState() => _CostLogScreenState();
}

class _CostLogScreenState extends State<CostLogScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String? _payer;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = PlanningScope.of(context);
    final trip = controller.trip;
    if (trip == null) {
      return const NeedTrip();
    }
    final payer = _payer ?? trip.viewerId ?? trip.organiser.id;
    final transfers = transfersFor(
      trip,
      simplified: controller.simplifyPayments,
    );
    final logged = loggedTotal(trip);
    final estimate = sharedEstimate(trip);
    final text = Theme.of(context).textTheme;
    final viewerNet = _net(trip, trip.viewerId);
    return ProductScaffold(
      title: 'Settle up',
      body: ListView(
        key: const Key('cost-log'),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const PaperCard(
            color: JourneyColors.dune,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Eyebrow(text: 'Possible v2'),
                SizedBox(height: 6),
                Text(
                  'A shared cost log for after the trip is confirmed. Nothing here moves money.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Estimate ${money(estimate)} each · Logged ${money(logged)} so far',
            style: text.titleSmall,
          ),
          const SizedBox(height: 12),
          if (trip.costs.isEmpty)
            const Text('Nothing logged yet. The estimate still stands.')
          else ...[
            for (final cost in trip.costs.reversed)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${cost.title} · ${money(cost.amount)}'),
                subtitle: Text(
                  '${_name(trip, cost.addedById)}, ${agoLabel(cost.addedAt, controller.now)} · paid by ${_name(trip, cost.payerId)}',
                ),
              ),
            const SizedBox(height: 8),
            Text(_balanceLine(viewerNet), style: text.titleMedium),
          ],
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fewest payments'),
            subtitle: const Text(
              'Combine what people owe so fewer transfers settle the trip.',
            ),
            value: controller.simplifyPayments,
            onChanged: controller.setSimplify,
          ),
          if (trip.costs.isNotEmpty && transfers.isEmpty)
            const Text('Everyone\'s square.')
          else
            for (final transfer in transfers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${_name(trip, transfer.fromId)} pays ${_name(trip, transfer.toId)} ${money(transfer.amount)}',
                ),
                trailing: TextButton(
                  key: Key('mark-paid-${transfer.fromId}-${transfer.toId}'),
                  onPressed: () => controller.markPaid(transfer),
                  child: const Text('Mark paid'),
                ),
              ),
          const SizedBox(height: 16),
          Text('Add a cost', style: text.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              const ChoiceChip(
                label: Text('Type'),
                selected: true,
                onSelected: _noop,
              ),
              ChoiceChip(
                label: const Text('Voice'),
                selected: false,
                onSelected: (_) =>
                    controller.note('Voice arrives in a later version.'),
              ),
              ChoiceChip(
                label: const Text('Scan'),
                selected: false,
                onSelected: (_) =>
                    controller.note('Scan arrives in a later version.'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Voice and scan arrive in a later version.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('cost-title'),
            controller: _title,
            decoration: const InputDecoration(hintText: 'What was it?'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('cost-amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Amount'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: payer,
            decoration: const InputDecoration(labelText: 'Paid by'),
            items: [
              for (final member in trip.joined)
                if (!trip.optOutReasons.containsKey(member.id))
                  DropdownMenuItem(value: member.id, child: Text(member.name)),
            ],
            onChanged: (value) => setState(() => _payer = value),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            key: const Key('cost-add'),
            label: 'Add cost',
            onPressed: () => _add(controller, payer),
          ),
        ],
      ),
    );
  }

  void _add(PlanningController controller, String payer) {
    final amount = int.tryParse(_amount.text.trim());
    if (amount == null) {
      controller.note('Add a name and an amount.');
      return;
    }
    controller.addCost(title: _title.text, amount: amount, payerId: payer);
    _title.clear();
    _amount.clear();
  }

  String _name(TripSession trip, String id) {
    final person = trip.member(id);
    if (person == null) {
      return 'Someone';
    }
    if (id == trip.viewerId) {
      return 'You';
    }
    return person.name;
  }

  String _balanceLine(int net) {
    if (net > 0) {
      return 'You\'re owed ${money(net)}';
    }
    if (net < 0) {
      return 'You owe ${money(-net)}';
    }
    return 'You\'re square';
  }

  int _net(TripSession trip, String? memberId) {
    if (memberId == null) {
      return 0;
    }
    final members = [
      for (final member in trip.joined)
        if (!trip.optOutReasons.containsKey(member.id)) member.id,
    ];
    if (!members.contains(memberId) || members.isEmpty) {
      return 0;
    }
    var net = 0;
    for (final cost in trip.costs) {
      final shares = _shares(cost.amount, members.length);
      final index = members.indexOf(memberId);
      net -= shares[index];
      if (cost.payerId == memberId) {
        net += cost.amount;
      }
    }
    for (final settlement in trip.settlements) {
      if (settlement.fromId == memberId) {
        net += settlement.amount;
      }
      if (settlement.toId == memberId) {
        net -= settlement.amount;
      }
    }
    return net;
  }

  List<int> _shares(int amount, int count) {
    final base = amount ~/ count;
    final extra = amount % count;
    return [
      for (var index = 0; index < count; index += 1)
        base + (index < extra ? 1 : 0),
    ];
  }
}

void _noop(bool _) {}
