import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';

class CustomEmailNumberField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isEmail;
  final bool readOnly;
  final String initialCountryCode;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function(CountryCode)? onCountryCodeChanged;
  final int maxLines;
  final Color? fillColor;
  final BorderSide? borderSide;

  const CustomEmailNumberField({
    super.key,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isEmail = false,
    this.readOnly = false,
    this.initialCountryCode = '+1',
    this.hintText,
    this.labelText,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.onCountryCodeChanged,
    this.maxLines = 1,
    this.fillColor,
    this.borderSide,
    this.prefixIcon,
  });

  @override
  State<CustomEmailNumberField> createState() => _CustomEmailNumberFieldState();
}

class _CustomEmailNumberFieldState extends State<CustomEmailNumberField> {
  bool _obscureText = true;
  bool _isNumberMode = false; // 👈 track whether user typing number
  CountryCode selectedCode = CountryCode.fromDialCode('+1');

  void _togglePassword() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _handleTextChange(String value) {
    // Detect if input looks like a number (ignore spaces, +, and -)
    bool looksLikeNumber = RegExp(r'^[0-9+\-\s]+$').hasMatch(value);
    if (looksLikeNumber != _isNumberMode) {
      setState(() => _isNumberMode = looksLikeNumber);
    }

    if (widget.onChanged != null) {
      widget.onChanged!(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxLines == 1 ? 48 : null,
      child: TextFormField(
        controller: widget.controller,
        keyboardType: _isNumberMode ? TextInputType.phone : widget.keyboardType,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: _handleTextChange,
        obscureText: widget.isPassword ? _obscureText : false,
        obscuringCharacter: '*',
        maxLines: widget.maxLines,
        cursorColor: AppColors.primaryColor,
        style: const TextStyle(
          color: Color(0xFF676565),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        validator: _validator,
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.fillColor ?? Colors.white,
          hintText: widget.hintText,
          labelText: widget.labelText,
          hintStyle: const TextStyle(
            color: Color(0xFF676565),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ?? const BorderSide(color: Color(0xFFC4C3C3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ?? const BorderSide(color: Color(0xFFC4C3C3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ?? const BorderSide(color: Color(0xFFC4C3C3)),
          ),

          // ✅ Show Country Code Picker when user types number, else prefixIcon
          prefixIcon: _isNumberMode
              ? _buildCountryCodePicker()
              : widget.prefixIcon,
          prefixIconConstraints: BoxConstraints(minHeight: 24, minWidth: 24),

          // ✅ Password toggle or custom suffix
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: _togglePassword,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Icon(
                      _obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF676565),
                    ),
                  ),
                )
              : widget.suffixIcon,
        ),
      ),
    );
  }

  /// ✅ Validation logic
  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter ${widget.hintText?.toLowerCase() ?? 'value'}";
    }

    if (!_isNumberMode && widget.isEmail) {
      bool validEmail = AppConstants.emailValidator.hasMatch(value);
      if (!validEmail) return "Please check your email!";
    }

    if (widget.isPassword) {
      bool validPass = AppConstants.passwordValidator.hasMatch(value);
      if (!validPass) return "Insecure password detected.";
    }

    return null;
  }

  /// ✅ Country Code Picker (only code)
  Widget _buildCountryCodePicker() {
    return CountryCodePicker(
      onChanged: (code) {
        setState(() => selectedCode = code);
        if (widget.onCountryCodeChanged != null) {
          widget.onCountryCodeChanged!(code);
        }
      },
      initialSelection: widget.initialCountryCode,
      favorite: const ['+1', '+880', '+91'],
      showFlag: false,
      showCountryOnly: false,
      showOnlyCountryWhenClosed: false,
      alignLeft: false,
      padding: const EdgeInsets.only(left: 8, right: 4),
      textStyle: const TextStyle(
        color: Color(0xFF413E3E),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      builder: (CountryCode? code) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            code?.dialCode ?? '+1',
            style: const TextStyle(
              color: Color(0xFF413E3E),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }
}
