import 'package:asin_alert/services/police_service.dart';
import 'package:asin_alert/widgets/police/resolved_emergency_card.dart';
import 'package:flutter/material.dart';

class PoliceHistoryScreen extends StatefulWidget {
  const PoliceHistoryScreen({super.key});

  @override
  State<PoliceHistoryScreen> createState() => _PoliceHistoryScreenState();
}

class _PoliceHistoryScreenState extends State<PoliceHistoryScreen> {
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color accentGold = Color(0xFFD97706);

  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  List<String> _categories = ['ALL'];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await PoliceService.fetchCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildFilterHeader(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: PoliceService.streamEmergencyHistory(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryNavy),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.red),
                        SizedBox(height: 12),
                        Text(
                          'Failed to load your resolved history.',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final rawList = snapshot.data ?? [];

                final filteredList = rawList.where((alert) {
                  final category =
                      (alert['category'] ?? '').toString().toUpperCase();
                  final notes =
                      (alert['notes'] ?? '').toString().toLowerCase();
                  final id = (alert['id'] ?? '').toString().toLowerCase();
                  final establishment = (alert['establishment_name'] ?? '')
                      .toString()
                      .toLowerCase();
                  final address = (alert['address'] ?? '')
                      .toString()
                      .toLowerCase();

                  final query = _searchQuery.toLowerCase();

                  final matchesCategory = _selectedCategory == 'ALL' ||
                      category == _selectedCategory;

                  final matchesQuery = query.isEmpty ||
                      notes.contains(query) ||
                      id.contains(query) ||
                      category.toLowerCase().contains(query) ||
                      establishment.contains(query) ||
                      address.contains(query);

                  return matchesCategory && matchesQuery;
                }).toList();

                if (filteredList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final alertData = filteredList[index];

                    return ResolvedEmergencyCard(
                      alert: alertData, onTap: () {  },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by establishment, address, or category...',
              hintStyle:
                  const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: primaryNavy),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryNavy, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _isLoadingCategories
              ? const SizedBox(
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryNavy),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                          },
                          selectedColor: primaryNavy,
                          backgroundColor: const Color(0xFFF1F5F9),
                          checkmarkColor: accentGold,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF475569),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: isSelected
                                  ? primaryNavy
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'NO RESOLVED RECORDS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'You have not resolved any emergencies yet.',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}