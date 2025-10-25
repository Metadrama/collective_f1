const List<String> availableMoods = [
  "😊", "😃", "😄", "😁", "😆", 
  "😐", "😌", "🙂", "😶", "😑",
  "😔", "😞", "😟", "😕", "🙁",
  "😢", "😭", "😤", "😡", "🤬",
  "😴", "😪", "🥱", "😵", "🤒",
  "😎", "🤩", "🥳", "😍", "🤗"
];

String analyzeMood(String text) {
  final lower = text.toLowerCase();
  if (lower.contains("happy") || lower.contains("excited") || lower.contains("love")) return "😊";
  if (lower.contains("tired") || lower.contains("ok") || lower.contains("fine")) return "😐";
  if (lower.contains("sad") || lower.contains("stress") || lower.contains("hate")) return "😔";
  return "😐";
}

String? selectedMood;

String getCurrentMood(String text) {
  return selectedMood ?? analyzeMood(text);
}
