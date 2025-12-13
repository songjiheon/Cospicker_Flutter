import 'package:flutter/material.dart';


class BottomNavItem extends StatelessWidget {
  final String label;
  final String asset;
  final VoidCallback onTap;

  const BottomNavItem({
    super.key,
    required this.label,
    required this.asset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(asset, width: 28, height: 28),
          SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}



