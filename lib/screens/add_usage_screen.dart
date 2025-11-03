import 'package:flutter/material.dart';
import '../repository/pond_repository.dart';
import '../models/product.dart';
import '../models/usage.dart';

class AddUsageScreen extends StatefulWidget {
  final int? pondId; // if null user must pick pond
  final String? productType; // 'feed' or 'medicine' or null
  const AddUsageScreen({super.key, this.pondId, this.productType});

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
  int? _selectedPond;

  double get total {
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    if (selected == null) return 0.0;
    return w * selected!.pricePerUnit;
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _weightCtrl.dispose();
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a product')));
      return;
    }
    final pondId = widget.pondId ?? _selectedPond;
    if (pondId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a pond')));
      return;
    }
    final w = double.tryParse(_weightCtrl.text.trim()) ?? 0.0;
    final usage = Usage(date: _selectedDate, productCode: selected!.code, productName: selected!.name, unit: selected!.unit, weight: w, totalPrice: w * selected!.pricePerUnit);
    repo.addUsage(pondId, usage);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // filter products by category if requested
    List<Product> available = repo.products;
    if (widget.productType != null) {
      final t = widget.productType!.toLowerCase();
      available = repo.products.where((p) => p.category.toLowerCase() == t).toList();
    }
    final productCodes = available.map((e) => e.code).toList();

    // If productType filtered to a single product and nothing selected yet, prefill selection
    if (widget.productType != null && selected == null && available.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          selected = available.first;
          _codeCtrl.text = selected!.code;
          _nameCtrl.text = selected!.name;
          _unitCtrl.text = selected!.unit;
          _priceCtrl.text = selected!.pricePerUnit.toString();
        });
      });
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product Usage')),
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
                          child: Row(children: [Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]), const SizedBox(width: 8), Text('${_selectedDate.toLocal().toString().split(' ').first}')] ),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
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
                        _priceCtrl.text = p.pricePerUnit.toString();
                      });
                    },
                    fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                      return TextField(controller: controller, focusNode: focusNode, decoration: const InputDecoration(labelText: 'Product Code (search)'));
                    },
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 12),
                  TextField(controller: _weightCtrl, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight used'), onChanged: (_) => setState(() {})),
                  const SizedBox(height: 18),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: TextStyle(color: Colors.grey[700])),
                    Text('৳ ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))), const SizedBox(width: 12), Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save')))]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
