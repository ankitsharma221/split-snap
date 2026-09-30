import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _bubbleEnabled = true;
  bool _autoSave = true;
  Map<String, bool> _perms = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final sms = await Permission.sms.status;
    final location = await Permission.location.status;
    final contacts = await Permission.contacts.status;
    final notification = await Permission.notification.status;
    setState(() {
      _bubbleEnabled = prefs.getBool('bubble_enabled') ?? true;
      _autoSave = prefs.getBool('auto_save') ?? true;
      _perms = {
        'SMS': sms.isGranted,
        'Location': location.isGranted,
        'Contacts': contacts.isGranted,
        'Notifications': notification.isGranted,
      };
    });
  }

  Future<void> _saveToggle(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        leading: const BackButton(color: Colors.white),
        title: const Text('Settings',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Behaviour ──────────────────────────────────────────────────
          const _SectionHeader('Behaviour'),
          _card(children: [
            SwitchListTile(
              title: const Text('Show floating bubble',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Private bubble when payment detected'),
              value: _bubbleEnabled,
              activeColor: const Color(0xFF4CAF50),
              onChanged: (v) {
                setState(() => _bubbleEnabled = v);
                _saveToggle('bubble_enabled', v);
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Auto-save when bubble ignored',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Saves with location & context after 3 min'),
              value: _autoSave,
              activeColor: const Color(0xFF4CAF50),
              onChanged: (v) {
                setState(() => _autoSave = v);
                _saveToggle('auto_save', v);
              },
            ),
          ]),

          const SizedBox(height: 20),

          // ── Permissions ────────────────────────────────────────────────
          const _SectionHeader('Permissions'),
          _card(
            children: _perms.entries.map((e) {
              return ListTile(
                leading: Text(e.value ? '✅' : '❌',
                    style: const TextStyle(fontSize: 20)),
                title: Text(e.key,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: e.value
                    ? const Text('Granted',
                        style: TextStyle(color: Color(0xFF4CAF50)))
                    : TextButton(
                        onPressed: () async {
                          await openAppSettings();
                          await _loadAll();
                        },
                        child: const Text('Grant',
                            style: TextStyle(color: Colors.red)),
                      ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // ── About ──────────────────────────────────────────────────────
          const _SectionHeader('About'),
          _card(children: [
            const ListTile(
              leading: Text('💸', style: TextStyle(fontSize: 22)),
              title: Text('SplitSnap',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Version 1.0.0'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('All data stored locally'),
              subtitle: Text('No cloud. No account. 100% private.'),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14)),
      child: Column(children: children),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.8)),
    );
  }
}
