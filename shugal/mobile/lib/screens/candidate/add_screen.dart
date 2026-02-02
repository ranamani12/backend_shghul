import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.work,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),

                // Notification Icon
                const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),

          // 🔹 WHITE CONTENT AREA
          Expanded(
            child: Container(margin:EdgeInsets.only(top: 0),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    width: 60,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
