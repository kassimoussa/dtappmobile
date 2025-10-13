import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/speedtest_service.dart';

class SpeedtestNativeScreen extends StatefulWidget {
  const SpeedtestNativeScreen({super.key});

  @override
  State<SpeedtestNativeScreen> createState() => _SpeedtestNativeScreenState();
}

class _SpeedtestNativeScreenState extends State<SpeedtestNativeScreen>
    with SingleTickerProviderStateMixin {
  double _downloadRate = 0.0;
  double _uploadRate = 0.0;
  double _ping = 0.0;
  String _downloadProgress = '0';
  String _uploadProgress = '0';
  bool _isTesting = false;
  bool _testDone = false;
  final String _unitText = 'Mbps';
  TestingPhase _currentPhase = TestingPhase.idle;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startTest() async {
    setState(() {
      _isTesting = true;
      _testDone = false;
      _errorMessage = null;
      _downloadRate = 0.0;
      _uploadRate = 0.0;
      _ping = 0.0;
      _downloadProgress = '0';
      _uploadProgress = '0';
      _currentPhase = TestingPhase.ping;
    });

    _animationController.repeat();

    try {
      // Test du ping
      await _testPing();

      // Test de téléchargement
      setState(() {
        _currentPhase = TestingPhase.download;
      });
      await _testDownloadSpeed();

      // Test d'upload
      setState(() {
        _currentPhase = TestingPhase.upload;
      });
      await _testUploadSpeed();

      setState(() {
        _isTesting = false;
        _testDone = true;
        _currentPhase = TestingPhase.done;
      });
    } catch (e) {
      setState(() {
        _isTesting = false;
        _testDone = false;
        _errorMessage = 'Erreur: ${e.toString()}';
        _currentPhase = TestingPhase.idle;
      });
    } finally {
      _animationController.stop();
      _animationController.reset();
    }
  }

  Future<void> _testPing() async {
    try {
      final ping = await SpeedTestService.testPing();
      if (mounted) {
        setState(() {
          _ping = ping;
        });
      }
    } catch (e) {
      debugPrint('Erreur ping: $e');
    }
  }

  Future<void> _testDownloadSpeed() async {
    try {
      final result = await SpeedTestService.testDownloadSpeed(
        onProgress: (progress, currentSpeed) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress.toStringAsFixed(1);
              _downloadRate = currentSpeed;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _downloadRate = result.speedMbps;
          _downloadProgress = '100';
        });
      }
    } catch (e) {
      debugPrint('Erreur download: $e');
      rethrow;
    }
  }

  Future<void> _testUploadSpeed() async {
    try {
      final result = await SpeedTestService.testUploadSpeed(
        onProgress: (progress, currentSpeed) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress.toStringAsFixed(1);
              _uploadRate = currentSpeed;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _uploadRate = result.speedMbps;
          _uploadProgress = '100';
        });
      }
    } catch (e) {
      debugPrint('Erreur upload: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Speed Test',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
          child: Column(
            children: [
              // Message d'erreur si présent
              if (_errorMessage != null) ...[
                Container(
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusS),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              ],

              // Jauge de vitesse principale (style Ookla)
              _buildSpeedGauge(),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Résultats compacts
              _buildCompactResults(),

              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),

              // Bouton de test
              _buildTestButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedGauge() {
    double currentSpeed = _currentPhase == TestingPhase.download
        ? _downloadRate
        : _currentPhase == TestingPhase.upload
            ? _uploadRate
            : 0.0;

    // Calculer l'angle de la jauge (0 à 270 degrés)
    double maxDisplaySpeed = 100.0;
    double angle = (currentSpeed / maxDisplaySpeed) * 270;
    if (angle > 270) angle = 270;

    return Container(
      height: ResponsiveSize.getHeight(250),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Jauge de fond
          CustomPaint(
            size: Size(ResponsiveSize.getWidth(200), ResponsiveSize.getHeight(200)),
            painter: SpeedGaugePainter(
              angle: angle,
              isActive: _isTesting,
            ),
          ),
          // Vitesse au centre
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currentSpeed.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(52),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              Text(
                _unitText,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(8)),
              Text(
                _getPhaseText(),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(13),
                  color: AppTheme.dtYellow,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactResults() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGrey,
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResultItem(
            Icons.download_rounded,
            'Download',
            _downloadRate.toStringAsFixed(2),
            _unitText,
            const Color(0xFF00C853),
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          _buildResultItem(
            Icons.upload_rounded,
            'Upload',
            _uploadRate.toStringAsFixed(2),
            _unitText,
            AppTheme.dtYellow,
          ),
          Container(width: 1, height: 50, color: Colors.grey.shade300),
          _buildResultItem(
            Icons.timer_outlined,
            'Ping',
            _ping > 0 ? _ping.toStringAsFixed(0) : '--',
            'ms',
            AppTheme.dtBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String label, String value, String unit, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: ResponsiveSize.getFontSize(28)),
        SizedBox(height: ResponsiveSize.getHeight(6)),
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(11),
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: ResponsiveSize.getHeight(4)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(20),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(width: 3),
            Text(
              unit,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(11),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isTesting ? null : _startTest,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.dtBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: ResponsiveSize.getHeight(18),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              ResponsiveSize.getWidth(AppTheme.radiusM),
            ),
          ),
          disabledBackgroundColor: AppTheme.dtBlue.withOpacity(0.4),
          elevation: 4,
        ),
        child: _isTesting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: ResponsiveSize.getWidth(20),
                    height: ResponsiveSize.getHeight(20),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                  Text(
                    'Test en cours...',
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                'LANCER LE TEST',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  String _getPhaseText() {
    switch (_currentPhase) {
      case TestingPhase.idle:
        return 'Prêt à tester';
      case TestingPhase.ping:
        return 'Test du ping...';
      case TestingPhase.download:
        return 'Test de téléchargement...';
      case TestingPhase.upload:
        return 'Test d\'upload...';
      case TestingPhase.done:
        return 'Test terminé';
    }
  }
}

enum TestingPhase {
  idle,
  ping,
  download,
  upload,
  done,
}

// Custom Painter pour la jauge de vitesse style Ookla
class SpeedGaugePainter extends CustomPainter {
  final double angle;
  final bool isActive;

  SpeedGaugePainter({required this.angle, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Dessiner l'arc de fond (gris clair)
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      math.pi * 0.65, // Début à 135 degrés
      math.pi * 1.5, // 270 degrés au total
      false,
      backgroundPaint,
    );

    // Dessiner l'arc de progression (coloré avec gradient)
    if (isActive && angle > 0) {
      final progressPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF00C853), // Vert
            AppTheme.dtYellow, // Jaune DT
            const Color(0xFFFF6F00), // Orange
          ],
          stops: [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        math.pi * 0.65,
        (angle * math.pi) / 180,
        false,
        progressPaint,
      );
    }

    // Dessiner des graduations
    for (int i = 0; i <= 10; i++) {
      final tickAngle = (math.pi * 0.65) + (i * math.pi * 1.5 / 10);
      final startRadius = radius - 30;
      final endRadius = radius - 8;

      final start = Offset(
        center.dx + startRadius * math.cos(tickAngle),
        center.dy + startRadius * math.sin(tickAngle),
      );

      final end = Offset(
        center.dx + endRadius * math.cos(tickAngle),
        center.dy + endRadius * math.sin(tickAngle),
      );

      final tickPaint = Paint()
        ..color = Colors.grey.shade400
        ..strokeWidth = 2;

      canvas.drawLine(start, end, tickPaint);
    }
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.isActive != isActive;
  }
}
