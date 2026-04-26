import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/supabase_config.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  RealtimeChannel? _channel;

  // Status flow for the dropdown
  final List<String> _statusOptions = [
    'received',
    'confirmed',
    'out_for_delivery',
    'delivered',
  ];

  final Map<String, Color> _statusColors = {
    'received':         const Color(0xFF6366F1),
    'confirmed':        const Color(0xFFF59E0B),
    'out_for_delivery': const Color(0xFF0284C7),
    'delivered':        const Color(0xFF059669),
  };

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _subscribeToOrders();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final response = await supabase
          .from('orders')
          .select('id, total, status, delivery_address, created_at, customer_id')
          .order('created_at', ascending: false);

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
    _channel = supabase
        .channel('admin_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (payload) {
            print('🔔 Orders table changed — refreshing');
            _loadOrders();
          },
        )
        .subscribe();
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    try {
      await supabase
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      print('✅ Order $orderId updated to $newStatus');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Order updated to ${newStatus.replaceAll('_', ' ')}'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      print('❌ Failed to update order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Manage orders'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _orders.isEmpty
              ? const Center(child: Text('No orders yet'))
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) =>
                        _buildOrderCard(_orders[index]),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'].toString().substring(0, 8).toUpperCase();
    final status = order['status'] as String;
    final total = (order['total'] as num).toDouble();
    final address = order['delivery_address'] as String? ?? '';
    final isDelivery = address != 'Pickup';
    final color = _statusColors[status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order ID and total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#$id',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              Text('KES ${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
            ],
          ),
          const SizedBox(height: 6),

          // Delivery info
          Row(
            children: [
              Icon(
                isDelivery ? Icons.delivery_dining : Icons.store,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  isDelivery ? address : 'Store pickup',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status badge + dropdown to change status
          Row(
            children: [
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
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Spacer(),

              // Status update dropdown
              DropdownButton<String>(
                value: status,
                underline: const SizedBox(),
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A2E),
                    fontWeight: FontWeight.w500),
                icon: const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: Color(0xFF1A1A2E)),
                items: _statusOptions.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s.replaceAll('_', ' ')),
                  );
                }).toList(),
                onChanged: (newStatus) {
                  if (newStatus != null && newStatus != status) {
                    _updateStatus(order['id'].toString(), newStatus);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}