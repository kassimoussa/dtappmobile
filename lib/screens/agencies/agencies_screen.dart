import 'package:flutter/material.dart';
import 'package:dtservices/widgets/glass_app_bar.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../models/agency.dart';
import '../../services/agency_service.dart';
import '../../utils/responsive_size.dart';
import '../../generated/l10n/app_localizations.dart';

class AgenciesScreen extends StatefulWidget {
  const AgenciesScreen({super.key});

  @override
  State<AgenciesScreen> createState() => _AgenciesScreenState();
}

class _AgenciesScreenState extends State<AgenciesScreen> {
  List<Agency>? _agencies;
  bool _isLoading = true;
  String? _errorMessage;
  bool _showMap = true;
  GoogleMapController? _mapController;

  // Centre de Djibouti comme position par défaut
  static const LatLng _djiboutiCenter = LatLng(11.539376, 42.782418);
  static const CameraPosition _initialCamera = CameraPosition(
    target: _djiboutiCenter,
    zoom: 8.0,
  );

  @override
  void initState() {
    super.initState();
    _loadAgencies();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadAgencies() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final agencies = await AgencyService.getAgencies();
      setState(() {
        _agencies = agencies;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveSize.init(context);
    final l10n = AppLocalizations.of(context)!;

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
                GlassAppBar(title: l10n.agenciesTitle, actions: [GlassAppBarAction(icon: _showMap ? Icons.list : Icons.map, onTap: () => setState(() => _showMap = !_showMap))]),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBody() {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              l10n.loadingAgencies,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(16),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingL)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: ResponsiveSize.getFontSize(60),
                color: Colors.red,
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(16),
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingL)),
              ElevatedButton.icon(
                onPressed: _loadAgencies,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dtBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_agencies == null || _agencies!.isEmpty) {
      return Center(
        child: Text(
          l10n.noAgencies,
          style: TextStyle(
            fontSize: ResponsiveSize.getFontSize(16),
            color: AppTheme.textSecondary,
          ),
        ),
      );
    }

    return _showMap ? _buildMapView() : _buildListView();
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
      itemCount: _agencies!.length,
      itemBuilder: (context, index) {
        return _buildAgencyCard(_agencies![index]);
      },
    );
  }

  Widget _buildMapView() {
    final Set<Marker> markers =
        _agencies!
            .where(
              (agency) =>
                  agency.latitude != null && agency.longitude != null,
            )
            .map(
              (agency) => Marker(
                markerId: MarkerId(agency.id.toString()),
                position: LatLng(agency.latitude!, agency.longitude!),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
                onTap: () => _showAgencyDetails(agency),
              ),
            )
            .toSet();

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: _initialCamera,
          onMapCreated: (controller) => _mapController = controller,
          markers: markers,
          minMaxZoomPreference: const MinMaxZoomPreference(8.0, 18.0),
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
        ),
        Positioned(
          right: ResponsiveSize.getWidth(AppTheme.spacingM),
          bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'zoom_in',
                mini: true,
                backgroundColor: Colors.white,
                onPressed:
                    () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                child: const Icon(Icons.add, color: AppTheme.dtBlue),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                backgroundColor: Colors.white,
                onPressed:
                    () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                child: const Icon(Icons.remove, color: AppTheme.dtBlue),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'center_map',
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

  void _showAgencyDetails(Agency agency) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
        ),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(
                  ResponsiveSize.getWidth(AppTheme.spacingM),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(
                          bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(
                            ResponsiveSize.getWidth(AppTheme.spacingS),
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.dtBlueO10,
                            borderRadius: BorderRadius.circular(
                              ResponsiveSize.getWidth(AppTheme.radiusS),
                            ),
                          ),
                          child: Icon(
                            Icons.store,
                            color: AppTheme.dtBlue,
                            size: ResponsiveSize.getFontSize(24),
                          ),
                        ),
                        SizedBox(
                          width: ResponsiveSize.getWidth(AppTheme.spacingM),
                        ),
                        Expanded(
                          child: Text(
                            l10n.call,
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(14),
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    if (agency.description != null &&
                        agency.description!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        child: Text(
                          agency.description!,
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(14),
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    if (agency.address != null && agency.address!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveSize.getHeight(AppTheme.spacingS),
                        ),
                        child: _buildInfoRow(
                          Icons.location_on,
                          agency.address!,
                        ),
                      ),
                    if (agency.phone != null && agency.phone!.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                        ),
                        child: _buildInfoRow(Icons.phone, agency.phone!),
                      ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (agency.phone != null && agency.phone!.isNotEmpty)
                          ElevatedButton.icon(
                            onPressed: () => _launchPhoneCall(agency.phone!),
                            icon: const Icon(Icons.phone),
                            label: Text(l10n.call),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dtBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        if (agency.latitude != null && agency.longitude != null)
                          ElevatedButton.icon(
                            onPressed:
                                () => _launchDirections(
                                  agency.latitude!,
                                  agency.longitude!,
                                ),
                            icon: const Icon(Icons.directions),
                            label: Text(l10n.directions),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dtBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingM),
                    ),
                    Text(
                      l10n.openingHours,
                      style: TextStyle(
                        fontSize: ResponsiveSize.getFontSize(16),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dtBlue,
                      ),
                    ),
                    SizedBox(
                      height: ResponsiveSize.getHeight(AppTheme.spacingS),
                    ),
                    ...agency.openingHours.entries.map((entry) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.getHeight(
                            AppTheme.spacingXS,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _translateDay(entry.key, l10n),
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(13),
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _translateHours(entry.value, l10n),
                              style: TextStyle(
                                fontSize: ResponsiveSize.getFontSize(13),
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
    );
  }

  Widget _buildAgencyCard(Agency agency) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: EdgeInsets.only(
        bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
      ),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          ResponsiveSize.getWidth(AppTheme.radiusM),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et icône
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    ResponsiveSize.getWidth(AppTheme.spacingS),
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlueO10,
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusS),
                    ),
                  ),
                  child: Icon(
                    Icons.store,
                    color: AppTheme.dtBlue,
                    size: ResponsiveSize.getFontSize(24),
                  ),
                ),
                SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingM)),
                Expanded(
                  child: Text(
                    agency.name,
                    style: TextStyle(
                      fontSize: ResponsiveSize.getFontSize(18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.dtBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

            // Description
            if (agency.description != null && agency.description!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
                child: Text(
                  agency.description!,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),

            // Adresse
            if (agency.address != null && agency.address!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingS),
                ),
                child: _buildInfoRow(Icons.location_on, agency.address!),
              ),

            // Téléphone
            if (agency.phone != null && agency.phone!.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                  bottom: ResponsiveSize.getHeight(AppTheme.spacingM),
                ),
                child: _buildInfoRow(Icons.phone, agency.phone!),
              ),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (agency.phone != null && agency.phone!.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _launchPhoneCall(agency.phone!),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(l10n.call),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
                        ),
                      ),
                    ),
                  ),
                if (agency.phone != null &&
                    agency.phone!.isNotEmpty &&
                    agency.latitude != null &&
                    agency.longitude != null)
                  SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
                if (agency.latitude != null && agency.longitude != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _launchDirections(
                            agency.latitude!,
                            agency.longitude!,
                          ),
                      icon: const Icon(Icons.directions, size: 18),
                      label: Text(l10n.directions),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveSize.getHeight(AppTheme.spacingS),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

            // Horaires d'ouverture
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                l10n.openingHours,
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              children:
                  agency.openingHours.entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                        vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _translateDay(entry.key, l10n),
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(13),
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            _translateHours(entry.value, l10n),
                            style: TextStyle(
                              fontSize: ResponsiveSize.getFontSize(13),
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveSize.getFontSize(18),
          color: AppTheme.dtBlue,
        ),
        SizedBox(width: ResponsiveSize.getWidth(AppTheme.spacingS)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: ResponsiveSize.getFontSize(14),
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _translateDay(String frenchDay, AppLocalizations l10n) {
    switch (frenchDay.toLowerCase().trim()) {
      case 'dimanche': return l10n.daySunday;
      case 'lundi':    return l10n.dayMonday;
      case 'mardi':    return l10n.dayTuesday;
      case 'mercredi': return l10n.dayWednesday;
      case 'jeudi':    return l10n.dayThursday;
      case 'vendredi': return l10n.dayFriday;
      case 'samedi':   return l10n.daySaturday;
      default:         return _capitalize(frenchDay);
    }
  }

  String _translateHours(String frenchHours, AppLocalizations l10n) {
    if (frenchHours.toLowerCase() == 'fermé') return l10n.dayClosed;
    return frenchHours;
  }

  void _launchPhoneCall(String phoneNumber) async {
    final l10n = AppLocalizations.of(context)!;
    // Nettoyer le numéro de tous les caractères non numériques
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    // Enlever le code international 253 s'il est présent
    if (cleanNumber.startsWith('253') && cleanNumber.length > 8) {
      cleanNumber = cleanNumber.substring(3);
    }

    // S'assurer qu'on a un numéro à 8 chiffres
    if (cleanNumber.length == 8) {
      final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.launchPhoneError)));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidPhone)));
      }
    }
  }

  void _launchDirections(double latitude, double longitude) async {
    final l10n = AppLocalizations.of(context)!;
    // Essayer d'abord avec l'URL Google Maps pour Android
    final Uri googleMapsUrl = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude',
    );

    try {
      final bool launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Si geo: ne fonctionne pas, essayer avec l'URL web
        final Uri webUrl = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.launchMapError)));
      }
    }
  }
}
