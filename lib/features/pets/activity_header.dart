import 'package:flutter/material.dart';
import 'pet_mascot.dart';

class ActivityHeader extends StatelessWidget {
  const ActivityHeader(
      {super.key,
      required this.species,
      required this.activity,
      required this.title,
      required this.description,
      required this.color});
  final String species, title, description;
  final MascotActivity activity;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 16),
        color: color,
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              PetMascot(species: species, size: 80, activity: activity),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(description),
                  ])),
            ])),
      );
}
