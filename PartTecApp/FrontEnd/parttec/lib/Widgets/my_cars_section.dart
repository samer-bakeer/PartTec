import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';

import '../constants/car_data.dart';
import '../providers/car_provider.dart';
import '../providers/home_provider.dart';

class MyCarsSection extends StatefulWidget {
  const MyCarsSection({super.key});

  @override
  State<MyCarsSection> createState() => _MyCarsSectionState();
}

class _MyCarsSectionState extends State<MyCarsSection> {
  String? _extractCarId(Map<String, dynamic> car) {
    return car['id']?.toString() ??
        car['_id']?.toString() ??
        car['carId']?.toString() ??
        car['vehicleId']?.toString();
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = context.read<HomeProvider>();
      final carProvider = context.read<CarProvider>();

      if (homeProvider.userCars.isEmpty) {
        await homeProvider.fetchUserCars();
      }

      carProvider.setCars(homeProvider.userCars);
    });
  }

  Future<void> _deleteCar(Map<String, dynamic> car) async {
    final carProvider = context.read<CarProvider>();
    final homeProvider = context.read<HomeProvider>();

    final carId = _extractCarId(car);

    if (carId == null || carId.isEmpty) {
      debugPrint('car object delete = $car');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرف السيارة غير موجود')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف السيارة'),
        content: const Text('هل أنت متأكد أنك تريد حذف هذه السيارة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await carProvider.deleteCar(carId);

    if (!mounted) return;

    if (success) {
      await homeProvider.fetchUserCars();
      carProvider.setCars(homeProvider.userCars);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم حذف السيارة بنجاح')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ فشل حذف السيارة')),
      );
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> car) async {
    final carProvider = context.read<CarProvider>();
    final homeProvider = context.read<HomeProvider>();

    final carId = _extractCarId(car);

    if (carId == null || carId.isEmpty) {
      debugPrint('car object edit = $car');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('معرف السيارة غير موجود')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();

    String manufacturer = (car['manufacturer'] ?? '').toString();
    String model = (car['model'] ?? '').toString();
    String year = (car['year'] ?? '').toString();
    String serialNumber = (car['serialNumber'] ?? car['vin'] ?? '').toString();

    bool isValidVin(String? value) {
      final v = (value ?? '').trim().toUpperCase();
      if (v.isEmpty) return true;
      return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(v);
    }

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('تعديل السيارة'),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            return Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: manufacturer,
                      decoration: const InputDecoration(
                        labelText: 'الشركة المصنعة',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => manufacturer = v,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يرجى إدخال الشركة المصنعة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: model,
                      decoration: const InputDecoration(
                        labelText: 'موديل السيارة',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) => model = v,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'يرجى إدخال موديل السيارة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: year.isEmpty ? null : year,
                      decoration: const InputDecoration(
                        labelText: 'سنة الصنع',
                        border: OutlineInputBorder(),
                      ),
                      items: CarData.years.map((y) {
                        return DropdownMenuItem<String>(
                          value: y,
                          child: Text(y),
                        );
                      }).toList(),
                      onChanged: (v) => setLocalState(() => year = v ?? ''),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'يرجى اختيار سنة الصنع';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: serialNumber,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 17,
                      decoration: const InputDecoration(
                        labelText: 'الرقم التسلسلي (VIN)',
                        hintText: 'مثال: 1HGCM82633A123456',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]'),
                        ),
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final upper = newValue.text.toUpperCase();

                          if (upper.contains('I') ||
                              upper.contains('O') ||
                              upper.contains('Q')) {
                            return oldValue;
                          }

                          if (upper.length > 17) {
                            return oldValue;
                          }

                          return TextEditingValue(
                            text: upper,
                            selection: TextSelection.collapsed(
                              offset: upper.length,
                            ),
                          );
                        }),
                      ],
                      validator: (value) {
                        final v = (value ?? '').trim().toUpperCase();
                        if (v.isEmpty) return null;
                        if (v.length != 17) {
                          return 'يجب أن يكون VIN من 17 خانة';
                        }
                        if (!isValidVin(v)) {
                          return 'VIN غير صالح';
                        }
                        return null;
                      },
                      onChanged: (v) => serialNumber = v.toUpperCase(),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              final success = await carProvider.editCar(
                carId: carId,
                manufacturer: manufacturer.trim(),
                model: model.trim(),
                year: year,
                serialNumber:
                serialNumber.trim().isEmpty ? null : serialNumber.trim(),
              );

              if (!context.mounted) return;

              if (success) {
                await homeProvider.fetchUserCars();
                carProvider.setCars(homeProvider.userCars);

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم تعديل السيارة بنجاح')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('❌ فشل تعديل السيارة')),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HomeProvider>();
    final cars = provider.userCars;

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'سياراتي'),
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.black54,
                    indicator: BoxDecoration(
                      color: Color(0x1A2196F3),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    tabs: [
                      Tab(icon: Icon(Icons.directions_car)),
                      Tab(icon: Icon(Icons.add_circle_outline)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    cars.isEmpty
                        ? Center(
                      child: Text(
                        'لا توجد سيارات بعد — أضِف سيارتك من التبويب التالي.',
                        style: TextStyle(color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                    )
                        : CarsSlider(
                      cars: cars,
                      onEdit: _showEditDialog,
                      onDelete: _deleteCar,
                    ),
                    const SingleChildScrollView(
                      child: CarFormCard(),
                    ),
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

class CarsSlider extends StatefulWidget {
  final List<dynamic> cars;
  final void Function(Map<String, dynamic> car)? onEdit;
  final void Function(Map<String, dynamic> car)? onDelete;

  const CarsSlider({
    super.key,
    required this.cars,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<CarsSlider> createState() => CarsSliderState();
}

class CarsSliderState extends State<CarsSlider> {
  final PageController _page = PageController(viewportFraction: 0.82);
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

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
              final c = Map<String, dynamic>.from(widget.cars[i]);

              final title =
              '${c['manufacturer'] ?? ''} ${c['model'] ?? ''}'.trim();
              final year = '${c['year'] ?? ''}';
              final vin =
              (c['serialNumber'] ?? c['vin'] ?? '').toString().trim();

              final isActive = _index == i;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(
                  right: 8,
                  left: i == 0 ? 2 : 0,
                  bottom: isActive ? 0 : 10,
                  top: isActive ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2196F3), Color(0xFF3949AB)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: Colors.white24,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title.isEmpty ? 'سيارة' : title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  year,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            children: [
                              _miniBtn(
                                icon: Icons.edit,
                                tooltip: 'تعديل',
                                onTap: () {
                                  debugPrint('edit car = $c');
                                  widget.onEdit?.call(c);
                                },
                              ),
                              const SizedBox(height: 8),
                              _miniBtn(
                                icon: Icons.delete,
                                tooltip: 'حذف',
                                onTap: () {
                                  debugPrint('delete car = $c');
                                  widget.onDelete?.call(c);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (vin.isNotEmpty) _pill('VIN: $vin'),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'بيانات السيارة محفوظة',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
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

  Widget _pill(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(
      t,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );

  Widget _miniBtn({
    required IconData icon,
    String? tooltip,
    VoidCallback? onTap,
  }) =>
      Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 42,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: Colors.white),
          ),
        ),
      );
}

class CarFormCard extends StatefulWidget {
  const CarFormCard({super.key});

  @override
  State<CarFormCard> createState() => _CarFormCardState();
}

class _CarFormCardState extends State<CarFormCard> {
  final _formKey = GlobalKey<FormState>();

  String? selectedBrandCode;
  String? selectedBrandName;
  String? selectedModel;
  String? selectedYear;
  String? serialNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final carProvider = context.read<CarProvider>();
      if (carProvider.brands.isEmpty) {
        await carProvider.fetchBrands();
      }
    });
  }

  bool _isValidVin(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return true;
    return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(v);
  }

  @override
  Widget build(BuildContext context) {
    final carProvider = context.watch<CarProvider>();
    final homeProvider = context.read<HomeProvider>();

    final selectedBrandItem = selectedBrandCode == null
        ? null
        : (carProvider.brands.any((e) => e['code'] == selectedBrandCode)
        ? carProvider.brands.firstWhere(
          (e) => e['code'] == selectedBrandCode,
    )
        : null);

    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("بيانات السيارة"),

              if (carProvider.isLoadingBrands)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                DropdownSearch<Map<String, dynamic>>(
                  items: carProvider.brands,
                  itemAsString: (item) => item['name']?.toString() ?? '',
                  selectedItem: selectedBrandItem,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'الشركة المصنعة',
                      prefixIcon: Icon(Icons.car_rental),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن الشركة...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  onChanged: (value) async {
                    final code = value?['code']?.toString();
                    final name = value?['name']?.toString();

                    setState(() {
                      selectedBrandCode = code;
                      selectedBrandName = name;
                      selectedModel = null;
                      selectedYear = null;
                      serialNumber = null;
                    });

                    if (code == null || code.isEmpty) return;
                    await context.read<CarProvider>().fetchModels(code);
                  },
                ),

              const SizedBox(height: 16),

              if (selectedBrandCode != null)
                carProvider.isLoadingModels
                    ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                )
                    : DropdownSearch<String>(
                  items: carProvider.models,
                  selectedItem: selectedModel,
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'موديل السيارة',
                      prefixIcon: Icon(Icons.directions_car),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  popupProps: const PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      decoration: InputDecoration(
                        hintText: 'ابحث عن الموديل...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => selectedModel = value);
                  },
                ),

              if (!carProvider.isLoadingModels &&
                  selectedBrandCode != null &&
                  carProvider.models.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'لا توجد موديلات متاحة',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'سنة الصنع',
                  prefixIcon: Icon(Icons.calendar_month),
                  border: OutlineInputBorder(),
                ),
                items: CarData.years
                    .map(
                      (y) => DropdownMenuItem<String>(
                    value: y,
                    child: Text(y),
                  ),
                )
                    .toList(),
                value: selectedYear,
                onChanged: (v) => setState(() => selectedYear = v),
              ),

              if (selectedYear != null) ...[
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: serialNumber,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 17,
                  decoration: const InputDecoration(
                    labelText: 'الرقم التسلسلي (VIN)',
                    hintText: 'مثال: 1HGCM82633A123456',
                    prefixIcon: Icon(Icons.confirmation_number),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9]'),
                    ),
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final upper = newValue.text.toUpperCase();

                      if (upper.contains('I') ||
                          upper.contains('O') ||
                          upper.contains('Q')) {
                        return oldValue;
                      }

                      if (upper.length > 17) {
                        return oldValue;
                      }

                      return TextEditingValue(
                        text: upper,
                        selection: TextSelection.collapsed(
                          offset: upper.length,
                        ),
                      );
                    }),
                  ],
                  validator: (value) {
                    final v = (value ?? '').trim().toUpperCase();

                    if (v.isEmpty) return null;
                    if (v.length != 17) {
                      return 'يجب أن يكون VIN من 17 خانة';
                    }
                    if (!_isValidVin(v)) {
                      return 'VIN غير صالح. استخدم أرقامًا وحروفًا كبيرة بدون I أو O أو Q';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      serialNumber = value.toUpperCase();
                    });
                  },
                ),
              ],

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ السيارة'),
                  onPressed: () async {
                    if (selectedBrandName == null ||
                        selectedModel == null ||
                        selectedYear == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('يرجى تحديد الشركة والموديل والسنة'),
                        ),
                      );
                      return;
                    }

                    if (!_formKey.currentState!.validate()) return;

                    final result = await homeProvider.submitCarDirect(
                      manufacturer: selectedBrandName!,
                      model: selectedModel!,
                      year: selectedYear!,
                      serialNumber:
                      (serialNumber == null || serialNumber!.trim().isEmpty)
                          ? null
                          : serialNumber!.trim(),
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result ?? '✅ تم حفظ السيارة بنجاح'),
                      ),
                    );

                    if (result == null) {
                      await homeProvider.fetchUserCars();
                      context.read<CarProvider>().setCars(homeProvider.userCars);

                      setState(() {
                        selectedBrandCode = null;
                        selectedBrandName = null;
                        selectedModel = null;
                        selectedYear = null;
                        serialNumber = null;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  final String title;
  const CardHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}