import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_theme.dart';
import '../../models/agency.dart';
import '../../services/agency_service.dart';
import '../../utils/responsive_size.dart';

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
  final MapController _mapController = MapController();
  double _currentZoom = 8.0;

  @override
  void initState() {
    super.initState();
    _loadAgencies();
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

    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text(
          'Nos Agences',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.dtBlue,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map),
            color: AppTheme.dtYellow,
            onPressed: () {
              setState(() {
                _showMap = !_showMap;
              });
            },
            tooltip: _showMap ? 'Vue liste' : 'Vue carte',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
            Text(
              'Chargement des agences...',
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
                label: const Text('Réessayer'),
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
          'Aucune agence disponible',
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
    // Centre de Djibouti comme position par défaut
    const LatLng djiboutiCenter = LatLng(11.539376, 42.782418);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: djiboutiCenter,
            initialZoom: _currentZoom,
            minZoom: 8.0,
            maxZoom: 18.0,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture) {
                setState(() {
                  _currentZoom = position.zoom ?? _currentZoom;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.dtservices',
              tileProvider: NetworkTileProvider(),
            ),
            MarkerLayer(
              markers: _agencies!.map((agency) {
                return Marker(
                  point: LatLng(agency.latitude, agency.longitude),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => _showAgencyDetails(agency),
                    child: Icon(
                      Icons.location_on,
                      color: AppTheme.dtBlue,
                      size: 40,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
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
                onPressed: () {
                  setState(() {
                    _currentZoom = (_currentZoom + 1).clamp(8.0, 18.0);
                  });
                  _mapController.move(
                    _mapController.camera.center,
                    _currentZoom,
                  );
                },
                child: Icon(
                  Icons.add,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'zoom_out',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _currentZoom = (_currentZoom - 1).clamp(8.0, 18.0);
                  });
                  _mapController.move(
                    _mapController.camera.center,
                    _currentZoom,
                  );
                },
                child: Icon(
                  Icons.remove,
                  color: AppTheme.dtBlue,
                ),
              ),
              SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
              FloatingActionButton(
                heroTag: 'center_map',
                mini: true,
                backgroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _currentZoom = 8.0;
                  });
                  _mapController.move(
                    djiboutiCenter,
                    _currentZoom,
                  );
                },
                child: Icon(
                  Icons.my_location,
                  color: AppTheme.dtBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAgencyDetails(Agency agency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveSize.getWidth(AppTheme.radiusL)),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingM)),
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
                      padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
                      decoration: BoxDecoration(
                        color: AppTheme.dtBlue.withOpacity(0.1),
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
                          fontSize: ResponsiveSize.getFontSize(20),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.dtBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                Text(
                  agency.description,
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(14),
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                _buildInfoRow(Icons.location_on, agency.address),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                _buildInfoRow(Icons.phone, agency.phone),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                _buildInfoRow(Icons.email, agency.email),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _launchPhoneCall(agency.phone),
                      icon: const Icon(Icons.phone),
                      label: const Text('Appeler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _launchDirections(agency.latitude, agency.longitude),
                      icon: const Icon(Icons.directions),
                      label: const Text('Itinéraire'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dtBlue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),
                Text(
                  'Horaires d\'ouverture',
                  style: TextStyle(
                    fontSize: ResponsiveSize.getFontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dtBlue,
                  ),
                ),
                SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),
                ...agency.openingHours.entries.map((entry) {
                  return Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _capitalize(entry.key),
                          style: TextStyle(
                            fontSize: ResponsiveSize.getFontSize(13),
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          entry.value,
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
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveSize.getHeight(AppTheme.spacingM)),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusM)),
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
                  padding: EdgeInsets.all(ResponsiveSize.getWidth(AppTheme.spacingS)),
                  decoration: BoxDecoration(
                    color: AppTheme.dtBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ResponsiveSize.getWidth(AppTheme.radiusS)),
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
            Text(
              agency.description,
              style: TextStyle(
                fontSize: ResponsiveSize.getFontSize(14),
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

            // Adresse
            _buildInfoRow(Icons.location_on, agency.address),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

            // Téléphone
            _buildInfoRow(Icons.phone, agency.phone),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingS)),

            // Email
            _buildInfoRow(Icons.email, agency.email),
            SizedBox(height: ResponsiveSize.getHeight(AppTheme.spacingM)),

            // Horaires d'ouverture
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(
                'Horaires d\'ouverture',
                style: TextStyle(
                  fontSize: ResponsiveSize.getFontSize(14),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.dtBlue,
                ),
              ),
              children: agency.openingHours.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(AppTheme.spacingM),
                    vertical: ResponsiveSize.getHeight(AppTheme.spacingXS),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _capitalize(entry.key),
                        style: TextStyle(
                          fontSize: ResponsiveSize.getFontSize(13),
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        entry.value,
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

  void _launchPhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer l\'application téléphone.')),
      );
    }
  }

  void _launchDirections(double latitude, double longitude) async {
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$latitude,$longitude');
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de lancer Google Maps.')),
      );
    }
  }
}
