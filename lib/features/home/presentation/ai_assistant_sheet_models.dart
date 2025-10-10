part of 'ai_assistant_sheet.dart';

class _AssistantChatThread {
  _AssistantChatThread({
    required this.id,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastMessagePreview,
    this.autoTitle = true,
  }) : title = title,
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String? title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastMessagePreview;
  final bool autoTitle;

  String get displayTitle =>
      (title?.trim().isNotEmpty ?? false) ? title!.trim() : 'Conversation';

  _AssistantChatThread copyWith({
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastMessagePreview,
    bool? autoTitle,
  }) {
    return _AssistantChatThread(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      autoTitle: autoTitle ?? this.autoTitle,
    );
  }
}

class _AiMessage {
  const _AiMessage({
    required this.rawText,
    required this.displayText,
    required this.isUser,
    required this.timestamp,
    this.preview,
    this.successNotice,
  });

  final String rawText;
  final String displayText;
  final bool isUser;
  final DateTime timestamp;
  final _TransactionPreview? preview;
  final _SuccessNotice? successNotice;

  Content toContent() {
    return Content(isUser ? 'user' : 'model', [TextPart(rawText)]);
  }
}

class _ParsedAssistantMessage {
  const _ParsedAssistantMessage({required this.displayText, this.preview});

  final String displayText;
  final _TransactionPreview? preview;
}

class _TransactionPreview {
  const _TransactionPreview({
    required this.headers,
    required this.rows,
    required this.title,
  });

  final List<String> headers;
  final List<List<String>> rows;
  final String title;
}

class _SuccessNotice {
  const _SuccessNotice({
    required this.title,
    this.subtitle,
    required this.transactions,
  });

  final String title;
  final String? subtitle;
  final List<_RecordedTransaction> transactions;
}

class _RecordedTransaction {
  const _RecordedTransaction({
    required this.description,
    required this.amount,
    required this.currencyCode,
    required this.isIncome,
    required this.walletName,
    required this.categoryName,
    required this.dateLabel,
    required this.formattedAmount,
  });

  final String description;
  final double amount;
  final String currencyCode;
  final bool isIncome;
  final String walletName;
  final String categoryName;
  final String dateLabel;
  final String formattedAmount;
}
