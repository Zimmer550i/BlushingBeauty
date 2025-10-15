import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class CustomNumberField extends StatefulWidget {
  final TextEditingController controller;
  final bool isPassword;
  final bool readOnly;
  final String initialCountryCode;
  final String? hintText;
  final String? labelText;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final Function()? onTap;
  final Function(CountryCode)? onCountryCodeChanged;
  final int maxLines;
  final Color? fillColor;
  final BorderSide? borderSide;

  const CustomNumberField({
    super.key,
    required this.controller,
    this.isPassword = false,
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
  });

  @override
  State<CustomNumberField> createState() => _CustomNumberFieldState();
}

class _CustomNumberFieldState extends State<CustomNumberField> {
  bool _obscureText = true;
  CountryCode selectedCode = CountryCode.fromDialCode('+1');

  void _togglePassword() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxLines == 1 ? 48 : null,
      child: TextFormField(
        controller: widget.controller,
        keyboardType: TextInputType.phone,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
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

          // ✅ Always show Country Code Picker
          prefixIcon: _buildCountryCodePicker(),
          prefixIconConstraints: const BoxConstraints(minHeight: 24, minWidth: 24),

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

  /// ✅ Simple phone validator
  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter phone number";
    }

    bool validPhone = RegExp(r'^[0-9]{6,15}$').hasMatch(value.replaceAll(RegExp(r'\s+'), ''));
    if (!validPhone) return "Invalid phone number";

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
