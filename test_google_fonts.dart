import 'package:google_fonts/google_fonts.dart';

void main() {
  var style = GoogleFonts.getFont('League Gothic');
  print('Font Family: ${style.fontFamily}');
  var style2 = GoogleFonts.getFont('Bebas Neue');
  print('Font Family: ${style2.fontFamily}');
}
