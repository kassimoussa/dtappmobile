import 'dart:async';
import 'dart:math' as math;
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:flutter/material.dart';
import '../../constants/app_theme.dart';
import '../../utils/responsive_size.dart';
import '../../services/speedtest_service.dart';
import '../../generated/l10n/app_localizations.dart';

class SpeedtestNativeScreen extends StatefulWidget {
  const SpeedtestNativeScreen({super.key});

  @override
  State<SpeedtestNativeScreen> createState() => _SpeedtestNativeScreenState();
}

class _SpeedtestNativeScreenState extends State<SpeedtestNativeScreen>
    with SingleTickerProviderStateMixin {
  // Paliers d'échelle de la jauge (Mbps). La jauge ne redescend jamais en
  // cours de phase pour éviter que l'aiguille ne saute.
  static const List<double> _gaugeLadder = [
    10, 25, 50, 100, 250, 500, 1000, 2500,
  ];

  static const Color _downloadColor = Color(0xFF00C853);
  static const Color _uploadColor = Color(0xFFF9A825);
  static const Color _jitterColor = Color(0xFF7C4DFF);

  double _downloadRate = 0.0;
  double _uploadRate = 0.0;
  double _ping = 0.0;
  double _jitter = 0.0;
  double _liveSpeed = 0.0;
  double _gaugeMax = _gaugeLadder.first;

  bool _isTesting = false;
  TestingPhase _currentPhase = TestingPhase.idle;
  String? _errorMessage;

  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
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
      _errorMessage = null;
      _downloadRate = 0.0;
      _uploadRate = 0.0;
      _ping = 0.0;
      _jitter = 0.0;
      _liveSpeed = 0.0;
      _gaugeMax = _gaugeLadder.first;
      _currentPhase = TestingPhase.ping;
    });
    _animationController.repeat();

    try {
      // 1) Latence + gigue
      final latency = await SpeedTestService.measureLatency();
      if (!mounted) return;
      setState(() {
        _ping = latency.ping;
        _jitter = latency.jitter;
      });

      // 2) Download
      _enterPhase(TestingPhase.download);
      final download = await SpeedTestService.measureDownload(
        onProgress: _onLiveSpeed,
      );
      if (!mounted) return;
      setState(() => _downloadRate = download);

      // 3) Upload
      _enterPhase(TestingPhase.upload);
      final upload = await SpeedTestService.measureUpload(
        onProgress: _onLiveSpeed,
      );
      if (!mounted) return;
      setState(() => _uploadRate = upload);

      setState(() {
        _isTesting = false;
        _liveSpeed = 0.0;
        _currentPhase = TestingPhase.done;
        // Échelle finale cohérente avec la valeur download affichée.
        _gaugeMax = _gaugeLadder.firstWhere(
          (v) => v >= _downloadRate / 0.85,
          orElse: () => _gaugeLadder.last,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _errorMessage =
            AppLocalizations.of(context)!.speedTestError(e.toString());
        _currentPhase = TestingPhase.idle;
      });
    } finally {
      _animationController.stop();
      _animationController.reset();
    }
  }

  void _enterPhase(TestingPhase phase) {
    if (!mounted) return;
    setState(() {
      _currentPhase = phase;
      _liveSpeed = 0.0;
      _gaugeMax = _gaugeLadder.first;
    });
  }

  void _onLiveSpeed(double mbps) {
    if (!mounted) return;
    setState(() {
      _liveSpeed = mbps;
      final needed = _gaugeLadder.firstWhere(
        (v) => v >= mbps / 0.85,
        orElse: () => _gaugeLadder.last,
      );
      if (needed > _gaugeMax) _gaugeMax = needed;
    });
  }

  /// Vitesse affichée au centre de la jauge selon la phase.
  double get _displaySpeed {
    switch (_currentPhase) {
      case TestingPhase.download:
      case TestingPhase.upload:
        return _liveSpeed;
      case TestingPhase.done:
        return _downloadRate;
      case TestingPhase.idle:
      case TestingPhase.ping:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);

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
                  colors: [AppTheme.dtBlueO08, Colors.transparent],
                  radius: 0.8,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassAppBar(
                  title: AppLocalizations.of(context)!.speedTestTitle,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      ResponsiveSize.getWidth(AppTheme.spacingM),
                    ),
                    child: Column(
                      children: [
                        if (_errorMessage != null) ...[
                          _buildErrorBanner(),
                          SizedBox(
                            height: ResponsiveSize.getHeight(AppTheme.spacingM),
                          ),
                        ],
                        _buildSpeedGauge(),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingL),
                        ),
                        _buildResults(),
                        SizedBox(
                          height: ResponsiveSize.getHeight(AppTheme.spacingL),
                        ),
                        _buildTestButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusS),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedGauge() {
    final fraction = (_displaySpeed / _gaugeMax).clamp(0.0, 1.0);

    return Container(
      height: ResponsiveSize.getHeight(280),
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusL),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, _) {
              return CustomPaint(
                size: Size(
                  ResponsiveSize.getWidth(220),
                  ResponsiveSize.getHeight(220),
                ),
                painter: SpeedGaugePainter(
                  fraction: fraction,
                  gaugeMax: _gaugeMax,
                  isActive: _isTesting,
                  pulse: _animationController.value,
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _displaySpeed.toStringAsFixed(_displaySpeed >= 100 ? 0 : 1),
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(52),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                  height: 1.0,
                ),
              ),
              Text(
                'Mbps',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(15),
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(10)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isTesting) ...[
                    _PhaseDot(color: _phaseColor()),
                    SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
                  ],
                  Text(
                    _getPhaseText(),
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(13),
                      color: _phaseColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final l10n = AppLocalizations.of(context)!;
    final hasPing = _ping > 0;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: ResponsiveSize.getHeight(AppTheme.spacingM),
        horizontal: ResponsiveSize.getWidth(AppTheme.spacingS),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  Icons.download_rounded,
                  l10n.downloadLabel,
                  _downloadRate > 0 ? _downloadRate.toStringAsFixed(1) : '--',
                  'Mbps',
                  _downloadColor,
                ),
              ),
              _divider(),
              Expanded(
                child: _metricTile(
                  Icons.upload_rounded,
                  l10n.uploadLabel,
                  _uploadRate > 0 ? _uploadRate.toStringAsFixed(1) : '--',
                  'Mbps',
                  _uploadColor,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
            ),
            child: Divider(height: 1, color: Colors.grey.shade200),
          ),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  Icons.wifi_tethering_rounded,
                  l10n.pingLabel,
                  hasPing ? _ping.toStringAsFixed(0) : '--',
                  'ms',
                  AppTheme.dtBlue,
                ),
              ),
              _divider(),
              Expanded(
                child: _metricTile(
                  Icons.multiple_stop_rounded,
                  l10n.jitterLabel,
                  hasPing ? _jitter.toStringAsFixed(0) : '--',
                  'ms',
                  _jitterColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: ResponsiveSize.getHeight(44), color: Colors.grey.shade200);

  Widget _metricTile(
    IconData icon,
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: ResponsiveSize.getFontSize(20)),
            SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingXS)),
            Text(
              label,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(12),
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveSize.getHeight(6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(22),
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
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
    final l10n = AppLocalizations.of(context)!;
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
          disabledBackgroundColor: AppTheme.dtBlue.withValues(alpha: 0.4),
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
                    l10n.testingInProgress,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(16),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                l10n.startTest,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Color _phaseColor() {
    switch (_currentPhase) {
      case TestingPhase.download:
        return _downloadColor;
      case TestingPhase.upload:
        return _uploadColor;
      case TestingPhase.ping:
        return AppTheme.dtBlue;
      case TestingPhase.done:
        return _downloadColor;
      case TestingPhase.idle:
        return AppTheme.textSecondary;
    }
  }

  String _getPhaseText() {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentPhase) {
      case TestingPhase.idle:
        return l10n.phaseIdle;
      case TestingPhase.ping:
        return l10n.phasePing;
      case TestingPhase.download:
        return l10n.phaseDownload;
      case TestingPhase.upload:
        return l10n.phaseUpload;
      case TestingPhase.done:
        return l10n.phaseDone;
    }
  }
}

enum TestingPhase { idle, ping, download, upload, done }

class _PhaseDot extends StatelessWidget {
  final Color color;
  const _PhaseDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Jauge circulaire style Ookla, à échelle dynamique.
class SpeedGaugePainter extends CustomPainter {
  final double fraction; // 0..1
  final double gaugeMax;
  final bool isActive;
  final double pulse; // 0..1, anime le curseur pendant le test

  static const double _startAngle = math.pi * 0.75; // 135°
  static const double _sweepAngle = math.pi * 1.5; // 270°

  SpeedGaugePainter({
    required this.fraction,
    required this.gaugeMax,
    required this.isActive,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Arc de fond
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _startAngle,
      _sweepAngle,
      false,
      bgPaint,
    );

    // Graduations
    for (var i = 0; i <= 10; i++) {
      final a = _startAngle + (i * _sweepAngle / 10);
      final p1 = Offset(
        center.dx + (radius - 20) * math.cos(a),
        center.dy + (radius - 20) * math.sin(a),
      );
      final p2 = Offset(
        center.dx + (radius - 12) * math.cos(a),
        center.dy + (radius - 12) * math.sin(a),
      );
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = Colors.grey.shade400
          ..strokeWidth = 2,
      );
    }

    // Arc de progression (gradient)
    if (fraction > 0) {
      final progressPaint = Paint()
        ..shader = const SweepGradient(
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
          colors: [Color(0xFF00C853), Color(0xFFFFCA28), Color(0xFFFF6F00)],
          stops: [0.0, 0.5, 1.0],
          transform: GradientRotation(_startAngle),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _startAngle,
        _sweepAngle * fraction,
        false,
        progressPaint,
      );

      // Curseur au bout de l'arc (pulse pendant le test)
      final endAngle = _startAngle + _sweepAngle * fraction;
      final thumbCenter = Offset(
        center.dx + radius * math.cos(endAngle),
        center.dy + radius * math.sin(endAngle),
      );
      final glow = isActive ? (6 + 4 * math.sin(pulse * 2 * math.pi)) : 6.0;
      canvas.drawCircle(
        thumbCenter,
        glow + 4,
        Paint()..color = const Color(0xFFFF6F00).withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        thumbCenter,
        6,
        Paint()..color = Colors.white,
      );
      canvas.drawCircle(
        thumbCenter,
        6,
        Paint()
          ..color = const Color(0xFFFF6F00)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    // Libellés d'échelle (0 et max) aux extrémités de l'arc
    _drawLabel(canvas, center, radius, _startAngle, '0');
    _drawLabel(
      canvas,
      center,
      radius,
      _startAngle + _sweepAngle,
      _formatMax(gaugeMax),
    );
  }

  void _drawLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pos = Offset(
      center.dx + (radius - 34) * math.cos(angle) - tp.width / 2,
      center.dy + (radius - 34) * math.sin(angle) - tp.height / 2,
    );
    tp.paint(canvas, pos);
  }

  String _formatMax(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}G' : v.toStringAsFixed(0);

  @override
  bool shouldRepaint(SpeedGaugePainter old) =>
      old.fraction != fraction ||
      old.isActive != isActive ||
      old.gaugeMax != gaugeMax ||
      old.pulse != pulse;
}
