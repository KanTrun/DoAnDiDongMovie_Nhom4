import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact.dart';
import 'chat_providers.dart';

final contactsProvider = StateNotifierProvider<ContactsNotifier, AsyncValue<List<Contact>>>(
  (ref) => ContactsNotifier(ref),
);

class ContactsNotifier extends StateNotifier<AsyncValue<List<Contact>>> {
  final Ref ref;
  String _lastQuery = '';
  ContactsNotifier(this.ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load({String query = ''}) async {
    try {
      _lastQuery = query;
      final api = ref.read(apiServiceProvider);
      final list = await api.getContacts(filter: query.isEmpty ? null : query);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load(query: _lastQuery);
}
