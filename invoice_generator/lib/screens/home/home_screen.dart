import 'package:flutter/material.dart';

import '../../models/company_model.dart';
import '../../services/hive_service.dart';
import '../../theme/app_theme.dart';
import '../about/about_screen.dart';
import '../company_settings/company_settings_screen.dart';
import '../history/invoice_history_screen.dart';
import '../invoice/create_invoice_screen.dart';

/// Main navigation hub of the app, shown after splash (once Company
/// Settings has been completed at least once).
///
/// Displays the business name/logo and four primary destinations:
/// Create Invoice, Invoice History, Company Settings, and About. Kept
/// deliberately simple — this screen's only job is navigation, not
/// business logic, matching the "separate UI from business logic"
/// requirement.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CompanyModel? _company;

  @override
  void initState() {
    super.initState();
    _loadCompany();
  }

  /// Re-reads the company profile every time this screen becomes visible
  /// (see [_HomeScreenState.didChangeDependencies] is not enough on its
  /// own — we explicitly reload after returning from Settings too, via
  /// [_openSettings]'s `.then()`), so an edited company name/logo shows
  /// up immediately without requiring an app restart.
  void _loadCompany() {
    setState(() {
      _company = HiveService.getCompanyProfile();
    });
  }

  void _openSettings() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) =>
                const CompanySettingsScreen(isFirstTimeSetup: false),
          ),
        )
        .then((_) => _loadCompany()); // Refresh in case name/logo changed.
  }

  @override
  Widget build(BuildContext context) {
    final companyName = _company?.companyName.isNotEmpty == true
        ? _company!.companyName
        : 'Your Business';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Company Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _CompanyHeader(companyName: companyName, company: _company),
            const SizedBox(height: 28),
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.add_circle_outline_rounded,
              iconColor: AppTheme.accentOrange,
              title: 'Create Invoice',
              subtitle: 'Generate a new professional invoice',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateInvoiceScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.history_rounded,
              iconColor: AppTheme.primaryBlue,
              title: 'Invoice History',
              subtitle: 'View, edit, or reprint past invoices',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const InvoiceHistoryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.business_outlined,
              iconColor: AppTheme.successGreen,
              title: 'Company Settings',
              subtitle: 'Manage your business profile',
              onTap: _openSettings,
            ),
            const SizedBox(height: 12),
            _HomeActionCard(
              icon: Icons.info_outline_rounded,
              iconColor: Colors.grey.shade600,
              title: 'About',
              subtitle: 'App info and version',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Header card showing the business name and, if available, a small
/// completeness hint — extracted as a private widget to keep [build]
/// readable and to make it independently reusable/testable.
class _CompanyHeader extends StatelessWidget {
  const _CompanyHeader({required this.companyName, required this.company});

  final String companyName;
  final CompanyModel? company;

  @override
  Widget build(BuildContext context) {
    final isComplete = company?.isProfileComplete ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: AppTheme.primaryBlue,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isComplete
                      ? 'Ready to create invoices'
                      : 'Complete your profile in Settings',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable tappable action card used for every Home screen destination.
/// Extracting this avoids duplicating the same Card/InkWell/Row structure
/// four times ("No duplicated code" per the brief).
class _HomeActionCard extends StatelessWidget {
  const _HomeActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
