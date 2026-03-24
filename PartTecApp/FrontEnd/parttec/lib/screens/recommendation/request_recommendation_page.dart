import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/car_data.dart';
import '../../providers/car_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_theme.dart';

class RequestRecommendationPage extends StatefulWidget {
  const RequestRecommendationPage({super.key});

  @override
  State<RequestRecommendationPage> createState() =>
      _RequestRecommendationPageState();
}

class _RequestRecommendationPageState extends State<RequestRecommendationPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _vinController = TextEditingController();

  String? name;
  String? note;

  File? _pickedImage;

  bool _useSavedCar = true;
  Map<String, dynamic>? _selectedSavedCar;

  String? selectedBrandCode;
  String? selectedBrandName;
  String? selectedModel;
  String? year;
  String? serialNumber;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<CarProvider>().fetchBrands();
        await context.read<HomeProvider>().fetchUserCars();
      } catch (e) {
        if (!mounted) return;
        _showAppSnackBar(
          'تعذر تحميل بيانات السيارات',
          isError: true,
        );
      }
    });
  }

  @override
  void dispose() {
    _vinController.dispose();
    super.dispose();
  }

  void _showAppSnackBar(String message, {bool isError = false}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        elevation: 10,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final f = await picker.pickImage(source: ImageSource.gallery);

      if (f != null) {
        setState(() => _pickedImage = File(f.path));
      }
    } catch (e) {
      if (!mounted) return;
      _showAppSnackBar(
        'تعذر اختيار الصورة',
        isError: true,
      );
    }
  }

  String _normalize(dynamic value) {
    return (value ?? '').toString().trim().toLowerCase();
  }

  String? _resolveBrandCode(
      CarProvider carProvider,
      String? manufacturer,
      ) {
    if (manufacturer == null || manufacturer.trim().isEmpty) return null;

    final target = _normalize(manufacturer);

    for (final brand in carProvider.brands) {
      final code = (brand['code'] ?? '').toString();
      final name = (brand['name'] ?? '').toString();

      if (_normalize(code) == target || _normalize(name) == target) {
        return code;
      }
    }

    return null;
  }

  void _setVin(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    _vinController.value = TextEditingValue(
      text: v,
      selection: TextSelection.collapsed(offset: v.length),
    );
    serialNumber = v.isEmpty ? null : v;
  }

  bool _isValidVin(String? value) {
    final v = (value ?? '').trim().toUpperCase();
    if (v.isEmpty) return true;
    return RegExp(r'^[A-HJ-NPR-Z0-9]{17}$').hasMatch(v);
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _modeSelector(bool hasSavedCars) {
    if (!hasSavedCars) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              label: 'سياراتي',
              icon: Icons.directions_car,
              selected: _useSavedCar,
              onTap: () {
                setState(() {
                  _useSavedCar = true;
                  selectedBrandCode = null;
                  selectedBrandName = null;
                  selectedModel = null;
                  year = null;
                });
              },
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _modeButton(
              label: 'إدخال يدوي',
              icon: Icons.edit_note,
              selected: !_useSavedCar,
              onTap: () {
                setState(() {
                  _useSavedCar = false;
                  _selectedSavedCar = null;
                  selectedBrandCode = null;
                  selectedBrandName = null;
                  selectedModel = null;
                  year = null;
                  _setVin(null);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black54,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedCarPreview() {
    if (_selectedSavedCar == null) return const SizedBox.shrink();

    final manufacturer = _selectedSavedCar?['manufacturer']?.toString() ?? '';
    final model = _selectedSavedCar?['model']?.toString() ?? '';
    final carYear = _selectedSavedCar?['year']?.toString() ?? '';
    final vin = _vinController.text.trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFF2196F3), Color(0xFF3949AB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$manufacturer $model',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'سنة الصنع: $carYear',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (vin.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'VIN: $vin',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _vinField() {
    return TextFormField(
      controller: _vinController,
      textCapitalization: TextCapitalization.characters,
      maxLength: 17,
      decoration: _inputDecoration(
        label: 'الرقم التسلسلي (VIN)',
        icon: Icons.confirmation_number,
        hint: 'مثال: 1HGCM82633A123456',
      ).copyWith(counterText: ''),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
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
            selection: TextSelection.collapsed(offset: upper.length),
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
      onChanged: (v) {
        serialNumber = v.toUpperCase().trim();
        setState(() {});
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final homeProvider = context.read<HomeProvider>();
    final carProvider = context.read<CarProvider>();
    final orderProvider = context.read<OrderProvider>();

    final savedCars = homeProvider.userCars
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final useSavedCar = _useSavedCar && savedCars.isNotEmpty;
    final vin = _vinController.text.trim().toUpperCase();

    if (useSavedCar) {
      if (_selectedSavedCar == null) {
        _showAppSnackBar(
          'يرجى اختيار سيارة من سياراتك المحفوظة',
          isError: true,
        );
        return;
      }

      final manufacturer = _selectedSavedCar?['manufacturer']?.toString();
      final resolvedCode = _resolveBrandCode(carProvider, manufacturer);

      if (resolvedCode == null) {
        _showAppSnackBar(
          'تعذر مطابقة الشركة المصنعة للسيارة المختارة',
          isError: true,
        );
        return;
      }

      selectedBrandCode = resolvedCode;
      selectedBrandName = manufacturer;
      selectedModel = _selectedSavedCar?['model']?.toString();
      year = _selectedSavedCar?['year']?.toString();
    }

    if (selectedBrandCode == null || selectedModel == null || year == null) {
      _showAppSnackBar(
        'يرجى إكمال بيانات السيارة أولاً',
        isError: true,
      );
      return;
    }

    _formKey.currentState!.save();

    try {
      final ok = await orderProvider.createSpecificOrder(
        brandCode: selectedBrandCode!,
        name: (name == null || name!.trim().isEmpty)
            ? 'unspecified'
            : name!.trim(),
        carModel: selectedModel!,
        carYear: year!,
        notes: (note ?? '').trim().isEmpty ? null : note!.trim(),
        image: _pickedImage,
        serialNumber: vin,
      );

      if (!mounted) return;

      if (ok) {
        _showAppSnackBar(
          'تم إرسال الطلب${orderProvider.lastOrderId != null ? " (#${orderProvider.lastOrderId})" : ""}',
        );
        Navigator.pop(context, true);
      } else {
        _showAppSnackBar(
          orderProvider.lastError ?? 'فشل الإرسال',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showAppSnackBar(
        'حدث خطأ غير متوقع أثناء إرسال الطلب',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<OrderProvider>().isSubmitting;
    final carProvider = context.watch<CarProvider>();
    final homeProvider = context.watch<HomeProvider>();

    final savedCars = homeProvider.userCars
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final hasSavedCars = savedCars.isNotEmpty;
    final useSavedCar = hasSavedCars && _useSavedCar;

    final selectedBrandItem = selectedBrandCode == null
        ? null
        : (carProvider.brands.any((e) => e['code'] == selectedBrandCode)
        ? carProvider.brands.firstWhere(
          (e) => e['code'] == selectedBrandCode,
    )
        : null);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('طلب توصية قطعة'),
          centerTitle: true,
          elevation: 1,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("معلومات القطعة"),
                      TextFormField(
                        decoration: _inputDecoration(
                          label: 'اسم القطعة',
                          icon: Icons.build,
                        ),
                        onSaved: (v) => name = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("بيانات السيارة"),
                      _modeSelector(hasSavedCars),
                      if (hasSavedCars) const SizedBox(height: 16),

                      if (useSavedCar) ...[
                        DropdownSearch<Map<String, dynamic>>(
                          items: savedCars,
                          selectedItem: _selectedSavedCar,
                          itemAsString: (item) {
                            final manufacturer =
                                item['manufacturer']?.toString() ?? '';
                            final model = item['model']?.toString() ?? '';
                            final carYear = item['year']?.toString() ?? '';
                            return '$manufacturer $model - $carYear';
                          },
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration(
                              label: 'اختر سيارة محفوظة',
                              icon: Icons.directions_car,
                            ),
                          ),
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                            searchFieldProps: TextFieldProps(
                              decoration: InputDecoration(
                                hintText: 'ابحث ضمن سياراتك...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          validator: (v) =>
                          useSavedCar && v == null ? 'مطلوب اختيار سيارة' : null,
                          onChanged: (value) {
                            final vin =
                            (value?['serialNumber'] ?? value?['vin'] ?? '')
                                .toString();

                            final manufacturer =
                            value?['manufacturer']?.toString();
                            final resolvedCode =
                            _resolveBrandCode(carProvider, manufacturer);

                            setState(() {
                              _selectedSavedCar = value;
                              selectedBrandCode = resolvedCode;
                              selectedBrandName = manufacturer;
                              selectedModel = value?['model']?.toString();
                              year = value?['year']?.toString();
                            });

                            _setVin(vin);
                          },
                        ),
                        _selectedCarPreview(),
                        const SizedBox(height: 16),
                        _vinField(),
                      ] else ...[
                        DropdownSearch<Map<String, dynamic>>(
                          items: carProvider.brands,
                          itemAsString: (item) =>
                          item['name']?.toString() ?? '',
                          selectedItem: selectedBrandItem,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration(
                              label: 'الشركة المصنعة',
                              icon: Icons.car_rental,
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
                          validator: (v) =>
                          !useSavedCar && v == null ? 'مطلوب اختيار الشركة' : null,
                          onChanged: (value) async {
                            final code = value?['code']?.toString();
                            final brandName = value?['name']?.toString();

                            setState(() {
                              selectedBrandCode = code;
                              selectedBrandName = brandName;
                              selectedModel = null;
                              year = null;
                            });
                            _setVin(null);

                            if (code == null || code.isEmpty) return;

                            try {
                              await context.read<CarProvider>().fetchModels(code);
                            } catch (e) {
                              if (!mounted) return;
                              _showAppSnackBar(
                                'تعذر تحميل الموديلات',
                                isError: true,
                              );
                            }
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
                            dropdownDecoratorProps: DropDownDecoratorProps(
                              dropdownSearchDecoration: _inputDecoration(
                                label: 'موديل السيارة',
                                icon: Icons.directions_car,
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
                            validator: (v) => !useSavedCar &&
                                (v == null || v.isEmpty)
                                ? 'مطلوب اختيار الموديل'
                                : null,
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
                          decoration: _inputDecoration(
                            label: 'سنة الصنع',
                            icon: Icons.calendar_month,
                          ),
                          items: CarData.years
                              .map(
                                (y) => DropdownMenuItem<String>(
                              value: y,
                              child: Text(y),
                            ),
                          )
                              .toList(),
                          value: year,
                          onChanged: (v) => setState(() => year = v),
                          validator: (v) =>
                          !useSavedCar && v == null ? 'مطلوب اختيار السنة' : null,
                        ),
                        if (year != null) ...[
                          const SizedBox(height: 16),
                          _vinField(),
                        ],
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("صورة القطعة (اختياري)"),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 170,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _pickedImage != null
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _pickedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                              : const Center(
                            child: Text(
                              'اضغط لاختيار صورة',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("ملاحظات (اختياري)"),
                      TextFormField(
                        maxLines: 4,
                        decoration: _inputDecoration(
                          label: 'اكتب ملاحظاتك هنا',
                          icon: Icons.notes,
                        ).copyWith(alignLabelWithHint: true),
                        onSaved: (v) => note = v,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : _submit,
                    icon: const Icon(Icons.send),
                    label: Text(
                      isSubmitting ? 'جارٍ الإرسال...' : 'إرسال الطلب',
                      style: const TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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
      ),
    );
  }
}