import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/database_service.dart';
import '../services/settings_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final SettingsService _settingsService = SettingsService();
  final TextEditingController _barcodeController = TextEditingController();
  final FocusNode _barcodeFocus = FocusNode();

  Map<String, dynamic>? _currentProduct;
  bool _isLoading = false;
  String? _errorMessage;
  String _lastScannedBarcode = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus the barcode input for immediate scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _barcodeFocus.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode(String barcode) async {
    if (barcode.trim().isEmpty || barcode == _lastScannedBarcode) {
      return;
    }

    _lastScannedBarcode = barcode;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentProduct = null;
    });

    try {
      final product = await _databaseService.getProductByBarcode(barcode.trim());

      setState(() {
        _currentProduct = product;
        _isLoading = false;
        if (product == null) {
          _errorMessage = 'Product not found for barcode: $barcode';
        }
      });

      // Clear the input and refocus for next scan
      _barcodeController.clear();
      _barcodeFocus.requestFocus();

      // Play scan sound/feedback
      SystemSound.play(SystemSound.click);

    } catch (e) {
      setState(() {
        _errorMessage = 'Error scanning barcode: $e';
        _isLoading = false;
      });

      // Clear and refocus even on error
      _barcodeController.clear();
      _barcodeFocus.requestFocus();
    }
  }

  Widget _buildPriceCard(String title, String price, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return 'N/A';
    try {
      final numPrice = double.parse(price.toString());
      return '\$${numPrice.toStringAsFixed(2)}';
    } catch (e) {
      return price.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barcode Input Section
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 48,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'CS Price Scanner',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Scan barcode or enter manually',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _barcodeController,
                      focusNode: _barcodeFocus,
                      decoration: InputDecoration(
                        labelText: 'Barcode',
                        hintText: 'Scan or type barcode here...',
                        prefixIcon: const Icon(Icons.barcode_reader),
                        border: const OutlineInputBorder(),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.search),
                                onPressed: () => _scanBarcode(_barcodeController.text),
                              ),
                      ),
                      onSubmitted: _scanBarcode,
                      autofocus: true,
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
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
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Product Information Section
            if (_currentProduct != null) ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Header
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.inventory,
                                size: 32,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Item ID: ${_currentProduct!['itemId']}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Barcode: $_lastScannedBarcode',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Price Grid
                      const Text(
                        'Pricing Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildPriceCard(
                            'Retail Price',
                            _formatPrice(_currentProduct!['retailPrice']),
                            Colors.blue,
                          ),
                          _buildPriceCard(
                            'Wholesale Price',
                            _formatPrice(_currentProduct!['wholesalePrice']),
                            Colors.green,
                          ),
                          _buildPriceCard(
                            'Half Wholesale',
                            _formatPrice(_currentProduct!['halfWholesalePrice']),
                            Colors.orange,
                          ),
                          _buildPriceCard(
                            'Export Price',
                            _formatPrice(_currentProduct!['exportPrice']),
                            Colors.purple,
                          ),
                          _buildPriceCard(
                            'Consumer Price',
                            _formatPrice(_currentProduct!['consumerPrice']),
                            Colors.red,
                          ),
                          _buildPriceCard(
                            'Cost Price',
                            _formatPrice(_currentProduct!['costPrice']),
                            Colors.brown,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Last Price Card (Special highlighting)
                      Card(
                        elevation: 6,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.deepPurple.withOpacity(0.1), Colors.deepPurple.withOpacity(0.05)],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Last Transaction Price',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.deepPurple,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatPrice(_currentProduct!['lastPrice']),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else if (!_isLoading) ...[
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to scan',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use a barcode reader or type the code manually',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}