import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';
import '../login_screen.dart';

class RiderScreen extends StatefulWidget {
  const RiderScreen({super.key});

  @override
  State<RiderScreen> createState() => _RiderScreenState();
}

class _RiderScreenState extends State<RiderScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _riderName;
  RealtimeChannel? _channel;

  final Map<String, Color> _statusColors = {
    'received':         const Color(0xFF6366F1),
    'confirmed':        const Color(0xFFF59E0B),
    'out_for_delivery': const Color(0xFF0284C7),
    'delivered':        const Color(0xFF059669),
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadOrders();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final profile = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .single();
      setState(() => _riderName = profile['full_name'] as String?);
    } catch (e) {
      print('❌ Error loading profile: $e');
    }
  }

  Future<void> _loadOrders() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      print('🛵 Loading orders for rider: $userId');

      // Only fetch orders assigned to this rider
      // that are not yet delivered
      final response = await supabase
          .from('orders')
          .select('id, total, status, delivery_address, created_at')
          .eq('rider_id', userId)
          .neq('status', 'delivered')
          .order('created_at', ascending: false);

      print('✅ Active orders: ${response.length}');

      setState(() {
        _orders = List<Map<String, dynamic>>.from(response);
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading orders: $e');
      setState(() => _loading = false);
    }
  }

  void _subscribeToOrders() {
    final userId = supabase.auth.currentUser!.id;

    _channel = supabase
        .channel('rider_orders_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'rider_id',
            value: userId,
          ),
          callback: (payload) {
            print('🔔 Order assigned/updated — refreshing');
            _loadOrders();

            // Show snackbar when new order assigned
            if (payload.eventType == PostgresChangeEvent.update &&
                mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('New order assigned to you!'),
                  backgroundColor: Color(0xFF0284C7),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  Future<void> _markDelivered(String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm delivery'),
        content: const Text(
            'Mark this order as delivered? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF059669)),
            child: const Text('Mark delivered'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase
          .from('orders')
          .update({'status': 'delivered'})
          .eq('id', orderId);

      print('✅ Order $orderId marked as delivered');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as delivered!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }

      // Remove from list immediately
      setState(() {
        _orders.removeWhere((o) => o['id'] == orderId);
      });
    } catch (e) {
      print('❌ Failed to mark delivered: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
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

  String _formatDate(String isoString) {
    final date = DateTime.parse(isoString).toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final min  = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} · $hour:$min';
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
                      onRefresh: _loadOrders,
                      child: _orders.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _orders.length,
                              itemBuilder: (context, index) =>
                                  _buildOrderCard(_orders[index]),
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
      color: const Color(0xFF0284C7),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining,
              color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _riderName != null ? 'Hi, $_riderName' : 'Rider panel',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_orders.length} active order${_orders.length == 1 ? '' : 's'}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout,
                color: Colors.white, size: 20),
            onPressed: _signOut,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delivery_dining,
                size: 40, color: Color(0xFF0284C7)),
          ),
          const SizedBox(height: 16),
          const Text('No active deliveries',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          const Text('New orders will appear here when assigned',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id      = order['id'].toString().substring(0, 8).toUpperCase();
    final status  = order['status'] as String;
    final total   = (order['total'] as num).toDouble();
    final address = order['delivery_address'] as String? ?? 'No address';
    final date    = _formatDate(order['created_at'] as String);
    final color   = _statusColors[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID + status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('#$id',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                            fontSize: 15,
                            color: Color(0xFF1A1A2E))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
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
                  ],
                ),
                const SizedBox(height: 12),

                // Delivery address — most important info for rider
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF0284C7)
                            .withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF0284C7), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Date and total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(date,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    Text('KES ${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E))),
                  ],
                ),
              ],
            ),
          ),

          // Mark as delivered button
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () =>
                    _markDelivered(order['id'].toString()),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Mark as delivered',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}