import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool large;

  const RoundedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.primary;
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: large ? 28 : 18),
      label: Padding(
        padding: EdgeInsets.symmetric(vertical: large ? 14 : 10),
        child: Text(
          label,
          style: TextStyle(
            fontSize: large ? 18 : 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 22),
        elevation: 6,
      ),
    );
  }
}
