import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repository/pond_repository.dart';

class AddProductScreen extends StatefulWidget {
  final String? productType; // 'feed' or 'medicine' or null
  const AddProductScreen({super.key, this.productType});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _unit = 'kg';
  String _category = 'feed';

  @override
  void initState() {
    super.initState();
    if (widget.productType != null) {
      _category = widget.productType!;
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final prod = Product(name: _nameCtrl.text.trim(), code: _codeCtrl.text.trim(), unit: _unit, pricePerUnit: double.tryParse(_priceCtrl.text.trim()) ?? 0.0, category: _category);
      PondRepository.instance.addProduct(prod);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Add Product')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      Expanded(child: TextFormField(controller: _nameCtrl, decoration: inputDecoration.copyWith(labelText: 'Product Name', hintText: 'e.g. GrowMax Feed'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _codeCtrl, decoration: inputDecoration.copyWith(labelText: 'Product Code', hintText: 'SKU or code'), validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null)),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: DropdownButtonFormField<String>(value: _unit, items: const [DropdownMenuItem(value: 'kg', child: Text('kg')), DropdownMenuItem(value: 'gm', child: Text('gm'))], onChanged: (v) { if (v != null) setState(() => _unit = v); }, decoration: inputDecoration.copyWith(labelText: 'Unit'))),
                      const SizedBox(width: 12),
                      Expanded(child: TextFormField(controller: _priceCtrl, decoration: inputDecoration.copyWith(labelText: 'Price per Unit', prefixText: '৳ '), keyboardType: TextInputType.numberWithOptions(decimal: true), validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null)),
                    ]),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(value: _category, items: const [DropdownMenuItem(value: 'feed', child: Text('Feed')), DropdownMenuItem(value: 'medicine', child: Text('Medicine'))], onChanged: (v) { if (v != null) setState(() => _category = v); }, decoration: inputDecoration.copyWith(labelText: 'Category')),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Cancel'),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Save'),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
