/// Client-side mirror of docwellness-backend/utils/dietaryConstraintValidator.js
/// Gives the dietician instant feedback (e.g. Jain + Garlic) without a round
/// trip; the backend re-validates the same rules as the source of truth.
library;

class DietRule {
  final String label;
  final List<String> excludes;
  const DietRule(this.label, this.excludes);
}

const Map<String, DietRule> dietRules = {
  'Vegan': DietRule('Vegan', [
    'milk', 'dairy', 'paneer', 'cheese', 'curd', 'yogurt', 'yoghurt', 'ghee',
    'butter', 'cream', 'honey', 'egg', 'eggs', 'chicken', 'mutton', 'lamb',
    'beef', 'pork', 'fish', 'prawn', 'shrimp', 'crab', 'meat', 'gelatin',
    'mayonnaise', 'khoya', 'malai',
  ]),
  'Jain': DietRule('Jain', [
    'garlic', 'onion', 'potato', 'potatoes', 'sweet potato', 'ginger',
    'carrot', 'radish', 'beetroot', 'beet', 'mushroom', 'spring onion',
    'leek', 'shallot', 'yam', 'turnip',
  ]),
  'Vegetarian': DietRule('Vegetarian', [
    'chicken', 'mutton', 'lamb', 'beef', 'pork', 'fish', 'prawn', 'shrimp',
    'crab', 'meat', 'egg', 'eggs', 'gelatin', 'anchovy',
  ]),
  'Eggetarian': DietRule('Eggetarian', [
    'chicken', 'mutton', 'lamb', 'beef', 'pork', 'fish', 'prawn', 'shrimp',
    'crab', 'meat', 'gelatin', 'anchovy',
  ]),
  'Non-Vegetarian': DietRule('Non-Vegetarian', []),
};

const Map<String, DietRule> freeFromRules = {
  'sugar': DietRule('Sugar-free', [
    'sugar', 'jaggery', 'honey', 'syrup', 'brown sugar', 'powdered sugar', 'castor sugar',
  ]),
  'salt': DietRule('Salt-free', ['salt', 'soy sauce', 'soya sauce', 'pickle', 'papad']),
  'processedFood': DietRule('No processed ingredients', [
    'ketchup', 'mayonnaise', 'instant noodles', 'canned', 'packaged', 'processed cheese', 'soda', 'maida',
  ]),
  'oil': DietRule('Oil-free', ['oil', 'ghee', 'butter', 'margarine']),
};

bool _containsKeyword(String text, String keyword) {
  final escaped = RegExp.escape(keyword);
  final pattern = RegExp(r'\b' + escaped + r'\b', caseSensitive: false);
  return pattern.hasMatch(text);
}

/// Scans [text] (the Custom Ingredients/Preferences note) for keywords that
/// conflict with the currently-selected diet names and free-from keys.
/// Returns human-readable conflict messages, or an empty list if none.
List<String> findDietaryConflicts({
  required List<String> selectedDietNames,
  required List<String> selectedFreeFromKeys,
  required String text,
}) {
  if (text.trim().isEmpty) return [];

  final conflicts = <String>[];

  for (final dietName in selectedDietNames) {
    final rule = dietRules[dietName];
    if (rule == null) continue;
    for (final keyword in rule.excludes) {
      if (_containsKeyword(text, keyword)) {
        conflicts.add('"$keyword" is not allowed for the ${rule.label} diet.');
      }
    }
  }

  for (final key in selectedFreeFromKeys) {
    final rule = freeFromRules[key];
    if (rule == null) continue;
    for (final keyword in rule.excludes) {
      if (_containsKeyword(text, keyword)) {
        conflicts.add('"$keyword" conflicts with the ${rule.label} restriction.');
      }
    }
  }

  return conflicts;
}
