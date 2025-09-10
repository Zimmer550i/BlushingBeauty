import 'package:flutter/material.dart';
import 'package:ree_social_media_app/utils/app_colors.dart';

class CustomSwitch extends StatelessWidget {

  final bool value;
  final void Function(bool) onChanged;

  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });



  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        onChanged(!value);
      },
      child: Stack(
        children:[
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
            height: 20,
            width: 40,
            decoration: BoxDecoration(
                color: value?AppColors.primaryColor: Color(0xFFE6E6E6),
                borderRadius: BorderRadius.circular(16)
            ),

          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: 300),
            left: value? null: 2,
            right: value? 2: null,
            top: 2,
            bottom: 2,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF000000).withValues(alpha: 0.10),
                      blurRadius: 2.13,
                      spreadRadius: 0.8,
                      offset: Offset(0, 1.6),
                    ),
                  ]
              ),
            ),
          )
        ],
      ),
    );
  }
}