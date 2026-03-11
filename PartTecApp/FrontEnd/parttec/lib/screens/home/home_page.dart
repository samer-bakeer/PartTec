import 'package:flutter/material.dart';
import 'package:parttec/screens/recommendation/request_recommendation_page.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:parttec/models/part.dart';
import '../../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import '../../widgets/parts_widgets.dart';
import '../order/MyOrdersDashboard.dart';
import '../part/add_part_page.dart';
import 'package:parttec/providers/currency_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/home_provider.dart';
import '../cart/cart_page.dart';
import '../favorites/favorite_parts_page.dart';
import '../order/user_delivered_orders_page.dart';
import '../auth/auth_page.dart';
import '../../utils/session_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../screens/profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  String? _locationName;
  bool _loadingLocationName = false;
  // نستخدم نفس الكنترولر
  late final TextEditingController _serialController;

  // حقول البحث الجديدة
  String _searchQuery = '';
  List<Part> _searchResults = [];

  final List<Map<String, dynamic>> _categories = const [
    {'label': 'محرك', 'icon': Icons.settings},
    {'label': 'هيكل', 'icon': Icons.car_repair},
    {'label': 'فرامل', 'icon': Icons.settings_input_component},
    {'label': 'كهرباء', 'icon': Icons.electrical_services},
    {'label': 'إطارات', 'icon': Icons.circle},
    {'label': 'نظام التعليق', 'icon': Icons.sync_alt},
  ];
  int _selectedCategoryIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? _pinnedLocation;

  Future<void> _logout() async {
    await SessionStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  Future<void> _resolveLocationName(double lat, double lng) async {
    try {
      setState(() {
        _loadingLocationName = true;
      });

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        String name = '';

        if (p.subLocality != null && p.subLocality!.isNotEmpty) {
          name = p.subLocality!;
        } else if (p.locality != null && p.locality!.isNotEmpty) {
          name = p.locality!;
        } else if (p.administrativeArea != null &&
            p.administrativeArea!.isNotEmpty) {
          name = p.administrativeArea!;
        } else if (p.country != null) {
          name = p.country!;
        }

        setState(() {
          _locationName = name.isNotEmpty ? name : "موقع غير معروف";
        });
      }
    } catch (e) {
      setState(() {
        _locationName = "موقع غير معروف";
      });
    }

    setState(() {
      _loadingLocationName = false;
    });
  }

  Future<void> _openWhatsApp() async {
    final Uri url = Uri.parse(
      'https://wa.me/message/YAOUPXTYYIZ4E1',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح واتساب')),
      );
    }
  }

  Future<bool> _confirmLogout() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تأكيد تسجيل الخروج'),
        content: const Text('هل تريد تسجيل الخروج وإنهاء الجلسة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  Future<void> _loadPinnedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('user_lat');
    final lng = prefs.getDouble('user_lng');

    if (lat != null && lng != null) {
      setState(() {
        _pinnedLocation = LatLng(lat, lng);
      });

      await _resolveLocationName(lat, lng);
    }
  }

  Future<void> _savePinnedLocationLocal(LatLng p, {String? locationName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_lat', p.latitude);
    await prefs.setDouble('user_lng', p.longitude);

    if (locationName != null && locationName.trim().isNotEmpty) {
      await prefs.setString('user_location_name', locationName.trim());
    }

    setState(() => _pinnedLocation = p);
  }

  Future<LatLng?> _pickLocationOnMap() async {
    final initial = _pinnedLocation ?? const LatLng(33.5138, 36.2765);
    return await showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.96,
        minChildSize: 0.6,
        builder: (ctx, controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Colors.white,
            child: _LocationPickerSheet(
              initialLocation: initial,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pinUserLocationToProfile() async {
    final picked = await _pickLocationOnMap();
    if (picked == null) return;
    await _resolveLocationName(picked.latitude, picked.longitude);
    await _savePinnedLocationLocal(
      picked,
      locationName: _locationName ?? 'الموقع المثبت',
    );
    if (!mounted) return;
    final userProv = Provider.of<UserProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('جاري حفظ موقعك في الحساب...')));
    final ok = await userProv.updateUserLocation(
      lat: picked.latitude,
      lng: picked.longitude,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ موقعك في الحساب بنجاح')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProv.error ?? 'تعذّر حفظ الموقع')));
    }
  }

  @override
  void initState() {
    super.initState();
    _serialController = TextEditingController();
    _loadPinnedLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
      Provider.of<HomeProvider>(context, listen: false).fetchRecommendations();
    });
  }

  @override
  void dispose() {
    _serialController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    await provider.fetchUserCars();
    await provider.fetchAvailableParts();
  }

  // مقارنة البحث: بالاسم والرقم التسلسلي
  bool _matchesPart(Part part, String q) {
    final qq = q.trim().toLowerCase();
    if (qq.isEmpty) return false;

    final name = (part.name ?? '').trim().toLowerCase();
    final sn = (part.serialNumber ?? '').trim().toLowerCase();

    final byName = name.contains(qq);
    final bySerial = sn == qq || sn.contains(qq);

    return byName || bySerial;
  }

  void _performSearch() {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    final query = _serialController.text;
    setState(() {
      _searchQuery = query;
      _searchResults = query.trim().isEmpty
          ? []
          : provider.availableParts
              .where((p) => _matchesPart(p, query))
              .toList();
    });
  }

  void _clearSearch() {
    _serialController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
    });
  }

  List<Part> _filterByCategory(List<Part> parts) {
    final selectedLabel =
        _categories[_selectedCategoryIndex]['label'] as String;
    return parts
        .where((p) => (p.category ?? '').trim() == selectedLabel)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          const _GradientBackground(),
          (provider.isLoadingAvailable && provider.availableParts.isEmpty)
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _refresh,
                  displacement: 140,
                  strokeWidth: 2.8,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        stretch: true,
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        expandedHeight: 150,
                        leading: IconButton(
                          icon: const Icon(Icons.shopping_cart,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => CartPage()))
                                .then((_) => _refresh());
                          },
                        ),
                        actions: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openEndDrawer(),
                            ),
                          ),
                        ],
                        flexibleSpace: const FlexibleSpaceBar(
                          titlePadding: EdgeInsetsDirectional.only(
                              start: 16, bottom: 12, end: 16),
                          title: Text('قطع الغيار',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          background: _HeaderGlow(),
                        ),
                      ),
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SearchBarHeader(
                          minExtent: 128,
                          maxExtent: 128,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _FloatingSearchBar(
                                  controller: _serialController,
                                  onSearch: _performSearch,
                                  onClear: _clearSearch,
                                  onChanged: (_) =>
                                      setState(() {}), // لتحديث زر المسح
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: _VisibilityToggle(
                                  isPrivate: provider.isPrivate,
                                  onChanged: (val) =>
                                      provider.toggleIsPrivate(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _SectionTitle(title: 'الفئات'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _CategoryChipsBar(
                          categories: _categories,
                          selectedIndex: _selectedCategoryIndex,
                          onChanged: (i) =>
                              setState(() => _selectedCategoryIndex = i),
                        ),
                      ),
                      /* SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                          child: _SectionTitle(title: 'قطع مقترحة لك'),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Consumer<HomeProvider>(
                          builder: (context, prov, _) {
                            if (prov.isLoadingRecommendations) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (prov.recommendedParts.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('لا توجد اقتراحات حالياً',
                                    style: TextStyle(color: Colors.grey[600])),
                              );
                            }
                            return SizedBox(
                              height: 260,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                reverse: true,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: prov.recommendedParts.length,
                                itemBuilder: (_, i) {
                                  return SizedBox(
                                      width: 180,
                                      child: PartCard(
                                          part: prov.recommendedParts[i]));
                                },
                              ),
                            );
                          },
                        ),
                      ),*/
                      if (_searchQuery.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: _SectionTitle(
                              title: 'نتائج البحث',
                              trailing: Text(
                                '${_searchResults.length} نتيجة',
                                style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _searchResults.length,
                              itemBuilder: (_, i) {
                                return SizedBox(
                                    width: 180,
                                    child: PartCard(part: _searchResults[i]));
                              },
                            ),
                          ),
                        ),
                      ] else ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: _SectionTitle(
                                title: _categories[_selectedCategoryIndex]
                                    ['label'] as String),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 260,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount:
                                  _filterByCategory(provider.availableParts)
                                      .length,
                              itemBuilder: (_, i) {
                                final part = _filterByCategory(
                                    provider.availableParts)[i];
                                return SizedBox(
                                    width: 180, child: PartCard(part: part));
                              },
                            ),
                          ),
                        ),
                      ],
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                          child: _MyCarsSection(),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
      endDrawer: Drawer(
        child: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color.fromARGB(255, 4, 49, 101),
                  Color.fromARGB(255, 34, 89, 215)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person,
                            size: 30, color: Colors.blueAccent),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'مرحباً بك\nمستخدم PartTec',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      _drawerItem(
                        icon: Icons.person,
                        title: 'البروفايل',
                        color: Colors.orange,
                        onTap: () async {
                          Navigator.pop(context);
                          await context.read<UserProvider>().fetchMyProfile();
                          if (!context.mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ProfilePage()),
                          );
                        },
                      ),
                      _drawerItem(
                        icon: Icons.support_agent,
                        title: 'الاتصال بالدعم',
                        subtitle: 'تواصل معنا عبر واتساب',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(context);
                          _openWhatsApp();
                        },
                      ),
                      Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amber.withOpacity(0.2),
                            child: const Icon(Icons.attach_money,
                                color: Colors.amber),
                          ),
                          title: const Text(
                            'العملة',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Consumer<CurrencyProvider>(
                            builder: (context, currencyProv, _) {
                              return DropdownButton<String>(
                                value: currencyProv.currency,
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: "USD",
                                    child: Text("USD"),
                                  ),
                                  DropdownMenuItem(
                                    value: "SYP",
                                    child: Text("SYP"),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    context
                                        .read<CurrencyProvider>()
                                        .changeCurrency(value);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      _drawerItem(
                        icon: Icons.logout,
                        title: 'تسجيل الخروج',
                        color: Colors.redAccent,
                        onTap: () async {
                          final ok = await _confirmLogout();
                          if (ok) {
                            Navigator.of(context).pop();
                            await _logout();
                          }
                        },
                      ),
                      _drawerItem(
                        icon: Icons.location_on,
                        title: 'تثبيت موقعي في الحساب',
                        subtitle: _pinnedLocation == null
                            ? 'اضغط لتحديد الموقع'
                            : _loadingLocationName
                                ? 'جاري تحديد المنطقة...'
                                : (_locationName ?? 'غير معروف'),
                        color: Colors.blueAccent,
                        onTap: () async {
                          Navigator.of(context).pop();
                          await _pinUserLocationToProfile();
                        },
                      ),
                      _drawerItem(
                        icon: Icons.delete_forever,
                        title: 'حذف الحساب',
                        color: Colors.red,
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text("تأكيد حذف الحساب"),
                                content:
                                    const Text("هل أنت متأكد من حذف الحساب؟"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text("إلغاء"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text("حذف"),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirm == true) {
                            final uid = await SessionStore.userId();

                            if (uid == null || uid.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "لم يتم العثور على معرف المستخدم")),
                              );
                              return;
                            }

                            final success = await context
                                .read<UserProvider>()
                                .deleteUser(uid);

                            if (success) {
                              await SessionStore.clear();

                              if (!context.mounted) return;

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                    builder: (_) => const AuthPage()),
                                (route) => false,
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RequestRecommendationPage()))
              .then((_) => _refresh());
        },
        backgroundColor: Colors.blue,
        icon: const Icon(Icons.add),
        label: const Text('طلب  قطعة'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomAppBar(),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      elevation: 10,
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'الإشعارات',
              icon: Icon(Icons.notifications,
                  color: _selectedIndex == 0 ? Colors.blue : Colors.grey),
              onPressed: () => setState(() => _selectedIndex = 0),
            ),
            IconButton(
              tooltip: 'طلباتي',
              icon: Icon(Icons.history,
                  color: _selectedIndex == 1 ? Colors.blue : Colors.grey),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DraggableScrollableSheet(
                    expand: false,
                    initialChildSize: 0.88,
                    maxChildSize: 0.95,
                    minChildSize: 0.6,
                    builder: (ctx, controller) => ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Material(
                        color: Colors.white,
                        child: const MyOrdersDashboard(),
                      ),
                    ),
                  ),
                ).whenComplete(() => _refresh());
              },
            ),
            const SizedBox(width: 40),
            IconButton(
              tooltip: 'المفضلة',
              icon: Icon(Icons.favorite,
                  color: _selectedIndex == 3 ? Colors.blue : Colors.grey),
              onPressed: () {
                Navigator.push(context,
                        MaterialPageRoute(builder: (_) => FavoritePartsPage()))
                    .then((_) => _refresh());
                setState(() => _selectedIndex = 3);
              },
            ),
            IconButton(
              tooltip: 'السجل',
              icon: Icon(Icons.history,
                  color: _selectedIndex == 2 ? Colors.blue : Colors.grey),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserDeliveredOrdersPage()),
                ).then((_) => _refresh());
                setState(() => _selectedIndex = 2);
              },
            ),
          ],
        ),
      ),
    );
  }
}

Widget _drawerItem({
  required IconData icon,
  required String title,
  String? subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 3,
    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      onTap: onTap,
    ),
  );
}

class _GradientBackground extends StatelessWidget {
  const _GradientBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.bgGradientA,
            AppColors.bgGradientB,
            AppColors.bgGradientC,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
    );
  }
}

class _HeaderGlow extends StatelessWidget {
  const _HeaderGlow();
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Opacity(opacity: 0.15)),
        Positioned(
          right: -40,
          bottom: -20,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), shape: BoxShape.circle),
          ),
        ),
        Positioned(
          left: -20,
          top: 10,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06), shape: BoxShape.circle),
          ),
        ),
      ],
    );
  }
}

class _SearchBarHeader extends SliverPersistentHeaderDelegate {
  final double _minExtent;
  final double _maxExtent;
  final Widget child;
  _SearchBarHeader({
    required double minExtent,
    required double maxExtent,
    required this.child,
  })  : _minExtent = minExtent,
        _maxExtent = maxExtent;
  @override
  double get minExtent => _minExtent;
  @override
  double get maxExtent => _maxExtent;
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: maxExtent,
      color: Colors.white.withOpacity(0.95),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarHeader oldDelegate) {
    return oldDelegate._minExtent != _minExtent ||
        oldDelegate._maxExtent != _maxExtent ||
        oldDelegate.child != child;
  }
}

class _FloatingSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSearch;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged; // جديد

  const _FloatingSearchBar({
    required this.controller,
    required this.onSearch,
    this.onClear,
    this.onChanged, // جديد
  });
  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => onSearch(),
        onChanged: onChanged, // لتحديث أيقونات الحقل لحظيًا
        decoration: InputDecoration(
          hintText: 'ابحث بالاسم أو الرقم التسلسلي...',
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((controller.text).isNotEmpty)
                IconButton(
                  tooltip: 'مسح',
                  icon: const Icon(Icons.clear),
                  onPressed: onClear,
                ),
              IconButton(
                tooltip: 'بحث',
                onPressed: onSearch,
                icon: const Icon(Icons.search),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionTitle({required this.title, this.trailing});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  final bool isPrivate;
  final ValueChanged<bool> onChanged;
  const _VisibilityToggle({required this.isPrivate, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          _segBtn(
              label: 'عامة',
              selected: !isPrivate,
              onTap: () => onChanged(false)),
          _segBtn(
              label: 'خاصة', selected: isPrivate, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Expanded _segBtn(
      {required String label,
      required bool selected,
      required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0x1A2196F3) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.blue : Colors.black87,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChipsBar extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const _CategoryChipsBar({
    required this.categories,
    required this.selectedIndex,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (_, i) {
          final label = categories[i]['label'] as String;
          final isSel = selectedIndex == i;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? Colors.blue : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  if (isSel)
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                ],
                border: Border.all(
                    color: isSel ? Colors.blue : Colors.grey.shade300),
              ),
              child: Center(
                child: Row(
                  children: [
                    Icon(categories[i]['icon'] as IconData,
                        size: 18, color: isSel ? Colors.white : Colors.black87),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSel ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: categories.length,
      ),
    );
  }
}

class _MyCarsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    final cars = provider.userCars;
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardHeader(title: 'سياراتي'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12)),
                child: const TabBar(
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.black54,
                  indicator: BoxDecoration(
                      color: Color(0x1A2196F3),
                      borderRadius: BorderRadius.all(Radius.circular(10))),
                  tabs: [
                    Tab(icon: Icon(Icons.directions_car), text: 'قائمتي'),
                    Tab(
                        icon: Icon(Icons.add_circle_outline),
                        text: 'إضافة/تحديث'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 260,
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    cars.isEmpty
                        ? Center(
                            child: Text(
                                'لا توجد سيارات بعد — أضِف سيارتك من التبويب التالي.',
                                style: TextStyle(color: Colors.grey[700])))
                        : _CarsSlider(cars: cars),
                    const SingleChildScrollView(child: _CarFormCard()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CarsSlider extends StatefulWidget {
  final List<dynamic> cars;
  const _CarsSlider({required this.cars});
  @override
  State<_CarsSlider> createState() => _CarsSliderState();
}

class _CarsSliderState extends State<_CarsSlider> {
  final PageController _page = PageController(viewportFraction: 0.86);
  int _index = 0;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _page,
            itemCount: widget.cars.length,
            onPageChanged: (i) => setState(() => _index = i),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, i) {
              final c = widget.cars[i];
              final title = '${c['manufacturer']} ${c['model']}';
              final sub = 'سنة ${c['year']} • ${c['fuel'] ?? 'غير محدد'}';
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(
                    right: 10,
                    left: i == 0 ? 2 : 0,
                    bottom: _index == i ? 0 : 10,
                    top: _index == i ? 0 : 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2196F3), Color(0xFF3949AB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 10))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 66,
                        height: 66,
                        decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.directions_car,
                            color: Colors.white, size: 34),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16)),
                            const SizedBox(height: 6),
                            Text(sub,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: -6,
                              children: [
                                if (c['vin'] != null &&
                                    (c['vin'] as String).isNotEmpty)
                                  _pill('VIN: ${c['vin']}'),
                                if (c['engine'] != null)
                                  _pill('محرك: ${c['engine']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _miniBtn(icon: Icons.edit, tooltip: 'تعديل'),
                          const SizedBox(height: 8),
                          _miniBtn(icon: Icons.delete, tooltip: 'حذف'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.cars.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2196F3) : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _pill(String t) => Chip(
        label: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      );
  Widget _miniBtn({required IconData icon, String? tooltip}) => Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      );
}

class _CarFormCard extends StatelessWidget {
  const _CarFormCard();
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    return Card(
      elevation: 6,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardHeader(title: 'إضافة/تحديث سيارة'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'ماركة السيارة', border: OutlineInputBorder()),
              value: provider.selectedMake,
              items: provider.makes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: provider.setSelectedMake,
            ),
            if (provider.selectedMake != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'الموديل', border: OutlineInputBorder()),
                value: provider.selectedModel,
                items: (provider.modelsByMake[provider.selectedMake] ?? [])
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: provider.setSelectedModel,
              ),
            ],
            if (provider.selectedModel != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'سنة الصنع', border: OutlineInputBorder()),
                value: provider.selectedYear,
                items: provider.years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: provider.setSelectedYear,
              ),
            ],
            if (provider.selectedYear != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'نوع الوقود', border: OutlineInputBorder()),
                value: provider.selectedFuel,
                items: provider.fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: provider.setSelectedFuel,
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ السيارة'),
                onPressed: () => provider.submitCar(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  final String title;
  const _CardHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final LatLng initialLocation;

  const _LocationPickerSheet({
    required this.initialLocation,
  });
  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
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
