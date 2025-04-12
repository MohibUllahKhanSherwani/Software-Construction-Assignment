import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../dashboard/presentation/admin_dashboard.dart';
import '../data/fee_service.dart';
import '../domain/fee_model.dart';

class AdminFeeSetupPage extends StatefulWidget {
  const AdminFeeSetupPage({super.key});

  @override
  State<AdminFeeSetupPage> createState() => _AdminFeeSetupPageState();
}

class _AdminFeeSetupPageState extends State<AdminFeeSetupPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  String? _selectedSchool;
  late TabController _tabController;

  final List<String> schools = [
    'Greenwood High',
    'Sunrise Academy',
    'Maplewood School',
    'Riverside College',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feeService = Provider.of<FeeService>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AdminDashboard()),
              ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Set Fees'), Tab(text: 'View Submissions')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Set Fees Tab
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Select School',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                    value: _selectedSchool,
                    items:
                        schools.map((String school) {
                          return DropdownMenuItem<String>(
                            value: school,
                            child: Text(school),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedSchool = newValue!;
                      });
                    },
                    validator:
                        (value) =>
                            value == null ? 'Please select a school' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Fee Amount',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Fee Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator:
                        (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter a description'
                                : null,
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    title: Text(
                      _dueDate == null
                          ? 'Select Due Date'
                          : 'Due Date: ${DateFormat('MMM dd, yyyy').format(_dueDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 30),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                      if (picked != null) {
                        setState(() {
                          _dueDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      if (_formKey.currentState!.validate() &&
                          _dueDate != null) {
                        final fee = Fee(
                          schoolId: _selectedSchool!.toLowerCase().replaceAll(
                            ' ',
                            '_',
                          ),
                          schoolName: _selectedSchool!,
                          amount: double.parse(_amountController.text),
                          description: _descriptionController.text,
                          dueDate: _dueDate!,
                        );
                        await Provider.of<FeeService>(
                          context,
                          listen: false,
                        ).setSchoolFee(fee);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fee set successfully!'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'Set Fee',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // View Submissions Tab
          _buildViewSubmissionsTab(feeService),
        ],
      ),
    );
  }

  Widget _buildViewSubmissionsTab(FeeService feeService) {
    return FutureBuilder<List<Fee>>(
      future: feeService.getAllFees(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final fees = snapshot.data ?? [];
        return ListView.builder(
          itemCount: fees.length,
          itemBuilder: (context, index) {
            final fee = fees[index];
            return ListTile(
              title: Text(fee.schoolName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Amount: \$${fee.amount.toStringAsFixed(2)}'),
                  if (fee.userId != null) Text('Submitted by: ${fee.userId}'),
                  if (fee.paidDate != null)
                    Text(
                      'Paid on: ${DateFormat('MMM dd, yyyy').format(fee.paidDate!)}',
                    ),
                ],
              ),
              trailing:
                  fee.adminApproved
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                        icon: const Icon(Icons.check, color: Colors.orange),
                        onPressed: () => _approveFee(fee, feeService),
                      ),
            );
          },
        );
      },
    );
  }

  Future<void> _approveFee(Fee fee, FeeService feeService) async {
    final approvedFee = fee.copyWith(adminApproved: true);
    await feeService.setSchoolFee(approvedFee);
    setState(() {});
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Fee approved successfully!')));
  }
}
