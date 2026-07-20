import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:dtservices/utils/responsive_size.dart';
import 'package:dtservices/services/refill_service.dart';
import 'package:dtservices/services/user_session.dart';
import 'package:dtservices/models/refill_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/balance_provider.dart';
import '../../providers/transaction_provider.dart';

class RefillCodeScreen extends StatefulWidget {
  final String phoneNumber;
  final VoidCallback? onRefreshSolde;
  final bool isGift; // Pour savoir si c'est un cadeau ou pour soi-même

  const RefillCodeScreen({
    super.key,
    required this.phoneNumber,
    this.onRefreshSolde,
    this.isGift = false,
  });

  @override
  State<RefillCodeScreen> createState() => _RefillCodeScreenState();
}

class _RefillCodeScreenState extends State<RefillCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FocusNode _codeFocusNode = FocusNode();
  String? _codeError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codeFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            right: -100,
            child: Container(
              height: 350,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.dtBlueO08,
                    Colors.transparent,
                  ],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(title: AppLocalizations.of(context)!.refillTitle),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingM),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Numéro concerné (le titre est déjà dans le header)
                            Text(
                              widget.isGift
                                  ? AppLocalizations.of(
                                    context,
                                  )!.refillRecipient(widget.phoneNumber)
                                  : AppLocalizations.of(
                                    context,
                                  )!.refillMyNumber(widget.phoneNumber),
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(16),
                                color: Colors.grey[600],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Champ code de recharge
                            _buildRefillCodeField(),

                            // Erreur code
                            if (_codeError != null) ...[
                              const SizedBox(height: 8),
                              _buildErrorMessage(_codeError!),
                            ],

                            const SizedBox(height: 24),

                            // Information importante
                            _buildInfoBox(),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    0,
                    ResponsiveSize.getWidth(AppTheme.spacingM),
                    ResponsiveSize.getHeight(AppTheme.spacingL),
                  ),
                  child: _buildConfirmButton(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour le champ code de recharge
  Widget _buildRefillCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.refillCodeLabel,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border:
                _codeError != null
                    ? Border.all(color: Colors.red[300]!, width: 1.5)
                    : _codeFocusNode.hasFocus
                        ? Border.all(color: AppTheme.dtBlue, width: 1.5)
                        : null,
          ),
          child: TextFormField(
            controller: _codeController,
            focusNode: _codeFocusNode,
            decoration: InputDecoration(
              hintText: '1234 5678 9012',
              hintStyle: TextStyle(color: Colors.grey[500], letterSpacing: 2),
              prefixIcon: const Icon(Icons.dialpad, color: AppTheme.dtBlue),
              suffixIcon:
                  _codeController.text.replaceAll(' ', '').length == 12
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(18),
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              // Formater le code avec des espaces pour la lisibilité
              TextInputFormatter.withFunction((oldValue, newValue) {
                String newText = newValue.text.replaceAll(' ', '');
                if (newText.length <= 12) {
                  // Ajouter des espaces tous les 4 chiffres
                  String formatted = '';
                  for (int i = 0; i < newText.length; i += 4) {
                    if (i > 0) formatted += ' ';
                    formatted += newText.substring(
                      i,
                      i + 4 > newText.length ? newText.length : i + 4,
                    );
                  }
                  return TextEditingValue(
                    text: formatted,
                    selection: TextSelection.collapsed(
                      offset: formatted.length,
                    ),
                  );
                }
                return oldValue;
              }),
            ],
            onChanged: (value) {
              _validateCode(value);
            },
          ),
        ),
      ],
    );
  }

  // Widget pour les messages d'erreur
  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[600], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour la boîte d'information
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dtBlueO10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dtBlueO30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.dtBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.howToUseCode,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Une ligne par consigne, avec indentation suspendue sous la puce
          ...AppLocalizations.of(context)!.refillInstructions
              .split('\n')
              .map((line) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•',
                            style: TextStyle(
                                color: AppTheme.dtBlue, fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            line.replaceFirst(RegExp(r'^•\s*'), ''),
                            style: const TextStyle(
                                color: AppTheme.dtBlue, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  // Widget pour le bouton de confirmation
  Widget _buildConfirmButton() {
    final cleanCode = _codeController.text.replaceAll(' ', '');
    final bool isFormValid = _codeError == null && cleanCode.length == 12;

    return DtButton.primary(
      label: AppLocalizations.of(context)!.confirm,
      loading: _isLoading,
      onPressed: isFormValid ? _validateAndProcessRefill : null,
    );
  }

  // Pendant la frappe : on efface seulement l'erreur (la validation
  // complète a lieu à la soumission — pas de message pendant la saisie)
  void _validateCode(String value) {
    setState(() {
      _codeError = null;
    });
  }

  void _validateAndProcessRefill() async {
    final cleanCode = _codeController.text.replaceAll(' ', '');

    if (cleanCode.length != 12) {
      setState(() {
        _codeError = AppLocalizations.of(context)!.refillCodeLengthError;
      });
      return;
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleanCode)) {
      setState(() {
        _codeError = AppLocalizations.of(context)!.refillCodeDigitError;
      });
      return;
    }

    // Commencer le chargement
    setState(() {
      _isLoading = true;
      _codeError = null;
    });

    try {
      // Deux endpoints distincts : /air/refill/gift pour un autre numéro
      // (l'autorisation porte sur le payeur), /air/refill/voucher pour soi-même.
      final RefillResponse response;
      if (widget.isGift) {
        final payer = await UserSession.getPhoneNumber();
        if (payer == null || payer.isEmpty) {
          throw RefillException(
            code: -105,
            message: 'Session expirée, veuillez vous reconnecter',
          );
        }
        response = await RefillService.processGiftRefill(
          payerMsisdn: payer,
          beneficiaryMsisdn: widget.phoneNumber,
          voucherCode: cleanCode,
        );
      } else {
        response = await RefillService.processRefillCode(
          phoneNumber: widget.phoneNumber,
          voucherCode: cleanCode,
        );
      }

      if (!mounted) return;

      // Si succès, rafraîchir le solde, l'historique et afficher le dialog
      context.read<BalanceProvider>().refreshBalance();
      context.read<TransactionProvider>().refresh();
      _showSuccessDialog(response);
    } on RefillException catch (e) {
      // Gérer les erreurs spécifiques de recharge
      debugPrint('RefillException: ${e.toString()}');
      if (!mounted) return;
      setState(() {
        _codeError = e.userFriendlyMessage;
      });
    } catch (e, stackTrace) {
      debugPrint('Erreur inattendue: $e');
      debugPrint('StackTrace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _codeError = AppLocalizations.of(context)!.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(RefillResponse response) {
    // Extraire les informations de la réponse
    final newBalance = RefillService.getNewBalanceFromResponse(response);
    final refillAmount = RefillService.getRefillAmountFromResponse(response);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, color: Colors.green[600], size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.refillSuccessTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.isGift
                    ? AppLocalizations.of(
                      context,
                    )!.refillSuccessMessageGift(widget.phoneNumber)
                    : AppLocalizations.of(context)!.refillSuccessMessageMine,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (refillAmount != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.refillAmount,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${refillAmount.toStringAsFixed(0)} DJF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[600],
                        ),
                      ),
                      if (newBalance != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.refillNewBalance(newBalance.toStringAsFixed(2)),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Fermer le dialog et revenir à l'écran principal
                Navigator.of(context).pop(); // Fermer le dialog
                widget.onRefreshSolde?.call(); // Rafraîchir le solde
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                AppLocalizations.of(context)!.closeAction,
                style: const TextStyle(
                  color: AppTheme.dtBlue2,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

}
