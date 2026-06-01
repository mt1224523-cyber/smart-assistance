import 'package:flutter/material.dart';

class Suggestion {
  final String text;
  final String category;
  final IconData icon;

  const Suggestion({
    required this.text,
    required this.category,
    required this.icon,
  });

  static const List<Suggestion> defaultSuggestions = [
    Suggestion(
      text: 'Comment démarrer un petit commerce?',
      category: 'Business',
      icon: Icons.business,
    ),
    Suggestion(
      text: 'Quel est le prix du riz aujourd\'hui?',
      category: 'Prix',
      icon: Icons.price_change,
    ),
    Suggestion(
      text: 'Comment traiter le paludisme?',
      category: 'Santé',
      icon: Icons.health_and_safety,
    ),
    Suggestion(
      text: 'Idée de business à Abidjan',
      category: 'Business',
      icon: Icons.lightbulb,
    ),
    Suggestion(
      text: 'Comment cultiver le manioc?',
      category: 'Agriculture',
      icon: Icons.grass,
    ),
    Suggestion(
      text: 'Conseils pour réussir un entretien',
      category: 'Carrière',
      icon: Icons.work,
    ),
  ];
}
