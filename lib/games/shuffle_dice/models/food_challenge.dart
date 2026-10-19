class FoodChallengePreset {
  final String title;
  final String icon;
  final Map<int, String> rules;

  const FoodChallengePreset({
    required this.title,
    required this.icon,
    required this.rules,
  });

  static const List<FoodChallengePreset> presets = [
    FoodChallengePreset(
      title: 'Spicy Sauce Roulette',
      icon: '🌶️',
      rules: {
        1: 'Mild Dip (1 tiny drop)',
        2: 'Medium Heat (1 full spoon)',
        3: 'Double Dip in the Hot Sauce',
        4: 'SAFE! Drink milk / water',
        5: 'Spicy Dare! 2 huge bites',
        6: 'MEGA HOT! Full spoon & no drink for 1 min!',
      },
    ),
    FoodChallengePreset(
      title: 'Mystery Bites Game',
      icon: '🍔',
      rules: {
        1: 'Take 1 tiny nibble',
        2: 'Take 2 HUGE bites',
        3: 'Feed a bite to the player on your left',
        4: 'Dip your food into a mystery sauce',
        5: 'Blindfold bite (guess the ingredient)',
        6: 'Clean the plate / Finish the item!',
      },
    ),
    FoodChallengePreset(
      title: 'Eat or Drink Party',
      icon: '🍕',
      rules: {
        1: 'Take 1 sip of your drink',
        2: 'Eat 1 mouthful of food',
        3: 'Swap plates/drinks with someone',
        4: 'SAFE! Pass turn freely',
        5: 'Combine two food items into one bite',
        6: 'DOUBLE TROUBLE! 2 bites + 2 sips!',
      },
    ),
    FoodChallengePreset(
      title: 'Fast Food Picker',
      icon: '🍟',
      rules: {
        1: 'Eat 1 French Fry',
        2: 'Eat 1 Chicken Nugget / Wing',
        3: 'Take 1 Burger / Pizza Bite',
        4: 'Have 1 big Soda Gulp',
        5: 'Dip food in ketchup + mayo + mustard combo',
        6: 'Chef Special: Mix all items in 1 bite!',
      },
    ),
  ];
}
