import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_hub_service.dart';
import '../services/api_service.dart';
import '../services/local_db_service.dart';

final apiServiceProvider = Provider((ref) => ChatApiService());
final localDbServiceProvider = Provider((ref) => LocalDbService());

final hubServiceProvider = Provider<ChatHubService>((ref) {
  final hub = ChatHubService();
  ref.onDispose(() => hub.stop());
  return hub;
});

final hubControllerProvider = NotifierProvider<HubController, bool>(() => HubController());

class HubController extends Notifier<bool> {
  ChatHubService get _hub => ref.read(hubServiceProvider);
  @override bool build() => false;

  Future<void> connect() async { 
    if (state) {
      print('DEBUG HUB: Already connected');
      return;
    }
    print('DEBUG HUB: Connecting...');
    await _hub.start(); 
    state = true;
    print('DEBUG HUB: Connected successfully');
  }
  Future<void> joinConversation(int id) => _hub.joinConversation(id);
  Future<void> leaveConversation(int id) => _hub.leaveConversation(id);
  Future<void> startTyping(int id) => _hub.startTyping(id);
  Future<void> stopTyping(int id) => _hub.stopTyping(id);
  Stream get messageStream => _hub.messageStream;
  Stream get typingStream => _hub.typingStream;
  Stream get stopTypingStream => _hub.stopTypingStream;
  Stream get messageReactionStream => _hub.messageReactionStream;
}

final currentOpenConversationIdProvider = StateProvider<int?>((_) => null);
