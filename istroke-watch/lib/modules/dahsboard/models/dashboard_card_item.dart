import 'package:flutter/material.dart';

class DashboardCardItem {
  final IconData icon;
  final String label;
  final void Function()? onPressed;

  const DashboardCardItem({required this.icon, required this.label, required this.onPressed});
}
