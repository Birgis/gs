import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_bar.dart';
import '../services/api_service.dart';

class PublicScreen extends StatefulWidget {
  const PublicScreen({super.key});

  @override
  State<PublicScreen> createState() => _PublicScreenState();
}

class _PublicScreenState extends State<PublicScreen> {
  bool _isLoading = true;
  String? _error;
  final _apiService = ApiService();
  final _emailController = TextEditingController();
  bool _isRequestingInvite = false;
  String? _requestError;
  bool _requestSuccess = false;

  @override
  void initState() {
    super.initState();
    _fetchPublicData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchPublicData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await http.get(Uri.parse('http://localhost:6060/api/public'));
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load public info';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _requestInvite() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _requestError = 'Please enter your email';
      });
      return;
    }

    setState(() {
      _isRequestingInvite = true;
      _requestError = null;
      _requestSuccess = false;
    });

    try {
      await _apiService.requestInvite(_emailController.text);
      setState(() {
        _requestSuccess = true;
        _emailController.clear();
      });
    } catch (e) {
      setState(() {
        _requestError = e.toString();
      });
    } finally {
      setState(() {
        _isRequestingInvite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = context.watch<AuthProvider>().isAuthenticated;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Welcome',
        showBackButton: false,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Container(
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
                                    'Welcome to GS App',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'A secure and private platform for managing your data. Our app provides:',
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildFeatureItem(
                                    context,
                                    Icons.security,
                                    'Secure Authentication',
                                    'Protected by industry-standard security measures',
                                  ),
                                  _buildFeatureItem(
                                    context,
                                    Icons.person,
                                    'User Management',
                                    'Full control over your profile and settings',
                                  ),
                                  _buildFeatureItem(
                                    context,
                                    Icons.admin_panel_settings,
                                    'Admin Features',
                                    'Advanced management tools for administrators',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          if (!isAuthenticated) ...[
                            if (_requestSuccess)
                              Card(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Invite request sent! We\'ll contact you soon.',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              Card(
                                elevation: 2,
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Request an Invite',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Enter your email to request an invite to join our platform.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 24),
                                      TextField(
                                        controller: _emailController,
                                        decoration: const InputDecoration(
                                          labelText: 'Email',
                                          border: OutlineInputBorder(),
                                          prefixIcon: Icon(Icons.email),
                                        ),
                                        keyboardType:
                                            TextInputType.emailAddress,
                                      ),
                                      if (_requestError != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _requestError!,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: _isRequestingInvite
                                            ? null
                                            : _requestInvite,
                                        icon: _isRequestingInvite
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.send),
                                        label: Text(_isRequestingInvite
                                            ? 'Requesting...'
                                            : 'Request Invite'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/register'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Register'),
                                ),
                                ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                  child: const Text('Login'),
                                ),
                              ],
                            ),
                          ],
                          if (isAuthenticated)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/home'),
                                  icon: const Icon(Icons.home),
                                  label: const Text('Go to Home'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/profile'),
                                  icon: const Icon(Icons.person),
                                  label: const Text('View Profile'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
