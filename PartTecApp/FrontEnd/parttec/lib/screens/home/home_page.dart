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
import 'package:carousel_slider/carousel_slider.dart';
import '../../utils/session_store.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/user_provider.dart';
import '../../screens/profile/profile_page.dart';
//
import '../../widgets/gradient_background.dart';
import '../../widgets/header_glow.dart';
import '../../widgets/floating_search_bar.dart';
import '../../widgets/category_chips_bar.dart';
import '../../widgets/my_cars_section.dart';
import '../location/location_picker_sheet.dart';
import '../../drawer/drawer_item.dart';

/*import 'widgets/header_glow.dart';
import 'widgets/floating_search_bar.dart';
import 'widgets/category_chips_bar.dart';
import 'widgets/visibility_toggle.dart';
import 'widgets/section_title.dart';

import 'cars/my_cars_section.dart';

import 'location/location_picker_sheet.dart';

import 'drawer/drawer_item.dart';*/

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 2;
  String? _locationName;
  bool _loadingLocationName = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  // نستخدم نفس الكنترولر
  late final TextEditingController _serialController;
  int _currentPart = 0;

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
    if (!mounted) return;

    setState(() {
      _loadingLocationName = true;
    });

    try {
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      );

      String name = 'الموقع المحدد';

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        final List<String> parts = [];

        if (p.administrativeArea != null &&
            p.administrativeArea!.trim().isNotEmpty) {
          parts.add(p.administrativeArea!.trim());
        }

        if (p.locality != null && p.locality!.trim().isNotEmpty) {
          parts.add(p.locality!.trim());
        }

        if (p.subLocality != null && p.subLocality!.trim().isNotEmpty) {
          parts.add(p.subLocality!.trim());
        }

        if (p.street != null && p.street!.trim().isNotEmpty) {
          parts.add(p.street!.trim());
        }

        if (p.thoroughfare != null && p.thoroughfare!.trim().isNotEmpty) {
          parts.add(p.thoroughfare!.trim());
        }

        if (p.subThoroughfare != null && p.subThoroughfare!.trim().isNotEmpty) {
          parts.add('رقم ${p.subThoroughfare!.trim()}');
        }

        final List<String> uniqueParts = [];
        for (final part in parts) {
          if (!uniqueParts.contains(part)) {
            uniqueParts.add(part);
          }
        }

        if (uniqueParts.isNotEmpty) {
          name = uniqueParts.join(' - ');
        }
      }

      if (!mounted) return;
      setState(() {
        _locationName = name;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationName = 'الموقع المحدد';
      });
    }

    if (!mounted) return;
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

  Future<void> _savePinnedLocationLocal(LatLng p,
      {String? locationName}) async {
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
            child: LocationPickerSheet(
              initialLocation: initial,
            ),
          ),
        ),
      ),
    );
  }

  void _showCircularProfilePreview(ImageProvider imageProvider) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
            ),
          ],
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

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fabAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(
        parent: _fabController,
        curve: Curves.easeInOut,
      ),
    );

    _fabController.repeat(reverse: true);

    _serialController = TextEditingController();
    _loadPinnedLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _refresh();
      await Provider.of<HomeProvider>(context, listen: false)
          .fetchRecommendations();

      final userProv = context.read<UserProvider>();
      await userProv.fetchMyProfile();
      await userProv.fetchProfileImage();
    });
  }

  @override
  void dispose() {
    _serialController.dispose();
    _fabController.dispose();
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
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: [
            const GradientBackground(),
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
                          scrolledUnderElevation: 0,
                          backgroundColor: AppColors.bgGradientA,
                          surfaceTintColor: Colors.transparent,
                          expandedHeight: 50,
                          leading: Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: Colors.white),
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openEndDrawer(),
                            ),
                          ),
                          actions: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart,
                                  color: Colors.white),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CartPage()),
                                ).then((_) => _refresh());
                              },
                            ),
                          ],
                          flexibleSpace: FlexibleSpaceBar(
                            titlePadding: const EdgeInsetsDirectional.only(
                              start: 16,
                              bottom: 12,
                              end: 16,
                            ),
                            title: const Text(
                              '',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            background: Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.bgGradientA,
                                    AppColors.bgGradientB,
                                    AppColors.bgGradientC,
                                  ],
                                ),
                              ),
                              child: const HeaderGlow(),
                            ),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  child: FloatingSearchBar(
                                    controller: _serialController,
                                    onSearch: _performSearch,
                                    onClear: _clearSearch,
                                    onChanged: (_) => _performSearch(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
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
                            child: _SectionTitle(title: ''),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: CategoryChipsBar(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                            onChanged: (i) =>
                                setState(() => _selectedCategoryIndex = i),
                          ),
                        ),
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
                                reverse: false,
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
                            child: Builder(
                              builder: (context) {
                                final parts =
                                    _filterByCategory(provider.availableParts);

                                if (parts.isEmpty) {
                                  return Container(
                                    height: 180,
                                    alignment: Alignment.center,
                                    child: Text(
                                      "لا يوجد قطع",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }
                                return SizedBox(
                                    height: 260,
                                    child: CarouselSlider.builder(
                                        itemCount: parts.length,
                                        itemBuilder: (context, i, realIndex) {
                                          return Center(
                                            child: SizedBox(
                                              width: 180,
                                              child: PartCard(part: parts[i]),
                                            ),
                                          );
                                        },
                                        options: CarouselOptions(
                                          height: 260,
                                          autoPlay: true,
                                          autoPlayInterval:
                                              const Duration(seconds: 3),
                                          autoPlayAnimationDuration:
                                              const Duration(milliseconds: 800),
                                          autoPlayCurve: Curves.easeInOut,
                                          enlargeCenterPage: true,
                                          viewportFraction: 0.5,
                                        )));
                              },
                            ),
                          ),
                        ],
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
                            child: MyCarsSection(),
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
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
                  child: Consumer<UserProvider>(
                    builder: (context, userProvider, _) {
                      final userName =
                          userProvider.profile?.name?.trim().isNotEmpty == true
                              ? userProvider.profile!.name!.trim()
                              : 'مستخدم PartTec';

                      final imageUrl = userProvider.profile?.imageUrl;
                      final hasImage =
                          imageUrl != null && imageUrl.trim().isNotEmpty;

                      final ImageProvider? avatarProvider =
                          hasImage ? NetworkImage(imageUrl) : null;

                      return Row(
                        children: [
                          GestureDetector(
                            onTap: avatarProvider == null
                                ? null
                                : () =>
                                    _showCircularProfilePreview(avatarProvider),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.white,
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.blueAccent,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'مرحباً بك\n$userName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    children: [
                      drawerItem(
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
                      drawerItem(
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
                      drawerItem(
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
                      drawerItem(
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
                      drawerItem(
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
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [
                Color(0xFF1E88E5),
                Color(0xFF1565C0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.45),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: FloatingActionButton(
            heroTag: "request_part",
            tooltip: "طلب قطعة",
            elevation: 0,
            backgroundColor: Colors.transparent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RequestRecommendationPage(),
                ),
              ).then((_) => _refresh());
            },
            child: const Icon(
              Icons.add,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
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
  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: maxExtent,
      color: Colors.white,
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

  const _VisibilityToggle({
    required this.isPrivate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _segmentButton(
            label: 'كل القطع',
            selected: !isPrivate,
            onTap: () => onChanged(false),
          ),
          _segmentButton(
            label: 'قطع لسيارتي',
            selected: isPrivate,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _segmentButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : Colors.black87,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
