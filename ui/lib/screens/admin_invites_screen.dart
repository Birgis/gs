import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:flutter/services.dart';

class AdminInvitesScreen extends StatefulWidget {
  const AdminInvitesScreen({super.key});

  @override
  State<AdminInvitesScreen> createState() => _AdminInvitesScreenState();
}

class _AdminInvitesScreenState extends State<AdminInvitesScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _invites = [];
  String? _error;
  String? _newInviteToken;

  @override
  void initState() {
    super.initState();
    _fetchInvites();
  }

  Future<void> _fetchInvites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final response = await _apiService.getInvites(token!);
      setState(() {
        _invites = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createInvite() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _newInviteToken = null;
    });
    try {
      final token = context.read<AuthProvider>().token;
      final inviteToken = await _apiService.createInviteWithToken(token!);
      setState(() {
        _newInviteToken = inviteToken;
      });
      await _fetchInvites();
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Manage Invites')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ElevatedButton(
                    onPressed: _createInvite,
                    child: const Text('Create New Invite'),
                  ),
                  if (_newInviteToken != null) ...[
                    const SizedBox(height: 8),
                    SelectableText('New Invite Token: $_newInviteToken'),
                  ],
                  const SizedBox(height: 16),
                  const Text('All Invites:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _invites.length,
                      itemBuilder: (context, index) {
                        final invite = _invites[index];
                        return ListTile(
                          title: Row(
                            children: [
                              Expanded(
                                  child: SelectableText(invite['token'] ?? '')),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copy token',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                      text: invite['token'] ?? ''));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Token copied to clipboard')),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: SelectableText(
                              'Used: 	${invite['used']} | Created by: ${invite['created_by']} | Used by: ${invite['used_by'] ?? "-"}'),
                          trailing: SelectableText(invite['created_at'] ?? ''),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
