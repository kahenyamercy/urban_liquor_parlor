import 'package:flutter/material.dart';

import '../config/supabase_config.dart';
import '../services/cart_service.dart';
import 'order_confirmation_screen.dart';
import 'mpesa_payment_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _cart = CartService();
  final _addressController = TextEditingController();
  bool _isDelivery = true;
  bool _placingOrder = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

 Future<void> _placeOrder() async {
  if (_isDelivery && _addressController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter your delivery address')),
    );
    return;
  }

  if (_cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your cart is empty')),
    );
    return;
  }

  setState(() => _placingOrder = true);

  try {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    print('🛒 Creating order for user: ${user.id}');

    final orderResponse = await supabase
        .from('orders')
        .insert({
          'customer_id':      user.id,
          'total':            _cart.totalPrice,
          'status':           'received',
          'payment_status':   'unpaid',
          'delivery_address': _isDelivery
              ? _addressController.text.trim()
              : 'Pickup',
        })
        .select()
        .single();

    final orderId = orderResponse['id'].toString();
    print('✅ Order created: $orderId');

    final orderItems = _cart.items.map((item) => {
      'order_id':   orderId,
      'product_id': item.product.id,
      'quantity':   item.quantity,
      'unit_price': item.product.price,
    }).toList();

    await supabase.from('order_items').insert(orderItems);
    print('✅ Order items saved');

    final amount = _cart.totalPrice;
    _cart.clear();

    if (!mounted) return;

    // Go to M-Pesa payment screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MpesaPaymentScreen(
          orderId: orderId,
          amount:  amount,
        ),
      ),
    );
  } catch (e) {
    print('❌ Order failed: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order failed: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _placingOrder = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: const Text('My cart'),
        elevation: 0,
      ),
      body: _cart.isEmpty ? _buildEmptyCart() : _buildCart(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Browse products'),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        // Cart items list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ..._cart.items.map((item) => _buildCartItem(item)),
              const SizedBox(height: 16),

              // Delivery toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fulfilment method',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _toggleOption(
                            label: 'Delivery',
                            icon: Icons.delivery_dining,
                            selected: _isDelivery,
                            onTap: () => setState(() => _isDelivery = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _toggleOption(
                            label: 'Pickup',
                            icon: Icons.store,
                            selected: !_isDelivery,
                            onTap: () => setState(() => _isDelivery = false),
                          ),
                        ),
                      ],
                    ),

                    // Address field — only shown for delivery
                    if (_isDelivery) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Enter your delivery address in Kayole',
                          hintStyle: const TextStyle(fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFFF8F8F8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Order summary + place order
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_cart.totalItems} items',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'KES ${_cart.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _placingOrder ? null : _placeOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _placingOrder
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Place order',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Product icon placeholder
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.liquor, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),

          // Name and price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'KES ${item.product.price.toStringAsFixed(0)} each',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Quantity controls
          Row(
            children: [
              _smallButton(
                icon: Icons.remove,
                onTap: () {
                  _cart.decreaseQuantity(item.product.id);
                  _refresh();
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              _smallButton(
                icon: Icons.add,
                onTap: () {
                  _cart.increaseQuantity(item.product.id);
                  _refresh();
                },
              ),
            ],
          ),

          const SizedBox(width: 10),

          // Item total
          Text(
            'KES ${item.totalPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF1A1A2E) : Colors.grey.shade300,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.grey, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14),
      ),
    );
  }
}
