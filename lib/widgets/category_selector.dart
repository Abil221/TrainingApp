import 'package:flutter/material.dart';
import '../models/category.dart';

class CategorySelector extends StatelessWidget {
  final List<Category> categories;
  final int selectedIndex;
  final Function(int) onSelected;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90, // немного больше высота, чтобы текст и иконка помещались
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              padding: const EdgeInsets.all(8),
              width: 80, // фиксированная ширина карточки
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1E88E5) : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    category.icon,
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.name,
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500),
                    textAlign: TextAlign.center, // текст по центру
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis, // обрезает длинные названия
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}