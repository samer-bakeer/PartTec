import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SimpleLocationResult {
  final latlng.LatLng location;
  final String locationName;

  const SimpleLocationResult({
    required this.location,
    required this.locationName,
  });
}

class SimpleLocationPickerPage extends StatefulWidget {
  const SimpleLocationPickerPage({super.key});

  @override
  State<SimpleLocationPickerPage> createState() =>
      _SimpleLocationPickerPageState();
}

class _SimpleLocationPickerPageState extends State<SimpleLocationPickerPage> {
  final MapController _mapController = MapController();

  bool _loading = true;
  bool _resolvingName = false;
  String? _error;

  latlng.LatLng? _pickedLocation;
  String _locationName = 'جاري تحديد الموقع...';

  static const latlng.LatLng _fallbackLocation =
  latlng.LatLng(33.5138, 36.2765);

  @override
  void initState() {
    super.initState();
    _detectCurrentLocation();
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _loading = false;
          _error = 'خدمة الموقع غير مفعلة. يرجى تشغيل GPS.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        setState(() {
          _loading = false;
          _error = 'تم رفض إذن الوصول إلى الموقع.';
        });
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loading = false;
          _error = 'تم رفض إذن الموقع نهائيًا. فعّله من إعدادات التطبيق.';
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final current = latlng.LatLng(position.latitude, position.longitude);

      if (!mounted) return;

      setState(() {
        _pickedLocation = current;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(current, 16);
      });

      await _resolveLocationName(current);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر تحديد الموقع: $e';
      });
    }
  }

  Future<void> _resolveLocationName(latlng.LatLng location) async {
    if (!mounted) return;

    setState(() {
      _resolvingName = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      String name = 'الموقع المحدد';

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final parts = [
          p.subLocality,
          p.locality,
          p.administrativeArea,
          p.country,
        ].where((e) => e != null && e.trim().isNotEmpty).toList();

        if (parts.isNotEmpty) {
          name = parts.join(' - ');
        }
      }

      if (!mounted) return;
      setState(() {
        _locationName = name;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationName = 'الموقع المحدد';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _resolvingName = false;
      });
    }
  }

  Future<void> _confirmCurrentCenter() async {
    final center = _mapController.camera.center;
    final picked = latlng.LatLng(center.latitude, center.longitude);

    setState(() {
      _pickedLocation = picked;
    });

    await _resolveLocationName(picked);

    if (!mounted) return;

    Navigator.of(context).pop(
      SimpleLocationResult(
        location: picked,
        locationName: _locationName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _pickedLocation ?? _fallbackLocation;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حدد موقعك'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _detectCurrentLocation,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        )
            : Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 16,
                onPositionChanged: (position, hasGesture) {
                  final center = position.center;
                  if (center != null) {
                    _pickedLocation = latlng.LatLng(
                      center.latitude,
                      center.longitude,
                    );
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'com.example.parttec',
                ),
              ],
            ),

            const Center(
              child: IgnorePointer(
                child: Icon(
                  Icons.location_pin,
                  size: 52,
                  color: Colors.red,
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حرّك الخريطة وضع الدبوس على المكان المطلوب',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_resolvingName)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text('جاري تحديث اسم الموقع...'),
                            ),
                          ],
                        )
                      else
                        Text(
                          _locationName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _pickedLocation == null
                          ? null
                          : _confirmCurrentCenter,
                      icon: const Icon(Icons.check),
                      label: const Text('اعتماد هذا الموقع'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _detectCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('العودة إلى موقعي الحالي'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}