import 'package:flutter/material.dart';
import '../repository/pond_repository.dart';
import '../models/product.dart';
import '../models/usage.dart';

class AddUsageScreen extends StatefulWidget {
  final int? pondId; // if null user must pick pond
  final String? productType; // 'feed' or 'medicine' or null
  final Usage? initialUsage;
  final int? usageIndex;

  const AddUsageScreen({super.key, this.pondId, this.productType, this.initialUsage, this.usageIndex});

  @override
  State<AddUsageScreen> createState() => _AddUsageScreenState();
}

class _AddUsageScreenState extends State<AddUsageScreen> {
  final repo = PondRepository.instance;
  Product? selected;
  DateTime _selectedDate = DateTime.now();
  final _codeCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _otherNameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  int? _selectedPond;
  late final bool _isOtherMode;
  String? _categoryFilter;

  bool get isOther => _isOtherMode;
  bool get isEditing => widget.initialUsage != null && widget.usageIndex != null;

  @override
  void initState() {
    super.initState();
    _selectedPond = widget.pondId;
    _isOtherMode = _determineIsOtherMode();
    _categoryFilter = _determineCategoryFilter();
    if (widget.initialUsage != null) {
      _applyInitialUsage(widget.initialUsage!);
    }
  }

  bool _determineIsOtherMode() {
    final type = widget.productType?.toLowerCase();
    if (type != null) return type == 'other';
    final usage = widget.initialUsage;
    if (usage != null) {
      return usage.productCode.toUpperCase() == 'OTHER';
    }
    return false;
  }

  String? _determineCategoryFilter() {
    if (_isOtherMode) return null;
    final type = widget.productType?.toLowerCase();
    if (type != null) return type;
    final usage = widget.initialUsage;
    if (usage == null) return null;
    final product = _findProductByCode(usage.productCode);
    if (product != null) {
      return product.category.toLowerCase();
    }
    final code = usage.productCode.toUpperCase();
    if (code.startsWith('M')) return 'medicine';
    if (code.startsWith('F')) return 'feed';
    return null;
  }

  void _applyInitialUsage(Usage usage) {
    _selectedDate = usage.date;
    if (_isOtherMode) {
      _otherNameCtrl.text = usage.productName;
      _amountCtrl.text = usage.totalPrice.toStringAsFixed(2);
    } else {
      final product = _findProductByCode(usage.productCode);
      selected = product;
      _codeCtrl.text = usage.productCode;
      _nameCtrl.text = usage.productName;
      _unitCtrl.text = usage.unit;
      if (usage.weight > 0) {
        _weightCtrl.text = usage.weight.toString();
        final unitPrice = product?.pricePerUnit ?? usage.totalPrice / usage.weight;
        _priceCtrl.text = unitPrice.toStringAsFixed(2);
      } else {
        _priceCtrl.text = product?.pricePerUnit.toStringAsFixed(2) ?? usage.totalPrice.toStringAsFixed(2);
      }
    }
  }

  Product? _findProductByCode(String code) {
    try {
      return repo.products.firstWhere((p) => p.code == code);
    } catch (_) {
      return null;
    }
  }

  double get total {
    if (isOther) {
      return double.tryParse(_amountCtrl.text.trim()) ?? 0.0;
    }
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final pricePerUnit = selected?.pricePerUnit ?? double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    return w * pricePerUnit;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _weightCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _otherNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final pondId = widget.pondId ?? _selectedPond;
    if (pondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pond')));
      return;
    }
    if (isOther) {
      final name = _otherNameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an expense name')));
        return;
      }
      final amount = double.tryParse(_amountCtrl.text.trim());
      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
        return;
      }
      final usage = Usage(
        date: _selectedDate,
        productCode: 'OTHER',
        productName: name,
        unit: 'amount',
        weight: 1,
        totalPrice: amount,
      );
      if (isEditing) {
        repo.updateUsage(pondId, widget.usageIndex!, usage);
      } else {
        repo.addUsage(pondId, usage);
      }
      Navigator.of(context).pop(true);
    } else {
      selected ??= _findProductByCode(_codeCtrl.text.trim());
      if (selected == null && _codeCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product')));
        return;
      }
      final w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
      final unitValue = selected?.unit ?? _unitCtrl.text.trim();
      final name = selected?.name ?? _nameCtrl.text.trim();
      final code = selected?.code ?? _codeCtrl.text.trim();
      final unitPrice = selected?.pricePerUnit ?? double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
      final usage = Usage(
        date: _selectedDate,
        productCode: code,
        productName: name,
        unit: unitValue,
        weight: w,
        totalPrice: w * unitPrice,
      );
      if (isEditing) {
        repo.updateUsage(pondId, widget.usageIndex!, usage);
      } else {
        repo.addUsage(pondId, usage);
      }
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // filter products by category if requested
    List<Product> available = repo.products;
    if (_categoryFilter != null && !isOther) {
      final t = _categoryFilter!;
      available = repo.products.where((p) => p.category.toLowerCase() == t).toList();
    }
    final productCodes = available.map((e) => e.code).toList();

    // If productType filtered to a single product and nothing selected yet, prefill selection
  if (!isOther && !isEditing && selected == null && available.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selected = available.first;
          _codeCtrl.text = selected!.code;
          _nameCtrl.text = selected!.name;
          _unitCtrl.text = selected!.unit;
          _priceCtrl.text = selected!.pricePerUnit.toStringAsFixed(2);
        });
      });
    }
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Usage' : 'Add Product Usage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(children: [
                  // date picker
                  Row(children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'Usage Date'),
                          child: Row(children: [Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]), const SizedBox(width: 8), Text(_selectedDate.toLocal().toString().split(' ').first)]),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (!isOther) ...[
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                        return productCodes.where((c) => c.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                      },
                      onSelected: (code) {
                        // find in the available list first to honor category filter
                        final p = available.firstWhere((p) => p.code == code, orElse: () => repo.products.firstWhere((p) => p.code == code));
                        setState(() {
                          selected = p;
                          _codeCtrl.text = p.code;
                          _nameCtrl.text = p.name;
                          _unitCtrl.text = p.unit;
                          _priceCtrl.text = p.pricePerUnit.toStringAsFixed(2);
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(controller: controller, focusNode: focusNode, decoration: const InputDecoration(labelText: 'Product Code (search)'));
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Pond selector when pondId not provided
                  if (widget.pondId == null) ...[
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(labelText: 'Select Pond'),
                      items: List.generate(6, (i) => DropdownMenuItem(value: i + 1, child: Text('Pond ${i + 1}'))),
                      onChanged: (v) => setState(() => _selectedPond = v),
                      initialValue: _selectedPond,
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!isOther) ...[
                    TextField(controller: _codeCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Selected Product Code')),
                    const SizedBox(height: 12),
                    // product preview
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: Theme.of(context).colorScheme.primary, child: const Icon(Icons.inventory_2, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_nameCtrl.text.isEmpty ? 'No product selected' : _nameCtrl.text, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), Text(_unitCtrl.text.isEmpty ? '' : '${_unitCtrl.text} • ৳ ${_priceCtrl.text}')])),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight used'), onChanged: (_) => setState(() {})),
                  ] else ...[
                    TextField(
                      controller: _otherNameCtrl,
                      decoration: const InputDecoration(labelText: 'Expense name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Amount (৳)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: TextStyle(color: Colors.grey[700])),
                    Text('৳ ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(onPressed: _save, child: Text(isEditing ? 'Update' : 'Save'))),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
