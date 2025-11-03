import 'package:flutter/material.dart';
import '../repository/pond_repository.dart';
import '../models/usage.dart';
import 'add_usage_screen.dart';

class PondDetailsScreen extends StatefulWidget {
  final int pondId;
  const PondDetailsScreen({super.key, required this.pondId});

  @override
  State<PondDetailsScreen> createState() => _PondDetailsScreenState();
}

class _PondDetailsScreenState extends State<PondDetailsScreen> {
  final repo = PondRepository.instance;

  void _openAddUsage({String? type}) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddUsageScreen(pondId: widget.pondId, productType: type)));
    setState(() {});
  }

  // Note: Print and Download were replaced by View Details modal. Kept methods removed.
  void _onDownload() {
    // Placeholder download action: inform user and offer guidance
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download PDF is not implemented yet. To export, enable PDF export in settings.')));
  }

  void _showDetails() {
    final usages = repo.getUsagesForPond(widget.pondId);
    final Map<String, Map<String, double>> dateTotals = {};
    for (final u in usages) {
      final key = u.date.toLocal().toIso8601String().split('T').first;
      final entry = dateTotals.putIfAbsent(key, () => {'weight': 0.0, 'cost': 0.0});
      entry['weight'] = (entry['weight'] ?? 0) + u.weight;
      entry['cost'] = (entry['cost'] ?? 0) + u.totalPrice;
    }

    showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (context) {
      final totalWeight = repo.totalWeightForPond(widget.pondId);
      final totalCost = repo.totalCostForPond(widget.pondId);
      final dates = dateTotals.keys.toList()..sort((a, b) => b.compareTo(a));
      return DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
            child: Column(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 12),
              Text('Pond Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Weight', style: TextStyle(color: Colors.grey[700])), Text('${totalWeight.toStringAsFixed(2)}')]),
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Cost', style: TextStyle(color: Colors.grey[700])), Text('৳ ${totalCost.toStringAsFixed(2)}')]),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: dates.length,
                  itemBuilder: (context, i) {
                    final d = dates[i];
                    final t = dateTotals[d]!;
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 12),
                      Text(d, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Weight:'), Text('${(t['weight'] ?? 0).toStringAsFixed(2)}')]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Cost:'), Text('৳ ${(t['cost'] ?? 0).toStringAsFixed(2)}')]),
                    ]);
                  },
                ),
              ),
            ]),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final usages = repo.getUsagesForPond(widget.pondId);
    final totalWeight = repo.totalWeightForPond(widget.pondId);
    final totalCost = repo.totalCostForPond(widget.pondId);

    // group usages by date (yyyy-mm-dd)
  final Map<String, List<Usage>> grouped = {};
    for (final u in usages) {
      final key = u.date.toLocal().toIso8601String().split('T').first;
      grouped.putIfAbsent(key, () => []).add(u);
    }
    // sort dates descending
  final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(title: Text(PondRepository.instance.getPondName(widget.pondId))),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _openAddUsage(type: 'feed'), icon: const Icon(Icons.restaurant_menu), label: const Text('Add Feed'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: () => _openAddUsage(type: 'medicine'), icon: const Icon(Icons.medical_services), label: const Text('Add Medicine'))),
            ]),
            const SizedBox(height: 12),
            Expanded(
              child: usages.isEmpty
                  ? Card(child: Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('No usage recorded yet', style: Theme.of(context).textTheme.bodyMedium))))
                  : ListView.builder(
                      itemCount: sortedDates.length,
                      itemBuilder: (context, idx) {
                        final dateKey = sortedDates[idx];
                        final items = grouped[dateKey] ?? [];
                        // date header + items
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Text(dateKey, style: Theme.of(context).textTheme.titleMedium),
                            ),
                            ...items.map((u) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
                                    padding: const EdgeInsets.all(12),
                                    child: Row(children: [
                                      CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.inventory_2, color: Colors.white)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(u.productName, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text('${u.unit} ${u.weight}', style: TextStyle(color: Colors.grey[600]))])),
                                      const SizedBox(width: 12),
                                      Column(children: [Text('৳ ${u.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w700)), const SizedBox(height: 6), TextButton(onPressed: () {}, child: const Text('Details'))]),
                                    ]),
                                  ),
                                )).toList(),
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Total Weight', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text('${totalWeight.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text('Total Cost', style: TextStyle(color: Colors.grey[700])), const SizedBox(height: 6), Text('৳ ${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))]),
              ]),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: ElevatedButton.icon(onPressed: _showDetails, icon: const Icon(Icons.visibility), label: const Text('View Details'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(onPressed: _onDownload, icon: const Icon(Icons.download), label: const Text('Download PDF'))),
            ],),
          ],
        ),
      ),
    );
  }
}
