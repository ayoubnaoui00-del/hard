class ChatMessageModel {
  final dynamic id;
  final dynamic conversationId;
  final String role; // 'user', 'assistant', 'system'
  final String content;
  final DateTime createdAt;

  const ChatMessageModel({
    this.id,
    this.conversationId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'],
      conversationId: json['conversationId'],
      role: json['role'] as String? ?? 'user',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (conversationId != null) 'conversationId': conversationId,
      'role': role,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  ChatMessageModel copyWith({
    dynamic id,
    dynamic conversationId,
    String? role,
    String? content,
    DateTime? createdAt,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatMessageModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          conversationId == other.conversationId &&
          role == other.role &&
          content == other.content;

  @override
  int get hashCode =>
      id.hashCode ^ conversationId.hashCode ^ role.hashCode ^ content.hashCode;
}

class ConversationModel {
  final dynamic id;
  final dynamic userId;
  final String title;
  final String? topic;
  final List<ChatMessageModel> messages;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.topic,
    this.messages = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final messages = rawMessages
        .map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return ConversationModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      title: json['title'] as String? ?? json['topic'] as String? ?? 'New Chat',
      topic: json['topic'] as String?,
      messages: messages,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      if (topic != null) 'topic': topic,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ConversationModel copyWith({
    dynamic id,
    dynamic userId,
    String? title,
    String? topic,
    List<ChatMessageModel>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      topic: topic ?? this.topic,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}
