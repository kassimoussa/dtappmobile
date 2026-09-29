import 'dart:math' show Point;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../constants/app_theme.dart';
import '../../models/agency.dart';
import '../../utils/responsive_size.dart';

/// Carte des agences rendue avec MapLibre (tuiles OpenStreetMap vectorielles
/// servies par OpenFreeMap, sans clé API). Évaluation en parallèle de la
/// carte Google Maps d'AgenciesScreen.
class MapLibreAgenciesMap extends StatefulWidget {
  final List<Agency> agencies;
  final ValueChanged<Agency> onAgencyTap;

  const MapLibreAgenciesMap({
    super.key,
    required this.agencies,
    required this.onAgencyTap,
  });

  @override
  State<MapLibreAgenciesMap> createState() => _MapLibreAgenciesMapState();
}

class _MapLibreAgenciesMapState extends State<MapLibreAgenciesMap> {
  // Styles OpenFreeMap disponibles : liberty, bright, positron.
  static const String _styleUrl =
      'https://tiles.openfreemap.org/styles/liberty';

  // Légèrement à l'ouest de la capitale, pour cadrer tout le pays.
  static const LatLng _djiboutiCenter = LatLng(11.539376, 42.59);
  static const CameraPosition _initialCamera = CameraPosition(
    target: _djiboutiCenter,
    zoom: 7.5,
  );

  static const String _pinImage = 'dt-agency-pin';
  // Taille logique de l'épingle ; l'image est rendue à la densité de l'écran.
  static const Size _pinSize = Size(30, 42);

  MapLibreMapController? _mapController;

  @override
  void dispose() {
    _mapController?.onSymbolTapped.remove(_onSymbolTapped);
    super.dispose();
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
    controller.onSymbolTapped.add(_onSymbolTapped);
  }

  // Les annotations ne peuvent être ajoutées qu'une fois le style chargé.
  Future<void> _onStyleLoaded() async {
    final controller = _mapController;
    if (controller == null) return;

    final located =
        widget.agencies
            .where((a) => a.latitude != null && a.longitude != null)
            .toList();

    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    await controller.addImage(_pinImage, await _renderPin(pixelRatio));
    // Toutes les agences restent visibles, même quand les épingles se
    // chevauchent au dézoom.
    await controller.setSymbolIconAllowOverlap(true);
    await controller.setSymbolIconIgnorePlacement(true);

    await controller.addSymbols(
      located
          .map(
            (agency) => SymbolOptions(
              geometry: LatLng(agency.latitude!, agency.longitude!),
              iconImage: _pinImage,
              iconAnchor: 'bottom',
            ),
          )
          .toList(),
      located.map((agency) => {'id': agency.id}).toList(),
    );
  }

  /// Dessine l'épingle aux couleurs de l'app : goutte bleue DT cerclée de
  /// blanc, pastille jaune au centre, légère ombre portée.
  static Future<Uint8List> _renderPin(double pixelRatio) async {
    final w = _pinSize.width;
    final h = _pinSize.height;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(pixelRatio);

    final r = w / 2 - 3;
    final center = Offset(w / 2, r + 3);
    final tip = Offset(w / 2, h - 2);
    final pin =
        Path()
          ..moveTo(tip.dx, tip.dy)
          ..quadraticBezierTo(
            center.dx - r * 0.95,
            center.dy + r * 0.9,
            center.dx - r,
            center.dy,
          )
          ..arcToPoint(
            Offset(center.dx + r, center.dy),
            radius: Radius.circular(r),
          )
          ..quadraticBezierTo(
            center.dx + r * 0.95,
            center.dy + r * 0.9,
            tip.dx,
            tip.dy,
          )
          ..close();

    canvas.drawShadow(pin, Colors.black, 2, false);
    canvas.drawPath(pin, Paint()..color = AppTheme.dtBlue);
    canvas.drawPath(
      pin,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(center, r * 0.42, Paint()..color = AppTheme.dtYellow);

    final image = await recorder.endRecording().toImage(
      (w * pixelRatio).ceil(),
      (h * pixelRatio).ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  void _onSymbolTapped(Symbol symbol) {
    final id = symbol.data?['id'];
    for (final agency in widget.agencies) {
      if (agency.id == id) {
        widget.onAgencyTap(agency);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MapLibreMap(
          styleString: _styleUrl,
          initialCameraPosition: _initialCamera,
          onMapCreated: _onMapCreated,
          onStyleLoadedCallback: _onStyleLoaded,
          minMaxZoomPreference: const MinMaxZoomPreference(6.0, 18.0),
          compassEnabled: false,
          // maplibre_gl ne permet pas de masquer le bouton (i) : on le pousse
          // hors de la vue. Les crédits obligatoires sont affichés en texte
          // ci-dessous.
          attributionButtonPosition: AttributionButtonPosition.bottomLeft,
          attributionButtonMargins: const Point(-200, -200),
        ),
        // Crédits exigés par la licence ODbL d'OpenStreetMap et par OpenFreeMap.
        Positioned(
          left: ResponsiveSize.getWidth(AppTheme.spacingS),
          bottom: ResponsiveSize.getHeight(AppTheme.spacingXS),
          child: IgnorePointer(
            child: Text(
              '© OpenFreeMap · © OpenMapTiles · © OpenStreetMap',
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(9),
                color: AppTheme.textSecondary.withValues(alpha: 0.8),
                shadows: const [Shadow(color: Colors.white, blurRadius: 2)],
              ),
            ),
          ),
        ),
        Positioned(
          right: ResponsiveSize.getWidth(AppTheme.spacingM),
          bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'maplibre_zoom_in',
                mini: true,
                backgroundColor: Colors.white,
                onPressed:
                    () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                child: const Icon(Icons.add, color: AppTheme.dtBlue),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'maplibre_zoom_out',
                mini: true,
                backgroundColor: Colors.white,
                onPressed:
                    () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                child: const Icon(Icons.remove, color: AppTheme.dtBlue),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'maplibre_center_map',
                mini: true,
                backgroundColor: Colors.white,
                onPressed:
                    () => _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(_initialCamera),
                    ),
                child: const Icon(Icons.my_location, color: AppTheme.dtBlue),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
