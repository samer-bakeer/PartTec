import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import '../../theme/app_theme.dart';

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

  bool _filledOnce = false;

  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = context.read<UserProvider>();

      await userProv.fetchMyProfile();
      await userProv.fetchProfileImage();

      _fillFromProviderIfNeeded();
    });
  }

  void _fillFromProviderIfNeeded() {
    final userProv = context.read<UserProvider>();
    final u = userProv.profile;

    if (_filledOnce) return;
    if (u == null) return;

    _name.text = (u.name ?? '');
    _phone.text = (u.phone ?? '');
    _email.text = (u.email ?? '');

    _filledOnce = true;
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

    ImageProvider? avatarProvider;

    if (_pickedImageFile != null) {
      avatarProvider = FileImage(_pickedImageFile!);
    } else if (userProv.profile?.imageUrl != null &&
        userProv.profile!.imageUrl!.trim().isNotEmpty) {
      avatarProvider = NetworkImage(userProv.profile!.imageUrl!);
    }

    return Scaffold(
        body: Directionality(
      textDirection: TextDirection.rtl,
      child: userProv.isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                /// HEADER
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.bgGradientA,
                        AppColors.bgGradientB,
                        AppColors.bgGradientC,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(30),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "الملف الشخصي",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// PROFILE IMAGE
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.bgGradientB,
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 18),
                      ),
                    )
                  ],
                ),

                const SizedBox(height: 10),

                /// NAME
                Text(
                  _name.text.isEmpty ? "اسم المستخدم" : _name.text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                /// CARD
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          /// NAME
                          TextFormField(
                            controller: _name,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person),
                              labelText: "الاسم",
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// PHONE
                          TextFormField(
                            controller: _phone,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone),
                              labelText: "رقم التواصل",
                            ),
                          ),

                          const SizedBox(height: 12),

                          /// EMAIL
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email),
                              labelText: "البريد الإلكتروني",
                            ),
                          ),

                          const Spacer(),

                          /// SAVE BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.bgGradientB,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: userProv.isSaving ? null : _save,
                              child: userProv.isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text("حفظ التعديلات"),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
    ));
  }
}
