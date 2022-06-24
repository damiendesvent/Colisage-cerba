import 'package:flutter/material.dart';

const Color themeMainColor = Color.fromARGB(255, 40, 113, 177);
const Color themeSecondColor = Color.fromARGB(255, 124, 84, 215);

const Color myBarrierColor = Colors.black26;

ButtonStyle myButtonStyle = ButtonStyle(
  foregroundColor:
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    return states.contains(MaterialState.disabled) ? null : Colors.white;
  }),
  backgroundColor:
      MaterialStateProperty.resolveWith((Set<MaterialState> states) {
    return states.contains(MaterialState.disabled) ? null : themeMainColor;
  }),
);

SnackBar mySnackBar(Text text,
    {double width = 600,
    Color color = const Color(0xFF2e7d32),
    Icon icon = const Icon(
      Icons.check,
      color: Colors.white,
    ),
    SnackBarAction? action,
    int duration = 5}) {
  return SnackBar(
    width: width,
    backgroundColor: color,
    duration: Duration(seconds: duration),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    content: Row(
        mainAxisAlignment: MainAxisAlignment.center, children: [icon, text]),
    action: action,
  );
}
