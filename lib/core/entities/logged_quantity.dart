/// Value object representing a quantity logged by the user with a specific unit.
class LoggedQuantity {
  const LoggedQuantity({
    required this.amount,
    required this.unit,
  });

  final double amount;
  final String unit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoggedQuantity &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          unit == other.unit;

  @override
  int get hashCode => amount.hashCode ^ unit.hashCode;

  @override
  String toString() => '$amount $unit';
}
