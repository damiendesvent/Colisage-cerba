import 'package:flutter/material.dart';

const Color themeColor = Color.fromARGB(255, 25, 111, 187);

ButtonStyle myButtonStyle = ButtonStyle(
  foregroundColor:
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    return states.contains(MaterialState.disabled) ? null : Colors.white;
  }),
  backgroundColor:
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    return states.contains(MaterialState.disabled) ? null : themeColor;
  }),
);

SnackBar mySnackBar(Text text,
    {double width = 600,
    Color color = const Color(0xFF2e7d32),
    Icon icon = const Icon(
      Icons.check,
      color: Colors.white,
    ),
    SnackBarAction? action}) {
  return SnackBar(
    width: width,
    backgroundColor: color,
    duration: const Duration(seconds: 5),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    content: Row(
        mainAxisAlignment: MainAxisAlignment.center, children: [icon, text]),
    action: action,
  );
}
