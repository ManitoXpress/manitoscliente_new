class Subcategory {
  final String id;
  final String name;
  final String description;
  final String image;
  final String parentId; // Puede ser nulo si no tiene un padre

  Subcategory({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.parentId,
  });
}