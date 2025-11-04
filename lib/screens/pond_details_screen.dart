import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../controllers/pond_controller.dart';
import '../models/product.dart';
import '../models/usage.dart';
import '../routes/app_routes.dart';

class PondDetailsScreen extends StatefulWidget {
  final int pondId;
  const PondDetailsScreen({super.key, required this.pondId});

  @override
  State<PondDetailsScreen> createState() => _PondDetailsScreenState();
}

class _PondDetailsScreenState extends State<PondDetailsScreen> {
  final PondController pondController = Get.find<PondController>();

  void _openAddUsage({String? type}) async {
    final result = await Get.toNamed(
      AppRoutes.addUsage,
      arguments: {'pondId': widget.pondId, 'productType': type},
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _renamePond() async {
    final currentName = pondController.pondName(widget.pondId);
    final controller = TextEditingController(text: currentName);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Rename Pond'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(labelText: 'Pond name'),
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

    if (confirmed == true) {
      final name = controller.text.trim();
      if (name.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
        return;
      }
      pondController.renamePond(widget.pondId, name);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Renamed to $name')));
      }
    }
  }

  Future<void> _onDownload() async {
    final usages = pondController.usagesForPond(widget.pondId);
    if (usages.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No usage data to export')));
      return;
    }

    final feedUsages = <Usage>[];
    final medicineUsages = <Usage>[];
    final otherUsages = <Usage>[];

    for (final usage in usages) {
      switch (_categoryForUsage(usage)) {
        case 'feed':
          feedUsages.add(usage);
          break;
        case 'medicine':
          medicineUsages.add(usage);
          break;
        default:
          otherUsages.add(usage);
      }
    }

    double totalFor(List<Usage> list) =>
        list.fold(0.0, (sum, u) => sum + u.totalPrice);
    double weightFor(List<Usage> list) =>
        list.fold(0.0, (sum, u) => sum + (u.weight > 0 ? u.weight : 0.0));

    String formatCurrency(double amount) => 'Tk ${amount.toStringAsFixed(2)}';

    String? weightLabelFor(List<Usage> list) {
      final totalWeight = weightFor(list);
      if (totalWeight <= 0) return null;
      final units = <String>{};
      for (final usage in list) {
        final unit = usage.unit.trim();
        if (unit.isNotEmpty) units.add(unit);
      }
      final unitLabel = units.isEmpty
          ? ''
          : units.length == 1
          ? units.first
          : 'mixed units';
      final value = totalWeight.toStringAsFixed(2);
      return unitLabel.isEmpty ? value : '$value $unitLabel';
    }

    String composeCategorySummary(double cost, String? weightLabel) {
      return weightLabel == null
          ? formatCurrency(cost)
          : '${formatCurrency(cost)} | Weight: $weightLabel';
    }

    pw.Widget summaryRow(String label, String value, pw.TextStyle valueStyle) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label),
            pw.Text(value, style: valueStyle),
          ],
        ),
      );
    }

    pw.Widget categorySection(
      String title,
      List<Usage> data, {
      required bool showWeight,
    }) {
      final total = totalFor(data);
      final weightLabel = showWeight ? weightLabelFor(data) : null;
      final headerStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 11,
      );
      final cellStyle = const pw.TextStyle(fontSize: 11);
      final headers = <String>['Date', 'Item', if (showWeight) 'Qty', 'Cost'];
      final rows = data.map((u) {
        final cells = <String>[_formatDisplayDate(u.date), u.productName];
        if (showWeight) {
          final qty = u.weight > 0
              ? '${u.weight.toStringAsFixed(2)} ${u.unit}'
              : '-';
          cells.add(qty);
        }
        cells.add(formatCurrency(u.totalPrice));
        return cells;
      }).toList();

      return pw.Column(
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey200,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(title, style: headerStyle),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(formatCurrency(total), style: headerStyle),
                    if (weightLabel != null)
                      pw.Text(
                        'Weight: $weightLabel',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (data.isEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 12),
              child: pw.Text(
                'No records in this category',
                style: cellStyle.copyWith(color: PdfColors.grey600),
              ),
            )
          else ...[
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.4),
              columnWidths: showWeight
                  ? {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(2.4),
                      2: const pw.FlexColumnWidth(1.3),
                      3: const pw.FlexColumnWidth(1.2),
                    }
                  : {
                      0: const pw.FlexColumnWidth(1.4),
                      1: const pw.FlexColumnWidth(2.7),
                      2: const pw.FlexColumnWidth(1.2),
                    },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: headers
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h, style: headerStyle),
                        ),
                      )
                      .toList(),
                ),
                ...rows.map(
                  (row) => pw.TableRow(
                    children: row
                        .map(
                          (cell) => pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(cell, style: cellStyle),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 16),
        ],
      );
    }

    final pondName = pondController.pondName(widget.pondId);
    final totalWeight = pondController.totalWeightForPond(widget.pondId);
    final totalCost = pondController.totalCostForPond(widget.pondId);
    final feedTotalCost = totalFor(feedUsages);
    final medicineTotalCost = totalFor(medicineUsages);
    final otherTotalCost = totalFor(otherUsages);
    final feedWeightLabel = weightLabelFor(feedUsages);
    final medicineWeightLabel = weightLabelFor(medicineUsages);

    try {
      final baseFontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final boldFontData = await rootBundle.load(
        'assets/fonts/NotoSans-Bold.ttf',
      );
      final baseFont = pw.Font.ttf(baseFontData);
      final boldFont = pw.Font.ttf(boldFontData);

      final doc = pw.Document();
      final boldValueStyle = pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 12,
      );

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
          ),
          build: (context) => [
            pw.Text(
              'Pond Summary',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(pondName, style: const pw.TextStyle(fontSize: 14)),
            pw.Text(
              'Generated on ${_formatDisplayDate(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 16),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: pw.BoxDecoration(
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.grey400, width: 0.6),
              ),
              child: pw.Column(
                children: [
                  summaryRow(
                    'Total Weight',
                    totalWeight.toStringAsFixed(2),
                    boldValueStyle,
                  ),
                  summaryRow(
                    'Total Cost',
                    formatCurrency(totalCost),
                    boldValueStyle,
                  ),
                  summaryRow(
                    'Feed',
                    composeCategorySummary(feedTotalCost, feedWeightLabel),
                    boldValueStyle,
                  ),
                  summaryRow(
                    'Medicine',
                    composeCategorySummary(
                      medicineTotalCost,
                      medicineWeightLabel,
                    ),
                    boldValueStyle,
                  ),
                  summaryRow(
                    'Other Expense',
                    formatCurrency(otherTotalCost),
                    boldValueStyle,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),
            categorySection('Feed', feedUsages, showWeight: true),
            categorySection('Medicine', medicineUsages, showWeight: true),
            categorySection('Other Expense', otherUsages, showWeight: false),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Grand Total: ${formatCurrency(totalCost)}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );

      final bytes = await doc.save();
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'pond_${widget.pondId}_summary.pdf',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF ready to share')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to generate PDF right now')),
      );
    }
  }

  void _showDetails() {
    final usages = pondController.usagesForPond(widget.pondId);
    final feedUsages = <Usage>[];
    final medicineUsages = <Usage>[];
    final otherUsages = <Usage>[];

    for (final usage in usages) {
      switch (_categoryForUsage(usage)) {
        case 'feed':
          feedUsages.add(usage);
          break;
        case 'medicine':
          medicineUsages.add(usage);
          break;
        default:
          otherUsages.add(usage);
      }
    }

    Map<DateTime, List<Usage>> groupByDate(List<Usage> list) {
      final map = <DateTime, List<Usage>>{};
      for (final usage in list) {
        final localDate = usage.date.toLocal();
        final key = DateTime(localDate.year, localDate.month, localDate.day);
        map.putIfAbsent(key, () => []).add(usage);
      }
      return map;
    }

    double totalFor(List<Usage> list) =>
        list.fold(0.0, (sum, u) => sum + u.totalPrice);
    double weightFor(List<Usage> list) =>
        list.fold(0.0, (sum, u) => sum + u.weight);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final totalWeight = pondController.totalWeightForPond(widget.pondId);
        final totalCost = pondController.totalCostForPond(widget.pondId);
        final feedGrouped = groupByDate(feedUsages);
        final medicineGrouped = groupByDate(medicineUsages);
        final otherGrouped = groupByDate(otherUsages);
        final feedTotal = totalFor(feedUsages);
        final medicineTotal = totalFor(medicineUsages);
        final otherTotal = totalFor(otherUsages);
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            final theme = Theme.of(context);
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pond Summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Weight',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(totalWeight.toStringAsFixed(2)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Cost',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text('Tk ${totalCost.toStringAsFixed(2)}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _CategoryTotalRow(
                          label: 'Feed',
                          amount: feedTotal,
                          color: _categoryColor('feed', theme),
                          icon: _categoryIcon('feed'),
                        ),
                        const SizedBox(height: 10),
                        _CategoryTotalRow(
                          label: 'Medicine',
                          amount: medicineTotal,
                          color: _categoryColor('medicine', theme),
                          icon: _categoryIcon('medicine'),
                        ),
                        const SizedBox(height: 10),
                        _CategoryTotalRow(
                          label: 'Other Expense',
                          amount: otherTotal,
                          color: _categoryColor('other', theme),
                          icon: _categoryIcon('other'),
                        ),
                        const SizedBox(height: 12),
                        _CategoryBreakdown(
                          title: 'Feed',
                          groupedByDate: feedGrouped,
                          totalCost: feedTotal,
                          totalWeight: weightFor(feedUsages),
                          showWeight: true,
                          accentColor: _categoryColor('feed', theme),
                          icon: _categoryIcon('feed'),
                          onViewUsage: _showUsageActions,
                        ),
                        const SizedBox(height: 16),
                        _CategoryBreakdown(
                          title: 'Medicine',
                          groupedByDate: medicineGrouped,
                          totalCost: medicineTotal,
                          totalWeight: weightFor(medicineUsages),
                          showWeight: true,
                          accentColor: _categoryColor('medicine', theme),
                          icon: _categoryIcon('medicine'),
                          onViewUsage: _showUsageActions,
                        ),
                        const SizedBox(height: 16),
                        _CategoryBreakdown(
                          title: 'Other Expense',
                          groupedByDate: otherGrouped,
                          totalCost: otherTotal,
                          totalWeight: weightFor(otherUsages),
                          showWeight: false,
                          accentColor: _categoryColor('other', theme),
                          icon: _categoryIcon('other'),
                          onViewUsage: _showUsageActions,
                        ),
                        const SizedBox(height: 20),
                        Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Grand Totals',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Weight'),
                                    Text(totalWeight.toStringAsFixed(2)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Total Cost'),
                                    Text('Tk ${totalCost.toStringAsFixed(2)}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _categoryForUsage(Usage usage) {
    final codeUpper = usage.productCode.toUpperCase();
    final product = _findProductByCode(usage.productCode);
    if (product != null) {
      final category = product.category.toLowerCase();
      if (category.contains('feed')) return 'feed';
      if (category.contains('medicine')) return 'medicine';
    }
    if (codeUpper.startsWith('F')) return 'feed';
    if (codeUpper.startsWith('M')) return 'medicine';
    if (codeUpper == 'OTHER') return 'other';
    return 'other';
  }

  Color _categoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'feed':
        return theme.colorScheme.primary;
      case 'medicine':
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.secondary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'feed':
        return Icons.restaurant_menu;
      case 'medicine':
        return Icons.medical_services;
      default:
        return Icons.attach_money;
    }
  }

  Product? _findProductByCode(String code) {
    return pondController.productByCode(code);
  }

  Future<void> _showUsageActions(Usage usage) async {
    final usageId = usage.id;
    if (usageId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usage not available yet')),
      );
      return;
    }
    final categoryKey = _categoryForUsage(usage);
    final result = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final accent = _categoryColor(categoryKey, theme);
        final icon = _categoryIcon(categoryKey);
        final dateLabel = _formatDisplayDate(usage.date);
        final showWeight = categoryKey != 'other';
        final unitValue = showWeight
            ? '${usage.weight.toStringAsFixed(2)} ${usage.unit}'
            : 'Tk ${usage.totalPrice.toStringAsFixed(2)}';
        final unitPrice = showWeight && usage.weight > 0
            ? usage.totalPrice / usage.weight
            : null;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: accent.withAlpha(36),
                      child: Icon(icon, color: accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        usage.productName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailInfoRow(
                  label: 'Category',
                  value: _categoryLabel(categoryKey),
                ),
                _DetailInfoRow(label: 'Date', value: dateLabel),
                _DetailInfoRow(
                  label: showWeight ? 'Weight Used' : 'Expense Amount',
                  value: unitValue,
                ),
                if (unitPrice != null)
                  _DetailInfoRow(
                    label: 'Unit Price',
                    value: 'Tk ${unitPrice.toStringAsFixed(2)}',
                  ),
                _DetailInfoRow(
                  label: 'Total Cost',
                  value: 'Tk ${usage.totalPrice.toStringAsFixed(2)}',
                  emphasize: true,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Get.back(result: 'edit'),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Entry'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Get.back(result: 'delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                      color: theme.colorScheme.error.withAlpha(120),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Entry'),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => Get.back(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;
    if (result == 'edit') {
      await _editUsageEntry(usage, categoryKey);
    } else if (result == 'delete') {
      await _confirmDeleteUsage(usage);
    }
  }

  Future<void> _editUsageEntry(
    Usage usage,
    String categoryKey,
  ) async {
    final edited =
        await Get.toNamed(
              AppRoutes.addUsage,
              arguments: {
                'pondId': widget.pondId,
                'productType': categoryKey,
                'initialUsage': usage,
                'usageId': usage.id,
              },
            )
            as bool?;
    if (!mounted) return;
    if (edited == true) {
      setState(() {});
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usage updated')));
    }
  }

  Future<void> _confirmDeleteUsage(Usage usage) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete usage?'),
        content: const Text(
          'This will remove the selected usage entry permanently.',
        ),
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
      final usageId = usage.id;
      if (usageId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usage not available yet')),
        );
        return;
      }
      final removed = await pondController.removeUsage(usageId);
      if (!mounted) return;
      if (removed) {
        setState(() {});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usage deleted')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Unable to delete usage')));
      }
    }
  }

  String _formatDisplayDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final local = date.toLocal();
    final month = months[local.month - 1];
    final day = local.day.toString().padLeft(2, '0');
    return '$day $month ${local.year}';
  }

  String _categoryLabel(String categoryKey) {
    switch (categoryKey) {
      case 'feed':
        return 'Feed';
      case 'medicine':
        return 'Medicine';
      default:
        return 'Other Expense';
    }
  }

  @override
  Widget build(BuildContext context) {
    final usages = pondController.usagesForPond(widget.pondId);
    final totalWeight = pondController.totalWeightForPond(widget.pondId);
    final totalCost = pondController.totalCostForPond(widget.pondId);

    final Map<String, List<Usage>> grouped = {};
    for (final u in usages) {
      final key = u.date.toLocal().toIso8601String().split('T').first;
      grouped.putIfAbsent(key, () => []).add(u);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Text(pondController.pondName(widget.pondId)),
        actions: [
          IconButton(onPressed: _renamePond, icon: const Icon(Icons.edit)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  Card(
                    elevation: 0,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.black.withAlpha(12)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _openAddUsage(type: 'feed'),
                                  icon: const Icon(Icons.restaurant_menu),
                                  label: const Text('Add Feed'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _openAddUsage(type: 'medicine'),
                                  icon: const Icon(Icons.medical_services),
                                  label: const Text('Add Medicine'),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _openAddUsage(type: 'other'),
                            icon: const Icon(Icons.attach_money),
                            label: const Text('Add Other Expense'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (usages.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            'No usage recorded yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    )
                  else
                    ...sortedDates.expand((dateKey) {
                      final items = grouped[dateKey] ?? [];
                      return [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            dateKey,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        ...items.map(
                          (u) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(10),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    child: const Icon(
                                      Icons.inventory_2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.productName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${u.unit} ${u.weight}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        'Tk ${u.totalPrice.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        onPressed: () => _showUsageActions(u),
                                        child: const Text('Details'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ];
                    }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Weight',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        totalWeight.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Cost',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tk ${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDetails,
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _onDownload,
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final String title;
  final Map<DateTime, List<Usage>> groupedByDate;
  final double totalCost;
  final double totalWeight;
  final bool showWeight;
  final Color accentColor;
  final IconData icon;
  final void Function(Usage usage) onViewUsage;

  const _CategoryBreakdown({
    required this.title,
    required this.groupedByDate,
    required this.totalCost,
    required this.totalWeight,
    required this.showWeight,
    required this.accentColor,
    required this.icon,
    required this.onViewUsage,
  });

  @override
  Widget build(BuildContext context) {
    final entries = groupedByDate.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final theme = Theme.of(context);
    final sections = <Widget>[];

    if (entries.isEmpty) {
      sections.add(
        Text('No records yet', style: TextStyle(color: Colors.grey[500])),
      );
    } else {
      for (var index = 0; index < entries.length; index++) {
        final entry = entries[index];
        sections.add(
          Padding(
            padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
            child: Text(
              _formatDate(entry.key),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
        for (final usage in entry.value) {
          sections.add(
            _UsageRow(
              usage: usage,
              showWeight: showWeight,
              accentColor: accentColor,
              onView: () => onViewUsage(usage),
            ),
          );
        }
        if (index != entries.length - 1) {
          sections.add(const Divider(height: 24));
        }
      }
    }

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: accentColor.withAlpha(32),
                  child: Icon(icon, color: accentColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tk ${totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (showWeight && totalWeight > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${totalWeight.toStringAsFixed(2)} ${_weightUnit(entries)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sections,
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final day = date.day.toString().padLeft(2, '0');
    return '$day $month ${date.year}';
  }

  String _weightUnit(List<MapEntry<DateTime, List<Usage>>> entries) {
    for (final entry in entries) {
      for (final usage in entry.value) {
        if (usage.unit.isNotEmpty) {
          return usage.unit;
        }
      }
    }
    return 'unit';
  }
}

class _UsageRow extends StatelessWidget {
  final Usage usage;
  final bool showWeight;
  final Color accentColor;
  final VoidCallback onView;

  const _UsageRow({
    required this.usage,
    required this.showWeight,
    required this.accentColor,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onView,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withAlpha(40)),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    usage.productName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (showWeight && usage.weight > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        '${usage.unit} ${usage.weight}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Tk ${usage.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Details',
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: accentColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTotalRow extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _CategoryTotalRow({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blended = Color.alphaBlend(
      color.withAlpha(24),
      theme.colorScheme.surfaceContainerLow,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: blended,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(54)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withAlpha(36),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            'Tk ${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _DetailInfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final valueStyle = emphasize
        ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)
        : theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value, textAlign: TextAlign.right, style: valueStyle),
          ),
        ],
      ),
    );
  }
}
