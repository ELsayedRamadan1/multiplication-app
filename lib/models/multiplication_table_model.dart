class MultiplicationTable {
  final int number;
  final List<int> multiplications;

  MultiplicationTable(this.number)
      : multiplications = List.generate(12, (index) => number * (index + 1));

  int getResult(int multiplier) {
    if (multiplier < 1 || multiplier > 12) {
      throw ArgumentError('Multiplier must be between 1 and 12');
    }
    return number * multiplier;
  }
}
