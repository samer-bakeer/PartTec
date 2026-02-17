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

<<<<<<< HEAD
class _RequestRecommendationPageState extends State<RequestRecommendationPage> {
  final _formKey = GlobalKey<FormState>();

=======
class _RequestRecommendationPageState
    extends State<RequestRecommendationPage>
    with SingleTickerProviderStateMixin {

  final _formKey = GlobalKey<FormState>();

>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007
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
      name:
          (name == null || name!.trim().isEmpty) ? 'unspecified' : name!.trim(),
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
<<<<<<< HEAD
            'تم إرسال الطلب${provider.lastOrderId != null ? " (#${provider.lastOrderId})" : ""}',
          ),
=======
              'تم إرسال الطلب${provider.lastOrderId != null ? " (#${provider.lastOrderId})" : ""}'),
>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.lastError ?? 'فشل الإرسال')),
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
<<<<<<< HEAD
    final carProvider = context.watch<CarProvider>();
=======
>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
<<<<<<< HEAD
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
                // ------------------ معلومات القطعة ------------------
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
=======
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
>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007
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
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------ بيانات السيارة ------------------
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("بيانات السيارة"),
                      DropdownSearch<Map<String, dynamic>>(
                        items: carProvider.brands,
                        itemAsString: (item) => item['name'],
                        selectedItem: selectedBrandCode == null
                            ? null
                            : carProvider.brands.firstWhere(
                                (e) => e['code'] == selectedBrandCode),
                        dropdownDecoratorProps: const DropDownDecoratorProps(
                          dropdownSearchDecoration: InputDecoration(
                            labelText: 'الشركة المصنعة',
                            prefixIcon: Icon(Icons.car_rental),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        popupProps: PopupProps.menu(
                          showSearchBox: true,
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
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                ),
                                onChanged: (value) {
                                  setState(() => selectedModel = value);
                                },
                                validator: (v) =>
                                    v == null ? 'مطلوب اختيار الموديل' : null,
                              ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'سنة الصنع',
                          prefixIcon: Icon(Icons.calendar_month),
                          border: OutlineInputBorder(),
                        ),
                        items: CarData.years
                            .map((y) =>
                                DropdownMenuItem(value: y, child: Text(y)))
                            .toList(),
                        value: year,
                        onChanged: (v) => setState(() => year = v),
                        validator: (v) => v == null ? 'مطلوب' : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------ صورة القطعة ------------------
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

                // ------------------ زر الإرسال ------------------
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
<<<<<<< HEAD
                    ),
                  ),
                ),
              ],
=======

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
>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007
            ),
          ),
        ),
      ),
    );
  }
<<<<<<< HEAD
=======

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
>>>>>>> f1f91ddc94174b9ee420b07cf9f8d99351d65007
}
