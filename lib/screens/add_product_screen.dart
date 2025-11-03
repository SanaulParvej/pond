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

  String get _typeLabel {
    final type = widget.productType?.toLowerCase();
    if (type == 'feed') return 'Feed';
    if (type == 'medicine') return 'Medicine';
    return 'Product';
  }

  String get _screenTitle => 'Add $_typeLabel';

  IconData get _screenIcon {
    switch (widget.productType?.toLowerCase()) {
      case 'medicine':
        return Icons.medical_services_rounded;
      case 'feed':
        return Icons.restaurant_menu_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  Color _headerColor(ThemeData theme) {
    final scheme = theme.colorScheme;
    switch (widget.productType?.toLowerCase()) {
      case 'medicine':
        return scheme.tertiary;
      case 'feed':
        return scheme.primary;
      default:
        return scheme.secondary;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.productType != null) {
      _category = widget.productType!.toLowerCase();
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
    final theme = Theme.of(context);

    InputDecoration decorate(String label, {String? hint, String? prefixText}) {
      return const InputDecoration().applyDefaults(theme.inputDecorationTheme).copyWith(labelText: label, hintText: hint, prefixText: prefixText);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_screenTitle)),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 640;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: _headerColor(theme),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                  child: Icon(_screenIcon, color: Colors.white, size: 30),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(_screenTitle, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (isCompact) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: decorate('Product Name', hint: 'e.g. GrowMax Feed'),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeCtrl,
                              decoration: decorate('Product Code', hint: 'SKU or code'),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                          ] else ...[
                            Row(children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameCtrl,
                                  decoration: decorate('Product Name', hint: 'e.g. GrowMax Feed'),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: TextFormField(
                                  controller: _codeCtrl,
                                  decoration: decorate('Product Code', hint: 'SKU or code'),
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 22),
                          if (isCompact) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _unit,
                              items: const [
                                DropdownMenuItem(value: 'kg', child: Text('kg')),
                                DropdownMenuItem(value: 'gm', child: Text('gm')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _unit = v);
                              },
                              decoration: decorate('Unit'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceCtrl,
                              decoration: decorate('Price per Unit', prefixText: '৳ '),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                            ),
                          ] else ...[
                            Row(children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: _unit,
                                  items: const [
                                    DropdownMenuItem(value: 'kg', child: Text('kg')),
                                    DropdownMenuItem(value: 'gm', child: Text('gm')),
                                  ],
                                  onChanged: (v) {
                                    if (v != null) setState(() => _unit = v);
                                  },
                                  decoration: decorate('Unit'),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: TextFormField(
                                  controller: _priceCtrl,
                                  decoration: decorate('Price per Unit', prefixText: '৳ '),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                                ),
                              ),
                            ]),
                          ],
                          const SizedBox(height: 22),
                          if (widget.productType == null) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              items: const [
                                DropdownMenuItem(value: 'feed', child: Text('Feed')),
                                DropdownMenuItem(value: 'medicine', child: Text('Medicine')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                              decoration: decorate('Category'),
                            ),
                          ] else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                backgroundColor: theme.colorScheme.primaryContainer,
                                label: Text(_typeLabel, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
                                avatar: Icon(_screenIcon, size: 18, color: theme.colorScheme.onPrimaryContainer),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                          Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.6)),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _save,
                                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
                                child: const Text('Save'),
                              ),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
