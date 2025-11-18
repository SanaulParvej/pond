import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/pond_controller.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final String? productType;
  const AddProductScreen({super.key, this.productType});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final PondController pondController = Get.find<PondController>();
  String _unit = 'kg';
  String _category = 'feed';
  Product? _editingProduct;

  bool get _isEditing => _editingProduct != null;

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
    _unit = _defaultUnitForCategory(_category);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String _defaultUnitForCategory(String category) {
    return category.toLowerCase() == 'medicine' ? 'ml' : 'kg';
  }

  String _normalizedUnitForCategory(String category, String unit) {
    final options = _baseUnitsForCategory(category);
    final lowerUnit = unit.toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == lowerUnit) {
        return option;
      }
    }
    return options.first;
  }

  void _resetForm({bool keepCategory = true}) {
    setState(() {
      _editingProduct = null;
      _nameCtrl.clear();
      _codeCtrl.clear();
      _priceCtrl.clear();
      if (!keepCategory && widget.productType == null) {
        _category = 'feed';
      } else if (widget.productType != null) {
        _category = widget.productType!.toLowerCase();
      }
      _unit = _defaultUnitForCategory(_category);
    });
  }

  void _startEditing(Product product) {
    setState(() {
      _editingProduct = product;
      _nameCtrl.text = product.name;
      _codeCtrl.text = product.code;
      _priceCtrl.text = product.pricePerUnit.toStringAsFixed(2);
      _category = widget.productType?.toLowerCase() ?? product.category;
      _unit = _normalizedUnitForCategory(_category, product.unit);
    });
  }

  List<String> _baseUnitsForCategory(String category) {
    return category.toLowerCase() == 'medicine'
      ? <String>['ml', 'L']
        : <String>['kg', 'gm'];
  }

  List<DropdownMenuItem<String>> _unitDropdownItems() {
    String labelForUnit(String unit) {
      if (unit.toLowerCase() == 'ml') return 'ML';
      if (unit.toLowerCase() == 'l') return 'L';
      return unit;
    }

    final baseUnits = _baseUnitsForCategory(_category);
    return baseUnits
        .map(
          (unit) => DropdownMenuItem<String>(
            value: unit,
            child: Text(labelForUnit(unit)),
          ),
        )
        .toList();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Remove ${product.name}?'),
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

    if (!mounted) return;

    if (confirm == true) {
      final removed = await pondController.removeProduct(product.code);
      if (removed) {
        if (_editingProduct?.code == product.code) {
          _resetForm();
        } else {
          setState(() {});
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${product.name} deleted')));
      }
    }
  }

  void _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final product = Product(
      name: name,
      code: code,
      unit: _unit,
      pricePerUnit: price,
      category: _category,
    );

    if (_isEditing) {
      final originalCode = _editingProduct!.code;
      if (originalCode != code && pondController.codeExists(code)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code already exists')));
        return;
      }
      final updated = await pondController.updateProduct(originalCode, product);
      if (!updated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update item right now')),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Updated $name')));
      _resetForm();
    } else {
      if (pondController.codeExists(code)) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Code already exists')));
        return;
      }
      final added = await pondController.addProduct(product);
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save item right now')),
        );
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Added $name')));
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputDecoration decorate(String label, {String? hint, String? prefixText}) {
      return const InputDecoration()
          .applyDefaults(theme.inputDecorationTheme)
          .copyWith(labelText: label, hintText: hint, prefixText: prefixText);
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 26,
                    ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 20,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _screenIcon,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _screenTitle,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          if (isCompact) ...[
                            TextFormField(
                              controller: _nameCtrl,
                              decoration: decorate(
                                'Product Name',
                                hint: 'e.g. GrowMax Feed',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _codeCtrl,
                              readOnly: _isEditing,
                              decoration: decorate(
                                'Product Code',
                                hint: 'SKU or code',
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Required'
                                  : null,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _nameCtrl,
                                    decoration: decorate(
                                      'Product Name',
                                      hint: 'e.g. GrowMax Feed',
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: TextFormField(
                                    controller: _codeCtrl,
                                    readOnly: _isEditing,
                                    decoration: decorate(
                                      'Product Code',
                                      hint: 'SKU or code',
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          if (isCompact) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _unit,
                              items: _unitDropdownItems(),
                              onChanged: (v) {
                                if (v != null) setState(() => _unit = v);
                              },
                              decoration: decorate('Unit'),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceCtrl,
                              decoration: decorate(
                                'Price per Unit',
                                prefixText: 'Tk ',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textInputAction: TextInputAction.next,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _unit,
                                    items: _unitDropdownItems(),
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
                                    decoration: decorate(
                                      'Price per Unit',
                                      prefixText: 'Tk ',
                                    ),
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 22),
                          if (widget.productType == null) ...[
                            DropdownButtonFormField<String>(
                              initialValue: _category,
                              items: const [
                                DropdownMenuItem(
                                  value: 'feed',
                                  child: Text('Feed'),
                                ),
                                DropdownMenuItem(
                                  value: 'medicine',
                                  child: Text('Medicine'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) {
                                  setState(() {
                                    _category = v;
                                    _unit = _normalizedUnitForCategory(
                                      v,
                                      _unit,
                                    );
                                  });
                                }
                              },
                              decoration: decorate('Category'),
                            ),
                          ] else ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Chip(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                label: Text(
                                  _typeLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                avatar: Icon(
                                  _screenIcon,
                                  size: 18,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          const Divider(height: 1),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    if (_isEditing) {
                                      _resetForm();
                                    } else {
                                      Get.back();
                                    }
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    side: BorderSide(
                                      color: _isEditing
                                          ? theme.colorScheme.outline
                                              .withValues(alpha: 0.6)
                                          : Colors.red,
                                      width: _isEditing ? 1 : 2,
                                    ),
                                    foregroundColor:
                                        _isEditing ? null : Colors.red,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    _isEditing ? 'Cancel Edit' : 'Close',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(
                                    _isEditing ? 'Update' : 'Save Item',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          const Divider(height: 1),
                          const SizedBox(height: 20),
                          Obx(
                            () => _InventoryList(
                              products: pondController.products.toList(
                                growable: false,
                              ),
                              filterCategory: widget.productType,
                              onEdit: _startEditing,
                              onDelete: _deleteProduct,
                              editingCode: _editingProduct?.code,
                            ),
                          ),
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

class _InventoryList extends StatelessWidget {
  final List<Product> products;
  final String? filterCategory;
  final ValueChanged<Product> onEdit;
  final ValueChanged<Product> onDelete;
  final String? editingCode;

  const _InventoryList({
    required this.products,
    required this.onEdit,
    required this.onDelete,
    this.filterCategory,
    this.editingCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryFilter = filterCategory?.toLowerCase();
    final filtered =
        products
            .where(
              (product) =>
                  categoryFilter == null ||
                  product.category.toLowerCase() == categoryFilter,
            )
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              Icons.inventory_2_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No items yet. Add products to keep track here.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    IconData iconFor(Product product) {
      switch (product.category) {
        case 'medicine':
          return Icons.medical_services_rounded;
        case 'feed':
          return Icons.restaurant_menu_rounded;
        default:
          return Icons.inventory_2_rounded;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Inventory',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = filtered[index];
            final isEditing = product.code == editingCode;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: isEditing
                    ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                    : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEditing
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  child: Icon(
                    iconFor(product),
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                ),
                title: Text(
                  product.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Code: ${product.code}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Tk ${product.pricePerUnit.toStringAsFixed(2)} per ${product.unit}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: Icon(
                        Icons.edit_rounded,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: () => onEdit(product),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: Icon(
                        Icons.delete_rounded,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () => onDelete(product),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
