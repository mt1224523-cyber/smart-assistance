enum MessageStatus { sending, received, error }

class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final List<String>? imagePaths;

  const Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.received,
    this.imagePaths,
  });

  Message copyWith({
    String? content,
    MessageStatus? status,
  }) {
    return Message(
      id: id,
      content: content ?? this.content,
      isUser: isUser,
      timestamp: timestamp,
      status: status ?? this.status,
      imagePaths: imagePaths,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'imagePaths': imagePaths,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.received,
      ),
      imagePaths: json['imagePaths'] != null
          ? List<String>.from(json['imagePaths'])
          : null,
    );
  }
}
