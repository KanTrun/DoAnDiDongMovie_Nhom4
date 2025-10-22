import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import '../models/conversation.dart';
import '../state/contacts_provider.dart';
import '../state/chat_providers.dart';

class NewConversationSheet extends ConsumerStatefulWidget {
  const NewConversationSheet({super.key});

  @override
  ConsumerState<NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends ConsumerState<NewConversationSheet> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _searchCtrl = TextEditingController();
  final _groupNameCtrl = TextEditingController();
  final _selected = <String>{}; // userIds được chọn cho group

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // nạp danh bạ
    ref.read(contactsProvider.notifier).load();
    _searchCtrl.addListener(() {
      ref.read(contactsProvider.notifier).load(query: _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    _groupNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create1on1(Contact c) async {
    try {
      final api = ref.read(apiServiceProvider);
      final conv = await api.createConversation(isGroup: false, participantIds: [c.id]);
      if (mounted) Navigator.pop(context, conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo chat: $e')));
      }
    }
  }

  Future<void> _createGroup() async {
    if (_selected.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chọn ít nhất 2 thành viên')));
      return;
    }
    final name = _groupNameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nhập tên nhóm')));
      return;
    }
    try {
      final api = ref.read(apiServiceProvider);
      final conv = await api.createConversation(
        isGroup: true,
        title: name,
        participantIds: _selected.toList(),
      );
      if (mounted) Navigator.pop(context, conv);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tạo nhóm: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(contactsProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * .85,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 8),
            const Text('New conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search contacts'),
              ),
            ),
            const SizedBox(height: 6),
            TabBar(controller: _tab, tabs: const [Tab(text: 'New Chat'), Tab(text: 'New Group')]),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  // --- Tab 1: New Chat ---
                  contactsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Lỗi: $e')),
                    data: (list) => ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = list[i];
                        return ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text(c.userName),
                          subtitle: Text(c.email),
                          onTap: () => _create1on1(c),
                        );
                      },
                    ),
                  ),

                  // --- Tab 2: New Group ---
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TextField(
                          controller: _groupNameCtrl,
                          decoration: const InputDecoration(prefixIcon: Icon(Icons.title), hintText: 'Group name'),
                        ),
                      ),
                      Expanded(
                        child: contactsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(child: Text('Lỗi: $e')),
                          data: (list) => ListView.separated(
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final c = list[i];
                              final chosen = _selected.contains(c.id);
                              return CheckboxListTile(
                                value: chosen,
                                title: Text(c.userName),
                                subtitle: Text(c.email),
                                onChanged: (_) {
                                  setState(() {
                                    chosen ? _selected.remove(c.id) : _selected.add(c.id);
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.group_add),
                            label: const Text('Create group'),
                            onPressed: _createGroup,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
