import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../common/presentation/moneybase_shell.dart';

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final List<_AiMessage> _messages = <_AiMessage>[];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const int _maxHistoryMessages = 20;
  static final GenerationConfig _generationConfig = GenerationConfig(
    maxOutputTokens: 512,
    temperature: 0.4,
    topP: 0.9,
  );
  static final List<SafetySetting> _safetySettings = <SafetySetting>[
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
    SafetySetting(
      HarmCategory.sexuallyExplicit,
      HarmBlockThreshold.medium,
    ),
    SafetySetting(
      HarmCategory.dangerousContent,
      HarmBlockThreshold.medium,
    ),
  ];
  static final Content _systemInstruction = Content.system(<Part>[
    TextPart(
      "You are MoneyBase's AI budgeting assistant. Provide concise, safe "
      'financial guidance that helps people understand their spending, '
      'budgets, and savings progress using the information they share.',
    ),
  ]);
  late final _AiMessage _welcomeMessage;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  bool _isSending = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _userId;
  static const String _defaultChatId = 'default';
  GenerativeModel? _model;
  ChatSession? _chatSession;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _welcomeMessage = _AiMessage(
      text:
          'Hi there! I\'m Gemini, MoneyBase\'s budgeting copilot. Ask me about your spending, wallets, or goals.',
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(_welcomeMessage);
    unawaited(_initializeAssistant());
  }

  Future<void> _initializeAssistant() async {
    final user = _auth.currentUser;
    _userId = user?.uid;

    final apiKey = _readGeminiApiKey();
    if (user == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Sign in to use the Gemini assistant.';
      });
      return;
    }

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Add GEMINI_API_KEY to your .env file to enable the assistant.';
      });
      return;
    }

    List<_AiMessage> history = <_AiMessage>[];
    try {
      history = await _loadMessageHistory(user.uid);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Failed to load Gemini history: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load previous Gemini messages.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load Gemini history: $error\n$stackTrace');
    }

    if (!mounted) {
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: _systemInstruction,
        generationConfig: _generationConfig,
        safetySettings: _safetySettings,
      );
      _chatSession = _model!.startChat(
        history: history.map((message) => message.toContent()).toList(),
        safetySettings: _safetySettings,
        generationConfig: _generationConfig,
      );
    } on GenerativeAIException catch (error, stackTrace) {
      debugPrint('Failed to initialise Gemini: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Gemini configuration error: ${error.message}. Check your API key and project setup.';
      });
      return;
    } catch (error, stackTrace) {
      debugPrint('Failed to initialise Gemini: $error\n$stackTrace');
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'We could not connect to Gemini right now. Please try again later.';
      });
      return;
    }

    setState(() {
      _messages
        ..clear()
        ..add(_welcomeMessage)
        ..addAll(history);
      _isInitializing = false;
      _errorMessage = null;
    });

    _scrollToBottom();
  }

  Future<List<_AiMessage>> _loadMessageHistory(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(_defaultChatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_maxHistoryMessages)
        .get();

    final docs = querySnapshot.docs.reversed;

    return docs.map((doc) {
      final data = doc.data();
      final text = (data['text'] as String?)?.trim();
      if (text == null || text.isEmpty) {
        return null;
      }

      final isUser = data['isUser'] as bool? ?? false;
      final timestamp = data['timestamp'];
      DateTime resolvedTimestamp;
      if (timestamp is Timestamp) {
        resolvedTimestamp = timestamp.toDate();
      } else if (timestamp is DateTime) {
        resolvedTimestamp = timestamp;
      } else {
        resolvedTimestamp = DateTime.now();
      }

      return _AiMessage(
        text: text,
        isUser: isUser,
        timestamp: resolvedTimestamp,
      );
    }).whereType<_AiMessage>().toList();
  }

  String? _readGeminiApiKey() {
    final envValue = dotenv.env['GEMINI_API_KEY']?.trim();
    if (envValue != null && envValue.isNotEmpty) {
      return envValue;
    }

    const fromEnvironment = String.fromEnvironment('GEMINI_API_KEY');
    if (fromEnvironment.isNotEmpty) {
      return fromEnvironment;
    }

    return null;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    unawaited(_sendMessage());
  }

  Future<void> _sendMessage() async {
    final raw = _messageController.text.trim();
    if (raw.isEmpty || _isSending || _isInitializing) {
      return;
    }

    if (_errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_errorMessage!)),
        );
      }
      return;
    }

    final userId = _userId;
    final chatSession = _chatSession;
    if (userId == null || chatSession == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gemini is still getting ready. Please try again.'),
          ),
        );
      }
      return;
    }

    final userMessage = _AiMessage(
      text: raw,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isSending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    final chatRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(_defaultChatId);

    try {
      await chatRef.set(
        {
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await chatRef.collection('messages').add({
        'text': userMessage.text,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      final response = await chatSession.sendMessage(Content.text(raw));
      final replyText = _extractReplyText(response);

      final aiMessage = _AiMessage(
        text: replyText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(aiMessage);
      });
      _scrollToBottom();

      await chatRef.collection('messages').add({
        'text': aiMessage.text,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } on GenerativeAIException catch (error, stackTrace) {
      debugPrint('Gemini rejected the message: $error\n$stackTrace');
      final fallback = _AiMessage(
        text:
            'Gemini could not process that request. Please double-check your question and try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(fallback);
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gemini error: ${error.message}'),
          ),
        );
      }

      try {
        await chatRef.collection('messages').add({
          'text': fallback.text,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (writeError, writeStackTrace) {
        debugPrint(
            'Failed to record Gemini error message: $writeError\n$writeStackTrace');
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to send Gemini message: $error\n$stackTrace');
      const fallbackText =
          'I had trouble reaching Gemini just now. Please try again in a moment.';
      final fallback = _AiMessage(
        text: fallbackText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _messages.add(fallback);
        });
        _scrollToBottom();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Something went wrong while contacting Gemini. Please try again.'),
          ),
        );
      }

      try {
        await chatRef.collection('messages').add({
          'text': fallback.text,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (writeError, writeStackTrace) {
        debugPrint(
            'Failed to record fallback Gemini message: $writeError\n$writeStackTrace');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _extractReplyText(GenerateContentResponse response) {
    final primaryText = response.text?.trim();
    if (primaryText != null && primaryText.isNotEmpty) {
      return primaryText;
    }

    final buffer = StringBuffer();
    for (final candidate in response.candidates ?? const <GenerateContentCandidate>[]) {
      final content = candidate.content;
      for (final part in content.parts) {
        if (part is TextPart) {
          buffer.write(part.text);
        }
      }
    }

    final fallback = buffer.toString().trim();
    if (fallback.isNotEmpty) {
      return fallback;
    }

    return 'I'm still thinking about that. Could you try asking in a different way?';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final onSurface = colorScheme.onSurface;
    final mutedOnSurface = onSurface.withOpacity(0.72);
    final composerEnabled = !_isInitializing && _errorMessage == null;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: MoneyBaseFrostedPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.smart_toy_outlined, color: onSurface),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini assistant',
                          style: textTheme.titleMedium?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ask about budgets, wallets, or savings goals. Responses run on Firebase-hosted Gemini.',
                          style: textTheme.bodySmall?.copyWith(
                            color: mutedOnSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(Icons.close, color: mutedOnSurface),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isInitializing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            mutedOnSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Connecting to Gemini…',
                          style: textTheme.bodySmall?.copyWith(
                            color: mutedOnSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.error,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final alignment =
                        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
                    return Align(
                      alignment: alignment,
                      child: _MessageBubble(message: message),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              _Composer(
                controller: _messageController,
                onSend: _handleSend,
                isSending: _isSending,
                isEnabled: composerEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isSending,
    required this.isEnabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            enabled: isEnabled,
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
              if (!isSending && isEnabled) {
                onSend();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: (!isEnabled || isSending) ? null : onSend,
          icon: const Icon(Icons.send),
          label: const Text('Send'),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(maxWidth: 420),
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
      child: Text(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: textColor,
          height: 1.4,
        ),
      ),
    );
  }
}

class _AiMessage {
  const _AiMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime timestamp;

  Content toContent() {
    return Content(
      role: isUser ? 'user' : 'model',
      parts: [TextPart(text)],
    );
  }
}
