import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../fees/data/fee_service.dart';
import '../../fees/domain/fee_model.dart';
import '../../auth/data/auth_service.dart';
import '../../../routes/app_routes.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  Fee? _currentFee;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadFeeData();
  }

  Future<void> _loadFeeData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final feeService = Provider.of<FeeService>(context, listen: false);

    if (authService.user?.school != null) {
      final fee = await feeService.getSchoolFee(
        authService.user!.school.toLowerCase().replaceAll(' ', '_'),
      );
      if (mounted) {
        setState(() {
          _currentFee = fee;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School Information Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'School Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('School', user?.school ?? 'Not specified'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Fee Status Header
            if (_currentFee != null) ...[
              const Text(
                'Fee Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.hasSubmittedFees ?? false ? 'Paid' : 'Unpaid',
                style: TextStyle(
                  fontSize: 18,
                  color:
                      user?.hasSubmittedFees ?? false
                          ? Colors.green
                          : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Fee Details Card
            if (_currentFee != null)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fee Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildDetailRow('School', _currentFee!.schoolName),
                      _buildDetailRow(
                        'Amount',
                        '\$${_currentFee!.amount.toStringAsFixed(2)}',
                      ),
                      _buildDetailRow('Description', _currentFee!.description),
                      _buildDetailRow(
                        'Due Date',
                        DateFormat('MMM dd, yyyy').format(_currentFee!.dueDate),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1976D2),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed:
                              _currentFee?.isPaid ?? false
                                  ? null
                                  : _isSubmitting
                                  ? null
                                  : () async {
                                    setState(() {
                                      _isSubmitting = true;
                                    });
                                    await _submitPayment(context);
                                    setState(() {
                                      _isSubmitting = false;
                                    });
                                  },
                          child:
                              _isSubmitting
                                  ? const CircularProgressIndicator()
                                  : Text(
                                    _currentFee?.isPaid ?? false
                                        ? 'Payment Submitted'
                                        : 'Submit Payment',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty State
            if (user?.school != null && _currentFee == null)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text(
                    'No fee structure found for selected school',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _submitPayment(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final feeService = Provider.of<FeeService>(context, listen: false);

    try {
      if (_currentFee != null && authService.user != null) {
        await feeService.submitFeePayment(
          userId: authService.user!.uid,
          schoolId: _currentFee!.schoolId,
          amount: _currentFee!.amount,
        );

        // Refresh fee data
        await _loadFeeData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment submitted successfully!'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
