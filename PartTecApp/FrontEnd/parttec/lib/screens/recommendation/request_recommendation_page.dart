import 'package:flutter/material.dart';
import '../../providers/car_provider.dart';
import '../../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../providers/order_provider.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../../constants/car_data.dart';

class RequestRecommendationPage extends StatefulWidget {
  const RequestRecommendationPage({super.key});

  @override
  State<RequestRecommendationPage> createState() =>
      _RequestRecommendationPageState();
}

class _RequestRecommendationPageState
    extends State<RequestRecommendationPage>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

  String? name;
  String? model;
  String? year;
  String? serialNumber;
  String? note;
  File? _pickedImage;
  String? selectedBrandCode;
  String? selectedModel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CarProvider>().fetchBrands();
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final f = await picker.pickImage(source: ImageSource.gallery);
    if (f != null) {
      setState(() => _pickedImage = File(f.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final provider = context.read<OrderProvider>();

    final mergedNotes = [
      if ((note ?? '').trim().isNotEmpty) note!.trim(),
      if ((serialNumber ?? '').trim().isNotEmpty)
        'Serial: ${serialNumber!.trim()}',
    ].join(' • ');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'تم إرسال الطلب${provider.lastOrderId != null ? " (#${provider.lastOrderId})" : ""}'),
        ),
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
    final isSubmitting = context.watch<OrderProvider>().isSubmitting;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: AppColors.primary,
          centerTitle: true,
          title: const Text(
            'طلب توصية قطعة',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        body: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(milliseconds: 600),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 6,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [

                      /// اسم القطعة
                      TextFormField(
                        decoration: _inputDecoration('اسم القطعة'),
                        onSaved: (v) => name = v,
                      ),

                      const SizedBox(height: 16),

                      /// الشركة
                      DropdownSearch<Map<String, dynamic>>(
                        items: context.watch<CarProvider>().brands,
                        itemAsString: (item) => item['name'],

                        selectedItem: selectedBrandCode == null
                            ? null
                            : context.watch<CarProvider>().brands.firstWhere(
                              (e) => e['code'] == selectedBrandCode,
                          orElse: () => context.watch<CarProvider>().brands.first,
                        ),

                        dropdownDecoratorProps: DropDownDecoratorProps(
                          dropdownSearchDecoration: _inputDecoration('الشركة المصنعة'),
                        ),

                        popupProps: const PopupProps.menu(
                          showSearchBox: true,
                        ),

                        onChanged: (value) async {
                          if (value == null) return;

                          setState(() {
                            selectedBrandCode = value['code'];
                            selectedModel = null;
                          });

                          // 🔥 هذا السطر مهم جداً
                          await context
                              .read<CarProvider>()
                              .fetchModels(selectedBrandCode!);
                        },

                        validator: (v) => v == null ? 'مطلوب اختيار الشركة' : null,
                      ),

                      const SizedBox(height: 16),

                      /// الموديل بأنيميشن
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: selectedBrandCode != null
                            ? DropdownSearch<String>(
                          key: const ValueKey("models"),
                          items: context.watch<CarProvider>().models,
                          selectedItem: selectedModel,
                          dropdownDecoratorProps: DropDownDecoratorProps(
                            dropdownSearchDecoration: _inputDecoration('موديل السيارة'),
                          ),
                          popupProps: const PopupProps.menu(
                            showSearchBox: true,
                          ),
                          onChanged: (value) {
                            setState(() => selectedModel = value);
                          },
                          validator: (v) =>
                          v == null ? 'مطلوب اختيار الموديل' : null,
                        )
                            : const SizedBox(),
                      ),

                      const SizedBox(height: 16),

                      /// السنة
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('سنة صنع السيارة'),
                        items: CarData.years
                            .map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y),
                        ))
                            .toList(),
                        value: year,
                        onChanged: (v) => setState(() => year = v),
                        validator: (v) => v == null ? 'مطلوب' : null,
                      ),

                      const SizedBox(height: 16),

                      /// الرقم التسلسلي
                      TextFormField(
                        decoration:
                        _inputDecoration('الرقم التسلسلي (اختياري)'),
                        onSaved: (v) => serialNumber = v,
                      ),

                      const SizedBox(height: 20),

                      /// الصورة
                      GestureDetector(
                        onTap: _pickImage,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _pickedImage != null
                                  ? AppColors.primary
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _pickedImage != null
                                ? Image.file(_pickedImage!,
                                fit: BoxFit.cover)
                                : const Center(
                              child: Icon(Icons.add_a_photo_outlined,
                                  size: 40),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      /// زر الإرسال
                      SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            backgroundColor: AppColors.primary,
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isSubmitting
                                ? const SizedBox(
                              key: ValueKey(1),
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'إرسال الطلب',
                              key: ValueKey(2),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
