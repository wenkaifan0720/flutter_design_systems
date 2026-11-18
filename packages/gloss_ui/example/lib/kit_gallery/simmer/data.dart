/// Simmer's kitchen: its recipes, this week's plan and the shopping list it
/// makes. Every name and number here is made up for the example.
library;

import 'package:flutter/widgets.dart';

/// One ingredient of a recipe, for one serving.
@immutable
class SimmerIngredient {
  /// [amount] [unit] of [name], for one serving, found in [aisle].
  const SimmerIngredient(this.name, this.amount, this.unit, this.aisle);

  /// What it is.
  final String name;

  /// How much one serving needs; 0 for "to taste".
  final double amount;

  /// Its unit: g, ml, tbsp, or empty for a count.
  final String unit;

  /// Where it is in a shop.
  final String aisle;

  /// The amount for [servings], as a cook reads it.
  String amountFor(int servings) {
    if (amount == 0) return 'to taste';
    final total = amount * servings;
    final halves = (total * 2).round();
    final shown = total >= 10
        ? '${total.round()}'
        : halves.isEven
        ? '${halves ~/ 2}'
        : '${halves / 2}';
    return unit.isEmpty ? shown : '$shown $unit';
  }
}

/// A recipe.
@immutable
class SimmerRecipe {
  /// A recipe called [name].
  const SimmerRecipe({
    required this.id,
    required this.name,
    required this.blurb,
    required this.minutes,
    required this.serves,
    required this.kcal,
    required this.cuisine,
    required this.diets,
    required this.ingredients,
    required this.steps,
    required this.dish,
    required this.food,
  });

  /// Its id.
  final String id;

  /// Its name.
  final String name;

  /// One line on it.
  final String blurb;

  /// Minutes from start to table.
  final int minutes;

  /// The servings it is written for.
  final int serves;

  /// Calories a serving.
  final int kcal;

  /// Where it is from.
  final String cuisine;

  /// The diets it fits.
  final Set<String> diets;

  /// What goes in, a serving's worth each.
  final List<SimmerIngredient> ingredients;

  /// The method; a step with a timer says its minutes in [SimmerStep.timer].
  final List<SimmerStep> steps;

  /// The glaze of the dish it is served in.
  final Color dish;

  /// The colours of the food, for its picture.
  final List<Color> food;
}

/// One step of a method.
@immutable
class SimmerStep {
  /// A step saying [text], with a [timer] of that many minutes.
  const SimmerStep(this.text, {this.timer});

  /// What to do.
  final String text;

  /// Minutes to set a timer for.
  final int? timer;
}

/// The diets a person can choose.
const simmerDiets = ['Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free'];

/// The recipes.
const simmerRecipes = <SimmerRecipe>[
  SimmerRecipe(
    id: 'miso-aubergine',
    name: 'Miso-glazed aubergine',
    blurb: 'Soft halves under a sticky miso glaze, on sesame\u00A0rice.',
    minutes: 35,
    serves: 2,
    kcal: 520,
    cuisine: 'Japanese',
    diets: {'Vegetarian', 'Vegan', 'Dairy-free'},
    dish: Color(0xFF2F4A5C),
    food: [
      Color(0xFF5B2A4E),
      Color(0xFFC9873A),
      Color(0xFFF2EBDD),
      Color(0xFF6E9B4A),
    ],
    ingredients: [
      SimmerIngredient('Aubergine', 1, '', 'Produce'),
      SimmerIngredient('White miso', 1.5, 'tbsp', 'World foods'),
      SimmerIngredient('Maple syrup', 1, 'tsp', 'Pantry'),
      SimmerIngredient('Short-grain rice', 75, 'g', 'Pantry'),
      SimmerIngredient('Spring onions', 1, '', 'Produce'),
      SimmerIngredient('Sesame seeds', 1, 'tsp', 'Pantry'),
    ],
    steps: [
      SimmerStep(
        'Heat the oven to 200 °C. Halve the aubergines and score the flesh in a criss-cross.',
      ),
      SimmerStep('Roast cut side up until soft right through.', timer: 20),
      SimmerStep('Stir the miso with the maple syrup and a splash of water.'),
      SimmerStep(
        'Spread the glaze over the aubergines and grill until it bubbles.',
        timer: 4,
      ),
      SimmerStep('Serve on the rice with spring onions and sesame.'),
    ],
  ),
  SimmerRecipe(
    id: 'lemon-orzo',
    name: 'Lemon orzo with peas',
    blurb: 'One pan, bright and creamy, ready before the table is laid.',
    minutes: 20,
    serves: 4,
    kcal: 430,
    cuisine: 'Italian',
    diets: {'Vegetarian'},
    dish: Color(0xFFE9D9B8),
    food: [
      Color(0xFFF3E3A6),
      Color(0xFF7FB04A),
      Color(0xFFF8F2DC),
      Color(0xFFE8C547),
    ],
    ingredients: [
      SimmerIngredient('Orzo', 80, 'g', 'Pantry'),
      SimmerIngredient('Frozen peas', 60, 'g', 'Frozen'),
      SimmerIngredient('Lemon', 0.5, '', 'Produce'),
      SimmerIngredient('Parmesan', 15, 'g', 'Dairy'),
      SimmerIngredient('Vegetable stock', 200, 'ml', 'Pantry'),
      SimmerIngredient('Butter', 10, 'g', 'Dairy'),
    ],
    steps: [
      SimmerStep('Toast the orzo in the butter for a minute.'),
      SimmerStep('Add the stock a ladle at a time, stirring.', timer: 9),
      SimmerStep('Stir in the peas, lemon zest and juice, then the parmesan.'),
    ],
  ),
  SimmerRecipe(
    id: 'chickpea-curry',
    name: 'Chickpea and spinach curry',
    blurb: 'A weeknight curry from the cupboard, rich with coconut.',
    minutes: 30,
    serves: 4,
    kcal: 480,
    cuisine: 'Indian',
    diets: {'Vegetarian', 'Vegan', 'Gluten-free', 'Dairy-free'},
    dish: Color(0xFF9B3B2A),
    food: [
      Color(0xFFD9932F),
      Color(0xFF3F6B2E),
      Color(0xFFE9C46A),
      Color(0xFFF4EBD9),
    ],
    ingredients: [
      SimmerIngredient('Chickpeas', 120, 'g', 'Pantry'),
      SimmerIngredient('Coconut milk', 100, 'ml', 'World foods'),
      SimmerIngredient('Spinach', 50, 'g', 'Produce'),
      SimmerIngredient('Onion', 0.5, '', 'Produce'),
      SimmerIngredient('Curry paste', 1, 'tbsp', 'World foods'),
      SimmerIngredient('Basmati rice', 75, 'g', 'Pantry'),
    ],
    steps: [
      SimmerStep(
        'Soften the onion, then fry the paste until fragrant.',
        timer: 6,
      ),
      SimmerStep('Add chickpeas and coconut milk and simmer.', timer: 12),
      SimmerStep('Wilt in the spinach and season.'),
    ],
  ),
  SimmerRecipe(
    id: 'salmon-greens',
    name: 'Roast salmon, green beans',
    blurb: 'A tray of salmon and beans with a soy and ginger dressing.',
    minutes: 25,
    serves: 2,
    kcal: 560,
    cuisine: 'Modern',
    diets: {'Gluten-free', 'Dairy-free'},
    dish: Color(0xFFDCE4E8),
    food: [
      Color(0xFFF08A5D),
      Color(0xFF4F8A3C),
      Color(0xFFFFD8B5),
      Color(0xFF2E4A2A),
    ],
    ingredients: [
      SimmerIngredient('Salmon fillet', 1, '', 'Fish'),
      SimmerIngredient('Green beans', 100, 'g', 'Produce'),
      SimmerIngredient('Tamari', 1, 'tbsp', 'World foods'),
      SimmerIngredient('Ginger', 5, 'g', 'Produce'),
      SimmerIngredient('New potatoes', 150, 'g', 'Produce'),
    ],
    steps: [
      SimmerStep('Roast the potatoes first.', timer: 15),
      SimmerStep('Add salmon and beans to the tray.', timer: 10),
      SimmerStep('Spoon over the dressing to serve.'),
    ],
  ),
  SimmerRecipe(
    id: 'mushroom-ragu',
    name: 'Slow mushroom ragù',
    blurb: 'Deep and meaty without meat, over soft polenta.',
    minutes: 55,
    serves: 4,
    kcal: 510,
    cuisine: 'Italian',
    diets: {'Vegetarian', 'Gluten-free'},
    dish: Color(0xFF1F3B36),
    food: [
      Color(0xFF6B4A33),
      Color(0xFFE7C66B),
      Color(0xFF3E5B2B),
      Color(0xFFA0583A),
    ],
    ingredients: [
      SimmerIngredient('Chestnut mushrooms', 150, 'g', 'Produce'),
      SimmerIngredient('Tinned tomatoes', 100, 'g', 'Pantry'),
      SimmerIngredient('Polenta', 60, 'g', 'Pantry'),
      SimmerIngredient('Red wine', 40, 'ml', 'Drinks'),
      SimmerIngredient('Rosemary', 0, '', 'Produce'),
    ],
    steps: [
      SimmerStep('Brown the mushrooms hard in two batches.', timer: 10),
      SimmerStep('Add wine and tomatoes and simmer low.', timer: 30),
      SimmerStep('Whisk the polenta into boiling water.', timer: 5),
    ],
  ),
  SimmerRecipe(
    id: 'tofu-noodles',
    name: 'Crispy tofu noodles',
    blurb: 'Golden tofu, glossy noodles and a heap of herbs.',
    minutes: 25,
    serves: 2,
    kcal: 590,
    cuisine: 'Thai',
    diets: {'Vegetarian', 'Vegan', 'Dairy-free'},
    dish: Color(0xFFF3F1EC),
    food: [
      Color(0xFFE5B55B),
      Color(0xFFB8572B),
      Color(0xFF5E9E4F),
      Color(0xFFF0DFA8),
    ],
    ingredients: [
      SimmerIngredient('Firm tofu', 100, 'g', 'Chilled'),
      SimmerIngredient('Rice noodles', 75, 'g', 'World foods'),
      SimmerIngredient('Lime', 0.5, '', 'Produce'),
      SimmerIngredient('Coriander', 0, '', 'Produce'),
      SimmerIngredient('Peanuts', 15, 'g', 'Pantry'),
    ],
    steps: [
      SimmerStep('Press the tofu, then fry until golden.', timer: 8),
      SimmerStep('Soak the noodles.', timer: 5),
      SimmerStep('Toss everything with the sauce and herbs.'),
    ],
  ),
  SimmerRecipe(
    id: 'tomato-tart',
    name: 'Tomato and ricotta tart',
    blurb: 'Bought pastry, the best tomatoes, a lemony ricotta base.',
    minutes: 40,
    serves: 4,
    kcal: 470,
    cuisine: 'French',
    diets: {'Vegetarian'},
    dish: Color(0xFFB7C9C2),
    food: [
      Color(0xFFD9442E),
      Color(0xFFE9B949),
      Color(0xFFF6EFE0),
      Color(0xFF4B7F3A),
    ],
    ingredients: [
      SimmerIngredient('Puff pastry', 80, 'g', 'Chilled'),
      SimmerIngredient('Tomatoes', 120, 'g', 'Produce'),
      SimmerIngredient('Ricotta', 50, 'g', 'Dairy'),
      SimmerIngredient('Basil', 0, '', 'Produce'),
    ],
    steps: [
      SimmerStep('Score a border and bake the pastry blind.', timer: 12),
      SimmerStep(
        'Spread the ricotta, lay on the tomatoes and bake.',
        timer: 18,
      ),
    ],
  ),
  SimmerRecipe(
    id: 'black-bean-tacos',
    name: 'Black bean tacos',
    blurb: 'Smoky beans, quick-pickled onion, a crumble of feta.',
    minutes: 20,
    serves: 4,
    kcal: 450,
    cuisine: 'Mexican',
    diets: {'Vegetarian', 'Gluten-free'},
    dish: Color(0xFFD8873B),
    food: [
      Color(0xFF2B2A33),
      Color(0xFFC2457A),
      Color(0xFF7CB342),
      Color(0xFFF7F1E3),
    ],
    ingredients: [
      SimmerIngredient('Black beans', 100, 'g', 'Pantry'),
      SimmerIngredient('Corn tortillas', 2, '', 'Bakery'),
      SimmerIngredient('Red onion', 0.25, '', 'Produce'),
      SimmerIngredient('Feta', 20, 'g', 'Dairy'),
      SimmerIngredient('Avocado', 0.5, '', 'Produce'),
    ],
    steps: [
      SimmerStep('Pickle the onion in lime juice and salt.', timer: 10),
      SimmerStep('Warm the beans with spices and mash a little.'),
      SimmerStep('Char the tortillas and fill.'),
    ],
  ),
];

/// The recipe [id].
SimmerRecipe simmerRecipe(String id) =>
    simmerRecipes.firstWhere((r) => r.id == id);

/// The week's days, Monday first.
const simmerDays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// Today, as an index into [simmerDays]: the example is set on a Thursday.
const simmerToday = 3;

/// This week's dinners, by day; null for a night off.
const simmerWeek = <String?>[
  'lemon-orzo',
  'chickpea-curry',
  'tofu-noodles',
  'miso-aubergine',
  'black-bean-tacos',
  null,
  'mushroom-ragu',
];

/// A thing to buy.
class SimmerItem {
  /// [amount] of [name], from [aisle].
  SimmerItem(
    this.name,
    this.amount,
    this.aisle, {
    this.bought = false,
    this.addedByHand = false,
  });

  /// What it is.
  final String name;

  /// How much.
  final String amount;

  /// Where it is in a shop.
  final String aisle;

  /// Whether it is in the basket.
  bool bought;

  /// Whether this was added in the shopping field and stays when the plan changes.
  final bool addedByHand;
}

/// Combines the week's ingredients, including repeated dinners, for [servings] people.
/// Checked ingredients and handwritten extras carry over from [previous].
List<SimmerItem> simmerShoppingFor(
  Iterable<String?> week,
  int servings,
  List<SimmerItem> previous,
) {
  final amounts = <({String name, String unit, String aisle}), double>{};
  for (final id in week.whereType<String>()) {
    for (final ingredient in simmerRecipe(id).ingredients) {
      final key = (
        name: ingredient.name,
        unit: ingredient.unit,
        aisle: ingredient.aisle,
      );
      amounts.update(
        key,
        (value) => value + ingredient.amount,
        ifAbsent: () => ingredient.amount,
      );
    }
  }
  final bought = {
    for (final item in previous)
      if (!item.addedByHand && item.bought) (item.name, item.aisle),
  };
  return [
    for (final entry in amounts.entries)
      SimmerItem(
        entry.key.name,
        SimmerIngredient(
          entry.key.name,
          entry.value,
          entry.key.unit,
          entry.key.aisle,
        ).amountFor(servings),
        entry.key.aisle,
        bought: bought.contains((entry.key.name, entry.key.aisle)),
      ),
    ...previous.where((item) => item.addedByHand),
  ];
}

/// The shopping list this week's plan makes, in shop order.
List<SimmerItem> simmerShopping() => [
  SimmerItem('Aubergines', '2', 'Produce', bought: true),
  SimmerItem('Spring onions', '1 bunch', 'Produce', bought: true),
  SimmerItem('Spinach', '200 g', 'Produce'),
  SimmerItem('Lemons', '2', 'Produce'),
  SimmerItem('Limes', '2', 'Produce', bought: true),
  SimmerItem('Avocados', '2', 'Produce'),
  SimmerItem('Chestnut mushrooms', '600 g', 'Produce'),
  SimmerItem('Parmesan', '60 g', 'Dairy'),
  SimmerItem('Feta', '100 g', 'Dairy', bought: true),
  SimmerItem('Firm tofu', '200 g', 'Chilled'),
  SimmerItem('Orzo', '320 g', 'Pantry'),
  SimmerItem('Chickpeas', '2 tins', 'Pantry'),
  SimmerItem('Black beans', '1 tin', 'Pantry'),
  SimmerItem('Polenta', '250 g', 'Pantry'),
  SimmerItem('White miso', '1 tub', 'World foods'),
  SimmerItem('Coconut milk', '1 tin', 'World foods'),
  SimmerItem('Rice noodles', '150 g', 'World foods'),
  SimmerItem('Corn tortillas', '8', 'Bakery'),
];

/// The person using it.
const simmerOwner = (name: 'Noa Ferreira', email: 'noa@example.com');
