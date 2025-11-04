import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pond_controller.dart';
import '../models/usage.dart';
import '../routes/app_routes.dart';

class HomeScreen extends GetView<PondController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future<void> showAddPondDialog() async {
      final nameCtrl = TextEditingController();
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Add Pond'),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Pond name (optional)',
            ),
            onSubmitted: (_) => Get.back(result: true),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result == true) {
        final name = nameCtrl.text.trim();
        final nextNumber = controller.pondCount + 1;
        final pondName = name.isEmpty ? 'Pond $nextNumber' : name;
        await controller.addPond(pondName);
        Get.snackbar(
          'Pond added',
          pondName,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }

    Future<void> confirmDeletePond(int pondId) async {
      final pondName = controller.pondName(pondId);
      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Delete Pond'),
          content: Text('Remove $pondName along with its usage records?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final removed = await controller.removePond(pondId);
        if (removed) {
          Get.snackbar(
            'Pond deleted',
            '$pondName removed',
            snackPosition: SnackPosition.BOTTOM,
          );
        } else {
          Get.snackbar(
            'Action blocked',
            'Core ponds cannot be removed',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    }

    Future<void> openPond(int id) async {
      await Get.toNamed(AppRoutes.pondDetails, arguments: {'pondId': id});
    }

    Future<void> openAddProductQuick(String type) async {
      await Get.toNamed(AppRoutes.addProduct, arguments: {'productType': type});
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pond Management'),
        actions: [
          IconButton(
            onPressed: showAddPondDialog,
            icon: const Icon(Icons.add_circle_outline, size: 22),
          ),
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
                            onPressed: () => openAddProductQuick('feed'),
                            icon: const Icon(Icons.restaurant_menu, size: 22),
                            label: const Text('Add Feed'),
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              minimumSize: const Size.fromHeight(56),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => openAddProductQuick('medicine'),
                            icon: const Icon(Icons.medical_services, size: 22),
                            label: const Text('Add Medicine'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                width: 1.8,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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
          Obx(() {
            final pondList = controller.ponds.toList(growable: false);
            final usageMap = controller.pondUsages.map(
              (key, value) => MapEntry(key, List<Usage>.from(value)),
            );
            final pondCount = pondList.length;
            final totalTiles = pondCount < 6 ? 6 : pondCount;
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final hasPond = index < pondCount && index < pondList.length;
                  final pond = hasPond ? pondList[index] : null;
                  final pondId = pond?.id ?? index + 1;
                  final usageList = hasPond
                      ? (usageMap[pondId] ?? const <Usage>[])
                      : const <Usage>[];
          final totalCost = usageList.fold<double>(
          0,
          (sum, usage) => sum + usage.totalPrice,
          );
                  final pondName = hasPond ? pond!.name : 'Pond $pondId';
                  const globalPondAsset = 'assets/pond.png';
                  return Material(
                    color: Colors.white,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: hasPond ? () => openPond(pondId) : null,
                      onLongPress: hasPond
                          ? () => confirmDeletePond(pondId)
                          : null,
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 12,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(
                                      (0.06 * 255).round(),
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary
                                      .withAlpha((0.14 * 255).round()),
                                ),
                                color: Colors.white,
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  globalPondAsset,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        child: const Center(
                                          child: Icon(
                                            Icons.pool,
                                            size: 44,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              pondName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[850],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.list_alt,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${usageList.length}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      size: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Tk ${totalCost.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }, childCount: totalTiles),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
