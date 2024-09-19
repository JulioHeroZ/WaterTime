class CustomAmount {
  final String id;
  int amount;

  CustomAmount({required this.id, required this.amount});

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
      };

  factory CustomAmount.fromJson(Map<String, dynamic> json) => CustomAmount(
        id: json['id'],
        amount: json['amount'],
      );
}
