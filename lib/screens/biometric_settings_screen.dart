import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';
import '../config/security_config.dart';

class BiometricSettingsScreen extends StatefulWidget {
  const BiometricSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BiometricSettingsScreen> createState() => _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState extends State<BiometricSettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final SecureStorageService _secureStorage = SecureStorageService();
  bool _isBiometricEnabled = false;
  bool _isLoading = true;
  List<BiometricType> _availableBiometrics = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final isEnabled = await _secureStorage.getBiometricSettings();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      
      setState(() {
        _isBiometricEnabled = isEnabled;
        _availableBiometrics = availableBiometrics;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading settings: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Verify biometric is available before enabling
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) {
        setState(() {
          _errorMessage = 'Biometric authentication is not available';
        });
        return;
      }

      // Test authentication before enabling
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to enable biometric login',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!authenticated) {
        setState(() {
          _errorMessage = 'Authentication failed';
        });
        return;
      }
    }

    try {
      await _secureStorage.storeBiometricSettings(value);
      setState(() {
        _isBiometricEnabled = value;
        _errorMessage = '';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving settings: $e';
      });
    }
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Biometric Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Biometric Authentication',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _availableBiometrics.isEmpty
                                ? 'No biometrics enrolled'
                                : 'Available: ${_availableBiometrics.map(_getBiometricTypeName).join(", ")}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Enable/Disable Switch
                  SwitchListTile(
                    title: const Text('Enable Biometric Login'),
                    subtitle: const Text(
                      'Use biometric authentication to unlock your vault',
                    ),
                    value: _isBiometricEnabled,
                    onChanged: _toggleBiometric,
                  ),
                  const SizedBox(height: 16),

                  // Security Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Security Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          _buildSecurityInfoItem(
                            'Auto-lock',
                            'Vault locks after ${SecurityConfig.sessionTimeout.inMinutes} minutes of inactivity',
                          ),
                          _buildSecurityInfoItem(
                            'Biometric Timeout',
                            'Biometric authentication expires after ${SecurityConfig.biometricTimeout.inMinutes} minutes',
                          ),
                          _buildSecurityInfoItem(
                            'Fallback',
                            'Master password can always be used as a fallback',
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage,
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSecurityInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 