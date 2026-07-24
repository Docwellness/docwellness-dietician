// AI_EXECUTION_PLAN.md Phase 8, P8-02 - chat message deduplication.
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/models/chat_model.dart';

ChatModel _msg({required String id, String? clientMessageId}) {
  return ChatModel(
    id: id,
    senderId: 'dietician-1',
    receiverId: 'patient-1',
    message: 'hi',
    messageType: 'text',
    isRead: false,
    conversationId: 'conv-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    senderRole: 'dietician',
    receiverRole: 'patient',
    isMe: true,
    clientMessageId: clientMessageId,
  );
}

void main() {
  group('ChatModel.isDuplicate', () {
    test('same id is a duplicate', () {
      final existing = [_msg(id: 'server-1')];
      expect(ChatModel.isDuplicate(existing, _msg(id: 'server-1')), isTrue);
    });

    test('different id, no clientMessageId match, is not a duplicate', () {
      final existing = [_msg(id: 'server-1')];
      expect(ChatModel.isDuplicate(existing, _msg(id: 'server-2')), isFalse);
    });

    test(
      'matches an optimistic entry by clientMessageId before the REST '
      'response has replaced its temp id with the real server id - the '
      'dietician is joined to the conversation room, so their own '
      'just-sent message can be echoed back via the socket first',
      () {
        final optimistic = _msg(id: 'temp-123', clientMessageId: 'temp-123');
        final socketEcho = _msg(id: 'server-99', clientMessageId: 'temp-123');
        expect(ChatModel.isDuplicate([optimistic], socketEcho), isTrue);
      },
    );

    test('empty message list has no duplicates', () {
      expect(ChatModel.isDuplicate([], _msg(id: 'a')), isFalse);
    });
  });
}
