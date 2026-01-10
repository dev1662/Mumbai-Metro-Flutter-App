// payment_service.dart
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../views/HomeServiceView.dart';
import '../models/customer_data_model.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final Razorpay _razorpay = Razorpay();
  bool _initialized = false;

  // Optional: backend endpoints
  static const String _initiateUrl = 'https://54kidsstreet.org/api/payment/initiate';
  static const String _verifyUrl = 'https://54kidsstreet.org/api/payment/verify';

  // IMPORTANT: This is the publishable API key to open checkout.
  // Your backend should return the correct key if it differs; otherwise set here.
  // Do NOT put secret keys here.
  final String _razorpayKey = 'rzp_test_RhTYjoIGeyROHV';

  void _initCallbacks(BuildContext context, int amount, String orderNumber) {
    if (_initialized) return;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse res) {
      log('✔ PAYMENT SUCCESS → paymentId=${res.paymentId}, orderId=${res.orderId}, signature=${res.signature}');
      _handlePaymentSuccess(context, res);
    });

    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse res) {
      log('✖ PAYMENT ERROR → code=${res.code}, message=${res.message}');
      _handlePaymentError(context, res);
    });

    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse res) {
      log('⚠ EXTERNAL WALLET → ${res.walletName}');
      _handleExternalWallet(context, res);
    });

    _initialized = true;
  }

  Future<void> startPaymentFlow(
      BuildContext context, {
        required int amount,
        required String orderNumber,
        required CustomerModel customerData,
      }) async {
    _initCallbacks(context, amount, orderNumber);

    try {
      final body = {
        "order_no": orderNumber,
        "amount": amount,
      };

      log('📤 CALL INITIATE BACKEND → $_initiateUrl');
      log('➡️ BODY: $body');

      final res = await http.post(
        Uri.parse(_initiateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      log('📥 INITIATE RESPONSE → ${res.statusCode} | ${res.body}');

      if (res.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment initiation failed.")),
        );
        return;
      }

      final Map<String, dynamic> data = jsonDecode(res.body);

      // Adjust according to backend structure: razorpay_order_id is inside data
      final String? razorpayOrderId = data["data"]?["razorpay_order_id"]?.toString();
      final String? backendRazorpayKey = data["data"]?["razorpay_key"]?.toString();

      if (razorpayOrderId == null || razorpayOrderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid Razorpay order id from backend.")),
        );
        return;
      }

      log('✔ Received razorpay_order_id → $razorpayOrderId');

      // Use backend provided key if present
      final keyToUse = (backendRazorpayKey != null && backendRazorpayKey.isNotEmpty)
          ? backendRazorpayKey
          : _razorpayKey;

      _openCheckout(
        context,
        amount: amount,
        orderNumber: orderNumber,
        customerData: customerData,
        razorpayOrderId: razorpayOrderId,
        apiKey: keyToUse,
      );
    } catch (e, st) {
      log('❌ Exception in startPaymentFlow → $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initiating payment: $e')),
      );
    }
  }

  void _openCheckout(
      BuildContext context, {
        required int amount,
        required String orderNumber,
        required CustomerModel customerData,
        required String razorpayOrderId,
        required String apiKey,
      }) {
    _initCallbacks(context, amount, orderNumber);

    final options = {
      'key': apiKey,
      'order_id': razorpayOrderId,
      'amount': (amount * 100).toInt(), // paise
      'name': customerData.data.customerName.isNotEmpty ? customerData.data.customerName : 'User',
      'description': 'Payment for service',
      'prefill': {
        'contact': customerData.data.mobileNo.isNotEmpty ? customerData.data.mobileNo : '',
        'email': customerData.data.email.isNotEmpty ? customerData.data.email : '',
      },
      'currency': 'INR',
      'theme': {'color': '#3399cc'},
    };

    log('🧾 Opening Razorpay Checkout with options → $options');

    try {
      _razorpay.open(options);
    } catch (e) {
      log('❌ Razorpay open error → $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening payment sheet: $e')),
      );
    }
  }

  Future<void> _handlePaymentSuccess(BuildContext context, PaymentSuccessResponse res) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Successful! ID: ${res.paymentId}')),
    );
    await verifyPayment(
      context: context,
      paymentId: res.paymentId,
      orderId: res.orderId,
      signature: res.signature,
    );
  }

  void _handlePaymentError(BuildContext context, PaymentFailureResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment Failed: ${res.message}')),
    );
  }

  void _handleExternalWallet(BuildContext context, ExternalWalletResponse res) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${res.walletName}')),
    );
  }

  Future<void> verifyPayment({
    required BuildContext context,
    required String? paymentId,
    required String? orderId,
    required String? signature,
  }) async {
    if (paymentId == null || orderId == null || signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid payment response for verification.')),
      );
      return;
    }

    final body = {
      "razorpay_payment_id": paymentId,
      "razorpay_order_id": orderId,
      "razorpay_signature": signature,
    };

    log('📤 VERIFY PAYMENT → $_verifyUrl');
    log('➡️ BODY: $body');

    try {
      final res = await http.post(
        Uri.parse(_verifyUrl),
        headers: {"Content-Type": "application/json", "Accept": "application/json"},
        body: jsonEncode(body),
      );

      log('📥 VERIFY RESPONSE → ${res.statusCode} | ${res.body}');

      if (res.statusCode == 200) {
        // Success flow
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeServiceView()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment verification failed.')),
        );
        log('❌ Verification failed: ${res.body}');
      }
    } catch (e) {
      log('❌ Error verifying payment → $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying payment: $e')),
      );
    }
  }

  void clear() {
    try {
      _razorpay.clear();
    } catch (_) {}
    _initialized = false;
  }
}
