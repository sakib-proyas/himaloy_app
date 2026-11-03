import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalLogs = 0;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs([int page = 1]) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final query = <String, dynamic>{'page': page};
      if (_searchCtrl.text.trim().isNotEmpty) {
        query['search'] = _searchCtrl.text.trim();
      }

      final res = await _apiClient.get('/activity-logs', queryParameters: query);
      if (res.data['success'] == true) {
        final data = res.data['data'] ?? {};
        final List list = data['logs'] ?? [];
        setState(() {
          _logs = list;
          _currentPage = data['current_page'] ?? 1;
          _totalLogs = data['total'] ?? list.length;
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to load activity logs. Please check connection.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getActionColor(String action) {
    switch (action.toUpperCase()) {
      case 'CREATED':
        return AppTheme.primaryGreen;
      case 'UPDATED':
        return Colors.blue.shade800;
      case 'DELETED':
        return AppTheme.errorRed;
      default:
        return Colors.purple.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Log ($_totalLogs)'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search module, action, IP address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _fetchLogs(1);
                        },
                      )
                    : null,
              ),
              onSubmitted: (_) => _fetchLogs(1),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: () => _fetchLogs(1), child: const Text('Retry Connection')),
                          ],
                        ),
                      )
                    : _logs.isEmpty
                        ? const Center(child: Text('No activity log entries found.'))
                        : RefreshIndicator(
                            onRefresh: () => _fetchLogs(_currentPage),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: _logs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final log = _logs[idx];
                                final action = (log['action'] ?? 'ACTION').toString().toUpperCase();
                                final actionColor = _getActionColor(action);
                                final module = log['module'] ?? 'System';
                                final user = log['user'] ?? 'User';
                                final date = log['created_at'] ?? '-';
                                final ip = log['ip_address'] ?? '127.0.0.1';

                                return Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.history_toggle_off, size: 18, color: Colors.blueGrey.shade700),
                                                const SizedBox(width: 6),
                                                Text('$module Module', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: actionColor.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                action,
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: actionColor),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('Performed by: $user', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('Record ID: #${log['record_id'] ?? "-"} • IP: $ip', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                        const SizedBox(height: 2),
                                        Text('Time: $date', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
