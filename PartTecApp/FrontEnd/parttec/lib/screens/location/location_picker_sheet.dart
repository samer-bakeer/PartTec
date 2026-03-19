import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerSheet extends StatefulWidget {
  final LatLng initialLocation;

  const LocationPickerSheet({
    required this.initialLocation,
  });
  @override
  State<LocationPickerSheet> createState() => LocationPickerSheetState();
}

class LocationPickerSheetState extends State<LocationPickerSheet> {
  final MapController _map = MapController();
  late LatLng _center;
  LatLng? _picked;
  bool _locating = false; // حالة لجعل الواجهة تظهر أننا نحاول الحصول على الموقع

  @override
  void initState() {
    super.initState();
    _center = widget.initialLocation;
    _picked = widget.initialLocation;
    // حاول الحصول على موقع الجهاز تلقائياً عند الفتح
    _determinePositionAndMove();
  }

  Future<void> _determinePositionAndMove() async {
    setState(() => _locating = true);

    try {
      // هل خدمة الموقع مفعّلة؟
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // إبلاغ المستخدم أو الاستمرار بالموقع الافتراضي
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('خدمة الموقع متوقفة، الرجاء تفعيلها')),
          );
        }
        setState(() => _locating = false);
        return;
      }

      // تحقق من الأذونات
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم رفض إذن الموقع')),
            );
          }
          setState(() => _locating = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'تم رفض إذن الموقع نهائياً. من فضلك فعّل الإذن من إعدادات التطبيق')),
          );
        }
        setState(() => _locating = false);
        return;
      }

      // الآن نأخذ الموقع الحالي
      final Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);

      final LatLng deviceLatLng = LatLng(pos.latitude, pos.longitude);

      // حدّث المركز والمؤشر
      if (mounted) {
        setState(() {
          _center = deviceLatLng;
          _picked = deviceLatLng;
        });

        // حرّك الخريطة إلى الموضع الجديد بعد قليل للتأكد أن MapController جاهز
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            _map.move(_center, 14); // ضبط مستوى التكبير كما تريد
          } catch (_) {}
        });
      }
    } catch (e) {
      // خطأ عام — يمكن إظهار رسالة للمستخدم
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذّر الحصول على موقعك: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // استبدل الشريط العلوي الحالي بعنصر يعرض حالة تحديد الموقع ويحتوي زر لإعادة المحاولة
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'اضغط على الخريطة لتثبيت الدبوس، ثم اضغط حفظ',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (_locating)
                Row(
                  children: const [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('جاري تحديد الموقع'),
                  ],
                )
              else
                IconButton(
                  tooltip: 'تحديد موقعي الآن',
                  icon: const Icon(Icons.my_location),
                  onPressed: _determinePositionAndMove,
                ),
            ],
          ),
        ),

        // بقية واجهة الخريطة كما كانت - مع استخدام _center و _picked
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              center: _center,
              zoom: 14,
              onTap: (tapPos, latlng) => setState(() => _picked = latlng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.parttec',
              ),
              if (_picked != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _picked!,
                    width: 42,
                    height: 42,
                    child: const Icon(Icons.location_pin,
                        size: 42, color: Colors.red),
                  ),
                ]),
            ],
          ),
        ),

        // أسفل الخريطة زر الحفظ/إلغاء كما لديك
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _picked == null
                      ? 'لم يتم اختيار موقع'
                      : 'Lat: ${_picked!.latitude.toStringAsFixed(6)} • Lng: ${_picked!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop<LatLng>(null),
                child: const Text('إلغاء'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _picked == null
                    ? null
                    : () => Navigator.of(context).pop<LatLng>(_picked),
                icon: const Icon(Icons.save),
                label: const Text('حفظ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
