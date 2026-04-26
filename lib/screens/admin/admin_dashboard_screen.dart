import 'package:flutter/material.dart';

import '../../config/supabase_config.dart';
import '../login_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_products_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stats = {
    'totalOrders': 0,
    'pendingOrders': 0,
    'todayRevenue': 0.0,
    'totalRevenue': 0.0,
  };
  List<Map<String, dynamic>> _recentOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      print('📊 Loading admin stats...');

      // All orders
      final allOrders = await supabase
          .from('orders')
          .select('id, total, status, created_at');

      // Today's orders
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day)
          .toIso8601String();

      final todayOrders = (allOrders as List).where((o) {
        final created = DateTime.parse(o['created_at'] as String);
        return created.isAfter(DateTime.parse(todayStart));
      }).toList();

      final pendingOrders = allOrders.where((o) =>
          o['status'] == 'received' || o['status'] == 'confirmed').toList();

      final totalRevenue = allOrders.fold<double>(
          0, (sum, o) => sum + (o['total'] as num).toDouble());

      final todayRevenue = todayOrders.fold<double>(
          0, (sum, o) => sum + (o['total'] as num).toDouble());

      // Recent 5 orders
      final recent = await supabase
          .from('orders')
          .select('id, total, status, created_at, delivery_address')
          .order('created_at', ascending: false)
          .limit(5);

      print('✅ Stats loaded. Total orders: ${allOrders.length}');

      setState(() {
        _stats = {
          'totalOrders': allOrders.length,
          'pendingOrders': pendingOrders.length,
          'todayRevenue': todayRevenue,
          'totalRevenue': totalRevenue,
        };
        _recentOrders = List<Map<String, dynamic>>.from(recent);
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading stats: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1A1A2E)))
                  : RefreshIndicator(
                      onRefresh: _loadStats,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildStatsGrid(),
                          const SizedBox(height: 20),
                          _buildQuickActions(),
                          const SizedBox(height: 20),
                          _buildRecentOrders(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      color: const Color(0xFF1A1A2E),
      child: Row(
        children: [
          const Icon(Icons.admin_panel_settings,
              color: Colors.white, size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Admin panel',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Urban Liquor Parlor',
                    style: TextStyle(
                        color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white, size: 20),
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Total orders',
            '${_stats['totalOrders']}',
            Icons.receipt_long, const Color(0xFF6366F1)),
        _statCard('Pending',
            '${_stats['pendingOrders']}',
            Icons.hourglass_top, const Color(0xFFF59E0B)),
        _statCard('Today\'s revenue',
            'KES ${(_stats['todayRevenue'] as double).toStringAsFixed(0)}',
            Icons.today, const Color(0xFF059669)),
        _statCard('Total revenue',
            'KES ${(_stats['totalRevenue'] as double).toStringAsFixed(0)}',
            Icons.bar_chart, const Color(0xFF1A1A2E)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            label: 'Manage orders',
            icon: Icons.list_alt,
            color: const Color(0xFF6366F1),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminOrdersScreen()),
            ).then((_) => _loadStats()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _actionButton(
            label: 'Manage products',
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFF059669),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AdminProductsScreen()),
            ).then((_) => _loadStats()),
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders() {
    if (_recentOrders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent orders',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 12),
        ..._recentOrders.map((order) => _buildOrderRow(order)),
      ],
    );
  }

  Widget _buildOrderRow(Map<String, dynamic> order) {
    final id = order['id'].toString().substring(0, 8).toUpperCase();
    final status = order['status'] as String;
    final total = (order['total'] as num).toDouble();

    final statusColors = {
      'received':         const Color(0xFF6366F1),
      'confirmed':        const Color(0xFFF59E0B),
      'out_for_delivery': const Color(0xFF0284C7),
      'delivered':        const Color(0xFF059669),
    };
    final color = statusColors[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Text('#$id',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.replaceAll('_', ' '),
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 10),
          Text('KES ${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}