import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../data/structures_data.dart';
import '../data/structures_storage_service.dart';
import 'structures_learn_screen.dart';

const List<List<Color>> _kDayGradients = [
  [Color(0xFF818CF8), Color(0xFF4338CA)],
  [Color(0xFFFB923C), Color(0xFFC2410C)],
  [Color(0xFF34D399), Color(0xFF059669)],
  [Color(0xFFF472B6), Color(0xFFBE185D)],
  [Color(0xFFA78BFA), Color(0xFF6D28D9)],
  [Color(0xFF22D3EE), Color(0xFF0891B2)],
  [Color(0xFFFDE047), Color(0xFFA16207)],
  [Color(0xFFF87171), Color(0xFFB91C1C)],
];

/// Day-tile grid for one unit — mirrors the web app's unit day picker (and
/// its own model, the vocab UnitPicker's day-tile grid): ~5-structure "days"
/// so a 93-structure unit (Speaking Part 3) isn't one overwhelming queue.
class StructuresDayPickerScreen extends StatefulWidget {
  final String unit;
  const StructuresDayPickerScreen({super.key, required this.unit});

  @override
  State<StructuresDayPickerScreen> createState() => _StructuresDayPickerScreenState();
}

class _StructuresDayPickerScreenState extends State<StructuresDayPickerScreen> {
  Set<String> _learnedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final srs = await StructuresStorageService.getStructuresSRS();
    if (!mounted) return;
    setState(() => _learnedIds = srs.map((s) => s.id).toSet());
  }

  @override
  Widget build(BuildContext context) {
    final days = subUnitsFor(widget.unit);

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('🔎 Pick a day',
            style: TextStyle(color: context.appText, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: days.entries.map((entry) {
            final day = entry.key;
            final structures = entry.value;
            final done = structures.every((s) => _learnedIds.contains(s.id));
            final grad = done
                ? const [Color(0xFF34D399), Color(0xFF059669)]
                : _kDayGradients[(day - 1) % _kDayGradients.length];

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StructuresLearnScreen(unit: widget.unit, day: day),
                ));
                _load();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(done ? '✅' : '🔎', style: const TextStyle(fontSize: 20)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DAY $day',
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                                color: Colors.white70)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${structures.length} structures',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
