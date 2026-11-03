import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  List<dynamic> _employees = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get('/employees');
      if (res.data['success'] == true) {
        setState(() {
          _employees = res.data['data'] ?? [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load employee list. Please check connection.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEmployeeModal() {
    final nameCtrl = TextEditingController();
    final desigCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final terrCtrl = TextEditingController();
    final regCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add New Employee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Employee Name *')),
              const SizedBox(height: 12),
              TextField(controller: desigCtrl, decoration: const InputDecoration(labelText: 'Designation (e.g. Sales Officer)')),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextField(controller: terrCtrl, decoration: const InputDecoration(labelText: 'Territory / Base')),
              const SizedBox(height: 12),
              TextField(controller: regCtrl, decoration: const InputDecoration(labelText: 'Region / Division')),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  try {
                    await _apiClient.post(
                      '/employees',
                      data: {
                        'name': nameCtrl.text.trim(),
                        'designation': desigCtrl.text.trim(),
                        'phone': phoneCtrl.text.trim(),
                        'territory': terrCtrl.text.trim(),
                        'region': regCtrl.text.trim(),
                      },
                    );
                    _fetchEmployees();
                  } catch (_) {
                    setState(() => _isLoading = false);
                  }
                },
                child: const Text('Save Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.toLowerCase().trim();
    final filtered = _employees.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final id = (e['employee_id'] ?? '').toString().toLowerCase();
      final desig = (e['designation'] ?? '').toString().toLowerCase();
      final phone = (e['phone'] ?? '').toString().toLowerCase();
      return query.isEmpty || name.contains(query) || id.contains(query) || desig.contains(query) || phone.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees Directory'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primaryGreen,
        onPressed: _showAddEmployeeModal,
        icon: const Icon(Icons.person_add, color: Colors.white),
        label: const Text('Add Employee', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search employee name, code, designation...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
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
                            ElevatedButton(onPressed: _fetchEmployees, child: const Text('Retry Connection')),
                          ],
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(child: Text('No employee records found.'))
                        : RefreshIndicator(
                            onRefresh: _fetchEmployees,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final e = filtered[idx];
                                final id = e['employee_id'] ?? 'EMP';
                                final designation = e['designation'] ?? 'Staff';
                                final region = e['region'] ?? 'N/A';
                                final territory = e['territory'] ?? 'N/A';

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Text(
                                        id.toString().length > 4 ? id.toString().substring(0, 4) : id.toString(),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                      ),
                                    ),
                                    title: Text(e['name'] ?? 'Employee', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('$designation • 📞 ${e['phone']}\n📍 $territory ($region)'),
                                    isThreeLine: true,
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
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
