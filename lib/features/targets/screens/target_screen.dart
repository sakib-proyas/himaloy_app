import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../models/target_model.dart';

class TargetScreen extends StatefulWidget {
  const TargetScreen({super.key});

  @override
  State<TargetScreen> createState() => _TargetScreenState();
}

class _TargetScreenState extends State<TargetScreen> with SingleTickerProviderStateMixin {
  final ApiClient _apiClient = ApiClient();
  late TabController _tabController;

  List<TargetModel> _monthlyTargets = [];
  List<TargetModel> _yearlyTargets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTargets();
  }

  Future<void> _fetchTargets() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get(ApiConstants.targets);
      if (res.data['success'] == true) {
        final List mList = res.data['data']['monthly'] ?? [];
        final List yList = res.data['data']['yearly'] ?? [];
        setState(() {
          _monthlyTargets = mList.map((m) => TargetModel.fromJson(m)).toList();
          _yearlyTargets = yList.map((y) => TargetModel.fromJson(y)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Target & Performance'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Monthly Targets'),
            Tab(text: 'Annual Targets'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTargetList(_monthlyTargets),
                _buildTargetList(_yearlyTargets),
              ],
            ),
    );
  }

  Widget _buildTargetList(List<TargetModel> targets) {
    if (targets.isEmpty) {
      return const Center(child: Text('No active sales targets recorded.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: targets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final target = targets[index];
        final remaining = (target.targetAmount - target.achievedAmount).clamp(0, double.infinity);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      target.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: target.percentage >= 100
                            ? AppTheme.primaryGreen.withOpacity(0.12)
                            : Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${target.percentage.toStringAsFixed(1)}% Achieved',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: target.percentage >= 100 ? AppTheme.primaryGreen : Colors.orange.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (target.percentage / 100).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: target.percentage >= 100 ? AppTheme.primaryGreen : Colors.orange.shade700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Target Amount', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('৳ ${target.targetAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text('Achieved', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('৳ ${target.achievedAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryGreen)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Remaining Gap', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                        Text('৳ ${remaining.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.errorRed)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

