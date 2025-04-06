import 'dart:math';

import 'package:flutter/material.dart';

enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary;

  Color get color {
    switch (this) {
      case Rarity.common:
        return Colors.green;
      case Rarity.uncommon:
        return Colors.blue;
      case Rarity.rare:
        return Colors.purple;
      case Rarity.epic:
        return Colors.red;
      case Rarity.legendary:
        return Colors.orange;
    }
  }

  String get description {
    switch (this) {
      case Rarity.common:
        return 'Frequently spotted species.';
      case Rarity.uncommon:
        return 'Less common species.';
      case Rarity.rare:
        return 'Species that are rarely spotted.';
      case Rarity.epic:
        return 'Incredibly rare species.';
      case Rarity.legendary:
        return 'Unique or endangered species.';
    }
  }

  int get points {
    switch (this) {
      case Rarity.common:
        return 10;
      case Rarity.uncommon:
        return 25;
      case Rarity.rare:
        return 50;
      case Rarity.epic:
        return 100;
      case Rarity.legendary:
        return 250;
    }
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);

  static Rarity fromString(String? rarity) {
    if (rarity == null) return Rarity.values[Random().nextInt(Rarity.values.length)];

    try {
      return Rarity.values.firstWhere(
            (r) => r.name.toLowerCase() == rarity.toLowerCase(),
      );
    } catch (_) {
      return Rarity.common;
    }
  }
}