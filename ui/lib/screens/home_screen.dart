import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  String? _protectedMessage;
  bool _isLoading = false;
  String? _username;
  String? _role;
  String? _secret;
  int? _timestamp;

  @override
  void initState() {
    super.initState();
    _loadProtectedData();
  }

  Future<void> _loadProtectedData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = context.read<AuthProvider>().token;
      if (token != null) {
        final response = await _apiService.getProtectedData(token);
        setState(() {
          _protectedMessage = response['message'];
          final data = response['data'] as Map<String, dynamic>? ?? {};
          final user = data['user'] as Map<String, dynamic>? ?? {};
          _username = user['username'] as String?;
          _role = user['role'] as String?;
          _secret = data['secret'] as String?;
          _timestamp =
              data['timestamp'] is int ? data['timestamp'] as int : null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Home',
        additionalActions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _protectedMessage != null
                ? Container(
                    constraints: BoxConstraints(
                      maxWidth: isLargeScreen ? 800 : double.infinity,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 32.0 : 16.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _protectedMessage!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        height: 1.5,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (_username != null)
                                  ListTile(
                                    leading: const Icon(Icons.person),
                                    title: const Text('Username'),
                                    subtitle: SelectableText(_username!),
                                  ),
                                if (_role != null)
                                  ListTile(
                                    leading: const Icon(Icons.security),
                                    title: const Text('Role'),
                                    subtitle: SelectableText(_role!),
                                  ),
                                if (_secret != null)
                                  ListTile(
                                    leading: const Icon(Icons.lock),
                                    title: const Text('Secret'),
                                    subtitle: SelectableText(_secret!),
                                  ),
                                if (_timestamp != null)
                                  ListTile(
                                    leading: const Icon(Icons.access_time),
                                    title: const Text('Timestamp'),
                                    subtitle:
                                        SelectableText(_timestamp.toString()),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (_role == 'admin') ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/admin/invites'),
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Manage Invites'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const Text('No data available'),
      ),
    );
  }
}
