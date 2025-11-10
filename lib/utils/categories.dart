import 'package:flutter/material.dart';

/// Event marketplace categories
/// This file must match the Provider app categories exactly
class EventCategory {
  final String id;
  final String name;
  final IconData icon;
  final Color color;

  const EventCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
  });
}

/// All available categories
class EventCategories {
  // Category IDs (used in database)
  static const String venuesHallsId = 'venues_halls';
  static const String campingPartiesId = 'camping_parties';
  static const String funeralsId = 'funerals';

  // Category objects
  static const EventCategory venuesHalls = EventCategory(
    id: venuesHallsId,
    name: 'Venues & Halls',
    icon: Icons.business,
    color: Color(0xFF2196F3), // Blue
  );

  static const EventCategory campingParties = EventCategory(
    id: campingPartiesId,
    name: 'Camping & Parties & Celebrations',
    icon: Icons.celebration,
    color: Color(0xFFFF9800), // Orange
  );

  static const EventCategory funerals = EventCategory(
    id: funeralsId,
    name: 'Funerals',
    icon: Icons.mosque, // Mosque icon
    color: Color(0xFF607D8B), // Blue Grey
  );

  // List of all categories
  static const List<EventCategory> all = [
    venuesHalls,
    campingParties,
    funerals,
  ];

  // Get category by ID
  static EventCategory? getById(String id) {
    try {
      return all.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get category name by ID
  static String getNameById(String id) {
    final category = getById(id);
    return category?.name ?? 'Unknown Category';
  }

  // Get category icon by ID
  static IconData getIconById(String id) {
    final category = getById(id);
    return category?.icon ?? Icons.category;
  }

  // Get category color by ID
  static Color getColorById(String id) {
    final category = getById(id);
    return category?.color ?? Colors.grey;
  }

  // Get all category IDs
  static List<String> getAllIds() {
    return all.map((category) => category.id).toList();
  }

  // Get all category names
  static List<String> getAllNames() {
    return all.map((category) => category.name).toList();
  }

  // Get map of id to name (useful for dropdowns)
  static Map<String, String> getIdToNameMap() {
    return {
      for (var category in all) category.id: category.name
    };
  }

  // Get map of name to id (useful for reverse lookup)
  static Map<String, String> getNameToIdMap() {
    return {
      for (var category in all) category.name: category.id
    };
  }
}
