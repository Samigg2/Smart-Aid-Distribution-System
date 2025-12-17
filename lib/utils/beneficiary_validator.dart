class BeneficiaryValidator {
  /// Check if two categories conflict with each other
  static bool areCategoriesConflicting(String category1, String category2) {
    // Pregnant woman cannot be elderly (60+)
    if ((category1 == 'pregnant_woman' && category2 == 'elderly') ||
        (category1 == 'elderly' && category2 == 'pregnant_woman')) {
      return true;
    }

    // Lactating mother cannot be elderly (60+)
    if ((category1 == 'lactating_mother' && category2 == 'elderly') ||
        (category1 == 'elderly' && category2 == 'lactating_mother')) {
      return true;
    }

    // Child under 5 cannot be elderly (60+)
    if ((category1 == 'child_under_5' && category2 == 'elderly') ||
        (category1 == 'elderly' && category2 == 'child_under_5')) {
      return true;
    }

    // Pregnant woman and lactating mother are mutually exclusive
    if ((category1 == 'pregnant_woman' && category2 == 'lactating_mother') ||
        (category1 == 'lactating_mother' && category2 == 'pregnant_woman')) {
      return true;
    }

    return false;
  }

  /// Validate if a category can be added to the current selection
  static String? validateCategorySelection(
    String newCategory,
    Set<String> currentCategories,
    int? age,
  ) {
    // Check conflicts with existing categories
    for (final existingCategory in currentCategories) {
      if (areCategoriesConflicting(newCategory, existingCategory)) {
        return _getConflictMessage(newCategory, existingCategory);
      }
    }

    // Age-based validation
    if (newCategory == 'elderly' && age != null && age < 60) {
      return 'Elderly category requires age 60 or older';
    }

    if (newCategory == 'pregnant_woman' && age != null && age >= 60) {
      return 'Pregnant woman category requires age less than 60';
    }

    if (newCategory == 'lactating_mother' && age != null && age >= 60) {
      return 'Lactating mother category requires age less than 60';
    }

    if (newCategory == 'child_under_5' && age != null && age >= 5) {
      return 'Child under 5 category requires age less than 5';
    }

    return null; // No conflict
  }

  /// Get user-friendly conflict message
  static String _getConflictMessage(String category1, String category2) {
    if (category1 == 'pregnant_woman' && category2 == 'elderly') {
      return 'Pregnant woman cannot be elderly (60+)';
    }
    if (category1 == 'elderly' && category2 == 'pregnant_woman') {
      return 'Elderly (60+) cannot be pregnant';
    }

    if (category1 == 'lactating_mother' && category2 == 'elderly') {
      return 'Lactating mother cannot be elderly (60+)';
    }
    if (category1 == 'elderly' && category2 == 'lactating_mother') {
      return 'Elderly (60+) cannot be lactating mother';
    }

    if (category1 == 'child_under_5' && category2 == 'elderly') {
      return 'Child under 5 cannot be elderly (60+)';
    }
    if (category1 == 'elderly' && category2 == 'child_under_5') {
      return 'Elderly (60+) cannot be child under 5';
    }

    if (category1 == 'pregnant_woman' && category2 == 'lactating_mother') {
      return 'Cannot be both pregnant and lactating at the same time';
    }
    if (category1 == 'lactating_mother' && category2 == 'pregnant_woman') {
      return 'Cannot be both lactating and pregnant at the same time';
    }

    return 'These categories conflict with each other';
  }

  /// Validate all selected categories together
  static List<String> validateAllCategories(Set<String> categories, int? age) {
    final errors = <String>[];
    final categoryList = categories.toList();

    for (int i = 0; i < categoryList.length; i++) {
      for (int j = i + 1; j < categoryList.length; j++) {
        if (areCategoriesConflicting(categoryList[i], categoryList[j])) {
          errors.add(_getConflictMessage(categoryList[i], categoryList[j]));
        }
      }

      // Age validation for each category
      final ageError = validateCategorySelection(categoryList[i], {}, age);
      if (ageError != null && !ageError.contains('conflict')) {
        errors.add(ageError);
      }
    }

    return errors;
  }

  /// Get conflicting categories for a given category
  static List<String> getConflictingCategories(String category) {
    switch (category) {
      case 'pregnant_woman':
        return ['elderly', 'lactating_mother'];
      case 'lactating_mother':
        return ['elderly', 'pregnant_woman'];
      case 'child_under_5':
        return ['elderly'];
      case 'elderly':
        return ['pregnant_woman', 'lactating_mother', 'child_under_5'];
      default:
        return [];
    }
  }
}
