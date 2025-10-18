part of 'ai_assistant_sheet.dart';

class _SendMessageIntent extends Intent {
  const _SendMessageIntent();
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.onMicPressed,
    required this.isSending,
    required this.isEnabled,
    required this.isListening,
    this.voiceError,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onMicPressed;
  final bool isSending;
  final bool isEnabled;
  final bool isListening;
  final String? voiceError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final isCompactWidth = viewportWidth < 560;
    final micTooltip = isListening ? 'Stop listening' : 'Voice input';
    final micIcon = isListening ? Icons.stop : Icons.mic_none;
    final micHandler = (!isEnabled || onMicPressed == null)
        ? null
        : onMicPressed;
    final canSend = isEnabled && !isSending;

    final Widget sendButton;
    if (isCompactWidth) {
      sendButton = FilledButton(
        onPressed: canSend ? onSend : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(16),
          minimumSize: const Size.square(48),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
        child: const Icon(Icons.send),
      );
    } else {
      sendButton = FilledButton.icon(
        onPressed: canSend ? onSend : null,
        icon: const Icon(Icons.send),
        label: const Text('Send'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      );
    }

    final row = Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            enabled: isEnabled,
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              hintText: 'Describe what you need help with…',
              filled: true,
              fillColor: onSurface.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) {
              if (canSend) {
                onSend();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: micTooltip,
          onPressed: micHandler,
          icon: Icon(
            micIcon,
            color: isListening ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(width: 8),
        sendButton,
      ],
    );

    final voiceMessage = voiceError;
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.enter):
            const _SendMessageIntent(),
        const SingleActivator(LogicalKeyboardKey.numpadEnter):
            const _SendMessageIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _SendMessageIntent: CallbackAction<_SendMessageIntent>(
            onInvoke: (_) {
              if (canSend) {
                onSend();
              }
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              row,
              if (isListening || (voiceMessage?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    voiceMessage != null
                        ? 'Voice input error: $voiceMessage'
                        : 'Listening… speak naturally and tap send when you\'re ready.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: voiceMessage != null
                          ? theme.colorScheme.error
                          : onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUser = message.isUser;
    final background = isUser
        ? colorScheme.primary.withOpacity(0.85)
        : colorScheme.surface.withOpacity(0.85);
    final textColor = isUser ? colorScheme.onPrimary : colorScheme.onSurface;
    final preview = message.preview;
    final success = message.successNotice;
    final displayText = message.displayText.trim();
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final bubbleMaxWidth = math.min(
      viewportWidth * (isUser ? 0.82 : 0.88),
      isUser ? 420.0 : 480.0,
    );

    MarkdownStyleSheet? markdownStyle;
    if (!isUser) {
      final baseStyle = theme.textTheme.bodyMedium?.copyWith(
        color: textColor,
        height: 1.45,
      );
      markdownStyle = MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: baseStyle,
        strong: baseStyle?.copyWith(fontWeight: FontWeight.w700),
        em: baseStyle?.copyWith(fontStyle: FontStyle.italic),
        h1: theme.textTheme.titleMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
        h2: theme.textTheme.titleSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
        h3: theme.textTheme.bodyLarge?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
        code: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontFamily: 'monospace',
          backgroundColor: background.withOpacity(0.2),
        ),
        blockquoteDecoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: colorScheme.primary.withOpacity(0.45),
              width: 4,
            ),
          ),
        ),
        codeblockDecoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.32),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.18),
          ),
        ),
        listBullet: baseStyle,
        listBulletPadding: const EdgeInsets.only(right: 12),
        tableBody: baseStyle,
        tableHead: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
        tableBorder: TableBorder(
          horizontalInside: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          verticalInside: BorderSide(
            color: colorScheme.outline.withOpacity(0.2),
          ),
          top: BorderSide(color: colorScheme.outline.withOpacity(0.24)),
          bottom: BorderSide(color: colorScheme.outline.withOpacity(0.24)),
        ),
        tableCellsPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        a: baseStyle?.copyWith(
          color: colorScheme.secondary,
          decoration: TextDecoration.underline,
        ),
      );
    }

    final content = <Widget>[];
    if (displayText.isNotEmpty) {
      if (isUser) {
        content.add(
          Text(
            displayText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.4,
            ),
          ),
        );
      } else {
        content.add(
          MarkdownBody(
            data: displayText,
            styleSheet: markdownStyle!,
            softLineBreak: true,
          ),
        );
      }
    }
    if (preview != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 12));
      }
      content.add(_TransactionPreviewCard(preview: preview));
    }
    if (success != null) {
      if (content.isNotEmpty) {
        content.add(const SizedBox(height: 12));
      }
      content.add(_SuccessNoticeCard(notice: success));
    }

    if (content.isEmpty) {
      if (isUser) {
        content.add(
          Text(
            message.rawText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.4,
            ),
          ),
        );
      } else {
        final fallback = markdownStyle == null
            ? Text(
                message.rawText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.4,
                ),
              )
            : MarkdownBody(
                data: message.rawText,
                styleSheet: markdownStyle,
                softLineBreak: true,
              );
        content.add(fallback);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: content,
      ),
    );
  }
}

class _TransactionPreviewCard extends StatelessWidget {
  const _TransactionPreviewCard({required this.preview});

  final _TransactionPreview preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final headerStyle = theme.textTheme.labelLarge?.copyWith(
      color: colorScheme.onSurface,
      fontWeight: FontWeight.w600,
    );
    final cellStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface.withOpacity(0.9),
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.08)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview.title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: {
              for (var i = 0; i < preview.headers.length; i++)
                i: const IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                children: [
                  for (final header in preview.headers)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 8,
                      ),
                      child: Text(header, style: headerStyle),
                    ),
                ],
              ),
              for (final row in preview.rows)
                TableRow(
                  children: [
                    for (final cell in row)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Text(cell, style: cellStyle),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessNoticeCard extends StatelessWidget {
  const _SuccessNoticeCard({required this.notice});

  final _SuccessNotice notice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlight = Colors.green.shade400;

    return Container(
      decoration: BoxDecoration(
        color: highlight.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_rounded, color: highlight, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notice.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (notice.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        notice.subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final entry in notice.transactions) ...[
            _SuccessTransactionRow(entry: entry),
            if (entry != notice.transactions.last)
              Divider(color: highlight.withOpacity(0.3), height: 16),
          ],
        ],
      ),
    );
  }
}

class _SuccessTransactionRow extends StatelessWidget {
  const _SuccessTransactionRow({required this.entry});

  final _RecordedTransaction entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountColor = entry.isIncome
        ? Colors.green.shade400
        : colorScheme.errorContainer.withOpacity(0.9);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.categoryName} • ${entry.walletName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          entry.formattedAmount,
          style: theme.textTheme.titleMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }
}

