// ✅ ProfilePage.dart (عدل عندك هالصفحة بهذا الشكل)
// الفكرة: نعبّي الكنترولرز أول ما نوصل بيانات المستخدم من UserProvider
// وبهيك الاسم/الرقم/الإيميل بيجوا من التسجيل (المحفوظين بالسيرفر/Session) وقابلين للتعديل.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  bool _filledOnce =
      false; // ✅ حتى ما يعبي كل rebuild ويرجع يمسح تعديل المستخدم

  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();

    // ✅ نعبيهم بعد أول فريم لما يكون provider جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = context.read<UserProvider>();

      // 1) إذا عندك دالة تجيب بيانات المستخدم من السيرفر/Session نادِها هون
      //    (إذا أصلاً بياناتك محمّلة مسبقاً احذف السطر التالي)
      await userProv.fetchMyProfile(); // ✅ اكتبها عندك بالـ UserProvider (تحت)

      // 2) عبّي الحقول مرة وحدة
      _fillFromProviderIfNeeded();
    });
  }

  void _fillFromProviderIfNeeded() {
    final userProv = context.read<UserProvider>();
    final u = userProv.profile; // ✅ عدّل حسب اسم الموديل عندك (User / Profile)

    if (_filledOnce) return;
    if (u == null) return;

    _name.text = (u.name ?? '').toString();
    _phone.text = (u.phone ?? '').toString();
    _email.text = (u.email ?? '').toString();

    _filledOnce = true;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ في حال provider صار جاهز لاحقاً
    _fillFromProviderIfNeeded();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1400,
    );
    if (x == null) return;
    setState(() => _pickedImageFile = File(x.path));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final userProv = context.read<UserProvider>();

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('جاري حفظ التعديلات...')));

    final ok = await userProv.updateProfile(
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      imageFile: _pickedImageFile,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (ok) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم حفظ البيانات بنجاح')));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProv.error ?? 'تعذّر حفظ البيانات')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();

    // ✅ صورة: لو في صورة من السيرفر استخدمها، وإلا لو اختار صورة محلياً استخدم FileImage
    ImageProvider? avatarProvider;
    if (_pickedImageFile != null) {
      avatarProvider = FileImage(_pickedImageFile!);
    } else if (userProv.profile != null) {
      avatarProvider = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        centerTitle: true,
      ),
      body: userProv.isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 6,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? const Icon(Icons.person, size: 56)
                                  : null,
                            ),
                            Material(
                              color: Colors.blue,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _pickImage,
                                child: const Padding(
                                  padding: EdgeInsets.all(10),
                                  child: Icon(Icons.camera_alt,
                                      color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'الاسم',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'الاسم مطلوب'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phone,
                          decoration: const InputDecoration(
                            labelText: 'رقم التواصل',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _email,
                          decoration: const InputDecoration(
                            labelText: 'البريد الإلكتروني',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            final s = (v ?? '').trim();
                            if (s.isEmpty) return null;
                            final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                .hasMatch(s);
                            return ok ? null : 'بريد غير صالح';
                          },
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: userProv.isSaving ? null : _save,
                            icon: userProv.isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('حفظ التعديلات'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
