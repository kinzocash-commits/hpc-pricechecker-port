import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  String? _statusMessage;
  bool _isConnectionSuccessful = false;
  String? _userId;
  String? _deviceId;
  int _userDuration = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _serverController.dispose();
    _portController.dispose();
    _dbNameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final serverIP = await _settingsService.getServerIP();
      final port = await _settingsService.getPort();
      final dbName = await _settingsService.getDbName();
      final username = await _settingsService.getUsername();
      final password = await _settingsService.getPassword();
      final userId = await _settingsService.getUserId();
      final deviceId = await _settingsService.getDeviceId();

      setState(() {
        _serverController.text = serverIP ?? '';
        _portController.text = port.toString();
        _dbNameController.text = dbName ?? '';
        _usernameController.text = username ?? '';
        _passwordController.text = password ?? '';
        _userId = userId;
        _deviceId = deviceId;
        _isLoading = false;
      });

      // Check user duration if we have a user ID
      if (userId != null && userId.isNotEmpty) {
        _checkUserDuration();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading settings: $e';
      });
    }
  }

  Future<void> _checkUserDuration() async {
    if (_userId == null || _userId!.isEmpty) return;

    try {
      final duration = await _databaseService.getUserDuration(_userId!);
      setState(() {
        _userDuration = duration;
      });
    } catch (e) {
      print('Error checking user duration: $e');
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });

    try {
      await _settingsService.setServerIP(_serverController.text.trim());
      await _settingsService.setPort(int.tryParse(_portController.text) ?? 3306);
      await _settingsService.setDbName(_dbNameController.text.trim());
      await _settingsService.setUsername(_usernameController.text.trim());
      await _settingsService.setPassword(_passwordController.text.trim());

      setState(() {
        _statusMessage = 'Settings saved successfully!';
        _isConnectionSuccessful = false; // Reset connection status
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error saving settings: $e';
        _isSaving = false;
      });
    }
  }

  Future<void> _testConnection() async {
    // Save settings first
    await _saveSettings();

    setState(() {
      _isTesting = true;
      _statusMessage = 'Testing connection...';
      _isConnectionSuccessful = false;
    });

    try {
      final isConnected = await _databaseService.testConnection();
      setState(() {
        _isConnectionSuccessful = isConnected;
        _statusMessage = isConnected
            ? 'Connection successful! ✓'
            : 'Connection failed. Please check your settings.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _isConnectionSuccessful = false;
        _statusMessage = 'Connection error: $e';
        _isTesting = false;
      });
    }
  }

  Widget _buildConnectionStatus() {
    if (_statusMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isConnectionSuccessful ? Colors.green[50] : Colors.red[50],
        border: Border.all(
          color: _isConnectionSuccessful ? Colors.green[300]! : Colors.red[300]!,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _isConnectionSuccessful ? Icons.check_circle : Icons.error,
            color: _isConnectionSuccessful ? Colors.green[700] : Colors.red[700],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage!,
              style: TextStyle(
                color: _isConnectionSuccessful ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    if (_userId == null || _userId!.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_circle, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Registration Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('User ID:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_userId!, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Device ID:', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(_deviceId ?? 'N/A', style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _userDuration > 0 ? Icons.check_circle : Icons.warning,
                  color: _userDuration > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _userDuration > 0
                      ? 'License valid for $_userDuration days'
                      : 'License expired or invalid',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _userDuration > 0 ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Information Card
            _buildUserInfo(),

            // Database Settings Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.storage, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Database Connection',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Server IP
                    TextField(
                      controller: _serverController,
                      decoration: const InputDecoration(
                        labelText: 'Server IP Address',
                        hintText: 'e.g., 192.168.1.100',
                        prefixIcon: Icon(Icons.computer),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Port
                    TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        hintText: '3306',
                        prefixIcon: Icon(Icons.network_check),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Database Name
                    TextField(
                      controller: _dbNameController,
                      decoration: const InputDecoration(
                        labelText: 'Database Name',
                        prefixIcon: Icon(Icons.database),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Username
                    TextField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),

                    // Connection Status
                    _buildConnectionStatus(),

                    // Action Buttons
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving || _isTesting ? null : _saveSettings,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: Text(_isSaving ? 'Saving...' : 'Save Settings'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isSaving || _isTesting ? null : _testConnection,
                            icon: _isTesting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.network_ping),
                            label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // App Information Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.deepPurple),
                        SizedBox(width: 8),
                        Text(
                          'Application Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const ListTile(
                      leading: Icon(Icons.app_registration),
                      title: Text('CS Price Scanner'),
                      subtitle: Text('Version 1.0.0'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.qr_code_scanner),
                      title: Text('Barcode Scanner'),
                      subtitle: Text('Supports keyboard wedge input and manual entry'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.storage),
                      title: Text('Database'),
                      subtitle: Text('Direct MySQL connection with mysql1 package'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.desktop_windows),
                      title: Text('Platform'),
                      subtitle: Text('Windows Desktop Application'),
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