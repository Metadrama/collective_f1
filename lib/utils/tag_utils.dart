List<String> extractTags(String text) {
  final words = text.toLowerCase().split(RegExp(r'\s+')).where((w) => w.length > 4).toList();
  words.sort((a, b) => b.length.compareTo(a.length));
  return words.take(2).map((e) => '#$e').toList();
}
