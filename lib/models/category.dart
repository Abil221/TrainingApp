class Category {
  final String name;
  final String icon;
  final String emoji;
  final String description;

  const Category({
    required this.name,
    required this.icon,
    this.emoji = '',
    this.description = '',
  });
}