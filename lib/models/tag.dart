import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'tag.g.dart';

@HiveType(typeId: 0)
class Tag {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int color;

  @HiveField(4)
  String type; // 'income', 'expense', 'withdrawal'

  Tag({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });

  // Helper to get icon data
  IconData getIconData() {
    switch (icon) {
      case 'money':
        return Icons.attach_money;
      case 'gift':
        return Icons.card_giftcard;
      case 'food':
        return Icons.restaurant;
      case 'car':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      case 'atm':
        return Icons.atm;
      case 'home':
        return Icons.home;
      case 'health':
        return Icons.medical_services;
      case 'sports':
        return Icons.sports_soccer;
      case 'travel':
        return Icons.flight;
      case 'bills':
        return Icons.receipt_long;
      case 'phone':
        return Icons.phone_android;
      case 'coffee':
        return Icons.coffee;
      case 'game':
        return Icons.sports_esports;
      case 'music':
        return Icons.music_note;
      case 'circle':
      default:
        return Icons.circle;
    }
  }
}
