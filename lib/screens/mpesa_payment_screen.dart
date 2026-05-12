import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../config/supabase_config.dart';
import 'order_confirmation_screen.dart';

class MpesaPaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;

  const MpesaPaymentScreen({
    super.key,
    required this.orderId,
    required this.amount,
  });

  @override
  State<MpesaPaymentScreen> createState() => _MpesaPaymentScreenState();
}

class _MpesaPaymentScreenState extends State<MpesaPaymentScreen> {
  bool _loading      = false;
  bool _showWebView  = false;
  String? _paymentUrl;
  String? _reference;
  String? _error;
  WebViewController? _webCtrl;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializePayment() async {
    setState(() { _loading = true; _error = null; });

    try {
      // Get customer email from Supabase auth
      final user  = supabase.auth.currentUser;
      final email = user?.email ?? 'customer@urbanliquor.com';

      print('💳 Initializing Paystack payment...');
      print('📦 Order: ${widget.orderId}, Amount: ${widget.amount}');

      final response = await supabase.functions.invoke(
        'paystack-initialize',
        body: {
          'order_id': widget.orderId,
          'email':    email,
          'amount':   widget.amount,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      print('📥 Response: $data');

      if (data == null || data['success'] != true) {
        setState(() {
          _error   = data?['error']?.toString() ?? 'Failed to initialize payment';
          _loading = false;
        });
        return;
      }

      _paymentUrl = data['payment_url'] as String;
      _reference  = data['reference'] as String;

      print('✅ Payment URL: $_paymentUrl');
      print('✅ Reference: $_reference');

      // Set up WebView controller
      _webCtrl = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(
          onPageStarted: (url) {
            print('🌐 Page started: $url');
            _checkPaymentComplete(url);
          },
          onPageFinished: (url) {
            print('🌐 Page finished: $url');
            _checkPaymentComplete(url);
          },
          onNavigationRequest: (req) {
            print('🌐 Navigation: ${req.url}');
            _checkPaymentComplete(req.url);
            return NavigationDecision.navigate;
          },
        ))
        ..loadRequest(Uri.parse(_paymentUrl!));

      setState(() { _loading = false; _showWebView = true; });

    } catch (e) {
      print('❌ Init error: $e');
      setState(() {
        _error   = 'Connection failed. Please try again.';
        _loading = false;
      });
    }
  }

  void _checkPaymentComplete(String url) {
    // Paystack redirects to callback_url after payment
    // We detect any redirect away from paystack.co as completion
    if (!url.contains('paystack.co') &&
        !url.contains('standard.paystack.co') &&
        _reference != null) {
      print('🔔 Redirect detected — verifying payment');
      _verifyPayment();
    }

    // Also detect Paystack success/cancel pages
    if (url.contains('payment-success') ||
        url.contains('trxref=') ||
        url.contains('reference=')) {
      print('🔔 Paystack callback detected');
      _verifyPayment();
    }
  }

  Future<void> _verifyPayment() async {
    if (_reference == null) return;

    // Prevent multiple verification calls
    _pollTimer?.cancel();

    setState(() { _showWebView = false; _loading = true; });

    print('🔍 Verifying payment: $_reference');

    try {
      final response = await supabase.functions.invoke(
        'paystack-verify',
        body: {
          'reference': _reference,
          'order_id':  widget.orderId,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      print('📥 Verify response: $data');

      if (data != null && data['success'] == true) {
        print('✅ Payment verified!');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderConfirmationScreen(
                orderId:   widget.orderId,
                mpesaCode: _reference,
              ),
            ),
          );
        }
      } else {
        final msg = data?['message']?.toString()
            ?? 'Payment could not be confirmed';
        setState(() { _error = msg; _loading = false; });
      }
    } catch (e) {
      print('❌ Verify error: $e');
      setState(() {
        _error   = 'Verification failed. Please contact support.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        title: Text(_showWebView ? 'Complete Payment' : 'Checkout'),
        elevation: 0,
        actions: [
          if (_showWebView)
            TextButton(
              onPressed: () => setState(() {
                _showWebView = false;
                _error = null;
              }),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: _showWebView
          ? _buildWebView()
          : _loading
              ? _buildLoading()
              : _buildForm(),
    );
  }

  // ── WebView ───────────────────────────────────────────────────────────────
  Widget _buildWebView() {
    return Column(children: [
      // Top bar with instruction
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 10),
        color: Colors.white.withValues(alpha: 0.05),
        child: Row(children: [
          const Icon(Icons.lock_outline,
              color: Color(0xFF4CAF50), size: 14),
          const SizedBox(width: 6),
          Text('Secure payment powered by Paystack',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12)),
          const Spacer(),
          GestureDetector(
            onTap: _verifyPayment,
            child: Text('I\'ve paid',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white.withValues(alpha: 0.5),
                )),
          ),
        ]),
      ),
      Expanded(
        child: WebViewWidget(controller: _webCtrl!),
      ),
    ]);
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
              color: Color(0xFF4CAF50), strokeWidth: 2),
          const SizedBox(height: 20),
          Text('Setting up payment...',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14)),
        ],
      ),
    );
  }

  // ── Payment form ──────────────────────────────────────────────────────────
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Column(children: [
              Text('Total amount',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                      letterSpacing: 0.5)),
              const SizedBox(height: 10),
              Text(
                'KES ${widget.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 4),
              Text('Urban Liquor Parlor · Kayole',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 12)),
            ]),
          ),
          const SizedBox(height: 32),

          // Payment methods label
          Text('Pay with',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  letterSpacing: 0.3)),
          const SizedBox(height: 14),

          // Payment options display
          Row(children: [
            _methodChip(Icons.credit_card, 'Card'),
            const SizedBox(width: 10),
            _methodChip(Icons.phone_android, 'M-Pesa'),
            const SizedBox(width: 10),
            _methodChip(Icons.account_balance, 'Bank'),
          ]),
          const SizedBox(height: 8),
          Text('All payment methods available via Paystack',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 11)),

          const SizedBox(height: 32),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_error!,
                    style: const TextStyle(
                        color: Colors.redAccent, fontSize: 13))),
              ]),
            ),
            const SizedBox(height: 20),
          ],

          // Pay button
          GestureDetector(
            onTap: _loading ? null : _initializePayment,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline,
                        color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text('Proceed to Payment',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Security note
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user_outlined,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 14),
              const SizedBox(width: 6),
              Text('256-bit SSL secured by Paystack',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _methodChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(children: [
        Icon(icon,
            color: Colors.white.withValues(alpha: 0.6),
            size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12)),
      ]),
    );
  }
}