import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Bill Generator',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Version $appVersion',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 28),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Bill Generator is a fully offline invoicing app built '
                  'for small businesses and independent professionals. '
                  'Create professional invoices, manage your company '
                  'profile, and generate print-ready PDFs — all without '
                  'requiring an internet connection.',
                  style: TextStyle(height: 1.5, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    SizedBox(height: 10),
                    _FeatureRow(text: 'Fully offline — your data never leaves your device'),
                    _FeatureRow(text: 'Professional, print-ready PDF invoices'),
                    _FeatureRow(text: 'Complete invoice history with search'),
                    _FeatureRow(text: 'Dark mode support'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© ${DateTime.now().year} Bill Generator',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: AppTheme.successGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13.5, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
