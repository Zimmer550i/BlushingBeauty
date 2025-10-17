import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';
import 'package:ree_social_media_app/utils/app_constants.dart';
import 'package:intl/intl.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool? isObscureText;
  final String? obscure;
  final Color? filColor;
  final Widget? prefixIcon;
  final String? labelText;
  final String? hintText;
  final double? contentPaddingHorizontal;
  final double? contentPaddingVertical;
  final Widget? suffixIcon;
  final FormFieldValidator? validator;
  final bool isPassword;
  final bool? isEmail;
  final bool? isRealOnly;
  final int? maxLines;
  final Color? borderColor;
  final BorderSide? borderSide;
  final Function(String)? onChanged;
  final Function()? onTap;

  const CustomTextField({
    super.key,
    this.contentPaddingHorizontal,
    this.contentPaddingVertical,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.isEmail,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.isObscureText = false,
    this.isRealOnly = false,
    this.obscure = '*',
    this.filColor,
    this.labelText,
    this.onChanged,
    this.onTap,
    this.maxLines = 1,
    this.borderColor,
    this.borderSide,
    this.isPassword = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool obscureText = true;

  void toggle() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.maxLines == 1 ? 48 : null,
      child: TextFormField(
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        readOnly: widget.isRealOnly!,
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscuringCharacter: widget.obscure!,
        maxLines: widget.maxLines,
        validator:
            widget.validator ??
            (value) {
              if (widget.isEmail == null) {
                if (value!.isEmpty) {
                  return "Please enter ${widget.hintText!.toLowerCase()}";
                } else if (widget.isPassword) {
                  bool data = AppConstants.passwordValidator.hasMatch(value);
                  if (value.isEmpty) {
                    return "Please enter ${widget.hintText!.toLowerCase()}";
                  } else if (!data) {
                    return "Insecure password detected.";
                  }
                }
              } else {
                bool data = AppConstants.emailValidator.hasMatch(value!);
                if (value.isEmpty) {
                  return "Please enter ${widget.hintText!.toLowerCase()}";
                } else if (!data) {
                  return "Please check your email!";
                }
              }
              return null;
            },
        cursorColor: AppColors.primaryColor,
        obscureText: widget.isPassword ? obscureText : false,
        style: TextStyle(
          color: Color(0xFF676565),
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          // No border color but keep the border radius
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ??
                BorderSide(color: Color(0xFFC4C3C3), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ??
                BorderSide(color: Color(0xFFC4C3C3), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                widget.borderSide ??
                BorderSide(color: Color(0xFFC4C3C3), width: 1),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.contentPaddingHorizontal ?? 20,
            vertical:
                widget.contentPaddingVertical ??
                12, // Adjusted for vertical centering
          ),
          fillColor: widget.filColor,
          filled: true,
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.isPassword
              ? GestureDetector(
                  onTap: toggle,
                  child: _suffixIcon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                )
              : widget.suffixIcon,
          prefixIconConstraints: BoxConstraints(minHeight: 24, minWidth: 24),
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Color(0xFF676565),
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Padding _suffixIcon(IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Icon(icon, color: Color(0xFF676565)),
    );
  }
}

class DateOfBirthField extends StatefulWidget {
  final TextEditingController controller;

  const DateOfBirthField({super.key, required this.controller});

  @override
  State<DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<DateOfBirthField> {
  // Function to open date picker when user taps on the field
  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    // If a date is selected, format it and update the text controller
    if (selectedDate != null) {
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      widget.controller.text = formattedDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      isRealOnly: true,
      onTap: () => _selectDate(context),
      controller: widget.controller,
      hintText: 'Enter your birthday',
      borderSide: const BorderSide(color: Color(0xFFC4C3C3), width: 1),
      prefixIcon: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryColor,
          ),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: SvgPicture.asset('assets/icons/dateOfBirth.svg'),
          ),
        ),
      ),
      suffixIcon: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          height: 16,
          width: 16,
          child: SvgPicture.asset(
            'assets/icons/calender_blue.svg',
            height: 16,
            width: 16,
          ),
        ),
      ),
    );
  }
}
