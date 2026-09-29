import 'package:flutter/material.dart';

// Minimal payment screen placeholder: integrate a real gateway here.
// On success, call `onPaymentSuccess` with a payment result map (e.g. paymentId, amountPaid, paidAt).
class PaymentScreen extends StatelessWidget {
  final double amount;
  final String currency;
  final String title;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({super.key, required this.amount, this.currency = 'INR', required this.title, required this.onPaymentSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Order Summary', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Text('Material: $title'),
          const SizedBox(height: 8),
          Text('Total: $currency ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}'),
          const SizedBox(height: 24),
          const Text('Payment method'),
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: const Text('No payment gateway integrated. Replace this screen with your gateway flow.')),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                // NOTE: Replace this with actual payment gateway integration.
                // This button acts as the payment completion hook.
                onPaymentSuccess();
              },
              child: Text('Pay $currency ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          )
        ]),
      ),
    );
  }
}
