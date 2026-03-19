import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/home_provider.dart';

class MyCarsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    final cars = provider.userCars;
    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: DefaultTabController(
          length: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CardHeader(title: 'سياراتي'),
              const SizedBox(height: 5),
              SizedBox(
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12)),
                  child: const TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.black54,
                    indicator: BoxDecoration(
                        color: Color(0x1A2196F3),
                        borderRadius: BorderRadius.all(Radius.circular(10))),
                    tabs: [
                      Tab(icon: Icon(Icons.directions_car)),
                      Tab(
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: TabBarView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    cars.isEmpty
                        ? Center(
                            child: Text(
                                'لا توجد سيارات بعد — أضِف سيارتك من التبويب التالي.',
                                style: TextStyle(color: Colors.grey[700])))
                        : CarsSlider(cars: cars),
                    const SingleChildScrollView(child: CarFormCard()),
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
  const CarsSlider({required this.cars});
  @override
  State<CarsSlider> createState() => CarsSliderState();
}

class CarsSliderState extends State<CarsSlider> {
  final PageController _page = PageController(viewportFraction: 0.6);
  int _index = 0;
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
              final c = widget.cars[i];
              final title = '${c['manufacturer']} ${c['model']}';
              final sub = ' ${c['year']} ';

              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: EdgeInsets.only(
                  right: 10,
                  left: i == 0 ? 2 : 0,
                  bottom: _index == i ? 0 : 10,
                  top: _index == i ? 0 : 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
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
                    )
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  sub,
                                  maxLines: 2,
                                  softWrap: true,
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    if (c['vin'] != null &&
                                        (c['vin'] as String).isNotEmpty)
                                      _pill('VIN: ${c['vin']}'),
                                    if (c['engine'] != null &&
                                        c['engine']
                                            .toString()
                                            .trim()
                                            .isNotEmpty)
                                      _pill('محرك: ${c['engine']}'),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _miniBtn(icon: Icons.edit, tooltip: 'تعديل'),
                          const SizedBox(height: 8),
                          _miniBtn(icon: Icons.delete, tooltip: 'حذف'),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _pill(String t) => Chip(
        label: Text(t,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white24,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
      );
  Widget _miniBtn({required IconData icon, String? tooltip}) => Tooltip(
        message: tooltip ?? '',
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      );
}

class CarFormCard extends StatelessWidget {
  const CarFormCard();
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<HomeProvider>(context);
    return Card(
      elevation: 6,
      shadowColor: Colors.black12,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CardHeader(title: 'إضافة/تحديث سيارة'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                  labelText: 'ماركة السيارة', border: OutlineInputBorder()),
              value: provider.selectedMake,
              items: provider.makes
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: provider.setSelectedMake,
            ),
            if (provider.selectedMake != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'الموديل', border: OutlineInputBorder()),
                value: provider.selectedModel,
                items: (provider.modelsByMake[provider.selectedMake] ?? [])
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: provider.setSelectedModel,
              ),
            ],
            if (provider.selectedModel != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'سنة الصنع', border: OutlineInputBorder()),
                value: provider.selectedYear,
                items: provider.years
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: provider.setSelectedYear,
              ),
            ],
            if (provider.selectedYear != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                    labelText: 'نوع الوقود', border: OutlineInputBorder()),
                value: provider.selectedFuel,
                items: provider.fuelTypes
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: provider.setSelectedFuel,
              ),
            ],
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('حفظ السيارة'),
                onPressed: () async {
                  final provider = context.read<HomeProvider>();
                  final result = await provider.submitCar();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result ?? '✅ تم حفظ السيارة بنجاح'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CardHeader extends StatelessWidget {
  final String title;
  const CardHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 22,
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(8))),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
