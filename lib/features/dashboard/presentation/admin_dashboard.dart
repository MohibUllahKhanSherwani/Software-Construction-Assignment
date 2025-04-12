import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/domain/user_model.dart';
import '../../fees/data/fee_service.dart';
import '../../fees/domain/fee_model.dart';
import '../../fees/presentation/admin_fee_setup_page.dart';
import '../../../routes/app_routes.dart';
import 'widgets/fee_stats_card.dart';

// Custom colors
const Color primaryColor = Color(0xFF1976D2);
const Color secondaryColor = Color(0xFF4CAF50);
const Color errorColor = Color(0xFFF44336);
const Color warningColor = Color(0xFFFF9800);
const Color background = Color(0xFFFAFAFA);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<UserModel> _users = [];
  bool _isLoading = true;
  Map<String, Fee?> _schoolFees = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final feeService = Provider.of<FeeService>(context, listen: false);

    final users = await authService.fetchAllUsers();
    final fees = await feeService.getAllFees();

    setState(() {
      _users = users;
      _schoolFees = {for (var fee in fees) fee.schoolName: fee};
      _isLoading = false;
    });
  }

  List<BarChartGroupData> _getSchoolSubmissionData() {
    final schools =
        _users
            .where((u) => u.role == 'parent')
            .map((u) => u.school)
            .toSet()
            .toList();

    return schools.asMap().entries.map((entry) {
      final school = entry.value;
      final paidCount =
          _users
              .where(
                (u) =>
                    u.role == 'parent' &&
                    u.school == school &&
                    u.hasSubmittedFees,
              )
              .length;
      final unpaidCount =
          _users
              .where(
                (u) =>
                    u.role == 'parent' &&
                    u.school == school &&
                    !u.hasSubmittedFees,
              )
              .length;

      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: paidCount.toDouble(),
            color: secondaryColor,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: unpaidCount.toDouble(),
            color: errorColor,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final parentUsers = _users.where((u) => u.role == 'parent').toList();
    final paidCount = parentUsers.where((u) => u.hasSubmittedFees).length;
    final unpaidCount = parentUsers.length - paidCount;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            color: Colors.white,
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Stats Cards
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          FeeStatsCard(
                            title: 'Total Parents',
                            value: parentUsers.length.toString(),
                            color: primaryColor,
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          FeeStatsCard(
                            title: 'Fee Submitted',
                            value: paidCount.toString(),
                            color: secondaryColor,
                            textColor: Colors.white,
                          ),
                          const SizedBox(width: 16),
                          FeeStatsCard(
                            title: 'Pending',
                            value: unpaidCount.toString(),
                            color: errorColor,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // School-wise Submissions Chart
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'School-wise Submissions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250,
                              child: BarChart(
                                BarChartData(
                                  alignment: BarChartAlignment.spaceAround,
                                  barTouchData: BarTouchData(
                                    enabled: true,
                                    touchTooltipData: BarTouchTooltipData(
                                      getTooltipItem: (
                                        group,
                                        groupIndex,
                                        rod,
                                        rodIndex,
                                      ) {
                                        final school =
                                            _users
                                                .where(
                                                  (u) => u.role == 'parent',
                                                )
                                                .map((u) => u.school)
                                                .toSet()
                                                .toList()[group.x.toInt()];
                                        return BarTooltipItem(
                                          '$school\n${rod.toY.toInt()} ${rodIndex == 0 ? 'Paid' : 'Unpaid'}',
                                          TextStyle(
                                            color:
                                                rodIndex == 0
                                                    ? secondaryColor
                                                    : errorColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          final schools =
                                              _users
                                                  .where(
                                                    (u) => u.role == 'parent',
                                                  )
                                                  .map((u) => u.school)
                                                  .toSet()
                                                  .toList();
                                          if (value.toInt() < schools.length) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: Text(
                                                schools[value.toInt()],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            );
                                          }
                                          return const Text('');
                                        },
                                        reservedSize: 40,
                                      ),
                                    ),
                                    leftTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  gridData: const FlGridData(show: false),
                                  borderData: FlBorderData(show: false),
                                  barGroups: _getSchoolSubmissionData(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Payment Status Pie Chart
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: paidCount.toDouble(),
                                      color: secondaryColor,
                                      title:
                                          '${(paidCount / parentUsers.length * 100).toStringAsFixed(1)}%',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: unpaidCount.toDouble(),
                                      color: errorColor,
                                      title:
                                          '${(unpaidCount / parentUsers.length * 100).toStringAsFixed(1)}%',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                  centerSpaceRadius: 40,
                                  sectionsSpace: 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Parent Details Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Parent Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text('Manage Fees'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminFeeSetupPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final user in parentUsers)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: primaryColor.withOpacity(
                                      0.2,
                                    ),
                                    child: Text(
                                      user.email[0].toUpperCase(),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    user.email,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('School: ${user.school}'),
                                      if (_schoolFees[user.school] != null)
                                        Text(
                                          'Fee: \$${_schoolFees[user.school]!.amount.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color:
                                                user.hasSubmittedFees
                                                    ? secondaryColor
                                                    : errorColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: Icon(
                                    user.hasSubmittedFees
                                        ? Icons.check_circle
                                        : Icons.warning,
                                    color:
                                        user.hasSubmittedFees
                                            ? secondaryColor
                                            : errorColor,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
