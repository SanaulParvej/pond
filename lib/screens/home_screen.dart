import 'dart:ui';
import 'package:flutter/material.dart';
import '../repository/pond_repository.dart';
import 'add_product_screen.dart';
import 'pond_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repo = PondRepository.instance;

  void _showAddPondDialog() async {
    final nameCtrl = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (context) {
      return AlertDialog(
        title: const Text('Add Pond'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Pond name (e.g. Pond 7)')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () { if (nameCtrl.text.trim().isEmpty) return; Navigator.of(context).pop(true); }, child: const Text('Save')),
        ],
      );
    });

    if (ok == true) {
      final name = nameCtrl.text.trim();
      PondRepository.instance.addPond(name.isEmpty ? 'Pond ${PondRepository.instance.getPondCount() + 1}' : name);
      setState(() {});
    }
  }

  void _openPond(int id) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PondDetailsScreen(pondId: id)));
    setState(() {});
  }

  void _openAddProductQuick({required String type}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddProductScreen(productType: type)));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pond Management'),
        actions: [
          IconButton(onPressed: _showAddPondDialog, icon: const Icon(Icons.add_circle_outline, size: 22)),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openAddProductQuick(type: 'feed'),
                            icon: const Icon(Icons.restaurant_menu, size: 22),
                            label: const Text('Add Feed'),
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              minimumSize: const Size.fromHeight(56),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openAddProductQuick(type: 'medicine'),
                            icon: const Icon(Icons.medical_services, size: 22),
                            label: const Text('Add Medicine'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(width: 1.8, color: Theme.of(context).colorScheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Pond grid as a sliver so the quick actions scroll away with the content
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            sliver: SliverGrid(
              // Always show 6 pond tiles (placeholders if fewer ponds are defined).
              delegate: SliverChildBuilderDelegate((context, index) {
                final pondIndex = index + 1;
                final hasPond = pondIndex <= PondRepository.instance.getPondCount();
        final usages = hasPond ? repo.getUsagesForPond(pondIndex) : <dynamic>[];
        final totalCost = hasPond ? repo.totalCostForPond(pondIndex) : 0.0;
        final pondName = hasPond ? PondRepository.instance.getPondName(pondIndex) : 'Pond $pondIndex';
                // Cycle through available pond images so you can compare multiple
                // options. The assets folder contains several images (pond.png,
                // "pond 2.png", bay_10506833.png, cove_10506818.png).
                final assetCandidates = [
                  'assets/pond.png',
                  'assets/pond 2.png',
                  'assets/bay_10506833.png',
                  'assets/cove_10506818.png',
                ];
        // Use the app logo for ponds 5 and 6 per user request; otherwise
        // cycle through the candidate images for comparison.
        final assetPath = hasPond
          ? ((pondIndex == 5 || pondIndex == 6) ? 'assets/logo.png' : assetCandidates[(pondIndex - 1) % assetCandidates.length])
          : 'assets/logo.png';

                return Material(
                  color: Colors.white,
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: hasPond ? () => _openPond(pondIndex) : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular logo with subtle border and shadow
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.06 * 255).round()), blurRadius: 8, offset: const Offset(0, 4))],
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withAlpha((0.14 * 255).round())),
                              color: Colors.white,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                assetPath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Theme.of(context).colorScheme.primary,
                                  child: Center(child: Icon(Icons.pool, size: 44, color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Pond label
                          Text(
                            pondName,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.grey[850]),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          // Small stats row to look polished
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.list_alt, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text('${usages.length}', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w600)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Icon(Icons.monetization_on, size: 14, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 6),
                                  Text('৳ ${totalCost.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, color: Colors.grey[800], fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }, childCount: 6),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
