import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_header.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double? activationFee;

  const PaymentScreen({
    super.key,
    this.activationFee,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  bool _isFetchingFee = true;
  String _selectedPaymentMethod = 'mastercard';
  double _activationFee = 1.0;
  double _serviceFee = 0.0;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchActivationFee();
  }

  Future<void> _fetchActivationFee() async {
    if (widget.activationFee != null) {
      setState(() {
        _activationFee = widget.activationFee!;
        _serviceFee = 0.0;
        _isFetchingFee = false;
      });
      return;
    }

    try {
      // For now, use default fee. In the future, fetch from backend settings
      setState(() {
        _activationFee = 1.0;
        _serviceFee = 0.0;
        _isFetchingFee = false;
      });
    } catch (e) {
      setState(() {
        _activationFee = 1.0;
        _serviceFee = 0.0;
        _isFetchingFee = false;
      });
    }
  }

  double get _totalAmount => _activationFee + _serviceFee;

  Future<void> _processPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Please login to continue';
          _isLoading = false;
        });
        return;
      }

      debugPrint('Processing payment...');
      debugPrint('Payment method: $_selectedPaymentMethod');
      debugPrint('Amount: $_totalAmount KWD');

      // Call the activation API
      final response = await ApiService.post(
        'mobile/candidate/activate',
        {
          'method': _selectedPaymentMethod,
          'currency': 'KWD',
        },
        token: token,
      );

      debugPrint('Activation response: $response');

      // Extract transaction info from response
      final transaction = response['transaction'] as Map<String, dynamic>?;
      final transactionId = transaction?['reference'] as String? ?? 'TXN${DateTime.now().millisecondsSinceEpoch}';

      if (mounted) {
        // Refresh user data to get updated profile
        await AuthService.getCurrentUser();

        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              transactionId: transactionId,
              amount: _totalAmount,
              paymentMethod: _selectedPaymentMethod,
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      debugPrint('Payment ApiException: ${e.statusCode} - ${e.message}');
      setState(() {
        if (e.message.contains('already activated')) {
          _errorMessage = 'Your profile is already activated!';
        } else {
          _errorMessage = e.message;
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Payment error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PaymentMethodSheet(
        selectedMethod: _selectedPaymentMethod,
        onSelect: (method) {
          setState(() {
            _selectedPaymentMethod = method;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'mastercard':
        return 'Master Card';
      case 'knet':
        return 'Knet';
      case 'paypal':
        return 'PayPal';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Card Payment';
    }
  }

  String _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'mastercard':
        return 'assets/images/icons/mastercard.png';
      case 'knet':
        return 'assets/images/icons/knet.png';
      case 'paypal':
        return 'assets/images/icons/paypal.png';
      case 'bank_transfer':
        return 'assets/images/icons/bank.png';
      default:
        return 'assets/images/icons/card.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            const AppHeader(showLanguageWithActions: true),

            // Main Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(56),
                    topRight: Radius.circular(56),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        height: 6,
                        width: 60,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const Expanded(
                            child: Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Content
                    Expanded(
                      child: _isFetchingFee
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Error message
                                  if (_errorMessage != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                  ],

                                  // Payment Summary Card
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppTheme.bodySurfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Payment Summary',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                'Pending',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        _buildSummaryRow('Activation Fee', _activationFee),
                                        if (_serviceFee > 0) ...[
                                          const SizedBox(height: 12),
                                          _buildSummaryRow('Service Fee', _serviceFee),
                                        ],
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 16),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Total Payment',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                            Text(
                                              'KWD ${_totalAmount.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Payment Method
                                  GestureDetector(
                                    onTap: _showPaymentMethodSheet,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppTheme.bodySurfaceColor,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: _getPaymentIcon(_selectedPaymentMethod),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _getPaymentMethodName(_selectedPaymentMethod),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textPrimary,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  'Tap to change payment method',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppTheme.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.chevron_right,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Info Text
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.blue.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'This is a one-time activation fee. Once paid, you can apply for unlimited jobs.',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.blue.shade700,
                                              height: 1.4,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),

                    // Bottom Button
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _processPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Pay KWD ${_totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
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

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          'KWD ${amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _getPaymentIcon(String method) {
    IconData iconData;
    Color color;

    switch (method) {
      case 'mastercard':
        iconData = Icons.credit_card;
        color = Colors.red;
        break;
      case 'knet':
        iconData = Icons.account_balance;
        color = AppTheme.primaryColor;
        break;
      case 'paypal':
        iconData = Icons.paypal;
        color = Colors.blue;
        break;
      case 'bank_transfer':
        iconData = Icons.account_balance;
        color = AppTheme.textPrimary;
        break;
      default:
        iconData = Icons.credit_card;
        color = AppTheme.textPrimary;
    }

    return Icon(iconData, color: color, size: 24);
  }
}

class _PaymentMethodSheet extends StatelessWidget {
  final String selectedMethod;
  final Function(String) onSelect;

  const _PaymentMethodSheet({
    required this.selectedMethod,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Payment Methods
          _buildMethodTile(
            context,
            'mastercard',
            'Master Card',
            '•••• 3154',
            Icons.credit_card,
            Colors.red,
          ),
          const SizedBox(height: 12),
          _buildMethodTile(
            context,
            'knet',
            'Knet',
            '•••• 3154',
            Icons.account_balance,
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 12),
          _buildMethodTile(
            context,
            'bank_transfer',
            'Bank Transfers',
            'Select Bank Integration',
            Icons.account_balance,
            AppTheme.textPrimary,
            showArrow: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMethodTile(
    BuildContext context,
    String method,
    String title,
    String subtitle,
    IconData icon,
    Color iconColor, {
    bool showArrow = false,
  }) {
    final isSelected = selectedMethod == method;

    return GestureDetector(
      onTap: () => onSelect(method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bodySurfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.primaryColor, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary)
            else if (isSelected)
              Icon(Icons.check, color: AppTheme.primaryColor),
          ],
        ),
      ),
    );
  }
}
