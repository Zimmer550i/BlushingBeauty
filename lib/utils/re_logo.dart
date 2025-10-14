import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ReeLogo extends StatelessWidget {
  final double size;
  const ReeLogo({super.key, this.size = 25});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset("assets/icons/re.svg", height: 35, width: 45);
  }
}
