import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../constants/car_data.dart';
import '../../providers/car_provider.dart';
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

  String? name;
  String? year;
  String? serialNumber;
  String? note;

  File? _pickedImage;
  String? selectedBrandCode;
  String? selectedModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await context.read<CarProvider>().fetchBrands();
      } catch (e) {
        if (!mounted) return;
        _showAppSnackBar(
          'تعذر تحميل الشركات المصنعة',
          isError: true,
        );
      }
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBrandCode == null || selectedModel == null || year == null) {
      _showAppSnackBar(
        'يرجى إكمال بيانات السيارة أولاً',
        isError: true,
      );
      return;
    }

    _formKey.currentState!.save();

    final provider = context.read<OrderProvider>();

    final mergedNotes = [
      if ((note ?? '').trim().isNotEmpty) note!.trim(),
      if ((serialNumber ?? '').trim().isNotEmpty)
        'Serial: ${serialNumber!.trim()}',
    ].join(' • ');

    try {
      final ok = await provider.createSpecificOrder(
        brandCode: selectedBrandCode!,
        name: (name == null || name!.trim().isEmpty)
            ? 'unspecified'
            : name!.trim(),
        carModel: selectedModel!,
        carYear: year!,
        notes: mergedNotes.isEmpty ? null : mergedNotes,
        image: _pickedImage,
        serialNumber: serialNumber ?? '',
      );

      if (!mounted) return;

      if (ok) {
        _showAppSnackBar(
          'تم إرسال الطلب${provider.lastOrderId != null ? " (#${provider.lastOrderId})" : ""}',
        );
        Navigator.pop(context, true);
      } else {
        _showAppSnackBar(
          provider.lastError ?? 'فشل الإرسال',
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

  Widget _card({required Widget child}) {
    return Card(
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context.watch<OrderProvider>().isSubmitting;
    final carProvider = context.watch<CarProvider>();

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
                        decoration: const InputDecoration(
                          labelText: 'اسم القطعة',
                          prefixIcon: Icon(Icons.build),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => name = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'الرقم التسلسلي (اختياري)',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => serialNumber = v,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'ملاحظات (اختياري)',
                          prefixIcon: Icon(Icons.notes),
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        onSaved: (v) => note = v,
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
                          setState(() {
                            selectedBrandCode = value?['code']?.toString();
                            selectedModel = null;
                          });

                          if (selectedBrandCode == null) return;

                          try {
                            await context
                                .read<CarProvider>()
                                .fetchModels(selectedBrandCode!);
                          } catch (e) {
                            if (!mounted) return;
                            _showAppSnackBar(
                              'تعذر تحميل الموديلات',
                              isError: true,
                            );
                          }
                        },
                        validator: (v) =>
                            v == null ? 'مطلوب اختيار الشركة' : null,
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
                                dropdownDecoratorProps:
                                    const DropDownDecoratorProps(
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
                                validator: (v) => v == null || v.isEmpty
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
                        value: year,
                        onChanged: (v) => setState(() => year = v),
                        validator: (v) =>
                            v == null ? 'مطلوب اختيار السنة' : null,
                      ),
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
