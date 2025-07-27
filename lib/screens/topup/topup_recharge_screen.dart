// lib/screens/topup/topup_recharge_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../widgets/appbar_widget.dart';
import '../../services/topup_api_service.dart';
import '../../exceptions/topup_exception.dart';
import '../../routes/custom_route_transitions.dart';
import '../../extensions/color_extensions.dart';
import 'topup_recharge_success_screen.dart';

class TopUpRechargeScreen extends StatefulWidget {
  final String fixedNumber;
  final String mobileNumber;
  final double soldeActuel;

  const TopUpRechargeScreen({
    super.key,
    required this.fixedNumber,
    required this.mobileNumber,
    required this.soldeActuel,
  });

  @override
  State<TopUpRechargeScreen> createState() => _TopUpRechargeScreenState();
}

class _TopUpRechargeScreenState extends State<TopUpRechargeScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Montants prédéfinis
  final List<double> _predefinedAmounts = [500, 1000, 2000, 5000, 10000];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _rechargeAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    
    if (amount > widget.soldeActuel) {
      _showErrorMessage('Solde insuffisant pour cette recharge.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('TopUp - Début recharge: ${amount.toStringAsFixed(0)} DJF');

      final response = await TopUpApi.instance.rechargeAccount(
        msisdn: widget.mobileNumber,
        isdn: widget.fixedNumber,
        amount: amount,
        pincode: _pinController.text.isNotEmpty ? _pinController.text : null,
      );

      if (mounted) {
        final success = response['success'] ?? false;
        
        if (success) {
          // Succès - naviguer vers l'écran de succès
          Navigator.pushReplacement(
            context,
            CustomRouteTransitions.fadeRoute(
              page: TopUpRechargeSuccessScreen(
                amount: amount,
                mobileNumber: widget.mobileNumber,
                fixedNumber: widget.fixedNumber,
                transactionId: response['transaction_id'] ?? '',
                accountImpact: response['account_impact'],
              ),
            ),
          );
        } else {
          final errorMessage = response['message'] ?? 'Erreur lors de la recharge';
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      debugPrint('TopUp - Erreur recharge: $e');
      
      if (mounted) {
        String errorMessage = 'Erreur de connexion';
        
        if (e is TopUpException) {
          errorMessage = e.userFriendlyMessage;
        } else {
          errorMessage = 'Erreur inattendue: ${e.toString().replaceAll('Exception: ', '')}';
        }
        
        _showErrorMessage(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: ResponsiveSize.getWidth(8)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(8)),
        ),
      ),
    );
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez saisir un montant';
    }
    
    final amount = double.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Montant invalide';
    }
    
    if (amount < 100) {
      return 'Montant minimum: 100 DJF';
    }
    
    if (amount > 50000) {
      return 'Montant maximum: 50 000 DJF';
    }
    
    if (amount > widget.soldeActuel) {
      return 'Solde insuffisant (${widget.soldeActuel.toStringAsFixed(0)} DJF)';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBarWidget(
        title: 'Recharger compte fixe',
        showAction: false,
        showCancelToHome: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildAccountInfo(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildPredefinedAmounts(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildAmountInput(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
                _buildPinInput(),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingXL)),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: AppTheme.dtBlue.withOpacityValue(0.1),
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(
          color: AppTheme.dtBlue.withOpacityValue(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet,
            color: AppTheme.dtBlue,
            size: ResponsiveSize.getFontSize(32),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          Text(
            'Recharge de compte',
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(20),
              fontWeight: FontWeight.bold,
              color: AppTheme.dtBlue,
            ),
          ),
          SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
          Text(
            'Transférez du crédit de votre mobile vers votre ligne fixe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('Mobile (source)', widget.mobileNumber),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildInfoRow('Fixe (destination)', widget.fixedNumber),
          Divider(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
          _buildInfoRow('Solde mobile disponible', '${widget.soldeActuel.toStringAsFixed(0)} DJF'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(14),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildPredefinedAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montants rapides',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
        Wrap(
          spacing: ResponsiveSize.getWidth(AppTheme.spacingS),
          runSpacing: ResponsiveSize.getHeight(AppTheme.spacingS),
          children: _predefinedAmounts.map((amount) {
            final isAffordable = amount <= widget.soldeActuel;
            return GestureDetector(
              onTap: isAffordable ? () {
                _amountController.text = amount.toStringAsFixed(0);
              } : null,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                  vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
                ),
                decoration: BoxDecoration(
                  color: isAffordable ? AppTheme.dtYellow.withOpacityValue(0.1) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
                  border: Border.all(
                    color: isAffordable ? AppTheme.dtYellow : Colors.grey[400]!,
                  ),
                ),
                child: Text(
                  '${amount.toStringAsFixed(0)} DJF',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    fontWeight: FontWeight.w600,
                    color: isAffordable ? AppTheme.dtBlue : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Montant à transférer *',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(5),
          ],
          decoration: InputDecoration(
            hintText: 'Ex: 1000',
            suffixText: 'DJF',
            prefixIcon: Icon(Icons.payments, color: AppTheme.dtBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
            ),
          ),
          validator: _validateAmount,
        ),
      ],
    );
  }

  Widget _buildPinInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code PIN (optionnel)',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: AppTheme.dtBlue,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        TextFormField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          decoration: InputDecoration(
            hintText: '0000',
            prefixIcon: Icon(Icons.lock, color: AppTheme.dtBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
              borderSide: BorderSide(color: AppTheme.dtBlue, width: 2),
            ),
          ),
          validator: (value) {
            if (value != null && value.isNotEmpty && value.length != 4) {
              return 'Le code PIN doit contenir 4 chiffres';
            }
            return null;
          },
        ),
        SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
        Text(
          'Si non renseigné, le code par défaut (0000) sera utilisé',
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(12),
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _rechargeAccount,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.dtBlue,
        foregroundColor: AppTheme.dtYellow,
        padding: EdgeInsets.symmetric(
          vertical: ResponsiveSize.getHeight(16),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveSize.getWidth(AppTheme.radiusM),
          ),
        ),
        elevation: _isLoading ? 0 : 2,
      ),
      child: _isLoading
          ? SizedBox(
              width: ResponsiveSize.getWidth(20),
              height: ResponsiveSize.getHeight(20),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtYellow),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.send,
                  size: ResponsiveSize.getFontSize(18),
                ),
                SizedBox(width: ResponsiveSize.getWidth(8)),
                Text(
                  'Effectuer la recharge',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }
}