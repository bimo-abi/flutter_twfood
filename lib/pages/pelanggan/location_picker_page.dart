import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapLocation {
  final double latitude;
  final double longitude;

  const MapLocation({required this.latitude, required this.longitude});
}

/// Pemilih titik alamat dengan OpenStreetMap.
/// Pengguna menggeser peta; pin tetap berada di tengah layar.
class LocationPickerPage extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerPage({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  static const LatLng _indonesiaCenter = LatLng(-2.5489, 118.0149);
  final MapController _mapController = MapController();

  late LatLng _selectedPoint;
  bool _hasSelectedLocation = false;
  bool _isGettingLocation = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    final hasInitialPoint =
        widget.initialLatitude != null && widget.initialLongitude != null;
    _selectedPoint = hasInitialPoint
        ? LatLng(widget.initialLatitude!, widget.initialLongitude!)
        : _indonesiaCenter;
    _hasSelectedLocation = hasInitialPoint;
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture || !mounted) return;
    setState(() {
      _selectedPoint = camera.center;
      _hasSelectedLocation = true;
      _locationMessage = null;
    });
  }

  Future<void> _useCurrentLocation() async {
    if (_isGettingLocation) return;
    setState(() {
      _isGettingLocation = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Layanan lokasi perangkat belum aktif. Aktifkan GPS terlebih dahulu.',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi belum diberikan.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Aktifkan izin lokasi melalui Pengaturan aplikasi.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );

      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedPoint = point;
        _hasSelectedLocation = true;
      });
      _mapController.move(point, 17);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locationMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _confirmLocation() {
    if (!_hasSelectedLocation) return;
    Navigator.of(context).pop(
      MapLocation(
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tentukan Lokasi Alamat')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Geser peta hingga pin berada tepat di lokasi rumah atau titik penerimaan pesanan.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isGettingLocation ? null : _useCurrentLocation,
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _isGettingLocation
                        ? 'Mencari lokasi...'
                        : 'Gunakan Lokasi GPS Saya',
                  ),
                ),
                if (_locationMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _locationMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                  if (_locationMessage!.contains('permanen'))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: Geolocator.openAppSettings,
                        child: const Text('Buka Pengaturan Aplikasi'),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _selectedPoint,
                    initialZoom: _hasSelectedLocation ? 16 : 4.5,
                    minZoom: 3,
                    maxZoom: 19,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'tw_food',
                      maxZoom: 19,
                    ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: Icon(
                      Icons.location_pin,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                      shadows: const [
                        Shadow(
                          color: Colors.black38,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'map_recenter_gps',
                    tooltip: 'Gunakan GPS',
                    onPressed: _isGettingLocation ? null : _useCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _hasSelectedLocation
                        ? 'Latitude: ${_selectedPoint.latitude.toStringAsFixed(6)}\nLongitude: ${_selectedPoint.longitude.toStringAsFixed(6)}'
                        : 'Tentukan lokasi menggunakan GPS atau geser peta terlebih dahulu.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _hasSelectedLocation ? _confirmLocation : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Gunakan Titik Lokasi Ini'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
