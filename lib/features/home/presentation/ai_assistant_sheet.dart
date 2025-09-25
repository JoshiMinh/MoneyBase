import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/models/category.dart';
import '../../../core/models/transaction.dart';
import '../../../core/models/wallet.dart';
import '../../../core/repositories/category_repository.dart';
import '../../../core/repositories/transaction_repository.dart';
import '../../../core/repositories/wallet_repository.dart';
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
  static final List<String> _walletTypeNames =
      WalletType.values.map((value) => value.name).toList(growable: false);
  static final List<Tool> _assistantTools = <Tool>[
    Tool(
      functionDeclarations: [
        FunctionDeclaration(
          'add_transaction',
          'Persist confirmed MoneyBase transactions. Only call after sharing a '
              'preview and the user explicitly confirms.',
          Schema.object(
            description: 'Payload describing the transactions to record.',
            requiredProperties: ['transactions'],
            properties: {
              'transactions': Schema.array(
                description: 'One or more transactions to create.',
                items: Schema.object(
                  description: 'Single transaction entry.',
                  requiredProperties: [
                    'amount',
                    'currencyCode',
                    'date',
                    'description',
                    'wallet',
                    'category',
                  ],
                  properties: {
                    'amount': Schema.number(
                      description: 'Absolute amount as a positive decimal.',
                    ),
                    'currencyCode': Schema.string(
                      description: 'Currency code in ISO 4217 format.',
                    ),
                    'description': Schema.string(
                      description: 'Short description or memo for the entry.',
                    ),
                    'note': Schema.string(
                      description: 'Optional note to append to the description.',
                      nullable: true,
                    ),
                    'date': Schema.string(
                      description:
                          'ISO 8601 date or datetime when the transaction happened.',
                    ),
                    'isIncome': Schema.boolean(
                      description:
                          'True for income, false for expense. Defaults to false.',
                      nullable: true,
                    ),
                    'flow': Schema.enumString(
                      enumValues: ['income', 'expense'],
                      description:
                          'Alternative to isIncome indicating the cash-flow direction.',
                      nullable: true,
                    ),
                    'walletId': Schema.string(
                      description: 'Existing wallet id to use.',
                      nullable: true,
                    ),
                    'walletName': Schema.string(
                      description: 'Existing wallet name if id is unknown.',
                      nullable: true,
                    ),
                    'categoryId': Schema.string(
                      description: 'Existing category id to use.',
                      nullable: true,
                    ),
                    'categoryName': Schema.string(
                      description: 'Existing category name if id is unknown.',
                      nullable: true,
                    ),
                    'wallet': Schema.object(
                      description:
                          'Wallet metadata. Provide an id for existing wallets or details to create one.',
                      properties: {
                        'id': Schema.string(
                          description: 'Existing wallet id to use.',
                          nullable: true,
                        ),
                        'name': Schema.string(
                          description: 'Wallet name when creating or matching by name.',
                          nullable: true,
                        ),
                        'currencyCode': Schema.string(
                          description: 'Currency for a new wallet.',
                          nullable: true,
                        ),
                        'type': Schema.enumString(
                          enumValues: _walletTypeNames,
                          description:
                              'Wallet type for new wallets. Defaults to physical.',
                          nullable: true,
                        ),
                        'initialBalance': Schema.number(
                          description: 'Optional initial balance for a new wallet.',
                          nullable: true,
                        ),
                        'setAsDefault': Schema.boolean(
                          description:
                              'Whether the wallet should become the default after creation.',
                          nullable: true,
                        ),
                      },
                    ),
                    'category': Schema.object(
                      description:
                          'Category metadata. Provide an id or enough details to create one.',
                      properties: {
                        'id': Schema.string(
                          description: 'Existing category id to use.',
                          nullable: true,
                        ),
                        'name': Schema.string(
                          description:
                              'Category name when matching by name or creating a new one.',
                          nullable: true,
                        ),
                        'parentId': Schema.string(
                          description:
                              'Optional parent category id when creating a new category.',
                          nullable: true,
                        ),
                      },
                    ),
                  },
                ),
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'create_wallet',
          'Create a new wallet for the user.',
          Schema.object(
            requiredProperties: ['name', 'currencyCode'],
            properties: {
              'name': Schema.string(description: 'Wallet display name.'),
              'currencyCode': Schema.string(
                description: 'Currency code in ISO 4217 format.',
              ),
              'type': Schema.enumString(
                enumValues: _walletTypeNames,
                description: 'Wallet type classification.',
                nullable: true,
              ),
              'initialBalance': Schema.number(
                description: 'Initial balance for the wallet.',
                nullable: true,
              ),
              'setAsDefault': Schema.boolean(
                description: 'Whether this wallet should become the default.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'create_category',
          'Create a new category in the user\'s collection.',
          Schema.object(
            requiredProperties: ['name'],
            properties: {
              'name': Schema.string(description: 'Category name.'),
              'parentCategoryId': Schema.string(
                description: 'Optional parent category id.',
                nullable: true,
              ),
              'iconName': Schema.string(
                description: 'Optional Material icon name.',
                nullable: true,
              ),
              'color': Schema.string(
                description: 'Optional hex colour string.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'set_default_wallet',
          'Set the wallet used by default when the user does not specify one.',
          Schema.object(
            requiredProperties: ['walletId'],
            properties: {
              'walletId': Schema.string(
                description: 'Existing wallet id to mark as default.',
              ),
            },
          ),
        ),
      ],
    ),
  ];
  static final ToolConfig _assistantToolConfig = ToolConfig(
    functionCallingConfig: FunctionCallingConfig(mode: FunctionCallingMode.auto),
  );
  static final Content _systemInstruction = Content.system(
    'You are MoneyBase Assistant, MoneyBase\'s budgeting copilot. Follow '
    'these rules:\n'
    '- Always introduce yourself as MoneyBase Assistant.\n'
    '- Parse user messages into potential transactions capturing amount, '
    'currency, category, wallet, note, and date or time.\n'
    '- Ask clarifying questions when any of category, wallet, time, or '
    'currency details are missing, offering relevant defaults or creation '
    'options.\n'
    '- Present a concise preview table and request confirmation before '
    'adding or updating any transactions.\n'
    '- Support user defaults such as preferred wallet or typical meal '
    'times, and mention when something is assumed.\n'
    '- Use the provided function calls to create wallets or categories, set '
    'defaults, and add transactions once the user explicitly confirms a '
    'preview.\n'
    '- After completing an action, send a short, friendly summary to the '
    'user.\n'
    '- Keep responses short, friendly, and focused on spending, budgets, '
    'and savings guidance using any MoneyBase data snapshot provided.',
  );
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
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;
  String? _voiceError;
  List<Wallet> _knownWallets = <Wallet>[];
  List<Category> _knownCategories = <Category>[];
  String? _defaultWalletId;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _transactionRepository = TransactionRepository(firestore: _firestore);
    _walletRepository = WalletRepository(firestore: _firestore);
    _categoryRepository = CategoryRepository(firestore: _firestore);
    _welcomeMessage = _AiMessage(
      text:
          'Hi there! I\'m MoneyBase Assistant, your budgeting copilot. Ask me about tracking spending, wallets, or goals.',
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

    List<_AiMessage> history = <_AiMessage>[];
    try {
      history = await _loadMessageHistory(user.uid);
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('Failed to load MoneyBase Assistant history: $error\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to load previous MoneyBase Assistant messages.'),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load MoneyBase Assistant history: $error\n$stackTrace');
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
        tools: _assistantTools,
        toolConfig: _assistantToolConfig,
      );
      _chatSession = _model!.startChat(
        history: history.map((message) => message.toContent()).toList(),
        safetySettings: _safetySettings,
        generationConfig: _generationConfig,
      );
    } on GenerativeAIException catch (error, stackTrace) {
      debugPrint('Failed to initialise MoneyBase Assistant: $error\n$stackTrace');
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
      debugPrint('Failed to initialise MoneyBase Assistant: $error\n$stackTrace');
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
        debugPrint('Failed to initialise speech recognition: $error\n$stackTrace');
        _speechInitialized = false;
      }

      if (!_speechInitialized) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input is unavailable. Check your microphone permissions.'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Voice input error: $error')),
        );
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
    debugPrint('Voice input error: ${error.errorMsg} (permanent: ${error.permanent})');
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
            content:
                Text('MoneyBase Assistant is still getting ready. Please try again.'),
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

      String? contextSnapshot;
      try {
        contextSnapshot = await _loadUserContext(userId);
      } catch (error, stackTrace) {
        debugPrint(
            'Failed to prepare MoneyBase Assistant context: $error\n$stackTrace');
      }

      final prompt = _buildPrompt(raw, contextSnapshot);

      var response = await chatSession.sendMessage(Content.text(prompt));
      response = await _resolveFunctionCalls(response);
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
      debugPrint('MoneyBase Assistant rejected the message: $error\n$stackTrace');
      final fallback = _AiMessage(
        text:
            'MoneyBase Assistant could not process that request. Please double-check your question and try again.',
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
          'text': fallback.text,
          'isUser': false,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } catch (writeError, writeStackTrace) {
        debugPrint(
            'Failed to record MoneyBase Assistant error message: $writeError\n$writeStackTrace');
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to send MoneyBase Assistant message: $error\n$stackTrace');
      const fallbackText =
          'I had trouble reaching MoneyBase Assistant just now. Please try again in a moment.';
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
            content: Text(
                'Something went wrong while contacting MoneyBase Assistant. Please try again.'),
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
            'Failed to record fallback MoneyBase Assistant message: $writeError\n$writeStackTrace');
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

      final categoriesSnapshot = await categoriesFuture;
      final walletsSnapshot = await walletsFuture;
      final transactionsSnapshot = await transactionsFuture;

      final categories = categoriesSnapshot.docs
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

      final wallets = walletsSnapshot.docs
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

      _knownWallets = wallets;
      _knownCategories = categories;

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
        final walletsToShow = wallets.length > 8 ? wallets.sublist(0, 8) : wallets;
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
              walletNames[defaultWalletId] ?? formatName(defaultWalletId, 'Wallet');
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
        final sampleSize =
            categoryNamesList.length > 12 ? 12 : categoryNamesList.length;
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
          final currency = formatName(transaction.currencyCode.toUpperCase(), 'USD');
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
        final transactionsToShow =
            transactions.length > 12 ? transactions.sublist(0, 12) : transactions;
        for (final transaction in transactionsToShow) {
          final date = transaction.date.toIso8601String().split('T').first;
          final flowLabel = transaction.isIncome ? 'income' : 'expense';
          final amount = transaction.amount.toStringAsFixed(2);
          final currency = formatName(transaction.currencyCode.toUpperCase(), 'USD');
          final description = formatName(transaction.description, 'No description');
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
              .map(
                (entry) => '${entry.value.toStringAsFixed(2)} ${entry.key}',
              )
              .join(', ');
        }

        buffer.writeln(
          'Summary: $incomeCount income (${describeTotals(incomeTotals)}) and '
          '$expenseCount expense (${describeTotals(expenseTotals)}). Values '
          "use each entry's currency and may mix different currencies.",
        );
      }

      final context = buffer.toString().trim();
      _cachedContextText = context.isEmpty ? null : context;
      _contextFetchedAt = DateTime.now();
      return _cachedContextText;
    } on FirebaseException catch (error, stackTrace) {
      debugPrint(
          'Failed to load MoneyBase Assistant context: $error\n$stackTrace');
    } catch (error, stackTrace) {
      debugPrint(
          'Failed to load MoneyBase Assistant context: $error\n$stackTrace');
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

  Future<GenerateContentResponse> _resolveFunctionCalls(
      GenerateContentResponse initialResponse) async {
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
              'MoneyBase Assistant action ${call.name} failed: $error\n$stackTrace');
          payload = {
            'success': false,
            'error': error.toString(),
          };
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
      case 'create_wallet':
        return _handleCreateWalletCall(args);
      case 'create_category':
        return _handleCreateCategoryCall(args);
      case 'set_default_wallet':
        return _handleSetDefaultWalletCall(args);
      default:
        throw StateError('Unknown MoneyBase Assistant action: ${call.name}');
    }
  }

  Future<Map<String, Object?>> _handleAddTransactionCall(
      Map<String, Object?> args) async {
    final userId = _requireUserId();
    final transactionsArg = args['transactions'];
    if (transactionsArg is! List) {
      throw FormatException('transactions must be an array');
    }

    final created = <Map<String, Object?>>[];
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
      final currencyCode =
          _normalizeCurrency(_parseString(entry['currencyCode']));
      final date =
          _parseDate(entry['date'] ?? entry['datetime'] ?? entry['timestamp']);
      final description =
          _parseString(entry['description']) ?? 'MoneyBase transaction';
      final note = _parseString(entry['note']);
      final combinedDescription =
          note == null || note.isEmpty ? description : '$description — $note';

      final walletId =
          await _resolveWalletId(entry, currencyCode: currencyCode);
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

      final saved =
          await _transactionRepository.addTransaction(userId, transaction);
      created.add(_transactionSummary(saved));
    }

    _cachedContextText = null;

    return {
      'success': true,
      'created': created,
    };
  }

  Future<Map<String, Object?>> _handleCreateWalletCall(
      Map<String, Object?> args) async {
    final name = _parseString(args['name']);
    final currency = _normalizeCurrency(_parseString(args['currencyCode']));
    if (name == null) {
      throw FormatException('Wallet name is required.');
    }

    final wallet = await _createWalletInternal(
      name: name,
      currencyCode: currency,
      typeName: _parseString(args['type']),
      initialBalance: _parseNumber(args['initialBalance']),
      setAsDefault: args['setAsDefault'] as bool? ?? false,
    );

    return {
      'success': true,
      'wallet': _walletSummary(wallet),
    };
  }

  Future<Map<String, Object?>> _handleCreateCategoryCall(
      Map<String, Object?> args) async {
    final name = _parseString(args['name']);
    if (name == null) {
      throw FormatException('Category name is required.');
    }

    final category = await _createCategoryInternal(
      name: name,
      parentCategoryId:
          _parseString(args['parentCategoryId'] ?? args['parentId']),
      iconName: _parseString(args['iconName']),
      color: _parseString(args['color']),
    );

    return {
      'success': true,
      'category': _categorySummary(category),
    };
  }

  Future<Map<String, Object?>> _handleSetDefaultWalletCall(
      Map<String, Object?> args) async {
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

    return {
      'success': true,
      'wallet': _walletSummary(wallet),
    };
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
    await _firestore
        .collection('users')
        .doc(userId)
        .set({'defaultWalletId': walletId}, SetOptions(merge: true));
    _defaultWalletId = walletId;
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
      final milliseconds = value > 1e12 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: false);
    }
    return DateTime.now();
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
    final directId =
        _parseString(data['walletId'] ?? data['wallet_id'] ?? data['walletID']);
    if (directId != null) {
      final wallet = _findWalletById(directId);
      if (wallet != null) {
        return wallet.id;
      }
    }

    final directName =
        _parseString(data['walletName'] ?? data['wallet_name']);
    if (directName != null) {
      final wallet = _findWalletByName(directName);
      if (wallet != null) {
        if (data['setAsDefault'] as bool? ?? false) {
          await _setDefaultWalletInternal(wallet.id);
        }
        return wallet.id;
      }
    }

    final walletData = data['wallet'];
    if (walletData is Map<String, Object?>) {
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

      final nestedName = _parseString(walletData['name']);
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
            _parseString(walletData['currencyCode']),
            fallback: currencyCode,
          ),
          typeName: _parseString(walletData['type']),
          initialBalance: _parseNumber(walletData['initialBalance']),
          setAsDefault: walletData['setAsDefault'] as bool? ?? false,
        );
        return created.id;
      }
    }

    if (directName != null) {
      final created = await _createWalletInternal(
        name: directName,
        currencyCode: currencyCode,
        setAsDefault: data['setAsDefault'] as bool? ?? false,
      );
      return created.id;
    }

    final defaultId = _defaultWalletId;
    if (defaultId != null) {
      return defaultId;
    }

    throw StateError('Wallet information is missing for the transaction.');
  }

  Future<String> _resolveCategoryId(Map<String, Object?> data) async {
    final directId = _parseString(
        data['categoryId'] ?? data['category_id'] ?? data['categoryID']);
    if (directId != null) {
      final category = _findCategoryById(directId);
      if (category != null) {
        return category.id;
      }
    }

    final directName =
        _parseString(data['categoryName'] ?? data['category_name']);
    if (directName != null) {
      final category = _findCategoryByName(directName);
      if (category != null) {
        return category.id;
      }
    }

    final categoryData = data['category'];
    if (categoryData is Map<String, Object?>) {
      final nestedId = _parseString(categoryData['id']);
      if (nestedId != null) {
        final category = _findCategoryById(nestedId);
        if (category != null) {
          return category.id;
        }
      }

      final nestedName =
          _parseString(categoryData['name']) ?? directName;
      if (nestedName != null) {
        final existing = _findCategoryByName(nestedName);
        if (existing != null) {
          return existing.id;
        }

        final created = await _createCategoryInternal(
          name: nestedName,
          parentCategoryId:
              _parseString(categoryData['parentId'] ?? categoryData['parentCategoryId']),
          iconName: _parseString(categoryData['iconName']),
          color: _parseString(categoryData['color']),
        );
        return created.id;
      }
    }

    if (directName != null) {
      final created = await _createCategoryInternal(name: directName);
      return created.id;
    }

    throw StateError('Category information is missing for the transaction.');
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

  Map<String, Object?> _transactionSummary(
          MoneyBaseTransaction transaction) =>
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
                          'MoneyBase Assistant',
                          style: textTheme.titleMedium?.copyWith(
                            color: onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Log expenses, review budgets, and manage wallets with a friendly MoneyBase copilot.',
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
                          'Connecting to MoneyBase Assistant…',
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
                onMicPressed: composerEnabled ? _handleVoiceInput : null,
                isSending: _isSending,
                isEnabled: composerEnabled,
                isListening: _isListening,
                voiceError: _voiceError,
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
    final micTooltip = isListening ? 'Stop listening' : 'Voice input';
    final micIcon = isListening ? Icons.stop : Icons.mic_none;
    final micHandler = (!isEnabled || onMicPressed == null) ? null : onMicPressed;

    final row = Row(
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
        IconButton(
          tooltip: micTooltip,
          onPressed: micHandler,
          icon: Icon(
            micIcon,
            color: isListening ? theme.colorScheme.error : null,
          ),
        ),
        const SizedBox(width: 8),
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

    final voiceMessage = voiceError;
    return Column(
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
      isUser ? 'user' : 'model',
      [TextPart(text)],
    );
  }
}
