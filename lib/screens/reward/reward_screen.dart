import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  // Use 10.0.2.2 for Android Emulator, or your PC's IP address for a real device
  final String baseUrl = 'http://10.0.2.2:5000';

  // Replace this with an actual address from your Ganache accounts
  final String userWallet = '0xYourGanacheAddressHere';

  int _balance = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  // GET Request: Check current balance from Python API
  Future<void> _fetchBalance() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/balance/$userWallet'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _balance = data['balance'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
    }
  }

  // POST Request: Trigger the Reward (The Blockchain Part)
  Future<void> _claimDailyReward() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/claim'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'address': userWallet}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _balance = data['new_balance'];
        });
        _showSuccessSnippet(data['transaction_hash']);
      } else {
        _showErrorSnippet(data['message'] ?? 'Claim failed');
      }
    } catch (e) {
      _showErrorSnippet('Could not connect to backend server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnippet(String txHash) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reward Secured! Tx: ${txHash.substring(0, 10)}...'),
        backgroundColor: Colors.green.shade600,
      ),
    );
  }

  void _showErrorSnippet(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Recovery Rewards', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Minimalist Balance Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text('CURRENT BALANCE', style: TextStyle(letterSpacing: 1.5, fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Text('$_balance Tokens', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // The Action Button
            ElevatedButton(
              onPressed: _isLoading ? null : _claimDailyReward,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('I stayed clean today', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),
            Text(
              'Wallet: ${userWallet.substring(0, 6)}...${userWallet.substring(userWallet.length - 4)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
