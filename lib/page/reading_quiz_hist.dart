class _Record {
  String question;
  String answer;
  bool correct;

  _Record({required this.question, required this.answer, required this.correct});
}

class ReadingQuizHist {
  List<_Record> records = [];

  add(String question, String answer, bool correct) {
    records.add(_Record(question: question, answer: answer, correct: correct));
  }

  int get correctCount => records.where((e) => e.correct).length;

  int get wrongCount => records.where((e) => !e.correct).length;

  int get totalCount => records.length;

  List<_Record> getRecords() {
    return records;
  }

  reset() {
    records = [];
  }
}
