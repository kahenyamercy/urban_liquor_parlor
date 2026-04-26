import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  RealtimeChannel? _channel;

  // Status flow — order they appear in the UI
  final List<String> _statusSteps = [
    'received',
    'confirmed',
    'out_for_delivery',
    'delivered',
  ];

  final Map<String, String> _statusLabels = {
    'received':         'Order received',
    'confirmed':        'Confirmed',
    'out_for_delivery': 'Out for delivery',
    'delivered':        'Delivered',
  };

  final Map<String, IconData> _statusIcons = {
    'received':         Icons.receipt_long_outlined,
    'confirmed':        Icons.check_circle_outline,
    'out_for_delivery': Icons.delivery_dining,
    'delivered':        Icons.home_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadOrder();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    // Always unsubscribe when leaving the screen
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      print('📡 Loading order: ${widget.orderId}');

      // Fetch order
      final orderResponse = await supabase
          .from('orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      // Fetch order items joined with product names
      final itemsResponse = await supabase
          .from('order_items')
          .select('quantity, unit_price, products(name)')
          .eq('order_id', widget.orderId);

      print('✅ Order loaded. Status: ${orderResponse['status']}');
      print('✅ Items loaded: ${itemsResponse.length}');

      setState(() {
        _order = orderResponse;
        _items = List<Map<String, dynamic>>.from(itemsResponse);
        _loading = false;
      });
    } catch (e) {
      print('❌ Error loading order: $e');
      setState(() {
        _error = 'Could not load order details.';
        _loading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    print('📡 Subscribing to realtime updates for order: ${widget.orderId}');

    _channel = supabase
        .channel('order_${widget.orderId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.orderId,
          ),
          callback: (payload) {
            print('🔔 Realtime update received: ${payload.newRecord}');
            if (mounted) {
              setState(() {
                _order = payload.newRecord;
              });

              // Show a snackbar when status changes
              final newStatus = payload.newRecord['status'] as String;
              final label = _statusLabels[newStatus] ?? newStatus;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Status updated: $label'),
                  backgroundColor: const Color(0xFF059669),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
        )
        .subscribe((status, [error]) {
          print('📡 Realtime channel status: $status');
          if (error != null) print('❌ Realtime error: $error');
        });
  }

  int _getStepIndex(String status) {
    final index = _statusSteps.indexOf(status);
    return index >= 0 ? index : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('Track order'),
        elevation: 0,
        // Prevent going back to confirmation screen
        leading: IconButton(
          icon: const Icon(Icons.home_outlined),
          onPressed: () => Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (_) => false,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1A1A2E)))
          : _error != null
              ? Center(child: Text(_error!))
              : _buildTracking(),
    );
  }

  Widget _buildTracking() {
    final status = _order?['status'] as String? ?? 'received';
    final currentStep = _getStepIndex(status);
    final isDelivery = _order?['delivery_address'] != 'Pickup';
    final address = _order?['delivery_address'] as String? ?? '';
    final total = (_order?['total'] as num?)?.toDouble() ?? 0;
    final orderId = widget.orderId.substring(0, 8).toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Order ID header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long,
                    color: Color(0xFF1A1A2E), size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #$orderId',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  Text(
                    isDelivery ? 'Delivery to $address' : 'Store pickup',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Status tracker
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Order status',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 20),
              ..._statusSteps.asMap().entries.map((entry) {
                final stepIndex = entry.key;
                final stepStatus = entry.value;
                final isDone = stepIndex <= currentStep;
                final isActive = stepIndex == currentStep;
                final isLast = stepIndex == _statusSteps.length - 1;

                return _buildStatusStep(
                  label: _statusLabels[stepStatus] ?? stepStatus,
                  icon: _statusIcons[stepStatus] ?? Icons.circle,
                  isDone: isDone,
                  isActive: isActive,
                  isLast: isLast,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Order items
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Items ordered',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E)),
              ),
              const SizedBox(height: 12),
              ..._items.map((item) {
                final name = (item['products'] as Map?)?['name'] ?? 'Product';
                final qty = item['quantity'] as int;
                final price = (item['unit_price'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Text('$qty×',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(name,
                              style: const TextStyle(fontSize: 14))),
                      Text(
                        'KES ${(price * qty).toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'KES ${total.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Realtime indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'Live updates active',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusStep({
    required String label,
    required IconData icon,
    required bool isDone,
    required bool isActive,
    required bool isLast,
  }) {
    final color = isDone ? const Color(0xFF059669) : Colors.grey.shade300;
    final textColor = isDone
        ? const Color(0xFF1A1A2E)
        : Colors.grey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon + vertical line
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(0xFF059669).withOpacity(0.1)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Icon(icon,
                  size: 20,
                  color: isDone ? const Color(0xFF059669) : Colors.grey),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: color,
              ),
          ],
        ),
        const SizedBox(width: 14),

        // Label
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                  color: textColor,
                  fontSize: 14,
                ),
              ),
              if (isActive)
                const Text(
                  'Current status',
                  style: TextStyle(
                      color: Color(0xFF059669), fontSize: 11),
                ),
            ],
          ),
        ),
      ],
    );
  }
}