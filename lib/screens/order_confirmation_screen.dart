import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'order_history_screen.dart';
import 'order_tracking_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String? mpesaCode;

  const OrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.mpesaCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success icon
              Container(
                width: 100, height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 56, color: Color(0xFF059669)),
              ),
              const SizedBox(height: 28),

              const Text('Order placed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  )),
              const SizedBox(height: 12),
              const Text(
                'Your order has been received.\nThe store will confirm it shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Order ID
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Order #${orderId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),

              // M-Pesa receipt — shown only if payment was made
              if (mpesaCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF059669).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF059669), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'M-Pesa: $mpesaCode',
                        style: const TextStyle(
                          color: Color(0xFF059669),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Track order
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) =>
                        OrderTrackingScreen(orderId: orderId)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Track my order',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              // Order history
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const OrderHistoryScreen()),
                    (_) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('View order history',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),

              // Back to home
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                ),
                child: const Text('Back to home',
                    style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}