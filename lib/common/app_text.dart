import 'package:flutter/cupertino.dart';

class AppText extends StatelessWidget {
  final String text;
  final GestureTapCallback? onClick;
  final Color? textColor;
  final double? fontSize;
  final int? maxLines;
  final TextStyle? style;

  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const AppText(
      this.text, {
        this.maxLines,
        this.overflow,
        this.textAlign,
        this.onClick,
        this.textColor,
        this.fontSize,
        this.style,
        super.key,
      });

  @override
  Widget build(BuildContext context) {
    TextStyle? appTextStyle;
    double defaultFontSize = 28;
    if (style == null) {
      appTextStyle = TextStyle(
        fontSize: fontSize ?? defaultFontSize,
        fontWeight: FontWeight.bold,
        fontStyle: FontStyle.normal,
        color: textColor,
        fontFamily: "My Fonts",
      );
    } else {
      appTextStyle = style?.copyWith(
        fontSize: style?.fontSize ?? defaultFontSize,
        fontWeight: style?.fontWeight ?? FontWeight.w400,
        fontStyle: style?.fontStyle ?? FontStyle.normal,
        color: style?.color,
        fontFamily: style?.fontFamily ?? "My Fonts",
      );
    }

    return GestureDetector(
      onTap: onClick,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        style: appTextStyle,
      ),
    );
  }
}