// lib/widgets/seasonal_banner_strip.dart
import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/seasonal_event.dart';
import '../services/seasonal_event_service.dart';
import '../utils/responsive_size.dart';
import 'seasonal_animation.dart';

/// Bandeau d'événement entre les actions rapides et les bannières promo
/// (emplacement `banner_strip`) : l'animation, et le titre de l'événement s'il y
/// en a un. Ne prend aucune place tant qu'aucun événement ne l'utilise.
class SeasonalBannerStrip extends StatelessWidget {
  const SeasonalBannerStrip({super.key});

  /// Hauteur de la zone, en unités de maquette (375 de large).
  static const double designHeight = 64;

  /// Hauteur réellement ajoutée à l'écran (zone + espace avant les bannières),
  /// pour que l'ajustement de la page en tienne compte.
  static double get extraHeight =>
      SeasonalEventService.has(SeasonalPlacement.bannerStrip)
          ? ResponsiveSize.getHeight(designHeight + 12)
          : 0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SeasonalEvent?>(
      valueListenable: SeasonalEventService.active,
      builder: (context, event, _) {
        final specs =
            event?.animationsFor(SeasonalPlacement.bannerStrip) ?? const [];
        if (specs.isEmpty) return const SizedBox.shrink();

        final language = Localizations.localeOf(context).languageCode;
        final titled = specs.where((s) => s.titleFor(language) != null);
        final spec = titled.isEmpty ? null : titled.first;
        final title = spec?.titleFor(language);

        return Padding(
          padding: EdgeInsets.only(bottom: ResponsiveSize.getHeight(12)),
          child: SizedBox(
            height: ResponsiveSize.getHeight(designHeight),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Le titre laisse la place à l'animation du côté où elle est.
                final reserved =
                    spec == null
                        ? 0.0
                        : constraints.maxWidth *
                            (spec.widthFraction +
                                SeasonalAnimation.sideMargin * 2);
                final x = spec?.position.alignment.x ?? 0;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    const SeasonalSlot(SeasonalPlacement.bannerStrip),
                    if (title != null)
                      Padding(
                        padding: EdgeInsets.only(
                          left: x < 0 ? reserved : 0,
                          right: x > 0 ? reserved : 0,
                        ),
                        child: Center(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dtBlue,
                              fontSize: ResponsiveSize.getFontSize(18),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
