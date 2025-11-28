import 'package:flutter/material.dart';
import 'package:safechild_system/features/home/presentation/policy_settings_screen.dart';

class _ContentModerationCard extends StatefulWidget {
  const _ContentModerationCard();

  @override
  State<_ContentModerationCard> createState() => _ContentModerationCardState();
}

class _ContentModerationCardState extends State<_ContentModerationCard> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'إدارة المحتوى',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: Color(0xFF28323B),
                ),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PolicySettingsScreen()),
                );
              },
              icon: const Icon(Icons.settings_outlined, size: 18),
              label: const Text(
                'فتح الإعدادات',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
