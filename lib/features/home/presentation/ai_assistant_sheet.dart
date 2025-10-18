import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/models/budget.dart';
import '../../../core/models/category.dart';
import '../../../core/models/shopping_item.dart';
import '../../../core/models/shopping_list.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/budget_repository.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/shopping_list_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
import '../../../app/theme/theme.dart';
import '../../common/presentation/moneybase_shell.dart';

part 'ai_assistant_sheet_tools.dart';
part 'ai_assistant_sheet_models.dart';
part 'ai_assistant_sheet_widgets.dart';

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final List<_AiMessage> _messages = <_AiMessage>[];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final _AiMessage _welcomeMessage;
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  bool _isSending = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _userId;
  static const String _defaultChatId = 'default';
  static const Duration _contextTtl = Duration(minutes: 5);
  GenerativeModel? _model;
  ChatSession? _chatSession;
  String? _cachedContextText;
  DateTime? _contextFetchedAt;
  late final TransactionRepository _transactionRepository;
  late final WalletRepository _walletRepository;
  late final CategoryRepository _categoryRepository;
  late final BudgetRepository _budgetRepository;
  late final ShoppingListRepository _shoppingListRepository;
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;
  String? _voiceError;
  List<Wallet> _knownWallets = <Wallet>[];
  List<Category> _knownCategories = <Category>[];
  List<Budget> _knownBudgets = <Budget>[];
  List<ShoppingList> _knownShoppingLists = <ShoppingList>[];
  final Map<String, List<ShoppingItem>> _knownShoppingItems =
      <String, List<ShoppingItem>>{};
  List<MoneyBaseTransaction> _knownTransactions = <MoneyBaseTransaction>[];
  List<_AssistantChatThread> _chatThreads = <_AssistantChatThread>[];
  String? _activeChatId;
  bool _isLoadingMessages = false;
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _transactionRepository = TransactionRepository(firestore: _firestore);
    _walletRepository = WalletRepository(firestore: _firestore);
    _categoryRepository = CategoryRepository(firestore: _firestore);
    _budgetRepository = BudgetRepository(firestore: _firestore);
    _shoppingListRepository = ShoppingListRepository(firestore: _firestore);
    const welcomeText =
        'Hi there! I\'m MoneyBase Assistant, your budgeting copilot. Ask me about tracking spending, wallets, or goals.';
    _welcomeMessage = _AiMessage(
      rawText: welcomeText,
      displayText: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(_welcomeMessage);
    unawaited(_initializeAssistant());
  }

  Future<void> _initializeAssistant() async {
    final user = _auth.currentUser;
    _userId = user?.uid;

    final apiKey = _readAssistantApiKey();
    if (user == null) {
      setState(() {
        _isInitializing = false;
        _errorMessage = 'Sign in to use MoneyBase Assistant.';
      });
      return;
    }

    if (apiKey == null || apiKey.isEmpty) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Add GEMINI_API_KEY to your .env file to enable MoneyBase Assistant.';
      });
      return;
    }

    List<_AssistantChatThread> threads = <_AssistantChatThread>[];

    try {
      _model = GenerativeModel(
        model: 'models/gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: _systemInstruction,
        generationConfig: _generationConfig,
        safetySettings: _safetySettings,
        tools: _assistantTools,
        toolConfig: _assistantToolConfig,
      );
    } on GenerativeAIException catch (error, stackTrace) {
      debugPrint(
        'Failed to initialise MoneyBase Assistant: $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'MoneyBase Assistant configuration error: ${error.message}. Check your API key and project setup.';
      });
      return;
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to initialise MoneyBase Assistant: $error\n$stackTrace',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'We could not connect to MoneyBase Assistant right now. Please try again later.';
      });
      return;
    }

    try {
      threads = await _loadChatThreads(user.uid);
      if (threads.isEmpty) {
        final fallbackThread = await _ensureDefaultChat(user.uid);
        threads = <_AssistantChatThread>[fallbackThread];
      }
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant chats: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load MoneyBase Assistant chats.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant chats: $error\n$stackTrace',
      );
    }

    if (!mounted) {
      return;
    }

    final initialChatId = threads.isNotEmpty
        ? threads.first.id
        : _defaultChatId;

    setState(() {
      _chatThreads = threads;
      _activeChatId = initialChatId;
    });

    await _loadChat(initialChatId, showLoadingIndicator: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  Future<List<_AssistantChatThread>> _loadChatThreads(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .limit(25)
        .get();

    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is DateTime) {
        return value;
      }
      if (value is num) {
        final milliseconds = value > 1e12
            ? value.toInt()
            : (value * 1000).toInt();
        return DateTime.fromMillisecondsSinceEpoch(milliseconds);
      }
      return DateTime.now();
    }

    final threads = snapshot.docs.map((doc) {
      final data = doc.data();
      return _AssistantChatThread(
        id: doc.id,
        title: (data['title'] as String?)?.trim(),
        createdAt: parseTimestamp(data['createdAt']),
        updatedAt: parseTimestamp(data['updatedAt']),
        lastMessagePreview: (data['lastMessagePreview'] as String?)?.trim(),
        autoTitle: data['autoTitle'] as bool? ?? true,
      );
    }).toList();

    threads.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return threads;
  }

  Future<_AssistantChatThread> _ensureDefaultChat(String userId) async {
    final chatRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(_defaultChatId);

    final snapshot = await chatRef.get();
    if (!snapshot.exists) {
      await chatRef.set({
        'title': 'MoneyBase chat',
        'autoTitle': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      final now = DateTime.now();
      return _AssistantChatThread(
        id: chatRef.id,
        title: 'MoneyBase chat',
        createdAt: now,
        updatedAt: now,
        autoTitle: true,
      );
    }

    final data = snapshot.data() ?? <String, dynamic>{};
    DateTime parseTimestamp(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return _AssistantChatThread(
      id: snapshot.id,
      title: (data['title'] as String?)?.trim(),
      createdAt: parseTimestamp(data['createdAt']),
      updatedAt: parseTimestamp(data['updatedAt']),
      lastMessagePreview: (data['lastMessagePreview'] as String?)?.trim(),
      autoTitle: data['autoTitle'] as bool? ?? true,
    );
  }

  Future<void> _loadChat(
    String chatId, {
    bool showLoadingIndicator = true,
  }) async {
    final userId = _userId;
    final model = _model;
    if (userId == null || model == null) {
      return;
    }

    if (showLoadingIndicator) {
      if (mounted) {
        setState(() {
          _isLoadingMessages = true;
        });
      } else {
        _isLoadingMessages = true;
      }
    } else {
      _isLoadingMessages = true;
    }

    List<_AiMessage> history = <_AiMessage>[];
    try {
      history = await _loadMessageHistory(userId, chatId);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant history: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load previous MoneyBase Assistant messages.',
            ),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant history: $error\n$stackTrace',
      );
    }

    if (!mounted) {
      return;
    }

    try {
      final session = model.startChat(
        history: history.map((message) => message.toContent()).toList(),
        safetySettings: _safetySettings,
        generationConfig: _generationConfig,
      );
      setState(() {
        _chatSession = session;
        _activeChatId = chatId;
        _messages
          ..clear()
          ..add(_welcomeMessage)
          ..addAll(history);
        _isLoadingMessages = false;
        _errorMessage = null;
      });
      _scrollToBottom();
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to initialise MoneyBase Assistant chat: $error\n$stackTrace',
      );
      setState(() {
        _chatSession = null;
        _messages
          ..clear()
          ..add(_welcomeMessage);
        _isLoadingMessages = false;
        _errorMessage =
            'We could not load this conversation. Please try again shortly.';
      });
    }
  }

  _AssistantChatThread? _chatThreadById(String id) {
    for (final thread in _chatThreads) {
      if (thread.id == id) {
        return thread;
      }
    }
    return null;
  }

  void _upsertChatThread(_AssistantChatThread thread) {
    final updated = List<_AssistantChatThread>.from(_chatThreads);
    final index = updated.indexWhere((entry) => entry.id == thread.id);
    if (index >= 0) {
      updated[index] = thread;
    } else {
      updated.add(thread);
    }
    updated.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (mounted) {
      setState(() {
        _chatThreads = updated;
      });
    } else {
      _chatThreads = updated;
    }
  }

  String _truncatePreview(String value, {int maxLength = 80}) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    if (trimmed.length <= maxLength) {
      return trimmed;
    }
    return '${trimmed.substring(0, maxLength).trim()}…';
  }

  String _deriveChatTitle(String rawText) {
    final preview = _truncatePreview(rawText, maxLength: 48);
    if (preview.isEmpty) {
      return 'Conversation';
    }
    return preview;
  }

  void _touchChatThread({
    required String chatId,
    String? title,
    String? preview,
    DateTime? updatedAt,
    bool? autoTitle,
  }) {
    final existing = _chatThreadById(chatId);
    final now = updatedAt ?? DateTime.now();
    final next = (existing ?? _AssistantChatThread(id: chatId)).copyWith(
      title: title ?? existing?.title,
      lastMessagePreview: preview ?? existing?.lastMessagePreview,
      updatedAt: now,
      createdAt: existing?.createdAt ?? now,
      autoTitle: autoTitle ?? existing?.autoTitle ?? true,
    );
    _upsertChatThread(next);
  }

  Future<_AssistantChatThread> _createChatThread(String userId) async {
    final chatsRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chats');
    final doc = chatsRef.doc();
    final now = DateTime.now();
    const defaultTitle = 'New chat';
    await doc.set({
      'title': defaultTitle,
      'autoTitle': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessagePreview': '',
    });
    return _AssistantChatThread(
      id: doc.id,
      title: defaultTitle,
      createdAt: now,
      updatedAt: now,
      autoTitle: true,
    );
  }

  Future<void> _handleCreateChat() async {
    final userId = _userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to create a MoneyBase Assistant chat.'),
          ),
        );
      }
      return;
    }

    _AssistantChatThread? pendingEmptyThread;
    for (final thread in _chatThreads) {
      if (thread.id == _defaultChatId) {
        continue;
      }
      final preview = thread.lastMessagePreview;
      if (preview == null || preview.trim().isEmpty) {
        pendingEmptyThread = thread;
        break;
      }
    }

    if (pendingEmptyThread != null) {
      final bool activeHasConversation =
          pendingEmptyThread.id == _activeChatId &&
              _messages.any(
                (message) => !identical(message, _welcomeMessage),
              );

      if (!activeHasConversation) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Finish your current chat before starting a new one.',
              ),
            ),
          );
        }
        return;
      }
    }

    try {
      final thread = await _createChatThread(userId);
      _upsertChatThread(thread);
      await _loadChat(thread.id);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to create MoneyBase Assistant chat: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create a new chat. Please try again.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to create MoneyBase Assistant chat: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to create a new chat. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteChat(String chatId) async {
    final userId = _userId;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign in to manage MoneyBase Assistant chats.'),
          ),
        );
      }
      return;
    }

    final wasActive = chatId == _activeChatId;
    final chatRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId);

    try {
      const batchSize = 100;
      while (true) {
        final snapshot = await chatRef.collection('messages').limit(batchSize).get();
        if (snapshot.docs.isEmpty) {
          break;
        }
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      await chatRef.delete();
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to delete MoneyBase Assistant chat: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete chat. Please try again.'),
          ),
        );
      }
      return;
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to delete MoneyBase Assistant chat: $error\n$stackTrace',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to delete chat. Please try again.'),
          ),
        );
      }
      return;
    }

    final remainingThreads = _chatThreads
        .where((thread) => thread.id != chatId)
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (mounted) {
      setState(() {
        _chatThreads = remainingThreads;
      });
    } else {
      _chatThreads = remainingThreads;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted.')),
      );
    }

    if (!wasActive) {
      return;
    }

    if (remainingThreads.isNotEmpty) {
      unawaited(_loadChat(remainingThreads.first.id));
      return;
    }

    if (mounted) {
      setState(() {
        _activeChatId = null;
        _chatSession = null;
        _messages
          ..clear()
          ..add(_welcomeMessage);
        _isLoadingMessages = false;
        _errorMessage = null;
      });
    } else {
      _activeChatId = null;
      _chatSession = null;
      _messages
        ..clear()
        ..add(_welcomeMessage);
      _isLoadingMessages = false;
      _errorMessage = null;
    }
  }

  void _handleSelectChat(String? chatId) {
    if (chatId == null || chatId == _activeChatId || _isLoadingMessages) {
      return;
    }
    unawaited(_loadChat(chatId));
  }

  Future<List<_AiMessage>> _loadMessageHistory(
    String userId,
    String chatId,
  ) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_maxHistoryMessages)
        .get();

    final docs = querySnapshot.docs.reversed;

    return docs
        .map((doc) {
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

          if (isUser) {
            return _AiMessage(
              rawText: text,
              displayText: text,
              isUser: true,
              timestamp: resolvedTimestamp,
            );
          }

          final parsed = _parseAssistantMessage(text);
          return _AiMessage(
            rawText: text,
            displayText: parsed.displayText.isNotEmpty
                ? parsed.displayText
                : text,
            isUser: false,
            timestamp: resolvedTimestamp,
            preview: parsed.preview,
          );
        })
        .whereType<_AiMessage>()
        .toList();
  }

  String? _readAssistantApiKey() {
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
    unawaited(_speechToText.stop());
    _speechToText.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    unawaited(_sendMessage());
  }

  void _handleVoiceInput() {
    unawaited(_toggleVoiceInput());
  }

  Future<void> _toggleVoiceInput() async {
    if (!mounted) {
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    if (!_speechInitialized) {
      try {
        _speechInitialized = await _speechToText.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to initialise speech recognition: $error\n$stackTrace',
        );
        _speechInitialized = false;
      }

      if (!_speechInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Voice input is unavailable. Check your microphone permissions.',
            ),
          ),
        );
        return;
      }
    }

    try {
      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenMode: ListenMode.dictation,
        localeId: Localizations.localeOf(context).toLanguageTag(),
      );
      if (mounted) {
        setState(() {
          _isListening = true;
          _voiceError = null;
        });
      } else {
        _isListening = true;
        _voiceError = null;
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to start voice input: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Voice input error: $error')));
      }
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) {
      return;
    }
    try {
      await _speechToText.stop();
    } catch (error, stackTrace) {
      debugPrint('Failed to stop voice input: $error\n$stackTrace');
    }
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    } else {
      _isListening = false;
    }
  }

  void _onSpeechStatus(String status) {
    if (status.toLowerCase() == 'notlistening') {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      } else {
        _isListening = false;
      }
    }
  }

  void _onSpeechError(SpeechRecognitionError error) {
    debugPrint(
      'Voice input error: ${error.errorMsg} (permanent: ${error.permanent})',
    );
    if (mounted) {
      setState(() {
        _isListening = false;
        _voiceError = error.errorMsg;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice input error: ${error.errorMsg}')),
      );
    } else {
      _isListening = false;
      _voiceError = error.errorMsg;
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final transcript = result.recognizedWords.trim();
    if (transcript.isEmpty) {
      return;
    }

    final existing = _messageController.text.trim();
    final combined = existing.isEmpty ? transcript : '$existing $transcript';
    _messageController
      ..text = combined
      ..selection = TextSelection.collapsed(offset: combined.length);

    if (mounted) {
      setState(() {
        _voiceError = null;
      });
    } else {
      _voiceError = null;
    }

    if (result.finalResult) {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      } else {
        _isListening = false;
      }
    }
  }

  Future<void> _sendMessage() async {
    await _stopListening();
    final raw = _messageController.text.trim();
    if (raw.isEmpty || _isSending || _isInitializing || _isLoadingMessages) {
      return;
    }

    if (_errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
      return;
    }

    final userId = _userId;
    final chatSession = _chatSession;
    final chatId = _activeChatId ?? _defaultChatId;
    if (userId == null || chatSession == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'MoneyBase Assistant is still getting ready. Please try again.',
            ),
          ),
        );
      }
      return;
    }

    final userMessage = _AiMessage(
      rawText: raw,
      displayText: raw,
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
        .doc(chatId);

    try {
      final thread = _chatThreadById(chatId);
      final userPreview = _truncatePreview(userMessage.rawText);
      final metadata = <String, Object?>{
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': userPreview,
      };
      if (thread == null) {
        metadata['createdAt'] = FieldValue.serverTimestamp();
      }
      final shouldUpdateTitle =
          thread == null || thread.autoTitle || (thread.title?.isEmpty ?? true);
      if (shouldUpdateTitle) {
        metadata['title'] = _deriveChatTitle(userMessage.rawText);
        metadata['autoTitle'] = true;
      }

      await chatRef.set(metadata, SetOptions(merge: true));

      _touchChatThread(
        chatId: chatId,
        title: shouldUpdateTitle
            ? _deriveChatTitle(userMessage.rawText)
            : thread?.title,
        preview: userPreview,
        autoTitle: shouldUpdateTitle ? true : thread?.autoTitle,
      );

      await chatRef.collection('messages').add({
        'text': userMessage.rawText,
        'isUser': true,
        'timestamp': FieldValue.serverTimestamp(),
      });

      String? contextSnapshot;
      try {
        contextSnapshot = await _loadUserContext(userId);
      } catch (error, stackTrace) {
        debugPrint(
          'Failed to prepare MoneyBase Assistant context: $error\n$stackTrace',
        );
      }

      final prompt = _buildPrompt(raw, contextSnapshot);

      var response = await chatSession.sendMessage(Content.text(prompt));
      response = await _resolveFunctionCalls(response);
      final replyText = _extractReplyText(response);

      final parsed = _parseAssistantMessage(replyText);
      final aiMessage = _AiMessage(
        rawText: replyText,
        displayText: parsed.displayText.isNotEmpty
            ? parsed.displayText
            : replyText,
        isUser: false,
        timestamp: DateTime.now(),
        preview: parsed.preview,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _messages.add(aiMessage);
      });
      _scrollToBottom();

      final aiPreview = _truncatePreview(aiMessage.displayText);

      await chatRef.collection('messages').add({
        'text': aiMessage.rawText,
        'isUser': false,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await chatRef.set({
        'updatedAt': FieldValue.serverTimestamp(),
        'lastMessagePreview': aiPreview,
      }, SetOptions(merge: true));

      _touchChatThread(chatId: chatId, preview: aiPreview);
    } on GenerativeAIException catch (error, stackTrace) {
      debugPrint(
        'MoneyBase Assistant rejected the message: $error\n$stackTrace',
      );
      const fallbackText =
          'MoneyBase Assistant could not process that request. Please double-check your question and try again.';
      final fallback = _AiMessage(
        rawText: fallbackText,
        displayText: fallbackText,
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
            content: Text('MoneyBase Assistant error: ${error.message}'),
          ),
        );
      }

      try {
        await chatRef.collection('messages').add({
          'text': fallback.rawText,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await chatRef.set({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessagePreview': _truncatePreview(fallback.displayText),
        }, SetOptions(merge: true));
        _touchChatThread(
          chatId: chatId,
          preview: _truncatePreview(fallback.displayText),
        );
      } catch (writeError, writeStackTrace) {
        debugPrint(
          'Failed to record MoneyBase Assistant error message: $writeError\n$writeStackTrace',
        );
      }
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to send MoneyBase Assistant message: $error\n$stackTrace',
      );
      const fallbackText =
          'I had trouble reaching MoneyBase Assistant just now. Please try again in a moment.';
      final fallback = _AiMessage(
        rawText: fallbackText,
        displayText: fallbackText,
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
            content: Text(
              'Something went wrong while contacting MoneyBase Assistant. Please try again.',
            ),
          ),
        );
      }

      try {
        await chatRef.collection('messages').add({
          'text': fallback.rawText,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
        await chatRef.set({
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessagePreview': _truncatePreview(fallback.displayText),
        }, SetOptions(merge: true));
        _touchChatThread(
          chatId: chatId,
          preview: _truncatePreview(fallback.displayText),
        );
      } catch (writeError, writeStackTrace) {
        debugPrint(
          'Failed to record fallback MoneyBase Assistant message: $writeError\n$writeStackTrace',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  String _buildPrompt(String userMessage, String? context) {
    if (context == null || context.trim().isEmpty) {
      return userMessage;
    }

    final buffer = StringBuffer()
      ..writeln(userMessage)
      ..writeln()
      ..writeln('---')
      ..writeln('MoneyBase data snapshot:')
      ..writeln(context.trim())
      ..writeln()
      ..writeln(
        'Use the snapshot for context and let the user know when data is missing or uncertain.',
      );

    return buffer.toString();
  }

  Future<String?> _loadUserContext(String userId) async {
    final cached = _cachedContextText;
    final lastFetched = _contextFetchedAt;
    if (cached != null &&
        lastFetched != null &&
        DateTime.now().difference(lastFetched) < _contextTtl) {
      return cached;
    }

    try {
      final userRef = _firestore.collection('users').doc(userId);
      final categoriesFuture = userRef.collection('categories').limit(50).get();
      final walletsFuture = userRef.collection('wallets').limit(25).get();
      final transactionsFuture = userRef
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(20)
          .get();
      final budgetsFuture = userRef
          .collection('budgets')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .get();
      final shoppingListsFuture = userRef
          .collection('shopping_lists')
          .orderBy('createdAt', descending: false)
          .limit(10)
          .get();

      final categoriesSnapshot = await categoriesFuture;
      final walletsSnapshot = await walletsFuture;
      final transactionsSnapshot = await transactionsFuture;
      final budgetsSnapshot = await budgetsFuture;
      final shoppingListsSnapshot = await shoppingListsFuture;

      final categories =
          categoriesSnapshot.docs
              .map(
                (doc) => Category.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList()
            ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
            );

      final wallets =
          walletsSnapshot.docs
              .map(
                (doc) => Wallet.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList()
            ..sort((a, b) {
              final positionComparison = a.position.compareTo(b.position);
              if (positionComparison != 0) {
                return positionComparison;
              }
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });

      final transactions = transactionsSnapshot.docs
          .map(
            (doc) => MoneyBaseTransaction.fromJson({
              ...doc.data(),
              'id': doc.id,
              'userId': userId,
            }),
          )
          .toList();
      final budgets =
          budgetsSnapshot.docs
              .map(
                (doc) => Budget.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList()
            ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final shoppingLists =
          shoppingListsSnapshot.docs
              .map(
                (doc) => ShoppingList.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                }),
              )
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final shoppingItems = <String, List<ShoppingItem>>{};
      final listsForItems = shoppingLists.length > 5
          ? shoppingLists.sublist(0, 5)
          : shoppingLists;
      await Future.wait(
        listsForItems.map((list) async {
          final snapshot = await userRef
              .collection('shopping_lists')
              .doc(list.id)
              .collection('shopping_items')
              .orderBy('createdAt', descending: false)
              .limit(25)
              .get();
          shoppingItems[list.id] = snapshot.docs
              .map(
                (doc) => ShoppingItem.fromJson({
                  ...doc.data(),
                  'id': doc.id,
                  'userId': userId,
                  'listId': list.id,
                }),
              )
              .toList();
        }),
      );

      _knownWallets = wallets;
      _knownCategories = categories;
      _knownBudgets = budgets;
      _knownShoppingLists = shoppingLists;
      _knownTransactions = transactions;
      _knownShoppingItems
        ..clear()
        ..addEntries(
          shoppingItems.entries.map(
            (entry) => MapEntry(
              entry.key,
              List<ShoppingItem>.unmodifiable(entry.value),
            ),
          ),
        );

      final userDoc = await userRef.get();
      final rawDefaultWalletId = userDoc.data()?['defaultWalletId'];
      final defaultWalletId =
          rawDefaultWalletId is String && rawDefaultWalletId.isNotEmpty
          ? rawDefaultWalletId
          : null;
      _defaultWalletId = defaultWalletId;

      String formatName(String value, String fallback) {
        final trimmed = value.trim();
        return trimmed.isEmpty ? fallback : trimmed;
      }

      final categoryNames = <String, String>{};
      for (final category in categories) {
        categoryNames[category.id] = formatName(category.name, 'Uncategorised');
      }

      final walletNames = <String, String>{};
      for (final wallet in wallets) {
        walletNames[wallet.id] = formatName(wallet.name, 'Unassigned wallet');
      }

      final buffer = StringBuffer();

      if (wallets.isEmpty) {
        buffer.writeln('No wallets recorded yet.');
      } else {
        buffer.writeln('Wallets (${wallets.length} total):');
        final walletsToShow = wallets.length > 8
            ? wallets.sublist(0, 8)
            : wallets;
        for (final wallet in walletsToShow) {
          final currency = formatName(wallet.currencyCode.toUpperCase(), 'USD');
          buffer.writeln(
            '- ${walletNames[wallet.id]} • balance ${wallet.balance.toStringAsFixed(2)} $currency • type ${wallet.type.name}',
          );
        }
        if (wallets.length > walletsToShow.length) {
          buffer.writeln(
            '- ...${wallets.length - walletsToShow.length} more wallets not listed.',
          );
        }
        if (defaultWalletId != null) {
          final defaultName =
              walletNames[defaultWalletId] ??
              formatName(defaultWalletId, 'Wallet');
          buffer.writeln('Default wallet: $defaultName ($defaultWalletId).');
        } else {
          buffer.writeln('No default wallet set.');
        }
        final walletCatalog = wallets
            .map(
              (wallet) => {
                'id': wallet.id,
                'name': walletNames[wallet.id] ?? wallet.name,
                'currencyCode': wallet.currencyCode,
                'type': wallet.type.name,
                'isDefault': wallet.id == defaultWalletId,
              },
            )
            .toList(growable: false);
        buffer.writeln('Wallet catalog JSON: ${jsonEncode(walletCatalog)}');
      }

      if (categories.isEmpty) {
        buffer.writeln('No categories configured.');
      } else {
        final categoryNamesList = categories
            .map((category) => categoryNames[category.id]!)
            .toList(growable: false);
        final sampleSize = categoryNamesList.length > 12
            ? 12
            : categoryNamesList.length;
        final sampled = categoryNamesList.take(sampleSize).join(', ');
        buffer.writeln(
          'Categories (${categories.length} total): '
          '$sampled${categoryNamesList.length > sampleSize ? ', …' : ''}.',
        );
        final categoryCatalog = categories
            .map(
              (category) => {
                'id': category.id,
                'name': categoryNames[category.id] ?? category.name,
                'parentCategoryId': category.parentCategoryId,
              },
            )
            .toList(growable: false);
        buffer.writeln('Category catalog JSON: ${jsonEncode(categoryCatalog)}');
      }

      if (transactions.isEmpty) {
        buffer.writeln('No transactions recorded yet.');
      } else {
        final incomeTotals = <String, double>{};
        final expenseTotals = <String, double>{};
        var incomeCount = 0;
        var expenseCount = 0;

        for (final transaction in transactions) {
          final currency = formatName(
            transaction.currencyCode.toUpperCase(),
            'USD',
          );
          if (transaction.isIncome) {
            incomeCount += 1;
            incomeTotals.update(
              currency,
              (value) => value + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          } else {
            expenseCount += 1;
            expenseTotals.update(
              currency,
              (value) => value + transaction.amount,
              ifAbsent: () => transaction.amount,
            );
          }
        }

        buffer.writeln('Recent transactions (newest first):');
        final transactionsToShow = transactions.length > 12
            ? transactions.sublist(0, 12)
            : transactions;
        for (final transaction in transactionsToShow) {
          final date = transaction.date.toIso8601String().split('T').first;
          final flowLabel = transaction.isIncome ? 'income' : 'expense';
          final amount = transaction.amount.toStringAsFixed(2);
          final currency = formatName(
            transaction.currencyCode.toUpperCase(),
            'USD',
          );
          final description = formatName(
            transaction.description,
            'No description',
          );
          final categoryName =
              categoryNames[transaction.categoryId] ?? 'Uncategorised';
          final walletName =
              walletNames[transaction.walletId] ?? 'Unassigned wallet';
          buffer.writeln(
            '- $date • $flowLabel • $currency $amount • $description '
            '• category: $categoryName • wallet: $walletName',
          );
        }
        if (transactions.length > transactionsToShow.length) {
          buffer.writeln(
            '- ...${transactions.length - transactionsToShow.length} more '
            'historical transactions not listed.',
          );
        }

        String describeTotals(Map<String, double> totals) {
          if (totals.isEmpty) {
            return '0';
          }
          return totals.entries
              .map((entry) => '${entry.value.toStringAsFixed(2)} ${entry.key}')
              .join(', ');
        }

        buffer.writeln(
          'Summary: $incomeCount income (${describeTotals(incomeTotals)}) and '
          '$expenseCount expense (${describeTotals(expenseTotals)}). Values '
          "use each entry's currency and may mix different currencies.",
        );
      }

      if (budgets.isEmpty) {
        buffer.writeln('No budgets configured yet.');
      } else {
        buffer.writeln('Budgets (${budgets.length} total):');
        final budgetsToShow = budgets.length > 8
            ? budgets.sublist(0, 8)
            : budgets;
        for (final budget in budgetsToShow) {
          final name = budget.name.trim().isEmpty
              ? 'Budget'
              : budget.name.trim();
          final limit = budget.limit.toStringAsFixed(2);
          final currency = budget.currencyCode.isEmpty
              ? 'USD'
              : budget.currencyCode;
          final categoriesLabel = budget.categoryIds.isEmpty
              ? 'all categories'
              : budget.categoryIds
                    .map(
                      (id) =>
                          categoryNames[id] ?? 'Category ${id.substring(0, 4)}',
                    )
                    .join(', ');
          buffer.writeln(
            '- $name • limit $limit $currency • period ${budget.period.name} • flow ${budget.flowType.name} • categories: $categoriesLabel',
          );
        }
        if (budgets.length > budgetsToShow.length) {
          buffer.writeln(
            '- ...${budgets.length - budgetsToShow.length} more budgets not listed.',
          );
        }
        final budgetCatalog = budgets
            .map(
              (budget) => {
                'id': budget.id,
                'name': budget.name,
                'currencyCode': budget.currencyCode,
                'limit': budget.limit,
                'period': budget.period.name,
                'flowType': budget.flowType.name,
                'categoryIds': budget.categoryIds,
                'notes': budget.notes,
                'startDate': budget.startDate?.toIso8601String(),
                'endDate': budget.endDate?.toIso8601String(),
              },
            )
            .toList(growable: false);
        buffer.writeln('Budget catalog JSON: ${jsonEncode(budgetCatalog)}');
      }

      if (shoppingLists.isEmpty) {
        buffer.writeln('No shopping lists recorded yet.');
      } else {
        buffer.writeln('Shopping lists (${shoppingLists.length} total):');
        final listsToShow = shoppingLists.length > 6
            ? shoppingLists.sublist(0, 6)
            : shoppingLists;
        for (final list in listsToShow) {
          final title = list.name.trim().isEmpty
              ? 'Shopping list'
              : list.name.trim();
          final items = shoppingItems[list.id] ?? const <ShoppingItem>[];
          final boughtCount = items.where((item) => item.bought).length;
          buffer.writeln(
            '- $title • type ${list.type.name} • currency ${list.currency} • ${items.length} items ($boughtCount bought)',
          );
          if (items.isNotEmpty) {
            final previewItems = items.length > 3 ? items.sublist(0, 3) : items;
            for (final item in previewItems) {
              buffer.writeln(
                '  • ${item.title} • priority ${item.priority.name} • bought ${item.bought ? 'yes' : 'no'}',
              );
            }
            if (items.length > previewItems.length) {
              buffer.writeln(
                '  • ...${items.length - previewItems.length} more items',
              );
            }
          }
        }
        if (shoppingLists.length > listsToShow.length) {
          buffer.writeln(
            '- ...${shoppingLists.length - listsToShow.length} more shopping lists not listed.',
          );
        }
        final shoppingCatalog = shoppingLists
            .map(
              (list) => {
                'id': list.id,
                'name': list.name,
                'type': list.type.name,
                'currency': list.currency,
                'notes': list.notes,
                'items': (shoppingItems[list.id] ?? const <ShoppingItem>[])
                    .map(
                      (item) => {
                        'id': item.id,
                        'title': item.title,
                        'priority': item.priority.name,
                        'bought': item.bought,
                        'price': item.price,
                        'currency': item.currency,
                        'purchaseDate': item.purchaseDate?.toIso8601String(),
                        'expiryDate': item.expiryDate?.toIso8601String(),
                      },
                    )
                    .toList(growable: false),
              },
            )
            .toList(growable: false);
        buffer.writeln('Shopping catalog JSON: ${jsonEncode(shoppingCatalog)}');
      }

      final context = buffer.toString().trim();
      _cachedContextText = context.isEmpty ? null : context;
      _contextFetchedAt = DateTime.now();
      return _cachedContextText;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant context: $error\n$stackTrace',
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to load MoneyBase Assistant context: $error\n$stackTrace',
      );
    }

    return cached;
  }

  String _extractReplyText(GenerateContentResponse response) {
    final primaryText = response.text?.trim();
    if (primaryText != null && primaryText.isNotEmpty) {
      return primaryText;
    }

    final buffer = StringBuffer();
    for (final candidate in response.candidates) {
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

    return "I'm still thinking about that. Could you try asking in a different way?";
  }

  _ParsedAssistantMessage _parseAssistantMessage(String rawText) {
    final match = RegExp(
      r'((?:^\|.*\|\s*\n?){2,})',
      multiLine: true,
    ).firstMatch(rawText);
    if (match == null) {
      return _ParsedAssistantMessage(displayText: rawText.trim());
    }

    final tableBlock = rawText.substring(match.start, match.end);
    final preview = _tryParsePreview(tableBlock);
    if (preview == null) {
      return _ParsedAssistantMessage(displayText: rawText.trim());
    }

    final before = rawText.substring(0, match.start);
    final after = rawText.substring(match.end);
    final combined = ('$before$after')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    final fallback = before.trim().isNotEmpty ? before.trim() : preview.title;
    final display = combined.isNotEmpty ? combined : fallback;

    return _ParsedAssistantMessage(displayText: display, preview: preview);
  }

  _TransactionPreview? _tryParsePreview(String tableText) {
    final lines = tableText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.startsWith('|'))
        .toList();
    if (lines.length < 2) {
      return null;
    }

    final headers = _parseTableRow(lines.first);
    if (headers.isEmpty) {
      return null;
    }

    final rows = <List<String>>[];
    for (var index = 1; index < lines.length; index += 1) {
      final cells = _parseTableRow(lines[index]);
      final separator = cells.every(
        (cell) => cell.replaceAll(RegExp(r'[-\s]'), '').isEmpty,
      );
      if (separator) {
        continue;
      }
      if (cells.length != headers.length) {
        if (cells.length < headers.length) {
          cells.addAll(List.filled(headers.length - cells.length, ''));
        } else {
          cells.removeRange(headers.length, cells.length);
        }
      }
      rows.add(cells);
    }

    if (rows.isEmpty) {
      return null;
    }

    return _TransactionPreview(
      headers: headers,
      rows: rows,
      title: 'Transactions to add',
    );
  }

  List<String> _parseTableRow(String line) {
    final cells = line.split('|').map((cell) => cell.trim()).toList();
    if (cells.isNotEmpty && cells.first.isEmpty) {
      cells.removeAt(0);
    }
    if (cells.isNotEmpty && cells.last.isEmpty) {
      cells.removeLast();
    }
    return cells;
  }

  Future<GenerateContentResponse> _resolveFunctionCalls(
    GenerateContentResponse initialResponse,
  ) async {
    final chatSession = _chatSession;
    if (chatSession == null) {
      return initialResponse;
    }

    var response = initialResponse;
    var guard = 0;

    while (response.functionCalls.isNotEmpty && guard < 10) {
      guard += 1;
      final calls = response.functionCalls.toList(growable: false);
      final responses = <FunctionResponse>[];

      for (final call in calls) {
        Map<String, Object?> payload;
        try {
          payload = await _executeFunctionCall(call);
        } catch (error, stackTrace) {
          debugPrint(
            'MoneyBase Assistant action ${call.name} failed: $error\n$stackTrace',
          );
          payload = {'success': false, 'error': error.toString()};
        }
        responses.add(FunctionResponse(call.name, payload));
      }

      response = await chatSession.sendMessage(
        Content.functionResponses(responses),
      );
    }

    return response;
  }

  Future<Map<String, Object?>> _executeFunctionCall(FunctionCall call) async {
    final args = call.args;
    switch (call.name) {
      case 'add_transaction':
        return _handleAddTransactionCall(args);
      case 'update_transaction':
        return _handleUpdateTransactionCall(args);
      case 'create_wallet':
        return _handleCreateWalletCall(args);
      case 'update_wallet':
        return _handleUpdateWalletCall(args);
      case 'create_category':
        return _handleCreateCategoryCall(args);
      case 'update_category':
        return _handleUpdateCategoryCall(args);
      case 'set_default_wallet':
        return _handleSetDefaultWalletCall(args);
      case 'create_budget':
        return _handleCreateBudgetCall(args);
      case 'update_budget':
        return _handleUpdateBudgetCall(args);
      case 'create_shopping_list':
        return _handleCreateShoppingListCall(args);
      case 'update_shopping_list':
        return _handleUpdateShoppingListCall(args);
      case 'create_shopping_item':
        return _handleCreateShoppingItemCall(args);
      case 'update_shopping_item':
        return _handleUpdateShoppingItemCall(args);
      case 'get_data_snapshot':
        return _handleGetDataSnapshotCall(args);
      default:
        throw StateError('Unknown MoneyBase Assistant action: ${call.name}');
    }
  }

  Future<Map<String, Object?>> _handleAddTransactionCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    final rawTransactions = args['transactions'] ?? args['transaction'];
    final List transactionsArg;
    if (rawTransactions is List) {
      transactionsArg = rawTransactions;
    } else if (rawTransactions is Map<String, Object?>) {
      transactionsArg = [rawTransactions];
    } else {
      throw FormatException('transactions must be provided as an array.');
    }

    final created = <Map<String, Object?>>[];
    final noticeEntries = <_RecordedTransaction>[];
    for (final entry in transactionsArg) {
      if (entry is! Map<String, Object?>) {
        continue;
      }

      final rawAmount = _parseNumber(entry['amount']);
      if (rawAmount == null || rawAmount == 0) {
        throw FormatException('Each transaction requires a non-zero amount.');
      }
      final isIncome = _determineIsIncome(entry, rawAmount);
      final amount = rawAmount.abs();
      final currencyCode = _normalizeCurrency(
        _parseString(
          entry['currencyCode'] ?? entry['currency'] ?? entry['currency_code'],
        ),
      );
      final date = _parseDate(
        entry['date'] ?? entry['datetime'] ?? entry['timestamp'],
      );
      final description =
          _parseString(
            entry['description'] ?? entry['title'] ?? entry['name'],
          ) ??
          'MoneyBase transaction';
      final note = _parseString(
        entry['note'] ?? entry['notes'] ?? entry['memo'],
      );
      final combinedDescription = note == null || note.isEmpty
          ? description
          : '$description — $note';

      final walletId = await _resolveWalletId(
        entry,
        currencyCode: currencyCode,
      );
      final categoryId = await _resolveCategoryId(entry);

      final transaction = MoneyBaseTransaction(
        amount: amount,
        currencyCode: currencyCode,
        description: combinedDescription,
        isIncome: isIncome,
        categoryId: categoryId,
        walletId: walletId,
        date: date,
        createdAt: DateTime.now(),
      );

      final saved = await _transactionRepository.addTransaction(
        userId,
        transaction,
      );
      created.add(_transactionSummary(saved));
      noticeEntries.add(_toRecordedTransaction(saved));
      _knownTransactions = <MoneyBaseTransaction>[
        ..._knownTransactions.where((existing) => existing.id != saved.id),
        saved,
      ];
    }

    _cachedContextText = null;

    if (noticeEntries.isNotEmpty) {
      _emitSuccessNotice(noticeEntries);
    }

    return {'success': true, 'created': created};
  }

  Future<Map<String, Object?>> _handleUpdateTransactionCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    final transactionId = _parseString(args['transactionId']);
    if (transactionId == null) {
      throw FormatException('transactionId is required.');
    }

    var transaction = await _getTransactionById(transactionId);
    if (transaction == null) {
      throw StateError('Transaction $transactionId was not found.');
    }

    final amountOverride = _parseNumber(args['amount']);
    if (amountOverride != null && amountOverride == 0) {
      throw FormatException('Transaction amount must be non-zero.');
    }

    final currency = _normalizeCurrency(
      _parseString(args['currencyCode']),
      fallback: transaction.currencyCode,
    );

    final note = _parseString(args['note']);
    var description =
        _parseString(args['description']) ?? transaction.description;
    if (note != null && note.isNotEmpty) {
      description = '$description — $note';
    }

    final rawAmount = amountOverride ?? transaction.amount;
    final resolvedAmount = rawAmount.abs();

    var resolvedIsIncome = transaction.isIncome;
    if (args.containsKey('isIncome') || args.containsKey('flow')) {
      final signedAmount =
          amountOverride ??
          (transaction.isIncome ? transaction.amount : -transaction.amount);
      resolvedIsIncome = _determineIsIncome(
        args,
        signedAmount == 0 ? rawAmount : signedAmount,
      );
    }

    DateTime resolvedDate = transaction.date;
    final dateInput = args['date'];
    if (dateInput != null) {
      resolvedDate = _parseDate(dateInput);
    }

    String resolvedWalletId = transaction.walletId;
    if (args.containsKey('walletId') ||
        args.containsKey('walletName') ||
        args['wallet'] is Map<String, Object?>) {
      resolvedWalletId = await _resolveWalletId(args, currencyCode: currency);
    }

    String resolvedCategoryId = transaction.categoryId;
    if (args.containsKey('categoryId') ||
        args.containsKey('categoryName') ||
        args['category'] is Map<String, Object?>) {
      resolvedCategoryId = await _resolveCategoryId(args);
    }

    transaction = transaction.copyWith(
      amount: resolvedAmount,
      currencyCode: currency,
      description: description,
      isIncome: resolvedIsIncome,
      date: resolvedDate,
      walletId: resolvedWalletId,
      categoryId: resolvedCategoryId,
    );

    await _transactionRepository.updateTransaction(userId, transaction);

    _knownTransactions = <MoneyBaseTransaction>[
      ..._knownTransactions.where((existing) => existing.id != transaction?.id),
      transaction,
    ];

    _cachedContextText = null;

    return {'success': true, 'transaction': _transactionSummary(transaction)};
  }

  Future<Map<String, Object?>> _handleCreateWalletCall(
    Map<String, Object?> args,
  ) async {
    final name = _parseString(args['name'] ?? args['walletName']);
    final currency = _normalizeCurrency(
      _parseString(
        args['currencyCode'] ?? args['currency'] ?? args['currency_code'],
      ),
    );
    if (name == null) {
      throw FormatException('Wallet name is required.');
    }

    final wallet = await _createWalletInternal(
      name: name,
      currencyCode: currency,
      typeName: _parseString(args['type']),
      initialBalance: _parseNumber(
        args['initialBalance'] ?? args['balance'] ?? args['startingBalance'],
      ),
      setAsDefault:
          args['setAsDefault'] as bool? ??
          args['makeDefault'] as bool? ??
          false,
    );

    return {'success': true, 'wallet': _walletSummary(wallet)};
  }

  Future<Map<String, Object?>> _handleUpdateWalletCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    Wallet? wallet;
    final walletId = _parseString(args['walletId']);
    if (walletId != null) {
      wallet = await _getWalletById(walletId);
    }

    final walletName = _parseString(args['walletName'] ?? args['name']);
    if (wallet == null && walletName != null) {
      wallet = _findWalletByName(walletName);
    }

    if (wallet == null) {
      throw StateError('Wallet to update was not found.');
    }

    final updated = wallet.copyWith(
      name: _parseString(args['name']) ?? wallet.name,
      currencyCode: _normalizeCurrency(
        _parseString(args['currencyCode']),
        fallback: wallet.currencyCode,
      ),
      balance: _parseNumber(args['balance']) ?? wallet.balance,
      color: _parseString(args['color']) ?? wallet.color,
      iconName: _parseString(args['iconName']) ?? wallet.iconName,
      type: args.containsKey('type')
          ? _parseWalletType(_parseString(args['type']), fallback: wallet.type)
          : wallet.type,
    );

    await _walletRepository.updateWallet(userId, updated);

    _knownWallets = <Wallet>[
      ..._knownWallets.where((existing) => existing.id != updated.id),
      updated,
    ];

    _cachedContextText = null;

    return {'success': true, 'wallet': _walletSummary(updated)};
  }

  Future<Map<String, Object?>> _handleCreateCategoryCall(
    Map<String, Object?> args,
  ) async {
    final name = _parseString(args['name'] ?? args['categoryName']);
    if (name == null) {
      throw FormatException('Category name is required.');
    }

    final category = await _createCategoryInternal(
      name: name,
      parentCategoryId: _parseString(
        args['parentCategoryId'] ?? args['parentId'],
      ),
      iconName: _parseString(args['iconName']),
      color: _parseString(args['color']),
    );

    return {'success': true, 'category': _categorySummary(category)};
  }

  Future<Map<String, Object?>> _handleUpdateCategoryCall(
    Map<String, Object?> args,
  ) async {
    final categoryId = _parseString(args['categoryId']);
    final categoryName = _parseString(args['name']);
    Category? category;
    if (categoryId != null) {
      category = _findCategoryById(categoryId);
    }
    if (category == null && categoryName != null) {
      category = _findCategoryByName(categoryName);
    }

    if (category == null) {
      throw StateError('Category to update was not found.');
    }

    final updated = category.copyWith(
      name: categoryName ?? category.name,
      parentCategoryId:
          _parseString(args['parentCategoryId'] ?? args['parentId']) ??
          category.parentCategoryId,
      iconName: _parseString(args['iconName']) ?? category.iconName,
      color: _parseString(args['color']) ?? category.color,
    );

    await _categoryRepository.updateCategory(_requireUserId(), updated);

    _knownCategories = <Category>[
      ..._knownCategories.where((existing) => existing.id != updated.id),
      updated,
    ];

    _cachedContextText = null;

    return {'success': true, 'category': _categorySummary(updated)};
  }

  Future<Map<String, Object?>> _handleSetDefaultWalletCall(
    Map<String, Object?> args,
  ) async {
    final walletId = _parseString(args['walletId']);
    if (walletId == null) {
      throw FormatException('walletId is required.');
    }

    final wallet = _findWalletById(walletId);
    if (wallet == null) {
      throw StateError('Wallet $walletId was not found.');
    }

    await _setDefaultWalletInternal(wallet.id);
    _cachedContextText = null;

    return {'success': true, 'wallet': _walletSummary(wallet)};
  }

  Future<Map<String, Object?>> _handleCreateBudgetCall(
    Map<String, Object?> args,
  ) async {
    final name = _parseString(args['name']);
    if (name == null) {
      throw FormatException('Budget name is required.');
    }

    final limit = _parseNumber(args['limit']);
    if (limit == null || limit <= 0) {
      throw FormatException('Budget limit must be a positive number.');
    }

    final budget = Budget(
      name: name,
      limit: limit,
      currencyCode: _normalizeCurrency(_parseString(args['currencyCode'])),
      notes: _parseString(args['notes']),
      period: _parseBudgetPeriod(_parseString(args['period'])),
      flowType: _parseBudgetFlowType(_parseString(args['flowType'])),
      startDate: _parseOptionalDate(args['startDate']),
      endDate: _parseOptionalDate(args['endDate']),
      categoryIds: await _resolveBudgetCategoryIds(args),
    );

    final created = await _budgetRepository.addBudget(_requireUserId(), budget);
    _knownBudgets = <Budget>[
      ..._knownBudgets.where((existing) => existing.id != created.id),
      created,
    ];
    _cachedContextText = null;

    return {'success': true, 'budget': _budgetSummary(created)};
  }

  Future<Map<String, Object?>> _handleUpdateBudgetCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    Budget? budget;
    final budgetId = _parseString(args['budgetId']);
    if (budgetId != null) {
      budget = await _getBudgetById(budgetId);
    }

    final budgetName = _parseString(args['name']);
    if (budget == null && budgetName != null) {
      budget = _findBudgetByName(budgetName);
    }

    if (budget == null) {
      throw StateError('Budget to update was not found.');
    }

    List<String>? categoryIds;
    final hasCategoryArgs =
        args.containsKey('categoryIds') ||
        args.containsKey('categoryNames') ||
        args.containsKey('categories');
    if (hasCategoryArgs) {
      categoryIds = await _resolveBudgetCategoryIds(args);
    }

    final updated = budget.copyWith(
      name: budgetName ?? budget.name,
      currencyCode: _normalizeCurrency(
        _parseString(args['currencyCode']),
        fallback: budget.currencyCode,
      ),
      limit: _parseNumber(args['limit']) ?? budget.limit,
      notes: _parseString(args['notes']) ?? budget.notes,
      period: args.containsKey('period')
          ? _parseBudgetPeriod(
              _parseString(args['period']),
              fallback: budget.period,
            )
          : budget.period,
      flowType: args.containsKey('flowType')
          ? _parseBudgetFlowType(
              _parseString(args['flowType']),
              fallback: budget.flowType,
            )
          : budget.flowType,
      startDate: args.containsKey('startDate')
          ? _parseOptionalDate(args['startDate'])
          : budget.startDate,
      endDate: args.containsKey('endDate')
          ? _parseOptionalDate(args['endDate'])
          : budget.endDate,
      categoryIds: categoryIds ?? budget.categoryIds,
    );

    await _budgetRepository.updateBudget(userId, updated);

    _knownBudgets = <Budget>[
      ..._knownBudgets.where((existing) => existing.id != updated.id),
      updated,
    ];

    _cachedContextText = null;

    return {'success': true, 'budget': _budgetSummary(updated)};
  }

  Future<Wallet> _createWalletInternal({
    required String name,
    required String currencyCode,
    String? typeName,
    double? initialBalance,
    bool setAsDefault = false,
  }) async {
    final userId = _requireUserId();
    final resolvedType = WalletType.values.firstWhere(
      (value) => value.name.toLowerCase() == (typeName?.toLowerCase() ?? ''),
      orElse: () => WalletType.physical,
    );

    final wallet = Wallet(
      name: name,
      currencyCode: currencyCode,
      type: resolvedType,
      balance: initialBalance ?? 0,
    );

    final created = await _walletRepository.addWallet(userId, wallet);
    _knownWallets = <Wallet>[
      ..._knownWallets.where((existing) => existing.id != created.id),
      created,
    ];
    if (setAsDefault) {
      await _setDefaultWalletInternal(created.id);
    }
    _cachedContextText = null;
    return created;
  }

  Future<Category> _createCategoryInternal({
    required String name,
    String? parentCategoryId,
    String? iconName,
    String? color,
  }) async {
    final userId = _requireUserId();
    final category = Category(
      name: name,
      parentCategoryId: parentCategoryId,
      iconName: iconName ?? '',
      color: color ?? '',
    );

    final created = await _categoryRepository.addCategory(userId, category);
    _knownCategories = <Category>[
      ..._knownCategories.where((existing) => existing.id != created.id),
      created,
    ];
    _cachedContextText = null;
    return created;
  }

  Future<void> _setDefaultWalletInternal(String walletId) async {
    final userId = _requireUserId();
    await _firestore.collection('users').doc(userId).set({
      'defaultWalletId': walletId,
    }, SetOptions(merge: true));
    _defaultWalletId = walletId;
  }

  Future<Map<String, Object?>> _handleCreateShoppingListCall(
    Map<String, Object?> args,
  ) async {
    final name = _parseString(args['name']);
    if (name == null) {
      throw FormatException('Shopping list name is required.');
    }

    final list = ShoppingList(
      name: name,
      type: _parseShoppingListType(_parseString(args['type'])),
      notes: _parseString(args['notes']),
      currency: _normalizeCurrency(
        _parseString(args['currency']),
        fallback: 'USD',
      ),
    );

    final created = await _shoppingListRepository.addShoppingList(
      _requireUserId(),
      list,
    );

    _knownShoppingLists = <ShoppingList>[
      ..._knownShoppingLists.where((existing) => existing.id != created.id),
      created,
    ];
    _knownShoppingItems.putIfAbsent(created.id, () => const <ShoppingItem>[]);
    _cachedContextText = null;

    return {'success': true, 'shoppingList': _shoppingListSummary(created)};
  }

  Future<Map<String, Object?>> _handleUpdateShoppingListCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    ShoppingList? list;
    final listId = _parseString(args['listId']);
    if (listId != null) {
      list = await _getShoppingListById(listId);
    }

    final listName = _parseString(args['name']);
    if (list == null && listName != null) {
      list = _findShoppingListByName(listName);
    }

    if (list == null) {
      throw StateError('Shopping list to update was not found.');
    }

    final updated = list.copyWith(
      name: listName ?? list.name,
      type: args.containsKey('type')
          ? _parseShoppingListType(
              _parseString(args['type']),
              fallback: list.type,
            )
          : list.type,
      notes: _parseString(args['notes']) ?? list.notes,
      currency: _normalizeCurrency(
        _parseString(args['currency']),
        fallback: list.currency,
      ),
    );

    await _shoppingListRepository.updateShoppingList(userId, updated);

    _knownShoppingLists = <ShoppingList>[
      ..._knownShoppingLists.where((existing) => existing.id != updated.id),
      updated,
    ];

    _cachedContextText = null;

    return {
      'success': true,
      'shoppingList': _shoppingListSummary(
        updated,
        items: _knownShoppingItems[updated.id] ?? const <ShoppingItem>[],
      ),
    };
  }

  Future<Map<String, Object?>> _handleCreateShoppingItemCall(
    Map<String, Object?> args,
  ) async {
    final title = _parseString(args['title']);
    if (title == null) {
      throw FormatException('Shopping item title is required.');
    }

    final listId = await _resolveShoppingListId(args);
    final list = await _getShoppingListById(listId);
    if (list == null) {
      throw StateError('Shopping list $listId was not found.');
    }

    final item = ShoppingItem(
      title: title,
      price: _parseNumber(args['price']) ?? 0,
      currency: _normalizeCurrency(
        _parseString(args['currency']),
        fallback: list.currency,
      ),
      priority: _parseShoppingItemPriority(_parseString(args['priority'])),
      bought: args['bought'] as bool? ?? false,
      purchaseDate: _parseOptionalDate(args['purchaseDate']),
      expiryDate: _parseOptionalDate(args['expiryDate']),
      iconEmoji: _parseString(args['iconEmoji']),
      iconUrl: _parseString(args['iconUrl']),
    );

    final created = await _shoppingListRepository.addItem(
      _requireUserId(),
      listId,
      item,
    );

    final updatedItems =
        List<ShoppingItem>.from(
            _knownShoppingItems[listId] ?? const <ShoppingItem>[],
          )
          ..removeWhere((existing) => existing.id == created.id)
          ..add(created);
    updatedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _knownShoppingItems[listId] = List<ShoppingItem>.unmodifiable(updatedItems);

    _cachedContextText = null;

    return {
      'success': true,
      'shoppingItem': _shoppingItemSummary(created),
      'shoppingList': _shoppingListSummary(
        list,
        items: _knownShoppingItems[listId] ?? const <ShoppingItem>[],
      ),
    };
  }

  Future<Map<String, Object?>> _handleUpdateShoppingItemCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    final itemId = _parseString(args['itemId']);
    if (itemId == null) {
      throw FormatException('itemId is required.');
    }

    String? listId = _parseString(args['listId']);
    if (listId == null) {
      final listName = _parseString(args['listName']);
      if (listName != null) {
        listId = _findShoppingListByName(listName)?.id;
      }
    }

    if (listId == null) {
      for (final entry in _knownShoppingItems.entries) {
        if (entry.value.any((item) => item.id == itemId)) {
          listId = entry.key;
          break;
        }
      }
    }

    if (listId == null) {
      throw StateError('Shopping item to update was not found.');
    }

    final list = await _getShoppingListById(listId);
    if (list == null) {
      throw StateError('Shopping list $listId was not found.');
    }

    final existingItem = await _getShoppingItemById(listId, itemId);
    if (existingItem == null) {
      throw StateError('Shopping item $itemId was not found.');
    }

    final updatedItem = existingItem.copyWith(
      title: _parseString(args['title']) ?? existingItem.title,
      price: _parseNumber(args['price']) ?? existingItem.price,
      currency: _normalizeCurrency(
        _parseString(args['currency']),
        fallback: existingItem.currency,
      ),
      priority: args.containsKey('priority')
          ? _parseShoppingItemPriority(
              _parseString(args['priority']),
              fallback: existingItem.priority,
            )
          : existingItem.priority,
      bought: args['bought'] as bool? ?? existingItem.bought,
      purchaseDate: args.containsKey('purchaseDate')
          ? _parseOptionalDate(args['purchaseDate'])
          : existingItem.purchaseDate,
      expiryDate: args.containsKey('expiryDate')
          ? _parseOptionalDate(args['expiryDate'])
          : existingItem.expiryDate,
      iconEmoji: _parseString(args['iconEmoji']) ?? existingItem.iconEmoji,
      iconUrl: _parseString(args['iconUrl']) ?? existingItem.iconUrl,
    );

    await _shoppingListRepository.updateItem(userId, listId, updatedItem);

    final updatedItems =
        List<ShoppingItem>.from(
            _knownShoppingItems[listId] ?? const <ShoppingItem>[],
          )
          ..removeWhere((existing) => existing.id == updatedItem.id)
          ..add(updatedItem);
    updatedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _knownShoppingItems[listId] = List<ShoppingItem>.unmodifiable(updatedItems);

    _cachedContextText = null;

    return {
      'success': true,
      'shoppingItem': _shoppingItemSummary(updatedItem),
      'shoppingList': _shoppingListSummary(
        list,
        items: _knownShoppingItems[listId] ?? const <ShoppingItem>[],
      ),
    };
  }

  Future<Map<String, Object?>> _handleGetDataSnapshotCall(
    Map<String, Object?> args,
  ) async {
    final userId = _requireUserId();
    try {
      await _loadUserContext(userId);
    } catch (error, stackTrace) {
      debugPrint(
        'Failed to refresh MoneyBase Assistant snapshot: $error\n$stackTrace',
      );
    }

    final includeTransactions = args['includeTransactions'] as bool? ?? true;

    final snapshot = <String, Object?>{
      'defaultWalletId': _defaultWalletId,
      'wallets': _knownWallets.map(_walletSummary).toList(growable: false),
      'categories': _knownCategories
          .map(_categorySummary)
          .toList(growable: false),
      'budgets': _knownBudgets.map(_budgetSummary).toList(growable: false),
      'shoppingLists': _knownShoppingLists
          .map(
            (list) => _shoppingListSummary(
              list,
              items: _knownShoppingItems[list.id] ?? const <ShoppingItem>[],
            ),
          )
          .toList(growable: false),
    };

    if (includeTransactions) {
      snapshot['transactions'] = _knownTransactions
          .map(_transactionSummary)
          .toList(growable: false);
    }

    return {'success': true, 'snapshot': snapshot};
  }

  String _requireUserId() {
    final id = _userId;
    if (id == null || id.isEmpty) {
      throw StateError('User must be signed in to use MoneyBase Assistant.');
    }
    return id;
  }

  Wallet? _findWalletById(String id) {
    for (final wallet in _knownWallets) {
      if (wallet.id == id) {
        return wallet;
      }
    }
    return null;
  }

  Wallet? _findWalletByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final wallet in _knownWallets) {
      if (wallet.name.trim().toLowerCase() == lower) {
        return wallet;
      }
    }
    return null;
  }

  Category? _findCategoryById(String id) {
    for (final category in _knownCategories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  Category? _findCategoryByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final category in _knownCategories) {
      if (category.name.trim().toLowerCase() == lower) {
        return category;
      }
    }
    return null;
  }

  MoneyBaseTransaction? _findTransactionById(String id) {
    for (final transaction in _knownTransactions) {
      if (transaction.id == id) {
        return transaction;
      }
    }
    return null;
  }

  Budget? _findBudgetById(String id) {
    for (final budget in _knownBudgets) {
      if (budget.id == id) {
        return budget;
      }
    }
    return null;
  }

  Budget? _findBudgetByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final budget in _knownBudgets) {
      if (budget.name.trim().toLowerCase() == lower) {
        return budget;
      }
    }
    return null;
  }

  ShoppingList? _findShoppingListById(String id) {
    for (final list in _knownShoppingLists) {
      if (list.id == id) {
        return list;
      }
    }
    return null;
  }

  ShoppingList? _findShoppingListByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final list in _knownShoppingLists) {
      if (list.name.trim().toLowerCase() == lower) {
        return list;
      }
    }
    return null;
  }

  ShoppingItem? _findShoppingItem(String listId, String itemId) {
    final items = _knownShoppingItems[listId];
    if (items == null) {
      return null;
    }
    for (final item in items) {
      if (item.id == itemId) {
        return item;
      }
    }
    return null;
  }

  Future<MoneyBaseTransaction?> _getTransactionById(String id) async {
    final cached = _findTransactionById(id);
    if (cached != null) {
      return cached;
    }

    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final transaction = MoneyBaseTransaction.fromJson({
      ...data,
      'id': snapshot.id,
      'userId': userId,
    });
    _knownTransactions = <MoneyBaseTransaction>[
      ..._knownTransactions.where((existing) => existing.id != transaction.id),
      transaction,
    ];
    return transaction;
  }

  Future<Budget?> _getBudgetById(String id) async {
    final cached = _findBudgetById(id);
    if (cached != null) {
      return cached;
    }

    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(id)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final budget = Budget.fromJson({
      ...data,
      'id': snapshot.id,
      'userId': userId,
    });
    _knownBudgets = <Budget>[
      ..._knownBudgets.where((existing) => existing.id != budget.id),
      budget,
    ];
    return budget;
  }

  Future<Wallet?> _getWalletById(String id) async {
    final cached = _findWalletById(id);
    if (cached != null) {
      return cached;
    }

    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(id)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final wallet = Wallet.fromJson({
      ...data,
      'id': snapshot.id,
      'userId': userId,
    });
    _knownWallets = <Wallet>[
      ..._knownWallets.where((existing) => existing.id != wallet.id),
      wallet,
    ];
    return wallet;
  }

  Future<ShoppingList?> _getShoppingListById(String id) async {
    final cached = _findShoppingListById(id);
    if (cached != null) {
      return cached;
    }

    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc(id)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final list = ShoppingList.fromJson({
      ...data,
      'id': snapshot.id,
      'userId': userId,
    });
    _knownShoppingLists = <ShoppingList>[
      ..._knownShoppingLists.where((existing) => existing.id != list.id),
      list,
    ];
    return list;
  }

  Future<ShoppingItem?> _getShoppingItemById(
    String listId,
    String itemId,
  ) async {
    final cached = _findShoppingItem(listId, itemId);
    if (cached != null) {
      return cached;
    }

    final userId = _requireUserId();
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('shopping_lists')
        .doc(listId)
        .collection('shopping_items')
        .doc(itemId)
        .get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    final item = ShoppingItem.fromJson({
      ...data,
      'id': snapshot.id,
      'userId': userId,
      'listId': listId,
    });
    final updatedItems =
        List<ShoppingItem>.from(
            _knownShoppingItems[listId] ?? const <ShoppingItem>[],
          )
          ..removeWhere((existing) => existing.id == item.id)
          ..add(item);
    updatedItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _knownShoppingItems[listId] = List<ShoppingItem>.unmodifiable(updatedItems);
    return item;
  }

  String? _parseString(Object? value) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return trimmed;
    }
    return null;
  }

  double? _parseNumber(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  DateTime _parseDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is num) {
      final milliseconds = value > 1e12
          ? value.toInt()
          : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: false);
    }
    return DateTime.now();
  }

  DateTime? _parseOptionalDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    if (value is num) {
      final milliseconds = value > 1e12
          ? value.toInt()
          : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: false);
    }
    return null;
  }

  List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value
          .map(_parseString)
          .whereType<String>()
          .toList(growable: false);
    }
    return const <String>[];
  }

  BudgetPeriod _parseBudgetPeriod(
    String? value, {
    BudgetPeriod fallback = BudgetPeriod.month,
  }) {
    if (value == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    return BudgetPeriod.values.firstWhere(
      (period) => period.name.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }

  BudgetFlowType _parseBudgetFlowType(
    String? value, {
    BudgetFlowType fallback = BudgetFlowType.expenses,
  }) {
    if (value == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    return BudgetFlowType.values.firstWhere(
      (type) => type.name.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }

  ShoppingListType _parseShoppingListType(
    String? value, {
    ShoppingListType fallback = ShoppingListType.grocery,
  }) {
    if (value == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    return ShoppingListType.values.firstWhere(
      (type) => type.name.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }

  ShoppingItemPriority _parseShoppingItemPriority(
    String? value, {
    ShoppingItemPriority fallback = ShoppingItemPriority.medium,
  }) {
    if (value == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    return ShoppingItemPriority.values.firstWhere(
      (priority) => priority.name.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }

  WalletType _parseWalletType(
    String? value, {
    WalletType fallback = WalletType.physical,
  }) {
    if (value == null) {
      return fallback;
    }
    final lower = value.toLowerCase();
    return WalletType.values.firstWhere(
      (type) => type.name.toLowerCase() == lower,
      orElse: () => fallback,
    );
  }

  String _normalizeCurrency(String? value, {String fallback = 'USD'}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback.toUpperCase();
    }
    return trimmed.toUpperCase();
  }

  bool _determineIsIncome(Map<String, Object?> data, double rawAmount) {
    final isIncome = data['isIncome'];
    if (isIncome is bool) {
      return isIncome;
    }

    final flow = _parseString(data['flow']);
    if (flow != null) {
      switch (flow.toLowerCase()) {
        case 'income':
        case 'inflow':
        case 'in':
          return true;
        case 'expense':
        case 'outflow':
        case 'out':
          return false;
      }
    }

    if (rawAmount < 0) {
      return false;
    }

    return false;
  }

  Future<String> _resolveWalletId(
    Map<String, Object?> data, {
    required String currencyCode,
  }) async {
    final directId = _parseString(
      data['walletId'] ?? data['wallet_id'] ?? data['walletID'],
    );
    if (directId != null) {
      final wallet = _findWalletById(directId);
      if (wallet != null) {
        return wallet.id;
      }
    }

    String? directName = _parseString(
      data['walletName'] ?? data['wallet_name'],
    );
    final walletField = data['wallet'];
    if (directName == null && walletField is String) {
      directName = _parseString(walletField);
    }
    if (directName != null) {
      final wallet = _findWalletByName(directName);
      if (wallet != null) {
        if (data['setAsDefault'] as bool? ?? false) {
          await _setDefaultWalletInternal(wallet.id);
        }
        return wallet.id;
      }
    }

    if (walletField is Map<String, Object?>) {
      final walletData = walletField;
      final nestedId = _parseString(walletData['id']);
      if (nestedId != null) {
        final existing = _findWalletById(nestedId);
        if (existing != null) {
          if (walletData['setAsDefault'] as bool? ?? false) {
            await _setDefaultWalletInternal(existing.id);
          }
          return existing.id;
        }
      }

      final nestedName = _parseString(
        walletData['name'] ?? walletData['walletName'] ?? walletData['title'],
      );
      if (nestedName != null) {
        final existing = _findWalletByName(nestedName);
        if (existing != null) {
          if (walletData['setAsDefault'] as bool? ?? false) {
            await _setDefaultWalletInternal(existing.id);
          }
          return existing.id;
        }

        final created = await _createWalletInternal(
          name: nestedName,
          currencyCode: _normalizeCurrency(
            _parseString(
              walletData['currencyCode'] ??
                  walletData['currency'] ??
                  walletData['currency_code'],
            ),
            fallback: currencyCode,
          ),
          typeName: _parseString(walletData['type']),
          initialBalance: _parseNumber(
            walletData['initialBalance'] ??
                walletData['balance'] ??
                walletData['startingBalance'],
          ),
          setAsDefault:
              walletData['setAsDefault'] as bool? ??
              walletData['makeDefault'] as bool? ??
              false,
        );
        return created.id;
      }
    }

    if (directName != null) {
      final created = await _createWalletInternal(
        name: directName,
        currencyCode: currencyCode,
        initialBalance: _parseNumber(
          data['initialBalance'] ?? data['balance'] ?? data['startingBalance'],
        ),
        setAsDefault:
            data['setAsDefault'] as bool? ??
            data['makeDefault'] as bool? ??
            false,
      );
      return created.id;
    }

    final defaultId = _defaultWalletId;
    if (defaultId != null) {
      final defaultWallet = _findWalletById(defaultId);
      if (defaultWallet != null) {
        return defaultWallet.id;
      }
      return defaultId;
    }

    if (_knownWallets.isNotEmpty) {
      final normalized = currencyCode.toUpperCase();
      final currencyMatch = _knownWallets.firstWhere(
        (wallet) => wallet.currencyCode.toUpperCase() == normalized,
        orElse: () => _knownWallets.first,
      );
      return currencyMatch.id;
    }

    final createdFallback = await _createWalletInternal(
      name: 'Primary Wallet',
      currencyCode: currencyCode,
      setAsDefault: true,
    );
    return createdFallback.id;
  }

  Future<String> _resolveCategoryId(Map<String, Object?> data) async {
    final directId = _parseString(
      data['categoryId'] ?? data['category_id'] ?? data['categoryID'],
    );
    if (directId != null) {
      final category = _findCategoryById(directId);
      if (category != null) {
        return category.id;
      }
    }

    String? directName = _parseString(
      data['categoryName'] ?? data['category_name'],
    );
    final rawCategory = data['category'];
    if (directName == null && rawCategory is String) {
      directName = _parseString(rawCategory);
    }
    if (directName != null) {
      final category = _findCategoryByName(directName);
      if (category != null) {
        return category.id;
      }
    }

    if (rawCategory is Map<String, Object?>) {
      final categoryData = rawCategory;
      final nestedId = _parseString(categoryData['id']);
      if (nestedId != null) {
        final category = _findCategoryById(nestedId);
        if (category != null) {
          return category.id;
        }
      }

      final nestedName =
          _parseString(
            categoryData['name'] ??
                categoryData['categoryName'] ??
                categoryData['title'] ??
                categoryData['label'],
          ) ??
          directName;
      if (nestedName != null) {
        final existing = _findCategoryByName(nestedName);
        if (existing != null) {
          return existing.id;
        }

        final created = await _createCategoryInternal(
          name: nestedName,
          parentCategoryId: _parseString(
            categoryData['parentId'] ??
                categoryData['parentCategoryId'] ??
                categoryData['parent'],
          ),
          iconName: _parseString(
            categoryData['iconName'] ??
                categoryData['icon'] ??
                categoryData['emoji'],
          ),
          color: _parseString(
            categoryData['color'] ?? categoryData['hexColor'],
          ),
        );
        return created.id;
      }
    }

    if (directName != null) {
      final created = await _createCategoryInternal(name: directName);
      return created.id;
    }

    final preferredDefault =
        _findCategoryByName('General') ?? _findCategoryByName('Uncategorised');
    if (preferredDefault != null) {
      return preferredDefault.id;
    }

    if (_knownCategories.isNotEmpty) {
      return _knownCategories.first.id;
    }

    final createdDefault = await _createCategoryInternal(name: 'General');
    return createdDefault.id;
  }

  Future<List<String>> _resolveBudgetCategoryIds(
    Map<String, Object?> data,
  ) async {
    final ids = <String>{};

    void addId(String? id) {
      if (id != null && id.isNotEmpty) {
        ids.add(id);
      }
    }

    for (final id in _parseStringList(data['categoryIds'])) {
      final existing = _findCategoryById(id);
      if (existing != null) {
        addId(existing.id);
      }
    }

    for (final name in _parseStringList(data['categoryNames'])) {
      final existing = _findCategoryByName(name);
      if (existing != null) {
        addId(existing.id);
      }
    }

    final categoryDetails = data['categories'];
    if (categoryDetails is List) {
      for (final entry in categoryDetails) {
        if (entry is! Map<String, Object?>) {
          continue;
        }
        final directId = _parseString(entry['id']);
        if (directId != null) {
          final existing = _findCategoryById(directId);
          if (existing != null) {
            addId(existing.id);
            continue;
          }
        }

        final name = _parseString(entry['name']);
        if (name != null) {
          final existing = _findCategoryByName(name);
          if (existing != null) {
            addId(existing.id);
            continue;
          }

          final created = await _createCategoryInternal(
            name: name,
            parentCategoryId: _parseString(
              entry['parentCategoryId'] ?? entry['parentId'],
            ),
            iconName: _parseString(entry['iconName']),
            color: _parseString(entry['color']),
          );
          addId(created.id);
        }
      }
    }

    return ids.toList(growable: false);
  }

  Future<String> _resolveShoppingListId(Map<String, Object?> data) async {
    final directId = _parseString(data['listId'] ?? data['shoppingListId']);
    if (directId != null) {
      final list = await _getShoppingListById(directId);
      if (list != null) {
        return list.id;
      }
    }

    final directName = _parseString(
      data['listName'] ?? data['shoppingListName'] ?? data['name'],
    );
    if (directName != null) {
      final existing = _findShoppingListByName(directName);
      if (existing != null) {
        return existing.id;
      }
    }

    final nested = data['list'];
    if (nested is Map<String, Object?>) {
      final nestedId = _parseString(nested['id']);
      if (nestedId != null) {
        final existing = await _getShoppingListById(nestedId);
        if (existing != null) {
          return existing.id;
        }
      }

      final nestedName =
          _parseString(nested['name'] ?? nested['listName']) ?? directName;
      if (nestedName != null) {
        final existing = _findShoppingListByName(nestedName);
        if (existing != null) {
          return existing.id;
        }
      }
    }

    if (directName != null) {
      throw StateError('Shopping list "$directName" was not found.');
    }

    throw StateError('Shopping list information is missing for the item.');
  }

  Map<String, Object?> _walletSummary(Wallet wallet) => {
    'id': wallet.id,
    'name': wallet.name,
    'currencyCode': wallet.currencyCode,
    'type': wallet.type.name,
    'isDefault': wallet.id == _defaultWalletId,
  };

  Map<String, Object?> _categorySummary(Category category) => {
    'id': category.id,
    'name': category.name,
    'parentCategoryId': category.parentCategoryId,
  };

  Map<String, Object?> _transactionSummary(MoneyBaseTransaction transaction) =>
      {
        'id': transaction.id,
        'amount': transaction.amount,
        'currencyCode': transaction.currencyCode,
        'description': transaction.description,
        'isIncome': transaction.isIncome,
        'walletId': transaction.walletId,
        'categoryId': transaction.categoryId,
        'date': transaction.date.toIso8601String(),
      };

  Map<String, Object?> _budgetSummary(Budget budget) => {
    'id': budget.id,
    'name': budget.name,
    'currencyCode': budget.currencyCode,
    'limit': budget.limit,
    'period': budget.period.name,
    'flowType': budget.flowType.name,
    'categoryIds': budget.categoryIds,
    'notes': budget.notes,
    'startDate': budget.startDate?.toIso8601String(),
    'endDate': budget.endDate?.toIso8601String(),
  };

  Map<String, Object?> _shoppingListSummary(
    ShoppingList list, {
    List<ShoppingItem> items = const <ShoppingItem>[],
  }) => {
    'id': list.id,
    'name': list.name,
    'type': list.type.name,
    'currency': list.currency,
    'notes': list.notes,
    'createdAt': list.createdAt.toIso8601String(),
    'items': items.map(_shoppingItemSummary).toList(growable: false),
  };

  Map<String, Object?> _shoppingItemSummary(ShoppingItem item) => {
    'id': item.id,
    'title': item.title,
    'bought': item.bought,
    'priority': item.priority.name,
    'price': item.price,
    'currency': item.currency,
    'iconEmoji': item.iconEmoji,
    'iconUrl': item.iconUrl,
    'purchaseDate': item.purchaseDate?.toIso8601String(),
    'expiryDate': item.expiryDate?.toIso8601String(),
  };

  void _emitSuccessNotice(List<_RecordedTransaction> transactions) {
    if (!mounted || transactions.isEmpty) {
      return;
    }

    final immutable = List<_RecordedTransaction>.unmodifiable(transactions);
    final title = immutable.length == 1
        ? 'Transaction added'
        : '${immutable.length} transactions added';
    final subtitle = immutable.length == 1
        ? 'MoneyBase recorded this entry successfully.'
        : 'MoneyBase recorded these entries successfully.';

    final message = _AiMessage(
      rawText: title,
      displayText: title,
      isUser: false,
      timestamp: DateTime.now(),
      successNotice: _SuccessNotice(
        title: title,
        subtitle: subtitle,
        transactions: immutable,
      ),
    );

    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  _RecordedTransaction _toRecordedTransaction(
    MoneyBaseTransaction transaction,
  ) {
    final wallet = transaction.walletId.isEmpty
        ? null
        : _findWalletById(transaction.walletId);
    final category = transaction.categoryId.isEmpty
        ? null
        : _findCategoryById(transaction.categoryId);
    final walletName = wallet == null || wallet.name.trim().isEmpty
        ? 'Wallet'
        : wallet.name.trim();
    final categoryName = category == null || category.name.trim().isEmpty
        ? 'Uncategorised'
        : category.name.trim();
    final currency = transaction.currencyCode.isEmpty
        ? 'USD'
        : transaction.currencyCode.toUpperCase();

    return _RecordedTransaction(
      description: transaction.description.trim().isEmpty
          ? 'MoneyBase transaction'
          : transaction.description.trim(),
      amount: transaction.amount,
      currencyCode: currency,
      isIncome: transaction.isIncome,
      walletName: walletName,
      categoryName: categoryName,
      dateLabel: _formatDateLabel(transaction.date),
      formattedAmount: _formatAmountLabel(
        transaction.amount,
        currency,
        isIncome: transaction.isIncome,
      ),
    );
  }

  String _formatAmountLabel(
    double amount,
    String currency, {
    required bool isIncome,
  }) {
    final prefix = isIncome ? '+' : '-';
    return '$prefix${amount.toStringAsFixed(2)} $currency';
  }

  String _formatDateLabel(DateTime date) {
    final local = date.toLocal();
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDate = DateTime(local.year, local.month, local.day);
    final difference = normalizedDate.difference(normalizedToday).inDays;

    final buffer = StringBuffer();
    if (difference == 0) {
      buffer.write('Today • ');
    } else if (difference == -1) {
      buffer.write('Yesterday • ');
    } else if (difference == 1) {
      buffer.write('Tomorrow • ');
    }

    buffer.write(
      '${local.month.toString().padLeft(2, '0')}/${local.day.toString().padLeft(2, '0')}/${local.year}',
    );
    return buffer.toString();
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
    final themeColors = context.moneyBaseColors;

    Color tonedSurface(double opacity) {
      return Color.alphaBlend(
        themeColors.primaryText.withOpacity(opacity),
        themeColors.surfaceElevated,
      );
    }

    Widget buildStatusRow(String message, {Widget? leading}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading ??
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(mutedOnSurface),
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: textTheme.bodySmall?.copyWith(
                  color: leading == null ? mutedOnSurface : colorScheme.error,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildChatArea(Color panelColor, {required bool isCompact}) {
      final borderRadius = BorderRadius.circular(isCompact ? 20 : 24);
      final composerSpacing = isCompact ? 12.0 : 16.0;

      return Container(
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: borderRadius,
          boxShadow: [
            BoxShadow(
              color: themeColors.surfaceShadow,
              blurRadius: isCompact ? 18 : 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 16 : 20,
          vertical: isCompact ? 16 : 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoadingMessages)
              buildStatusRow('Loading conversation…'),
            Expanded(
              child: _messages.isEmpty && !_isLoadingMessages
                  ? Center(
                      child: Text(
                        'Ask a question or describe a task to get started.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: mutedOnSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        vertical: isCompact ? 6 : 8,
                      ),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final alignment = message.isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft;
                        return Align(
                          alignment: alignment,
                          child: _MessageBubble(message: message),
                        );
                      },
                    ),
            ),
            SizedBox(height: composerSpacing),
            _Composer(
              controller: _messageController,
              onSend: _handleSend,
              onMicPressed: composerEnabled ? _handleVoiceInput : null,
              isSending: _isSending,
              isEnabled: composerEnabled,
              isListening: _isListening,
              voiceError: _voiceError,
            ),
          ],
        ),
      );
    }

    Widget buildSidebar() {
      final disabled = _isInitializing || _isLoadingMessages;
      final sidebarBackground = tonedSurface(
        theme.brightness == Brightness.dark ? 0.18 : 0.08,
      );

      return Container(
        width: 260,
        decoration: BoxDecoration(
          color: sidebarBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: themeColors.surfaceShadow,
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Conversations',
                    style: textTheme.titleSmall?.copyWith(
                      color: onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'New chat',
                  onPressed: disabled ? null : _handleCreateChat,
                  icon: const Icon(Icons.add_comment_outlined),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _chatThreads.isEmpty
                  ? Center(
                      child: Text(
                        'No chats yet.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: mutedOnSurface,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemBuilder: (context, index) {
                        final thread = _chatThreads[index];
                        final isActive = thread.id == _activeChatId;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          selected: isActive,
                          selectedTileColor:
                              colorScheme.primary.withOpacity(0.12),
                          title: Text(
                            thread.displayTitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: isActive ? colorScheme.primary : onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: thread.lastMessagePreview?.isNotEmpty == true
                              ? Text(
                                  thread.lastMessagePreview!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: mutedOnSurface,
                                  ),
                                )
                              : null,
                          onTap: disabled
                              ? null
                              : () => _handleSelectChat(thread.id),
                          trailing: IconButton(
                            tooltip: 'Delete chat',
                            icon: const Icon(Icons.close),
                            onPressed: disabled
                                ? null
                                : () => _handleDeleteChat(thread.id),
                          ),
                        );
                      },
                      separatorBuilder: (context, _) => const SizedBox(height: 8),
                      itemCount: _chatThreads.length,
                    ),
            ),
          ],
        ),
      );
    }

    Widget buildThreadChips({required bool isCompact}) {
      final disabled = _isInitializing || _isLoadingMessages;
      final containerPadding = EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 12 : 14,
      );
      if (_chatThreads.isEmpty) {
        return Container(
          padding: containerPadding,
          decoration: BoxDecoration(
            color: tonedSurface(
              theme.brightness == Brightness.dark
                  ? (isCompact ? 0.16 : 0.12)
                  : (isCompact ? 0.08 : 0.06),
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start a new chat to keep track of your assistant conversations.',
                style: textTheme.bodySmall?.copyWith(
                  color: mutedOnSurface,
                  height: 1.4,
                ),
              ),
              SizedBox(height: isCompact ? 12 : 10),
              FilledButton.icon(
                onPressed: disabled ? null : _handleCreateChat,
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('New chat'),
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 4 : 0,
          vertical: isCompact ? 8 : 4,
        ),
        child: Row(
          children: [
            for (final thread in _chatThreads) ...[
              InputChip(
                label: Text(thread.displayTitle),
                selected: thread.id == _activeChatId,
                onSelected: disabled
                    ? null
                    : (_) => _handleSelectChat(thread.id),
                onDeleted: disabled
                    ? null
                    : () => _handleDeleteChat(thread.id),
                deleteIcon: const Icon(Icons.close, size: 18),
              ),
              SizedBox(width: isCompact ? 8 : 12),
            ],
            FilledButton.icon(
              onPressed: disabled ? null : _handleCreateChat,
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('New chat'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MoneyBase Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            tooltip: 'New chat',
            icon: const Icon(Icons.add_comment_outlined),
            onPressed:
                (!_isInitializing && !_isLoadingMessages) ? _handleCreateChat : null,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 720;
          final showSidebar = constraints.maxWidth >= 1100;
          final chatIsCompact = constraints.maxWidth < 900;
          final padding = EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 32,
            vertical: isCompact ? 16 : 24,
          );
          final headerSpacing = isCompact ? 16.0 : 24.0;
          final titleStyle = textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          );
          final descriptionStyle = textTheme.bodySmall?.copyWith(
            color: mutedOnSurface,
            height: 1.45,
          );
          final iconExtent = isCompact ? 44.0 : 52.0;
          final panelBackground = tonedSurface(
            theme.brightness == Brightness.dark
                ? (chatIsCompact ? 0.2 : 0.16)
                : (chatIsCompact ? 0.08 : 0.06),
          );

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: iconExtent,
                          height: iconExtent,
                          decoration: BoxDecoration(
                            color: themeColors.primaryAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: isCompact ? 12 : 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MoneyBase Assistant', style: titleStyle),
                              SizedBox(height: isCompact ? 6 : 10),
                              Text(
                                'Log expenses, review budgets, and manage wallets with a friendly MoneyBase copilot.',
                                style: descriptionStyle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: headerSpacing),
                    if (_isInitializing)
                      buildStatusRow('Connecting to MoneyBase Assistant…'),
                    if (_errorMessage != null)
                      buildStatusRow(
                        _errorMessage!,
                        leading: Icon(Icons.info_outline, color: colorScheme.error),
                      ),
                    if (!showSidebar) ...[
                      buildThreadChips(isCompact: chatIsCompact),
                      SizedBox(height: isCompact ? 12 : 20),
                    ],
                    Expanded(
                      child: showSidebar
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                buildSidebar(),
                                SizedBox(width: isCompact ? 16 : 24),
                                Expanded(
                                  child: buildChatArea(
                                    panelBackground,
                                    isCompact: false,
                                  ),
                                ),
                              ],
                            )
                          : buildChatArea(
                              panelBackground,
                              isCompact: chatIsCompact,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
