import 'dart:io';
import 'package:flutter/material.dart' hide Split;
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/split.dart';
import '../../models/split_member.dart';
import '../../providers/splits_provider.dart';
import '../../core/database/app_database.dart';

class AddEditSplitScreen extends ConsumerStatefulWidget {
  final int? splitId; // null = new manual split
  const AddEditSplitScreen({super.key, this.splitId});

  @override
  ConsumerState<AddEditSplitScreen> createState() => _AddEditSplitScreenState();
}

class _AddEditSplitScreenState extends ConsumerState<AddEditSplitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _category = 'Food';
  String _splitType = 'equal'; // 'equal' | 'custom'
  String? _photoPath;

  List<_MemberEntry> _members = [];
  bool _isLoading = false;

  Split? _existingSplit;

  static const _categories = ['Food', 'Travel', 'Shopping', 'Entertainment', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.splitId != null) _loadExisting();
  }

  Future<void> _loadExisting() async {
    setState(() => _isLoading = true);
    final split = await AppDatabase.instance.getSplitById(widget.splitId!);
    final members =
        await AppDatabase.instance.getMembersForSplit(widget.splitId!);
    if (!mounted) return;
    setState(() {
      _existingSplit = split;
      if (split != null) {
        _merchantCtrl.text = split.merchant;
        _amountCtrl.text = split.amount.toStringAsFixed(0);
        _noteCtrl.text = split.note ?? '';
        _category = split.category ?? 'Food';
        _photoPath = split.photoPath;
      }
      _members = members
          .map((m) => _MemberEntry(
                name: m.name,
                phone: m.phone ?? '',
                amountCtrl:
                    TextEditingController(text: m.amountOwed.toStringAsFixed(0)),
              ))
          .toList();
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    for (final m in _members) {
      m.amountCtrl.dispose();
    }
    super.dispose();
  }

  void _recalculateEqual() {
    if (_splitType != 'equal' || _members.isEmpty) return;
    final total = double.tryParse(_amountCtrl.text) ?? 0;
    final share = total / _members.length;
    for (final m in _members) {
      m.amountCtrl.text = share.toStringAsFixed(0);
    }
  }

  Future<void> _pickContact() async {
    try {
      final contact = await FlutterContacts.openExternalPick();
      if (contact == null) return;
      final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
      setState(() {
        _members.add(_MemberEntry(
          name: contact.displayName,
          phone: phone,
          amountCtrl: TextEditingController(),
        ));
        _recalculateEqual();
      });
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _photoPath = picked.path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountCtrl.text);
    final merchant = _merchantCtrl.text.trim();

    final split = (_existingSplit ?? Split(
      amount: amount,
      merchant: merchant,
      note: _noteCtrl.text.trim(),
      category: _category,
      photoPath: _photoPath,
      isComplete: true,
      createdAt: DateTime.now(),
    )).copyWith(
      amount: amount,
      merchant: merchant,
      note: _noteCtrl.text.trim(),
      category: _category,
      photoPath: _photoPath,
      isComplete: true,
    );

    int splitId;
    if (_existingSplit != null) {
      await ref.read(splitsProvider.notifier).updateSplit(split);
      splitId = _existingSplit!.id!;
      await AppDatabase.instance.deleteMembersForSplit(splitId);
    } else {
      splitId = await ref.read(splitsProvider.notifier).addSplit(split);
    }

    for (final m in _members) {
      final memberAmount = double.tryParse(m.amountCtrl.text) ?? 0;
      await AppDatabase.instance.insertMember(SplitMember(
        splitId: splitId,
        name: m.name,
        phone: m.phone.isNotEmpty ? m.phone : null,
        amountOwed: memberAmount,
      ));
    }

    await ref.read(splitsProvider.notifier).refresh();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: const BackButton(color: Colors.white),
        title: Text(
          widget.splitId != null ? 'Edit Split' : 'New Split',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Amount + Merchant ─────────────────────────────────────────
            _card(children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold),
                  hintText: '0',
                  border: InputBorder.none,
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter amount' : null,
                onChanged: (_) => _recalculateEqual(),
              ),
              const Divider(),
              TextFormField(
                controller: _merchantCtrl,
                decoration: const InputDecoration(
                  hintText: 'Paid to (Zomato, Friend, etc.)',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter merchant' : null,
              ),
            ]),

            const SizedBox(height: 14),

            // ── Note ─────────────────────────────────────────────────────
            _card(children: [
              TextFormField(
                controller: _noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: '📝 Add a note (Dinner, Groceries...)',
                  border: InputBorder.none,
                ),
              ),
            ]),

            const SizedBox(height: 14),

            // ── Category ─────────────────────────────────────────────────
            _card(children: [
              Row(
                children: [
                  const Text('🏷️  Category  ',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? 'Food'),
                      ),
                    ),
                  ),
                ],
              ),
            ]),

            const SizedBox(height: 14),

            // ── Photo ─────────────────────────────────────────────────────
            _card(children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Text('📸', style: TextStyle(fontSize: 22)),
                title: const Text('Attach Photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  _photoPath != null ? 'Photo attached ✓' : 'Bill, receipt or anything',
                  style: TextStyle(
                      color: _photoPath != null
                          ? const Color(0xFF4CAF50)
                          : Colors.grey),
                ),
                trailing: TextButton(
                  onPressed: _pickPhoto,
                  child: Text(_photoPath != null ? 'Change' : 'Add'),
                ),
              ),
              if (_photoPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(File(_photoPath!),
                      height: 100, fit: BoxFit.cover),
                ),
            ]),

            const SizedBox(height: 20),

            // ── People ────────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('👥  Split with',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Equal'),
                      selected: _splitType == 'equal',
                      onSelected: (_) =>
                          setState(() {
                            _splitType = 'equal';
                            _recalculateEqual();
                          }),
                    ),
                    const SizedBox(width: 6),
                    ChoiceChip(
                      label: const Text('Custom'),
                      selected: _splitType == 'custom',
                      onSelected: (_) =>
                          setState(() => _splitType = 'custom'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._members.asMap().entries.map((entry) {
              final i = entry.key;
              final m = entry.value;
              return _MemberTile(
                entry: m,
                splitType: _splitType,
                onRemove: () => setState(() {
                  _members.removeAt(i);
                  _recalculateEqual();
                }),
              );
            }),

            const SizedBox(height: 8),

            // Add person buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.contacts_outlined),
                    label: const Text('From Contacts'),
                    onPressed: _pickContact,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Type Name'),
                    onPressed: _addManualPerson,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }

  void _addManualPerson() {
    showDialog(
      context: context,
      builder: (_) {
        final nameCtrl = TextEditingController();
        final phoneCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Add Person'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneCtrl,
                decoration:
                    const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  setState(() {
                    _members.add(_MemberEntry(
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      amountCtrl: TextEditingController(),
                    ));
                    _recalculateEqual();
                  });
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

// ── Member entry model ─────────────────────────────────────────────────────────

class _MemberEntry {
  final String name;
  final String phone;
  final TextEditingController amountCtrl;
  _MemberEntry(
      {required this.name, required this.phone, required this.amountCtrl});
}

// ── Member tile ────────────────────────────────────────────────────────────────

class _MemberTile extends StatelessWidget {
  final _MemberEntry entry;
  final String splitType;
  final VoidCallback onRemove;

  const _MemberTile(
      {required this.entry,
      required this.splitType,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF4CAF50).withValues(alpha: 0.15),
          child: Text(entry.name[0].toUpperCase(),
              style: const TextStyle(
                  color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
        ),
        title: Text(entry.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle:
            entry.phone.isNotEmpty ? Text(entry.phone) : null,
        trailing: SizedBox(
          width: 90,
          child: Row(
            children: [
              const Text('₹',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(width: 2),
              Expanded(
                child: TextField(
                  controller: entry.amountCtrl,
                  keyboardType: TextInputType.number,
                  readOnly: splitType == 'equal',
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

