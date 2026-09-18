import 'dart:math';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

class RegistrationScreen extends StatefulWidget {
  final VoidCallback onRegistered;

  const RegistrationScreen({super.key, required this.onRegistered});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _registrationCodeController = TextEditingController();

  String _deviceCode = '';
  String _expectedRegistrationCode = '';
  bool _isLoading = true;
  bool _isRegistering = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _generateDeviceCode();
  }

  @override
  void dispose() {
    _registrationCodeController.dispose();
    super.dispose();
  }

  Future<void> _generateDeviceCode() async {
    try {
      // Check if we already have a stored device ID
      String? existingDeviceId = await _settingsService.getDeviceId();

      if (existingDeviceId == null || existingDeviceId.isEmpty) {
        // Generate new device-specific code
        final deviceInfo = DeviceInfoPlugin();
        final windowsInfo = await deviceInfo.windowsInfo();

        // Create a device-specific identifier using system info
        final deviceString = '${windowsInfo.computerName}-${windowsInfo.systemMemoryInMegabytes}-${windowsInfo.numberOfCores}';

        // Generate a consistent numeric code from device info
        final hash = deviceString.hashCode.abs();
        final deviceCode = (hash % 900000 + 100000).toString(); // 6-digit code

        await _settingsService.setDeviceId(deviceCode);
        existingDeviceId = deviceCode;
      }

      final deviceCodeInt = int.parse(existingDeviceId);
      final expectedCode = ((deviceCodeInt / 2) + 8).round().toString();

      setState(() {
        _deviceCode = existingDeviceId;
        _expectedRegistrationCode = expectedCode;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating device code: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    final enteredCode = _registrationCodeController.text.trim();

    if (enteredCode.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the registration code';
      });
      return;
    }

    if (enteredCode != _expectedRegistrationCode) {
      setState(() {
        _errorMessage = 'Invalid registration code. Please check and try again.';
      });
      return;
    }

    setState(() {
      _isRegistering = true;
      _errorMessage = null;
    });

    try {
      // Check if we have database settings configured
      final hasSettings = await _settingsService.hasConnectionSettings();

      if (!hasSettings) {
        setState(() {
          _errorMessage = 'Please configure database settings first';
          _isRegistering = false;
        });
        _showSettingsDialog();
        return;
      }

      // Validate with database
      final userId = await _databaseService.getUserIdByDeviceId(_deviceCode);

      if (userId != null && userId.isNotEmpty) {
        await _settingsService.setUserId(userId);

        // Check user duration
        final duration = await _databaseService.getUserDuration(userId);
        if (duration <= 0) {
          setState(() {
            _errorMessage = 'License expired. Please contact administrator.';
            _isRegistering = false;
          });
          return;
        }

        widget.onRegistered();
      } else {
        setState(() {
          _errorMessage = 'Device not authorized. Please contact administrator.';
          _isRegistering = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Registration failed: $e';
        _isRegistering = false;
      });
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => const DatabaseSettingsDialog(),
    ).then((_) {
      // After settings dialog closes, try registration again
      _register();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CS Price Scanner - Registration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.security,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Device Registration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else ...[
                    const Text(
                      'Your device code is:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _deviceCode,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Calculate: (Device Code ÷ 2) + 8',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _registrationCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Registration Code',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      keyboardType: TextInputType.number,
                      onSubmitted: (_) => _register(),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          border: Border.all(color: Colors.red[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: Colors.red[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isRegistering ? null : _register,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                        child: _isRegistering
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Register Device',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _showSettingsDialog,
                      child: const Text('Configure Database Settings'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DatabaseSettingsDialog extends StatefulWidget {
  const DatabaseSettingsDialog({super.key});

  @override
  State<DatabaseSettingsDialog> createState() => _DatabaseSettingsDialogState();
}

class _DatabaseSettingsDialogState extends State<DatabaseSettingsDialog> {
  final SettingsService _settingsService = SettingsService();
  final DatabaseService _databaseService = DatabaseService();

  final TextEditingController _serverController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _dbNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = true;
  bool _isTesting = false;
  bool _isSaving = false;
  String? _statusMessage;
  bool _isSuccess = false;

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
    final serverIP = await _settingsService.getServerIP();
    final port = await _settingsService.getPort();
    final dbName = await _settingsService.getDbName();
    final username = await _settingsService.getUsername();
    final password = await _settingsService.getPassword();

    setState(() {
      _serverController.text = serverIP ?? '';
      _portController.text = port.toString();
      _dbNameController.text = dbName ?? '';
      _usernameController.text = username ?? '';
      _passwordController.text = password ?? '';
      _isLoading = false;
    });
  }

  Future<void> _testConnection() async {
    await _saveSettings();

    setState(() {
      _isTesting = true;
      _statusMessage = null;
    });

    try {
      final isConnected = await _databaseService.testConnection();
      setState(() {
        _isSuccess = isConnected;
        _statusMessage = isConnected
            ? 'Connection successful!'
            : 'Connection failed. Please check your settings.';
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Connection error: $e';
        _isTesting = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    await _settingsService.setServerIP(_serverController.text.trim());
    await _settingsService.setPort(int.tryParse(_portController.text) ?? 3306);
    await _settingsService.setDbName(_dbNameController.text.trim());
    await _settingsService.setUsername(_usernameController.text.trim());
    await _settingsService.setPassword(_passwordController.text.trim());

    setState(() {
      _isSaving = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Database Settings'),
      content: _isLoading
          ? const SizedBox(
              width: 300,
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _serverController,
                    decoration: const InputDecoration(
                      labelText: 'Server IP',
                      hintText: 'e.g., 192.168.1.100',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      hintText: '3306',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dbNameController,
                    decoration: const InputDecoration(
                      labelText: 'Database Name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  if (_statusMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isSuccess ? Colors.green[50] : Colors.red[50],
                        border: Border.all(
                          color: _isSuccess ? Colors.green[300]! : Colors.red[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error,
                            color: _isSuccess ? Colors.green[700] : Colors.red[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _isSuccess ? Colors.green[700] : Colors.red[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isTesting || _isSaving ? null : _testConnection,
          child: _isTesting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Test Connection'),
        ),
        ElevatedButton(
          onPressed: _isTesting || _isSaving ? null : () async {
            await _saveSettings();
            if (mounted) Navigator.of(context).pop();
          },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}