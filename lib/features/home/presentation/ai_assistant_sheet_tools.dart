part of 'ai_assistant_sheet.dart';

const int _maxHistoryMessages = 20;
final GenerationConfig _generationConfig = GenerationConfig(
    maxOutputTokens: 512,
    temperature: 0.4,
    topP: 0.9,
  );
final List<SafetySetting> _safetySettings = <SafetySetting>[
    SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
    SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
    SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
  ];
final List<String> _walletTypeNames = WalletType.values
      .map((value) => value.name)
      .toList(growable: false);
final List<String> _budgetPeriodNames = BudgetPeriod.values
      .map((value) => value.name)
      .toList(growable: false);
final List<String> _budgetFlowTypeNames = BudgetFlowType.values
      .map((value) => value.name)
      .toList(growable: false);
final List<String> _shoppingListTypeNames = ShoppingListType.values
      .map((value) => value.name)
      .toList(growable: false);
final List<String> _shoppingItemPriorityNames = ShoppingItemPriority
      .values
      .map((value) => value.name)
      .toList(growable: false);
final List<Tool> _assistantTools = <Tool>[
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
                      description:
                          'Optional note to append to the description.',
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
                          description:
                              'Wallet name when creating or matching by name.',
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
                          description:
                              'Optional initial balance for a new wallet.',
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
          'update_transaction',
          'Update an existing MoneyBase transaction with corrected details.',
          Schema.object(
            description:
                'Provide the transaction id and any fields that should be updated.',
            requiredProperties: ['transactionId'],
            properties: {
              'transactionId': Schema.string(
                description: 'Identifier of the transaction to update.',
              ),
              'amount': Schema.number(
                description: 'Absolute amount as a positive decimal.',
                nullable: true,
              ),
              'currencyCode': Schema.string(
                description: 'Currency code in ISO 4217 format.',
                nullable: true,
              ),
              'description': Schema.string(
                description: 'Updated description or memo.',
                nullable: true,
              ),
              'note': Schema.string(
                description: 'Optional note appended to the description.',
                nullable: true,
              ),
              'date': Schema.string(
                description: 'ISO 8601 date or datetime for the transaction.',
                nullable: true,
              ),
              'isIncome': Schema.boolean(
                description: 'Whether the entry should be marked as income.',
                nullable: true,
              ),
              'flow': Schema.enumString(
                enumValues: ['income', 'expense'],
                description:
                    'Alternative to isIncome indicating the flow direction.',
                nullable: true,
              ),
              'walletId': Schema.string(
                description: 'Wallet id that should own the transaction.',
                nullable: true,
              ),
              'walletName': Schema.string(
                description: 'Wallet name if the id is unknown.',
                nullable: true,
              ),
              'categoryId': Schema.string(
                description:
                    'Category id that should classify the transaction.',
                nullable: true,
              ),
              'categoryName': Schema.string(
                description: 'Category name if the id is unknown.',
                nullable: true,
              ),
              'wallet': Schema.object(
                description:
                    'Optional wallet details to resolve or create a wallet when updating.',
                nullable: true,
                properties: {
                  'id': Schema.string(
                    description: 'Existing wallet id to use.',
                    nullable: true,
                  ),
                  'name': Schema.string(
                    description: 'Wallet name when matching by name.',
                    nullable: true,
                  ),
                  'currencyCode': Schema.string(
                    description: 'Currency for a new wallet.',
                    nullable: true,
                  ),
                  'type': Schema.enumString(
                    enumValues: _walletTypeNames,
                    description: 'Wallet type for new wallets.',
                    nullable: true,
                  ),
                  'initialBalance': Schema.number(
                    description: 'Initial balance when creating a wallet.',
                    nullable: true,
                  ),
                  'setAsDefault': Schema.boolean(
                    description:
                        'Whether the wallet should become the default.',
                    nullable: true,
                  ),
                },
              ),
              'category': Schema.object(
                description:
                    'Optional category details to resolve or create a category.',
                nullable: true,
                properties: {
                  'id': Schema.string(
                    description: 'Existing category id to use.',
                    nullable: true,
                  ),
                  'name': Schema.string(
                    description: 'Category name to match or create.',
                    nullable: true,
                  ),
                  'parentId': Schema.string(
                    description: 'Parent category id when creating a new one.',
                    nullable: true,
                  ),
                },
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
          'update_wallet',
          'Update details for an existing wallet. Provide walletId or walletName '
              'to identify the wallet.',
          Schema.object(
            requiredProperties: [],
            properties: {
              'walletId': Schema.string(
                description: 'Identifier of the wallet to update.',
                nullable: true,
              ),
              'walletName': Schema.string(
                description: 'Wallet name if the id is not available.',
                nullable: true,
              ),
              'name': Schema.string(
                description: 'Updated wallet display name.',
                nullable: true,
              ),
              'currencyCode': Schema.string(
                description: 'Updated ISO 4217 currency code.',
                nullable: true,
              ),
              'type': Schema.enumString(
                enumValues: _walletTypeNames,
                description: 'Updated wallet type classification.',
                nullable: true,
              ),
              'balance': Schema.number(
                description: 'Updated balance for the wallet.',
                nullable: true,
              ),
              'color': Schema.string(
                description: 'Hex colour string for the wallet accent.',
                nullable: true,
              ),
              'iconName': Schema.string(
                description: 'Material icon name used for the wallet.',
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
          'update_category',
          'Update an existing category. Provide either categoryId or name to '
              'identify the entry.',
          Schema.object(
            requiredProperties: [],
            properties: {
              'categoryId': Schema.string(
                description: 'Identifier of the category to update.',
                nullable: true,
              ),
              'name': Schema.string(
                description: 'Updated category name.',
                nullable: true,
              ),
              'parentCategoryId': Schema.string(
                description: 'Updated parent category id.',
                nullable: true,
              ),
              'iconName': Schema.string(
                description: 'Updated Material icon name.',
                nullable: true,
              ),
              'color': Schema.string(
                description: 'Updated hex colour string.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'create_budget',
          'Create a new budget that can track limits for categories or flows.',
          Schema.object(
            requiredProperties: ['name', 'currencyCode', 'limit'],
            properties: {
              'name': Schema.string(description: 'Budget display name.'),
              'currencyCode': Schema.string(
                description: 'ISO 4217 currency code used for the budget.',
              ),
              'limit': Schema.number(
                description: 'Spending or saving limit for the budget.',
              ),
              'notes': Schema.string(
                description: 'Optional notes that describe the budget.',
                nullable: true,
              ),
              'period': Schema.enumString(
                enumValues: _budgetPeriodNames,
                description: 'Budget period such as month or week.',
                nullable: true,
              ),
              'flowType': Schema.enumString(
                enumValues: _budgetFlowTypeNames,
                description:
                    'Whether the budget tracks expenses, income, or both.',
                nullable: true,
              ),
              'startDate': Schema.string(
                description: 'ISO 8601 start date when using custom periods.',
                nullable: true,
              ),
              'endDate': Schema.string(
                description: 'ISO 8601 end date for custom periods.',
                nullable: true,
              ),
              'categoryIds': Schema.array(
                description: 'Category ids governed by the budget.',
                nullable: true,
                items: Schema.string(description: 'Category id.'),
              ),
              'categoryNames': Schema.array(
                description:
                    'Category names to associate when ids are unknown.',
                nullable: true,
                items: Schema.string(description: 'Category name.'),
              ),
              'categories': Schema.array(
                description:
                    'Category descriptors used to match or create categories.',
                nullable: true,
                items: Schema.object(
                  properties: {
                    'id': Schema.string(
                      description: 'Existing category id.',
                      nullable: true,
                    ),
                    'name': Schema.string(
                      description: 'Category name to match or create.',
                      nullable: true,
                    ),
                    'parentCategoryId': Schema.string(
                      description: 'Parent id when creating nested categories.',
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
            },
          ),
        ),
        FunctionDeclaration(
          'update_budget',
          'Update an existing budget. Supply budgetId or name to target it.',
          Schema.object(
            requiredProperties: [],
            properties: {
              'budgetId': Schema.string(
                description: 'Identifier of the budget to update.',
                nullable: true,
              ),
              'name': Schema.string(
                description: 'Updated budget name.',
                nullable: true,
              ),
              'currencyCode': Schema.string(
                description: 'Updated currency code.',
                nullable: true,
              ),
              'limit': Schema.number(
                description: 'Updated limit amount.',
                nullable: true,
              ),
              'notes': Schema.string(
                description: 'Updated notes for the budget.',
                nullable: true,
              ),
              'period': Schema.enumString(
                enumValues: _budgetPeriodNames,
                description: 'Updated budget period.',
                nullable: true,
              ),
              'flowType': Schema.enumString(
                enumValues: _budgetFlowTypeNames,
                description: 'Updated flow type.',
                nullable: true,
              ),
              'startDate': Schema.string(
                description: 'New custom start date.',
                nullable: true,
              ),
              'endDate': Schema.string(
                description: 'New custom end date.',
                nullable: true,
              ),
              'categoryIds': Schema.array(
                description: 'Replacement category ids for the budget.',
                nullable: true,
                items: Schema.string(description: 'Category id.'),
              ),
              'categoryNames': Schema.array(
                description:
                    'Category names to match when replacing categories.',
                nullable: true,
                items: Schema.string(description: 'Category name.'),
              ),
              'categories': Schema.array(
                description:
                    'Category descriptors to resolve when updating the budget.',
                nullable: true,
                items: Schema.object(
                  properties: {
                    'id': Schema.string(
                      description: 'Existing category id.',
                      nullable: true,
                    ),
                    'name': Schema.string(
                      description: 'Category name to match or create.',
                      nullable: true,
                    ),
                    'parentCategoryId': Schema.string(
                      description: 'Parent category id.',
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
            },
          ),
        ),
        FunctionDeclaration(
          'create_shopping_list',
          'Create a shopping or grocery list for the user.',
          Schema.object(
            requiredProperties: ['name'],
            properties: {
              'name': Schema.string(description: 'Shopping list name.'),
              'type': Schema.enumString(
                enumValues: _shoppingListTypeNames,
                description: 'List type such as grocery or shopping.',
                nullable: true,
              ),
              'notes': Schema.string(
                description: 'Optional notes for the list.',
                nullable: true,
              ),
              'currency': Schema.string(
                description: 'Currency used for estimating prices.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'update_shopping_list',
          'Update an existing shopping list. Provide listId or name.',
          Schema.object(
            requiredProperties: [],
            properties: {
              'listId': Schema.string(
                description: 'Identifier of the shopping list.',
                nullable: true,
              ),
              'name': Schema.string(
                description: 'Updated list name.',
                nullable: true,
              ),
              'type': Schema.enumString(
                enumValues: _shoppingListTypeNames,
                description: 'Updated list type.',
                nullable: true,
              ),
              'notes': Schema.string(
                description: 'Updated notes.',
                nullable: true,
              ),
              'currency': Schema.string(
                description: 'Updated currency code.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'create_shopping_item',
          'Create a shopping list item. Provide listId or listName to identify '
              'the list it belongs to.',
          Schema.object(
            requiredProperties: ['title'],
            properties: {
              'title': Schema.string(
                description: 'Display title for the item.',
              ),
              'listId': Schema.string(
                description:
                    'Identifier of the list that should contain the item.',
                nullable: true,
              ),
              'listName': Schema.string(
                description: 'List name if the id is unknown.',
                nullable: true,
              ),
              'price': Schema.number(
                description: 'Estimated price of the item.',
                nullable: true,
              ),
              'currency': Schema.string(
                description: 'Currency for the estimated price.',
                nullable: true,
              ),
              'priority': Schema.enumString(
                enumValues: _shoppingItemPriorityNames,
                description: 'Priority level for the item.',
                nullable: true,
              ),
              'bought': Schema.boolean(
                description: 'Whether the item has already been purchased.',
                nullable: true,
              ),
              'purchaseDate': Schema.string(
                description: 'ISO 8601 purchase date.',
                nullable: true,
              ),
              'expiryDate': Schema.string(
                description: 'ISO 8601 expiry date.',
                nullable: true,
              ),
              'iconEmoji': Schema.string(
                description: 'Emoji shown for the item.',
                nullable: true,
              ),
              'iconUrl': Schema.string(
                description: 'Custom icon URL for the item.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'update_shopping_item',
          'Update a shopping list item. Provide itemId and optionally listId or '
              'listName to locate it.',
          Schema.object(
            requiredProperties: ['itemId'],
            properties: {
              'itemId': Schema.string(
                description: 'Identifier of the item to update.',
              ),
              'listId': Schema.string(
                description: 'Identifier of the parent list.',
                nullable: true,
              ),
              'listName': Schema.string(
                description: 'List name if the id is unknown.',
                nullable: true,
              ),
              'title': Schema.string(
                description: 'Updated title for the item.',
                nullable: true,
              ),
              'price': Schema.number(
                description: 'Updated price estimate.',
                nullable: true,
              ),
              'currency': Schema.string(
                description: 'Updated currency code.',
                nullable: true,
              ),
              'priority': Schema.enumString(
                enumValues: _shoppingItemPriorityNames,
                description: 'Updated priority level.',
                nullable: true,
              ),
              'bought': Schema.boolean(
                description: 'Whether the item has been purchased.',
                nullable: true,
              ),
              'purchaseDate': Schema.string(
                description: 'Updated purchase date.',
                nullable: true,
              ),
              'expiryDate': Schema.string(
                description: 'Updated expiry date.',
                nullable: true,
              ),
              'iconEmoji': Schema.string(
                description: 'Updated emoji for the item.',
                nullable: true,
              ),
              'iconUrl': Schema.string(
                description: 'Updated icon URL.',
                nullable: true,
              ),
            },
          ),
        ),
        FunctionDeclaration(
          'get_data_snapshot',
          'Fetch the most recent MoneyBase data snapshot including wallets, '
              'categories, budgets, transactions, and shopping lists.',
          Schema.object(
            description: 'Optional flags to control the snapshot content.',
            properties: {
              'includeTransactions': Schema.boolean(
                description:
                    'Whether to include the most recent transactions in the snapshot.',
                nullable: true,
              ),
            },
          ),
        ),
      ],
    ),
  ];
final ToolConfig _assistantToolConfig = ToolConfig(
    functionCallingConfig: FunctionCallingConfig(
      mode: FunctionCallingMode.auto,
    ),
  );
final Content _systemInstruction = Content.system(
    'You are MoneyBase Assistant, MoneyBase\'s budgeting copilot. Follow '
    'these rules:\n'
    '- Introduce yourself as MoneyBase Assistant in your first reply for a '
    'new chat only and avoid repeating the introduction afterwards.\n'
    '- Format every response using Markdown, using tables, lists, and '
    'headings when they improve clarity.\n'
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
