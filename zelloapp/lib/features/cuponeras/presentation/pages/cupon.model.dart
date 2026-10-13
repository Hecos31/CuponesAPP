class CuponModel {
  final String id;
  final String title;
  final String discount;
  final String description;
  final String terms;

  CuponModel({
    required this.id,
    required this.title,
    required this.discount,
    required this.description,
    required this.terms,
  });

  // Factory para mapear el JSON que recibas de FastAPI
  factory CuponModel.fromJson(Map<String, dynamic> json) {
    return CuponModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      discount: json['discount'] ?? '',
      description: json['description'] ?? '',
      terms: json['terms'] ?? '',
    );
  }
}