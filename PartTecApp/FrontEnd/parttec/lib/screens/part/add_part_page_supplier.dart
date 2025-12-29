import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

import '../../providers/add_part_provider.dart';
import '../../utils/app_settings.dart';
import '../../theme/app_theme.dart';
import '../qr/qr_scan_page.dart';
import 'package:parttec/utils/session_store.dart';
class KiaPartAddPage extends StatefulWidget {
  const KiaPartAddPage({super.key});

  @override
  State<KiaPartAddPage> createState() => _KiaPartAddPageState();
}

class _KiaPartAddPageState extends State<KiaPartAddPage> {
  final List<String> years = ['2020', '2021', '2022', '2023', '2024'];
  final List<String> partsList = [
    'فلتر هواء',
    'كمبيوتر محرك',
    'ردياتير',
    'بواجي','ضو','ستوب','طارة','مخمدات','غطا باكاج'
  ];
  final List<String> categories = ['محرك', 'فرامل', 'كهرباء', 'هيكل'];
  final List<String> statuses = ['جديد', 'مستعمل'];

  List<String> brands = [];
  List<String> models = [];

  String? selectedBrand;
  String? selectedModel;
  String? selectedYear;
  String? selectedPart;
  String? selectedCategory;
  String? selectedStatus;

  File? _pickedImage;
  final priceController = TextEditingController();
  final serialNumberController = TextEditingController();
  final countController = TextEditingController(text: "1"); // 👈 عدد القطع

  bool isLoading = false;
  bool isModelsLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  @override
  void dispose() {
    priceController.dispose();
    serialNumberController.dispose();
    countController.dispose();
    super.dispose();
  }

  Future<void> _fetchBrands() async {
    final uid = await SessionStore.userId();
    final url = Uri.parse(
      '${AppSettings.serverurl}/user/viewsellerprands/$uid',
    );
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        setState(() {
          brands = (data['prands'] as List<dynamic>)
              .map((b) => (b as String).capitalize())
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchModels(String brand) async {
    setState(() => isModelsLoading = true);
    final url = Uri.parse(
      '${AppSettings.serverurl}/api/models?brand=${Uri.encodeComponent(brand.toLowerCase())}',
    );
    try {
      final r = await http.get(url);
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        models = List<String>.from(data['models']);
      } else {
        models = [];
      }
    } catch (_) {
      models = [];
    }
    setState(() => isModelsLoading = false);
  }

  Future<void> _pickImage() async {
    final p = ImagePicker();
    final f = await p.pickImage(source: ImageSource.gallery);
    if (f != null) setState(() => _pickedImage = File(f.path));
  }

  Future<void> _submit() async {
    if ([
      selectedBrand,
      selectedModel,
      selectedYear,
      selectedPart,
      selectedCategory,
      selectedStatus
    ].contains(null) ||
        priceController.text.isEmpty ||
        countController.text.isEmpty ||
        _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ يرجى تعبئة جميع الحقول')),
      );
      return;
    }
    setState(() => isLoading = true);

    final ok = await context.read<AddPartProvider>().addPart(
      name: selectedPart!,
      manufacturer: selectedBrand!.toLowerCase(),
      model: selectedModel!,
      year: selectedYear!,
      category: selectedCategory!,
      status: selectedStatus!,
      price: priceController.text,
      image: _pickedImage,
      serialNumber: serialNumberController.text,
      description: "", // 👈 ممكن تضيف حقل للوصف
      count: int.tryParse(countController.text) ?? 1, // 👈 عدد القطع
    );

    setState(() => isLoading = false);

    final msg = ok
        ? '✅ تمت إضافة القطعة بنجاح'
        : (context.read<AddPartProvider>().errorMessage ?? 'فشل في الإضافة');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (ok) Navigator.pop(context);
  }

  int get _currentStep {
    if (selectedBrand == null) return 0;
    if (selectedModel == null) return 1;
    if (selectedYear == null) return 2;
    if (selectedPart == null) return 3;
    if (selectedCategory == null) return 4;
    if (selectedStatus == null) return 5;
    return 6;
  }

  Widget _buildCurrentStep(int step) {
    switch (step) {
      case 0:
        return _cardStep('اختر البراند:', brands, selectedBrand, (b) {
          setState(() {
            selectedBrand = b;
            selectedModel = null;
            _fetchModels(b);
          });
        });
      case 1:
        return _cardStep(
          'اختر الموديل:',
          models,
          selectedModel,
              (m) => setState(() => selectedModel = m),
          loading: isModelsLoading,
        );
      case 2:
        return _cardStep('اختر سنة الصنع:', years, selectedYear,
                (y) => setState(() => selectedYear = y));
      case 3:
        return _cardStep('اختر اسم القطعة:', partsList, selectedPart,
                (p) => setState(() => selectedPart = p));
      case 4:
        return _cardStep('اختر التصنيف:', categories, selectedCategory,
                (c) => setState(() => selectedCategory = c));
      case 5:
        return _cardStep('اختر الحالة:', statuses, selectedStatus,
                (s) => setState(() => selectedStatus = s));
      default:
        return _buildFinalForm();
    }
  }

  Widget _cardStep<T>(
      String title,
      List<T> options,
      T? selected,
      void Function(T) onSelect, {
        bool loading = false,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark)),
        const SizedBox(height: AppSpaces.sm),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: options.map((opt) {
              final txt = opt.toString();
              final isSel = opt == selected;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color:
                  isSel ? AppColors.primary.withOpacity(0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.chipBorder,
                      width: isSel ? 2 : 1),
                  boxShadow: [
                    if (isSel)
                      BoxShadow(
                        blurRadius: 8,
                        color: AppColors.primary.withOpacity(0.25),
                        offset: const Offset(0, 4),
                      )
                  ],
                ),
                child: InkWell(
                  onTap: () => onSelect(opt),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 18),
                    child: Text(
                      txt,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? AppColors.primary : AppColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: AppSpaces.lg),
      ],
    );
  }

  Widget _buildFinalForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: serialNumberController,
          decoration: InputDecoration(
            labelText: 'الرقم التسلسلي (اختياري)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final code = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScanPage()),
                );
                if (code != null) {
                  setState(() {
                    serialNumberController.text = code;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: AppSpaces.md),
        TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'السعر (بالدولار)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppSpaces.md),
        TextField(
          controller: countController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'عدد القطع',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: AppSpaces.md),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.image),
          label: const Text('اختيار صورة'),
        ),
        if (_pickedImage != null) ...[
          const SizedBox(height: AppSpaces.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _pickedImage!,
              width: 120,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: AppSpaces.lg),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.send),
          label: const Text('إرسال'),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة قطعة')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, anim) => SlideTransition(
          position:
          Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
        child: SingleChildScrollView(
          key: ValueKey<int>(_currentStep),
          padding: const EdgeInsets.all(AppSpaces.md),
          child: _buildCurrentStep(_currentStep),
        ),
      ),
    );
  }
}

extension StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
