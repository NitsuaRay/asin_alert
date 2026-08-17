import 'package:flutter/material.dart';
import '../services/auth_service.dart';

import '../widgets/admin/safety_and_incidents_tab.dart';
import '../widgets/admin/user_management_tab.dart';
import '../widgets/admin/ota_release_tab.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Dark slate
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_rounded, color: Colors.amber),
            SizedBox(width: 10),
            Text(
              'A.S.I.N. Command Center',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
            onPressed: () => AuthService().signOut(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.shield_rounded), text: 'Safety Hub'),
            Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Users & Roles'),
            Tab(icon: Icon(Icons.system_security_update_rounded), text: 'OTA Releases'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SafetyAndIncidentsTab(),
          UserManagementTab(),
          OtaReleaseTab(),
        ],
      ),
    );
  }
}