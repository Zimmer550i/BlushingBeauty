import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class CustomDropdown extends StatefulWidget {
  final List<Map<String, dynamic>> items;

  const CustomDropdown({super.key, required this.items});

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  Map<String, dynamic>? selectedItem;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<Map<String, dynamic>>(
      dropdownColor: Color(0xFFC4C3C3),
      isExpanded: true,
      hint: const Text("See members",
      style: TextStyle(
        color: Color(0xFF413E3E),
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),),
      value: selectedItem,
      underline: const SizedBox(),
      icon: selectedItem == null? Container(
        height: 24,
        width: 24,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Icon(Icons.keyboard_arrow_down,
          color: Colors.white,)
        ),
      ): SizedBox(),
      items: widget.items.map((item) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: item,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8)
            ),
            child: Row(
              children: [
                // Image
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: AssetImage(item['image']),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Name
                Expanded(
                  child: Text(
                    item['name'],
                    style:  TextStyle(fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textColor),
                  ),
                ),

                Container(
                  height: 22,
                  width: 22,
                  decoration: BoxDecoration(
                    color: Color(0xFFc4c3c3),
                    shape: BoxShape.circle
                  ),
                  child: Icon(Icons.remove_circle, color: Colors.white, size: 15),

                )
                // Remove Icon
              ],
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedItem = value;
        });
      },
    );
  }
}