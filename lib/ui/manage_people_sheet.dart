import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../domain/models/plan.dart';

/// Add or remove people from an existing plan.
///
/// Rules: a plan keeps at least 2 people, and a person who already appears in
/// an expense or payment can't be removed until those are gone.
class ManagePeopleSheet extends ConsumerStatefulWidget {
  final String planId;

  const ManagePeopleSheet({super.key, required this.planId});

  @override
  ConsumerState<ManagePeopleSheet> createState() => _ManagePeopleSheetState();
}

class _ManagePeopleSheetState extends ConsumerState<ManagePeopleSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Set<String> _involvedIds(Plan plan) {
    final ids = <String>{};
    for (final e in plan.expenses) {
      ids.add(e.payerId);
      ids.addAll(e.shares.keys);
    }
    for (final p in plan.payments) {
      ids
        ..add(p.fromId)
        ..add(p.toId);
    }
    return ids;
  }

  void _add(String planId) {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    ref.read(plansProvider.notifier).addPerson(planId, name);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = ref
        .watch(plansProvider)
        .maybeWhen(
          data: (plans) {
            final matches = plans.where((p) => p.id == widget.planId);
            return matches.isEmpty ? null : matches.first;
          },
          orElse: () => null,
        );

    if (plan == null) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final involved = _involvedIds(plan);
    final canRemove = plan.people.length > 2;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'People',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView(
              shrinkWrap: true,
              children: plan.people.map((person) {
                final isInvolved = involved.contains(person.id);
                final removable = canRemove && !isInvolved;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(person.name),
                  subtitle: isInvolved
                      ? const Text('Has expenses — remove those first')
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: removable
                        ? () => ref
                              .read(plansProvider.notifier)
                              .removePerson(plan.id, person.id)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          TextField(
            controller: _controller,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'Add person',
              hintText: 'Caro',
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _add(plan.id),
              ),
            ),
            onSubmitted: (_) => _add(plan.id),
          ),
        ],
      ),
    );
  }
}
