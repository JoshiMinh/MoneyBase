
import 'package:flutter/material.dart';

import '../../../core/constants/currencies.dart';

class CurrencyDropdownFormField extends StatelessWidget {
  CurrencyDropdownFormField({
    required String value,
    required this.onChanged,
    this.labelText = 'Currency',
    this.validator,
    this.helperText,
    this.enabled = true,
    super.key,
  }) : value = currencyOptionFor(value).code;

  final String value;
  final ValueChanged<String> onChanged;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final String? helperText;
  final bool enabled;

  static final List<DropdownMenuItem<String>> _items =
      buildCurrencyDropdownItems();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: _items,
      validator: validator,
      onChanged: enabled
          ? (code) {
              if (code != null) onChanged(code);
            }
          : null,
      decoration: InputDecoration(
        labelText: labelText,
        helperText: helperText,
      ),
      isExpanded: true,
    );
  }
}
