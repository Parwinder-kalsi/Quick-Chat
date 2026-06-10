import 'package:flutter/material.dart';
import 'package:quick_chat/common/app_text.dart';
import 'package:quick_chat/themes/colors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: AppText(title),
      leading: leading,
      actions: actions,
      centerTitle: true,
      backgroundColor:AppColors.darkGreenColor,
    );
  }
  @override
  Size get preferredSize => const Size.fromHeight(70);
}
