import 'package:flutter/material.dart';
import '../../providers/car_provider.dart';
import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/order_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';

// 1. استيراد ملف البيانات الجديد (تأكد من المسار الصحيح)
import '../../constants/car_data.dart';

class RequestRecommendationPage extends StatefulWidget {
  const RequestRecommendationPage({super.key});



  @override
  State<RequestRecommendationPage> createState() =>
      _RequestRecommendationPageState();
}

class _RequestRecommendationPageState extends State<RequestRecommendationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().fetchBrands();
    });
  }
  final _formKey = GlobalKey<FormState>();
  String? partName;

  // carMake لم يعد له داعي لأنه يتم استخدام selectedBrandCode مباشرة
  String? model;
  String? year;
  String? serialNumber;
  String? note;
  File? _pickedImage;
  String? selectedBrandCode;
  String? selectedModel;

  List<String> availableModels = [];

  // تمت إزالة القوائم الطويلة (makes, years, carBrands, carModelsByBrand) من هنا

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _pickedImage = File(f.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<OrderProvider>();

    final mergedNotes = [
      if ((note ?? '')
          .trim()
          .isNotEmpty) note!.trim(),
      if ((serialNumber ?? '')
          .trim()
          .isNotEmpty)
        'Serial: ${serialNumber!.trim()}',
    ].join(' • ');

    final ok = await provider.createSpecificOrder(
      brandCode: selectedBrandCode!,
      partName: (partName == null || partName!.trim().isEmpty)
          ? 'unspecified'
          : partName!.trim(),
      carModel: selectedModel!,
      carYear: year!,
      notes: mergedNotes.isEmpty ? null : mergedNotes,
      image: _pickedImage,
      serialNumber: serialNumber ?? '',
    );


    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'تم إرسال الطلب${provider.lastOrderId != null ? " (#${provider
                    .lastOrderId})" : ""}')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.lastError ?? 'فشل الإرسال')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = context
        .watch<OrderProvider>()
        .isSubmitting;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('طلب توصية قطعة')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'اسم القطعة ',
                      border: OutlineInputBorder()),
                  onSaved: (v) => partName = v,
                ),
                const SizedBox(height: 12),

                // --- قائمة الشركات ---
                DropdownSearch<Map<String, dynamic>>(
                  items: context.watch<CarProvider>().brands,
                  itemAsString: (item) => item!['name'],

                  selectedItem: selectedBrandCode == null
                      ? null
                      : context.watch<CarProvider>().brands.firstWhere(
                        (e) => e['code'] == selectedBrandCode,
                  ),

                  // ✅ التلميح داخل البوكس
                  dropdownDecoratorProps: const DropDownDecoratorProps(
                    dropdownSearchDecoration: InputDecoration(
                      labelText: 'الشركة المصنعة',
                      hintText: 'اختر شركة السيارة',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  // ✅ تفعيل البحث
                  popupProps: PopupProps.menu(
                    showSearchBox: true,
                    searchFieldProps: TextFieldProps(
                      textDirection: TextDirection.rtl,
                      decoration: InputDecoration(
                        hintText: 'ابحث عن شركة...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  onChanged: (value) async {
                    setState(() {
                      selectedBrandCode = value?['code'];
                      selectedModel = null;
                    });

                    if (selectedBrandCode != null) {
                      await context
                          .read<CarProvider>()
                          .fetchModels(selectedBrandCode!);
                    }
                  },

                  validator: (v) => v == null ? 'مطلوب اختيار الشركة' : null,
                ),

                const SizedBox(height: 12),
                if (context.watch<CarProvider>().models.isNotEmpty) ...[
                  DropdownSearch<String>(
                    items: context.watch<CarProvider>().models,
                    selectedItem: selectedModel,

                    // ✅ التلميح
                    dropdownDecoratorProps: const DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText: 'موديل السيارة',
                        hintText: 'اختر موديل السيارة',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    // ✅ البحث داخل الموديلات
                    popupProps: PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          hintText: 'ابحث عن موديل...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),

                    onChanged: (value) {
                      setState(() => selectedModel = value);
                    },

                    validator: (v) => v == null ? 'مطلوب اختيار الموديل' : null,
                  ),

                ],
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(
                      labelText: 'الرقم التسلسلي (اختياري)',
                      border: OutlineInputBorder()),
                  onSaved: (v) => serialNumber = v,
                ),
                const SizedBox(height: 12),

                // --- قائمة السنوات ---
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                      labelText: 'سنة صنع السيارة', border: OutlineInputBorder()),
                  items: CarData.years
                      .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                      .toList(),
                  value: year,
                  onChanged: (v) => setState(() => year = v),
                  validator: (v) => v == null ? 'مطلوب' : null,
                ),

                const SizedBox(height: 12),
                const Text(
                  "أدخل صورة القطعة",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.chipBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _pickedImage != null
                        ? Image.file(_pickedImage!, fit: BoxFit.cover)
                        : const Center(
                        child: Text('اضغط لاختيار صورة (اختياري)')),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: isSubmitting ? null : _submit,
                  icon: const Icon(Icons.send),
                  label: Text(isSubmitting ? 'جارٍ الإرسال...' : 'إرسال الطلب'),

                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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