class category {
  final String id;
  final String name;

  category({required this.id, required this.name});
  factory category.fromMap(Map<String, dynamic> data) {
    return category(id: data['id'], name: data['name']);
  }
}
