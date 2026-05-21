import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Enveloppe l'app et affiche une bannière rouge en haut quand il n'y a
/// pas de connexion. Disparaît automatiquement dès que la connexion revient.
class ConnectivityBanner extends StatefulWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late StreamSubscription<List<ConnectivityResult>> _sub;
  bool _isOffline = false;
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    // Vérifier l'état initial
    Connectivity().checkConnectivity().then(_handleResults);

    // Écouter les changements
    _sub = Connectivity()
        .onConnectivityChanged
        .listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final offline = results.every((r) => r == ConnectivityResult.none);
    if (offline != _isOffline) {
      setState(() => _isOffline = offline);
      if (offline) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
      children: [
        widget.child,
        if (_isOffline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                color: Colors.transparent,
                child: SafeArea(
                  bottom: false,
                  child: Container(
                    color: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Pas de connexion',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
      ),
    );
  }
}
