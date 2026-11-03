import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';

class SiteSettingsScreen extends StatefulWidget {
  const SiteSettingsScreen({super.key});

  @override
  State<SiteSettingsScreen> createState() => _SiteSettingsScreenState();
}

class _SiteSettingsScreenState extends State<SiteSettingsScreen> {
  final ApiClient _apiClient = ApiClient();

  final _siteNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _fixedDescription;
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/settings');
      if (res.data['success'] == true) {
        final d = res.data['data'];
        setState(() {
          _siteNameCtrl.text = d['site_name'] ?? '';
          _emailCtrl.text = d['site_email'] ?? '';
          _phoneCtrl.text = d['site_phone'] ?? '';
          _addressCtrl.text = d['site_address'] ?? '';
          _aboutCtrl.text = d['about_company'] ?? '';
          _logoUrl = d['site_logo'];
          _fixedDescription = d['fixed_description'];
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final res = await _apiClient.post(
        '/settings',
        data: {
          'site_name': _siteNameCtrl.text.trim(),
          'site_email': _emailCtrl.text.trim(),
          'site_phone': _phoneCtrl.text.trim(),
          'site_address': _addressCtrl.text.trim(),
          'about_company': _aboutCtrl.text.trim(),
        },
      );

      if (res.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Site settings updated successfully.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating settings: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchSettings,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // General Site Settings Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'General Site Settings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Site Name
                          TextField(
                            controller: _siteNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Site Name',
                              hintText: 'Himaloy Agro Care',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Email & Phone Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: const InputDecoration(
                                    labelText: 'Contact Email',
                                    hintText: 'email@domain.com',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    labelText: 'Phone Number',
                                    hintText: '019XXXXXXXX',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Office Address
                          TextField(
                            controller: _addressCtrl,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Office Address',
                              hintText: 'Full physical address',
                            ),
                          ),
                          const SizedBox(height: 12),

                          // About Company
                          TextField(
                            controller: _aboutCtrl,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'About Company',
                              hintText: 'Company description...',
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Save Button
                          ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check_circle_outline),
                            label: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // System Information Card
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'System Information',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'FIXED SYSTEM DESCRIPTION',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _fixedDescription ??
                                'Invento Pro v1.0: A comprehensive Enterprise Resource Planning (ERP) solution designed for high-performance inventory tracking and personnel management.',
                            style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.cyan.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.cyan.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.cyan.shade900),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'The description above is hard-coded for system integrity.',
                                    style: TextStyle(fontSize: 12, color: Colors.cyan.shade900),
                                  ),
                                ),
                              ],
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
