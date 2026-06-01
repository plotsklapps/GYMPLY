import 'package:flutter/src/painting/text_style.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  final TextStyle style = GoogleFonts.getFont('League Gothic');
  print('Font Family: ${style.fontFamily}');
  final TextStyle style2 = GoogleFonts.getFont('Bebas Neue');
  print('Font Family: ${style2.fontFamily}');
}
