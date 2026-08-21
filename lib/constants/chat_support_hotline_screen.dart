import 'package:flutter/material.dart';
import 'package:asin_alert/constants/tabs/hotlines_tab.dart';
import 'package:asin_alert/constants/tabs/live_support_tab.dart';

class ChatSupportHotlineScreen extends StatefulWidget {
  const ChatSupportHotlineScreen({super.key});

  @override
  State<ChatSupportHotlineScreen> createState() => _ChatSupportHotlineScreenState();
}

class _ChatSupportHotlineScreenState extends State<ChatSupportHotlineScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color surfaceSlate = Color(0xFFF8FAFC);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceSlate,
      appBar: AppBar(
        backgroundColor: primaryNavy,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Support & Hotlines',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF38BDF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.phone_in_talk_rounded, size: 18),
              text: 'Hotlines',
            ),
            Tab(
              icon: Icon(Icons.confirmation_number_outlined, size: 18),
              text: 'Support Tickets',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HotlinesTab(),
          LiveSupportTab(),
        ],
      ),
    );
  }
}