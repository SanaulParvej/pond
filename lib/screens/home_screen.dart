import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pond_controller.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import '../widgets/logo_widget.dart';
import '../models/usage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final controller = Get.find<PondController>();
  final authController = Get.find<AuthController>();

  Future<void> showAddPondDialog() async {
    final nameCtrl = TextEditingController();
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Add New Pond'),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'Pond name'),
          onSubmitted: (_) => Get.back(result: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
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
      Get.snackbar('Pond added', pondName, snackPosition: SnackPosition.BOTTOM);
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

  @override
  Widget build(BuildContext context) {
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
      drawer: Drawer(
        child: Column(
          children: [
            Obx(() {
              final user = authController.user;
              return UserAccountsDrawerHeader(
                accountName: Text(user?.name ?? 'User'),
                accountEmail: Text(user?.email ?? user?.phoneNumber ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : const Icon(Icons.person, color: Colors.white),
                ),
              );
            }),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Get.back();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.profile);
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Get.back();
                    Get.defaultDialog(
                      title: 'Sign Out',
                      middleText: 'Are you sure you want to sign out?',
                      confirm: TextButton(
                        onPressed: () {
                          Get.back();
                          authController.signOut();
                        },
                        child: const Text('Yes'),
                      ),
                      cancel: TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('No'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Colors.red,
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
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF43A047),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => openAddProductQuick('feed'),
                            icon: const Icon(
                              Icons.restaurant_menu,
                              size: 24,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Feed',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shadowColor: Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: const Color(0xFF1E88E5),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => openAddProductQuick('medicine'),
                            icon: const Icon(
                              Icons.medical_services,
                              size: 24,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Add Medicine',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              side: BorderSide.none,
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const LogoWidget(size: 40, elevated: true),
                      const SizedBox(width: 12),
                      Text(
                        'Your Fish Ponds',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
                ),
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

                  final colors = [
                    const Color(0xFFE91E63),
                    const Color(0xFF9C27B0),
                    const Color(0xFF3F51B5),
                    const Color(0xFF009688),
                    const Color(0xFFFF9800),
                    const Color(0xFF795548),
                  ];
                  final pondColor = colors[pondId % colors.length];

                  return GestureDetector(
                    onTap: hasPond ? () => openPond(pondId) : null,
                    onLongPress: hasPond
                        ? () => confirmDeletePond(pondId)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: pondColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: pondColor, width: 3),
                                color: Colors.white,
                              ),
                              child: Center(
                                child: Image.asset(
                                  globalPondAsset,
                                  width: 30,
                                  height: 30,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              pondColor.withValues(alpha: 0.7),
                                              pondColor.withValues(alpha: 0.7),
                                            ],
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.pool,
                                            size: 30,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              pondName,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.list_alt,
                                      size: 14,
                                      color: pondColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${usageList.length}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Entries',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  height: 24,
                                  width: 1,
                                  color: Colors.grey[300],
                                ),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.monetization_on,
                                      size: 14,
                                      color: pondColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tk ${totalCost.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text(
                                      'Spent',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
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
              ),
            );
          }),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
