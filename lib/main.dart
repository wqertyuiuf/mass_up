import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MassUpApp());
}

// ============================================================
// APP
// ============================================================

class MassUpApp extends StatelessWidget {
  const MassUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MassUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D12),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B5CF6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AppLoader(),
    );
  }
}

// ============================================================
// LOADER
// ============================================================

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool loading = true;
  Map<String, dynamic>? profile;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('profile');

    if (saved != null) {
      profile = jsonDecode(saved);
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (profile == null) {
      return const ProfileSetupScreen();
    }

    return MainScreen(
      sex: profile!['sex'],
      age: profile!['age'],
      height: (profile!['height'] as num).toDouble(),
      weight: (profile!['weight'] as num).toDouble(),
      activity: (profile!['activity'] as num).toDouble(),
      calories: profile!['calories'],
      protein: profile!['protein'],
      fat: profile!['fat'],
      carbs: profile!['carbs'],
    );
  }
}

// ============================================================
// PROFILE SETUP
// ============================================================

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() =>
      _ProfileSetupScreenState();
}

class _ProfileSetupScreenState
    extends State<ProfileSetupScreen> {
  String sex = 'Мужской';

  final ageController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();

  double activity = 1.2;

  double? parse(String value) {
    return double.tryParse(
      value.replaceAll(',', '.').trim(),
    );
  }

  Future<void> createProfile() async {
    final age = int.tryParse(
      ageController.text.trim(),
    );

    final height = parse(heightController.text);
    final weight = parse(weightController.text);

    if (age == null ||
        height == null ||
        weight == null ||
        age <= 0 ||
        height <= 0 ||
        weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполни все поля правильно'),
        ),
      );
      return;
    }

    final targets = calculateTargets(
      sex: sex,
      age: age,
      height: height,
      weight: weight,
      activity: activity,
    );

    final profile = {
      'sex': sex,
      'age': age,
      'height': height,
      'weight': weight,
      'activity': activity,
      'calories': targets.calories,
      'protein': targets.protein,
      'fat': targets.fat,
      'carbs': targets.carbs,
    };

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'profile',
      jsonEncode(profile),
    );

    await saveWeightHistory(weight);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          sex: sex,
          age: age,
          height: height,
          weight: weight,
          activity: activity,
          calories: targets.calories,
          protein: targets.protein,
          fat: targets.fat,
          carbs: targets.carbs,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MassUp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            const Text(
              'Создадим твой профиль',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Это понадобится для расчёта калорий и БЖУ.',
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Пол',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: sex,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Мужской',
                  child: Text('Мужской'),
                ),
                DropdownMenuItem(
                  value: 'Женский',
                  child: Text('Женский'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    sex = value;
                  });
                }
              },
            ),

            const SizedBox(height: 20),

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Возраст',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Рост, см',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Вес, кг',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Активность',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            DropdownButtonFormField<double>(
              value: activity,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 1.2,
                  child: Text('Минимальная'),
                ),
                DropdownMenuItem(
                  value: 1.375,
                  child: Text('Низкая'),
                ),
                DropdownMenuItem(
                  value: 1.55,
                  child: Text('Средняя'),
                ),
                DropdownMenuItem(
                  value: 1.725,
                  child: Text('Высокая'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    activity = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton(
                onPressed: createProfile,
                child: const Text(
                  'Начать',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// MAIN SCREEN
// ============================================================

class MainScreen extends StatefulWidget {
  final String sex;
  final int age;
  final double height;
  final double weight;
  final double activity;

  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  const MainScreen({
    super.key,
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.activity,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;

  List<Food> foods = [];
  List<WeightEntry> weightHistory = [];

  @override
  void initState() {
    super.initState();
    loadFoods();
    loadWeightHistory();
  }

  // ----------------------------------------------------------
  // FOOD STORAGE
  // ----------------------------------------------------------

  Future<void> loadFoods() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('foods');

    if (saved == null) return;

    final List<dynamic> decoded = jsonDecode(saved);

    setState(() {
      foods = decoded
          .map(
            (item) => Food.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  Future<void> saveFoods() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'foods',
      jsonEncode(
        foods.map((food) => food.toJson()).toList(),
      ),
    );
  }

  Future<void> addFood(Food food) async {
    setState(() {
      foods.add(food);
    });

    await saveFoods();
  }

  Future<void> updateFood(
    int index,
    Food newFood,
  ) async {
    final oldFood = todayFoods[index];

    final realIndex = foods.indexOf(oldFood);

    if (realIndex == -1) return;

    setState(() {
      foods[realIndex] = newFood;
    });

    await saveFoods();
  }

  Future<void> deleteFood(int index) async {
    final food = todayFoods[index];

    setState(() {
      foods.remove(food);
    });

    await saveFoods();
  }

  // ----------------------------------------------------------
  // DATE
  // ----------------------------------------------------------

  String get today {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  List<Food> get todayFoods {
    return foods
        .where(
          (food) => food.date == today,
        )
        .toList();
  }

  // ----------------------------------------------------------
  // TODAY MACROS
  // ----------------------------------------------------------

  int get eatenCalories {
    return todayFoods.fold(
      0,
      (sum, food) => sum + food.calories,
    );
  }

  int get eatenProtein {
    return todayFoods.fold(
      0,
      (sum, food) => sum + food.protein,
    );
  }

  int get eatenFat {
    return todayFoods.fold(
      0,
      (sum, food) => sum + food.fat,
    );
  }

  int get eatenCarbs {
    return todayFoods.fold(
      0,
      (sum, food) => sum + food.carbs,
    );
  }

  // ----------------------------------------------------------
  // WEIGHT HISTORY
  // ----------------------------------------------------------

  Future<void> loadWeightHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final saved =
        prefs.getString('weight_history');

    if (saved == null) return;

    final List<dynamic> decoded =
        jsonDecode(saved);

    setState(() {
      weightHistory = decoded
          .map(
            (item) => WeightEntry.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  Future<void> saveWeightHistoryList() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'weight_history',
      jsonEncode(
        weightHistory
            .map((item) => item.toJson())
            .toList(),
      ),
    );
  }

  Future<void> addWeightToHistory(
    double weight,
  ) async {
    final date = formatDate(DateTime.now());

    final existingIndex = weightHistory.indexWhere(
      (entry) => entry.date == date,
    );

    final newEntry = WeightEntry(
      date: date,
      weight: weight,
    );

    setState(() {
      if (existingIndex >= 0) {
        weightHistory[existingIndex] = newEntry;
      } else {
        weightHistory.add(newEntry);
      }

      weightHistory.sort(
        (a, b) => a.date.compareTo(b.date),
      );
    });

    await saveWeightHistoryList();
  }

  // ----------------------------------------------------------
  // UPDATE WEIGHT
  // ----------------------------------------------------------

  Future<void> updateWeight(
    double newWeight,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final profileString =
        prefs.getString('profile');

    if (profileString == null) return;

    final profile =
        Map<String, dynamic>.from(
      jsonDecode(profileString),
    );

    profile['weight'] = newWeight;

    final targets = calculateTargets(
      sex: widget.sex,
      age: widget.age,
      height: widget.height,
      weight: newWeight,
      activity: widget.activity,
    );

    profile['calories'] = targets.calories;
    profile['protein'] = targets.protein;
    profile['fat'] = targets.fat;
    profile['carbs'] = targets.carbs;

    await prefs.setString(
      'profile',
      jsonEncode(profile),
    );

    await addWeightToHistory(newWeight);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MainScreen(
          sex: widget.sex,
          age: widget.age,
          height: widget.height,
          weight: newWeight,
          activity: widget.activity,
          calories: targets.calories,
          protein: targets.protein,
          fat: targets.fat,
          carbs: targets.carbs,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // UI
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final pages = [
      TodayPage(
        calories: widget.calories,
        protein: widget.protein,
        fat: widget.fat,
        carbs: widget.carbs,
        eatenCalories: eatenCalories,
        eatenProtein: eatenProtein,
        eatenFat: eatenFat,
        eatenCarbs: eatenCarbs,
        foods: todayFoods,
        onDelete: deleteFood,
        onEdit: (index) async {
          final oldFood = todayFoods[index];

          final edited =
              await Navigator.push<Food>(
            context,
            MaterialPageRoute(
              builder: (_) => AddFoodScreen(
                existingFood: oldFood,
              ),
            ),
          );

          if (edited != null) {
            await updateFood(
              index,
              edited,
            );
          }
        },
        onAddFood: () async {
          final food =
              await Navigator.push<Food>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddFoodScreen(),
            ),
          );

          if (food != null) {
            await addFood(food);
          }
        },
      ),

      StatisticsPage(
        weight: widget.weight,
        targetCalories: widget.calories,
        eatenCalories: eatenCalories,
        weightHistory: weightHistory,
      ),

      ProfilePage(
        sex: widget.sex,
        age: widget.age,
        height: widget.height,
        weight: widget.weight,
        calories: widget.calories,
        protein: widget.protein,
        fat: widget.fat,
        carbs: widget.carbs,
        onWeightChanged: updateWeight,
      ),
    ];

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Сегодня',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TODAY
// ============================================================

class TodayPage extends StatelessWidget {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  final int eatenCalories;
  final int eatenProtein;
  final int eatenFat;
  final int eatenCarbs;

  final List<Food> foods;

  final VoidCallback onAddFood;
  final Future<void> Function(int) onDelete;
  final Future<void> Function(int) onEdit;

  const TodayPage({
    super.key,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.eatenCalories,
    required this.eatenProtein,
    required this.eatenFat,
    required this.eatenCarbs,
    required this.foods,
    required this.onAddFood,
    required this.onDelete,
    required this.onEdit,
  });

  double progress(
    int current,
    int target,
  ) {
    if (target <= 0) return 0;

    return (current / target).clamp(
      0.0,
      1.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              10,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Сегодня',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: onAddFood,
                    icon: const Icon(
                      Icons.add_circle,
                      size: 34,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            sliver: SliverToBoxAdapter(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Text(
                        'Калории',
                        style: TextStyle(
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$eatenCalories / $calories ккал',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      LinearProgressIndicator(
                        value: progress(
                          eatenCalories,
                          calories,
                        ),
                        minHeight: 10,
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: MacroCard(
                      title: 'Белки',
                      current: eatenProtein,
                      target: protein,
                      unit: 'г',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MacroCard(
                      title: 'Жиры',
                      current: eatenFat,
                      target: fat,
                      unit: 'г',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MacroCard(
                      title: 'Углеводы',
                      current: eatenCarbs,
                      target: carbs,
                      unit: 'г',
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Дневник',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${foods.length} приёмов',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (foods.isEmpty)
            const SliverPadding(
              padding: EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(25),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.restaurant_outlined,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Сегодня пока ничего не добавлено',
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Нажми +, чтобы добавить еду',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final food = foods[index];

                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: ListTile(
                      onTap: () {
                        onEdit(index);
                      },
                      leading: CircleAvatar(
                        child: Text(
                          '${food.grams}',
                        ),
                      ),
                      title: Text(
                        food.name,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${food.grams} г • '
                        '${food.protein} Б • '
                        '${food.fat} Ж • '
                        '${food.carbs} У',
                      ),
                      trailing: Row(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Text(
                            '${food.calories} ккал',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                onEdit(index);
                              }

                              if (value == 'delete') {
                                onDelete(index);
                              }
                            },
                            itemBuilder:
                                (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Изменить',
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete,
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      'Удалить',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: foods.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MACRO CARD
// ============================================================

class MacroCard extends StatelessWidget {
  final String title;
  final int current;
  final int target;
  final String unit;

  const MacroCard({
    super.key,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '$current/$target',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STATISTICS
// ============================================================

class StatisticsPage extends StatelessWidget {
  final double weight;
  final int targetCalories;
  final int eatenCalories;
  final List<WeightEntry> weightHistory;

  const StatisticsPage({
    super.key,
    required this.weight,
    required this.targetCalories,
    required this.eatenCalories,
    required this.weightHistory,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Статистика',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Текущий вес',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weight.toStringAsFixed(1)} кг',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Калории сегодня',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$eatenCalories / $targetCalories ккал',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Динамика веса',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: SizedBox(
                height: 260,
                child: weightHistory.length < 2
                    ? Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.show_chart,
                              size: 55,
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            const Text(
                              'Недостаточно данных',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            Text(
                              'Изменяй вес хотя бы несколько раз,\n'
                              'чтобы появился график.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color: Colors
                                    .grey
                                    .shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : WeightChart(
                        entries: weightHistory,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (weightHistory.isNotEmpty)
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(15),
                child: Column(
                  children: [
                    for (final entry
                        in weightHistory.reversed
                            .take(5))
                      ListTile(
                        leading: const Icon(
                          Icons.monitor_weight,
                        ),
                        title: Text(
                          '${entry.weight.toStringAsFixed(1)} кг',
                        ),
                        trailing: Text(
                          formatReadableDate(
                            entry.date,
                          ),
                          style: TextStyle(
                            color:
                                Colors.grey.shade500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// WEIGHT CHART
// ============================================================

class WeightChart extends StatelessWidget {
  final List<WeightEntry> entries;

  const WeightChart({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WeightChartPainter(
        entries: entries,
        textColor:
            Theme.of(context).textTheme.bodyMedium?.color ??
                Colors.white,
        gridColor:
            Theme.of(context).dividerColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class WeightChartPainter extends CustomPainter {
  final List<WeightEntry> entries;
  final Color textColor;
  final Color gridColor;

  WeightChartPainter({
    required this.entries,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (entries.length < 2) return;

    final sorted = [...entries]
      ..sort(
        (a, b) => a.date.compareTo(b.date),
      );

    final values =
        sorted.map((e) => e.weight).toList();

    final minValue =
        values.reduce((a, b) => a < b ? a : b);

    final maxValue =
        values.reduce((a, b) => a > b ? a : b);

    final range =
        (maxValue - minValue).abs() < 0.1
            ? 1.0
            : maxValue - minValue;

    const left = 45.0;
    const right = 15.0;
    const top = 20.0;
    const bottom = 35.0;

    final chartWidth =
        size.width - left - right;

    final chartHeight =
        size.height - top - bottom;

    final paintLine = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = const Color(0xFF8B5CF6)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.25)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y =
          top + chartHeight * i / 4;

      canvas.drawLine(
        Offset(left, y),
        Offset(size.width - right, y),
        gridPaint,
      );
    }

    final path = Path();

    for (int i = 0;
        i < sorted.length;
        i++) {
      final x = sorted.length == 1
          ? left
          : left +
              chartWidth *
                  i /
                  (sorted.length - 1);

      final normalized =
          (values[i] - minValue) / range;

      final y =
          top +
              chartHeight -
              normalized * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      paintLine,
    );

    for (int i = 0;
        i < sorted.length;
        i++) {
      final x = sorted.length == 1
          ? left
          : left +
              chartWidth *
                  i /
                  (sorted.length - 1);

      final normalized =
          (values[i] - minValue) / range;

      final y =
          top +
              chartHeight -
              normalized * chartHeight;

      canvas.drawCircle(
        Offset(x, y),
        5,
        paintDot,
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text:
              '${values[i].toStringAsFixed(1)}',
          style: TextStyle(
            color: textColor,
            fontSize: 11,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(
        canvas,
        Offset(
          x - textPainter.width / 2,
          y - 24,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant WeightChartPainter oldDelegate,
  ) {
    return oldDelegate.entries != entries;
  }
}

// ============================================================
// PROFILE
// ============================================================

class ProfilePage extends StatelessWidget {
  final String sex;
  final int age;
  final double height;
  final double weight;

  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  final Future<void> Function(double)
      onWeightChanged;

  const ProfilePage({
    super.key,
    required this.sex,
    required this.age,
    required this.height,
    required this.weight,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.onWeightChanged,
  });

  Future<void> changeWeight(
    BuildContext context,
  ) async {
    final controller =
        TextEditingController(
      text: weight.toString(),
    );

    final result =
        await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Изменить вес'),
          content: TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(
              decimal: true,
            ),
            decoration:
                const InputDecoration(
              labelText: 'Вес, кг',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final value =
                    double.tryParse(
                  controller.text
                      .replaceAll(',', '.'),
                );

                if (value != null &&
                    value > 0) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text('Сохранить'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      await onWeightChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Профиль',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Пол'),
                  trailing: Text(sex),
                ),
                ListTile(
                  title: const Text('Возраст'),
                  trailing: Text('$age лет'),
                ),
                ListTile(
                  title: const Text('Рост'),
                  trailing: Text(
                    '${height.toStringAsFixed(0)} см',
                  ),
                ),
                ListTile(
                  title: const Text('Вес'),
                  trailing: Text(
                    '${weight.toStringAsFixed(1)} кг',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                changeWeight(context);
              },
              icon: const Icon(Icons.edit),
              label: const Text(
                'Изменить вес',
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Твои цели',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.local_fire_department,
                  ),
                  title: const Text('Калории'),
                  trailing: Text(
                    '$calories ккал',
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.fitness_center,
                  ),
                  title: const Text('Белки'),
                  trailing: Text(
                    '$protein г',
                  ),
                ),
                ListTile(
                  title: const Text('Жиры'),
                  trailing: Text(
                    '$fat г',
                  ),
                ),
                ListTile(
                  title: const Text('Углеводы'),
                  trailing: Text(
                    '$carbs г',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ADD / EDIT FOOD
// ============================================================

class AddFoodScreen extends StatefulWidget {
  final Food? existingFood;

  const AddFoodScreen({
    super.key,
    this.existingFood,
  });

  @override
  State<AddFoodScreen> createState() =>
      _AddFoodScreenState();
}

class _AddFoodScreenState
    extends State<AddFoodScreen> {
  late final TextEditingController nameController;
  late final TextEditingController caloriesController;
  late final TextEditingController proteinController;
  late final TextEditingController fatController;
  late final TextEditingController carbsController;
  late final TextEditingController gramsController;

  @override
  void initState() {
    super.initState();

    final food = widget.existingFood;

    nameController =
        TextEditingController(
      text: food?.name ?? '',
    );

    gramsController =
        TextEditingController(
      text: food?.grams.toString() ?? '',
    );

    if (food != null && food.grams > 0) {
      final multiplier =
          food.grams / 100;

      caloriesController =
          TextEditingController(
        text:
            (food.calories / multiplier)
                .toStringAsFixed(1),
      );

      proteinController =
          TextEditingController(
        text:
            (food.protein / multiplier)
                .toStringAsFixed(1),
      );

      fatController =
          TextEditingController(
        text:
            (food.fat / multiplier)
                .toStringAsFixed(1),
      );

      carbsController =
          TextEditingController(
        text:
            (food.carbs / multiplier)
                .toStringAsFixed(1),
      );
    } else {
      caloriesController =
          TextEditingController();

      proteinController =
          TextEditingController();

      fatController =
          TextEditingController();

      carbsController =
          TextEditingController();
    }
  }

  double? parse(String value) {
    return double.tryParse(
      value.replaceAll(',', '.').trim(),
    );
  }

  void saveFood() {
    final name =
        nameController.text.trim();

    final calories = parse(
      caloriesController.text,
    );

    final protein = parse(
      proteinController.text,
    );

    final fat = parse(
      fatController.text,
    );

    final carbs = parse(
      carbsController.text,
    );

    final grams = parse(
      gramsController.text,
    );

    if (name.isEmpty ||
        calories == null ||
        protein == null ||
        fat == null ||
        carbs == null ||
        grams == null ||
        grams <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Заполни все поля'),
        ),
      );
      return;
    }

    final multiplier =
        grams / 100;

    final date =
        widget.existingFood?.date ??
            formatDate(DateTime.now());

    Navigator.pop(
      context,
      Food(
        name: name,
        grams: grams.round(),
        calories:
            (calories * multiplier).round(),
        protein:
            (protein * multiplier).round(),
        fat:
            (fat * multiplier).round(),
        carbs:
            (carbs * multiplier).round(),
        date: date,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing =
        widget.existingFood != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing
              ? 'Изменить еду'
              : 'Добавить еду',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Название продукта',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: caloriesController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText:
                    'Калории на 100 г',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: proteinController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText:
                    'Белки на 100 г',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: fatController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText:
                    'Жиры на 100 г',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: carbsController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText:
                    'Углеводы на 100 г',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: gramsController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Сколько съел, г',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: saveFood,
                icon: Icon(
                  editing
                      ? Icons.save
                      : Icons.add,
                ),
                label: Text(
                  editing
                      ? 'Сохранить изменения'
                      : 'Добавить',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TARGETS
// ============================================================

Targets calculateTargets({
  required String sex,
  required int age,
  required double height,
  required double weight,
  required double activity,
}) {
  double bmr;

  if (sex == 'Мужской') {
    bmr =
        10 * weight +
        6.25 * height -
        5 * age +
        5;
  } else {
    bmr =
        10 * weight +
        6.25 * height -
        5 * age -
        161;
  }

  final maintenance =
      bmr * activity;

  final calories =
      (maintenance + 300).round();

  final protein =
      (weight * 2).round();

  final fat =
      (weight * 1).round();

  final remainingCalories =
      calories -
      protein * 4 -
      fat * 9;

  final carbs =
      (remainingCalories / 4).round();

  return Targets(
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
  );
}

class Targets {
  final int calories;
  final int protein;
  final int fat;
  final int carbs;

  Targets({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

// ============================================================
// FOOD MODEL
// ============================================================

class Food {
  final String name;
  final int grams;
  final int calories;
  final int protein;
  final int fat;
  final int carbs;
  final String date;

  Food({
    required this.name,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'grams': grams,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
      'date': date,
    };
  }

  factory Food.fromJson(
    Map<String, dynamic> json,
  ) {
    return Food(
      name: json['name'] ?? '',
      grams: json['grams'] ?? 0,
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      fat: json['fat'] ?? 0,
      carbs: json['carbs'] ?? 0,
      date: json['date'] ?? '',
    );
  }
}

// ============================================================
// WEIGHT MODEL
// ============================================================

class WeightEntry {
  final String date;
  final double weight;

  WeightEntry({
    required this.date,
    required this.weight,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'weight': weight,
    };
  }

  factory WeightEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return WeightEntry(
      date: json['date'] ?? '',
      weight:
          (json['weight'] as num).toDouble(),
    );
  }
}

// ============================================================
// HELPERS
// ============================================================

String formatDate(DateTime date) {
  return '${date.year}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatReadableDate(String date) {
  final parts = date.split('-');

  if (parts.length != 3) {
    return date;
  }

  return '${parts[2]}.${parts[1]}.${parts[0]}';
}

// ============================================================
// INITIAL WEIGHT HISTORY
// ============================================================

Future<void> saveWeightHistory(
  double weight,
) async {
  final prefs =
      await SharedPreferences.getInstance();

  final saved =
      prefs.getString('weight_history');

  List<WeightEntry> history = [];

  if (saved != null) {
    final List<dynamic> decoded =
        jsonDecode(saved);

    history = decoded
        .map(
          (item) => WeightEntry.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  final date =
      formatDate(DateTime.now());

  final index = history.indexWhere(
    (entry) => entry.date == date,
  );

  final entry = WeightEntry(
    date: date,
    weight: weight,
  );

  if (index >= 0) {
    history[index] = entry;
  } else {
    history.add(entry);
  }

  history.sort(
    (a, b) => a.date.compareTo(b.date),
  );

  await prefs.setString(
    'weight_history',
    jsonEncode(
      history.map((e) => e.toJson()).toList(),
    ),
  );
}