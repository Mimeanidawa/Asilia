class TzsFormat {
  TzsFormat._();

  static String full(int value) {
    final text = value.toString();
    final buf = StringBuffer('TZS ');
    for (var i = 0; i < text.length; i++) {
      final pos = text.length - i;
      buf.write(text[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }
}
