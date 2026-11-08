import 'dart:async';

import 'package:dtservices/constants/app_theme.dart';
import 'package:dtservices/utils/refill_voucher_parser.dart';
import 'package:dtservices/widgets/dt_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../generated/l10n/app_localizations.dart';

/// Scanne le QR code d'un ticket de recharge. Renvoie le code à 12 chiffres
/// (`Navigator.pop`), ou rien si l'utilisateur revient en arrière.
///
/// Rien n'est envoyé au serveur ici : l'écran de recharge remplit le champ, et
/// l'utilisateur confirme lui-même.
class RefillScanScreen extends StatefulWidget {
  const RefillScanScreen({super.key});

  @override
  State<RefillScanScreen> createState() => _RefillScanScreenState();
}

class _RefillScanScreenState extends State<RefillScanScreen> {
  static const _invalidFor = Duration(seconds: 2);

  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
  );
  Timer? _invalidTimer;
  bool _invalid = false;
  bool _done = false;

  @override
  void dispose() {
    _invalidTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_done) return;

    var sawQr = false;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null) continue;
      sawQr = true;

      final code = RefillVoucherParser.extractCode(raw);
      if (code != null) {
        _done = true;
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(code);
        return;
      }
    }
    if (sawQr) _flagInvalid();
  }

  // Un QR code qui n'est pas un ticket : on le dit un instant, puis on continue
  // de chercher.
  void _flagInvalid() {
    if (!_invalid) setState(() => _invalid = true);
    _invalidTimer?.cancel();
    _invalidTimer = Timer(_invalidFor, () {
      if (mounted) setState(() => _invalid = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final side = (MediaQuery.sizeOf(context).width * 0.68).clamp(220.0, 300.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder:
                (context, error) => _ScanError(
                  permissionDenied:
                      error.errorCode ==
                      MobileScannerErrorCode.permissionDenied,
                ),
          ),
          Center(
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _invalid ? Colors.redAccent : Colors.white,
                  width: 3,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(l10n),
                const Spacer(),
                _Pill(
                  text: _invalid ? l10n.refillScanInvalid : l10n.refillScanHint,
                  color: _invalid ? Colors.red.shade700 : Colors.black54,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          ),
          Expanded(
            child: Text(
              l10n.refillScanTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _controller,
            builder: (context, state, _) {
              // Pas de lampe sur cet appareil : on garde la place pour que le
              // titre ne bouge pas.
              if (state.torchState == TorchState.unavailable) {
                return const SizedBox(width: 48);
              }
              final on = state.torchState == TorchState.on;
              return IconButton(
                onPressed: _controller.toggleTorch,
                tooltip: l10n.refillScanTorch,
                icon: Icon(
                  on ? Icons.flash_on : Icons.flash_off,
                  color: on ? AppTheme.dtYellow : Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}

/// Caméra refusée ou indisponible : l'utilisateur peut toujours saisir le code.
class _ScanError extends StatelessWidget {
  final bool permissionDenied;

  const _ScanError({required this.permissionDenied});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                permissionDenied
                    ? l10n.refillScanPermissionDenied
                    : l10n.refillScanUnavailable,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              if (permissionDenied) ...[
                const SizedBox(height: 24),
                DtButton.primary(
                  label: l10n.refillScanOpenSettings,
                  onPressed: openAppSettings,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
