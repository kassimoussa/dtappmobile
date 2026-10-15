// lib/widgets/seasonal_animation.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../models/seasonal_event.dart';
import '../services/seasonal_event_service.dart';

/// Une animation d'événement posée dans la zone de son emplacement.
///
/// À placer dans un parent de taille définie (la zone) : la position et la
/// taille sont relatives à cette zone, pas en pixels, pour suivre les
/// différents écrans. Elle ne bloque jamais les touches et n'affiche rien tant
/// que le fichier n'est pas prêt ou si elle ne doit pas être jouée.
class SeasonalAnimation extends StatefulWidget {
  const SeasonalAnimation({super.key, required this.event, required this.spec});

  final SeasonalEvent event;
  final SeasonalAnimationSpec spec;

  /// Marge gardée sur les côtés gauche et droit (part de la largeur de la
  /// zone), pour que l'animation ne colle pas au bord. Verticalement elle reste
  /// collée au bord : une lanterne suspendue part du bord haut.
  static const double sideMargin = 0.05;

  @override
  State<SeasonalAnimation> createState() => _SeasonalAnimationState();
}

class _SeasonalAnimationState extends State<SeasonalAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  LottieComposition? _composition;
  bool _finished = false;

  SeasonalAnimationSpec get _spec => widget.spec;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    // Après le premier frame : un fichier déjà en cache est rendu de façon
    // synchrone, or le contexte (MediaQuery) n'est pas utilisable dans initState.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    if (!mounted) return;
    try {
      // Déjà en cache si le service l'a préchargé au splash.
      final composition = await _spec.provider.load();
      if (!mounted) return;

      final once = _spec.loop == SeasonalLoop.once;
      if (once && !await SeasonalEventService.shouldPlay(widget.event, _spec)) {
        return;
      }
      if (!mounted) return;

      // Animations réduites dans les réglages du téléphone : un décor se fige
      // sur sa première image, un effet joué une fois n'est pas montré.
      if (MediaQuery.disableAnimationsOf(context)) {
        if (!once) setState(() => _composition = composition);
        return;
      }

      _controller.duration = composition.duration;
      if (_spec.delay > Duration.zero) {
        await Future<void>.delayed(_spec.delay);
        if (!mounted) return;
      }

      setState(() => _composition = composition);

      if (once) {
        await SeasonalEventService.markPlayed(widget.event, _spec);
        await _controller.forward();
        if (mounted) setState(() => _finished = true);
      } else {
        _controller.repeat();
      }
    } catch (e) {
      // Fichier illisible : rien à afficher, jamais d'erreur visible.
      debugPrint('🎉 SeasonalAnimation ${_spec.id}: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final composition = _composition;
    if (composition == null || _finished) return const SizedBox.shrink();

    final alignment = _spec.position.alignment;

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final zoneWidth = constraints.maxWidth;
          final side =
              alignment.x == 0 ? 0.0 : zoneWidth * SeasonalAnimation.sideMargin;

          // OverflowBox : l'animation garde ses proportions même si elle est
          // plus haute que la zone (elle déborde alors, alignée sur la position).
          // minWidth/minHeight à 0 : sinon la zone, de taille fixe, imposerait
          // sa taille à l'animation.
          return OverflowBox(
            alignment: alignment,
            minWidth: 0,
            minHeight: 0,
            maxHeight: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: side),
              child: Lottie(
                composition: composition,
                controller: _controller,
                width: zoneWidth * _spec.widthFraction,
                fit: BoxFit.contain,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Toutes les animations de l'événement actif pour un emplacement, dans la zone
/// fournie par le parent. Ne dessine rien (et ne réserve aucune place) s'il n'y
/// en a pas.
class SeasonalSlot extends StatelessWidget {
  const SeasonalSlot(this.placement, {super.key});

  final SeasonalPlacement placement;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SeasonalEvent?>(
      valueListenable: SeasonalEventService.active,
      builder: (context, event, _) {
        final specs = event?.animationsFor(placement) ?? const [];
        if (event == null || specs.isEmpty) return const SizedBox.shrink();

        return Stack(
          fit: StackFit.expand,
          children: [
            for (final spec in specs)
              SeasonalAnimation(
                key: ValueKey('${event.id}:${spec.id}:${spec.animationUrl}'),
                event: event,
                spec: spec,
              ),
          ],
        );
      },
    );
  }
}
