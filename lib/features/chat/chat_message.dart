import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Papel do remetente na conversa.
enum ChatRole { user, assistant }

/// Mensagem da conversa de chat com o assistente IA.
///
/// Persistida localmente na tabela `chat_messages` (local-only, sem sync).
@freezed
abstract class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String vehicleId,
    required ChatRole role,
    required String content,
    required DateTime createdAt,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
