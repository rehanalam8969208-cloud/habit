import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:ui';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LevelUpApp());
}

class LevelUpApp extends StatelessWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Level Up Pro',
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.light,
        primaryColor: const Color(0xFF0284C7),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;

  const GlassCard({super.key, required this.child, required this.margin, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  spreadRadius: 1,
                )
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentTab = 0;
  int totalXP = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> todos = [];
  List<String> completedHabitsToday = [];

  final List<Map<String, dynamic>> defaultHabits = [
    {'id': 'h1', 'title': 'Wake up at 6:00 AM', 'points': 50},
    {'id': 'h2', 'title': 'Drink 2 Glasses of Water', 'points': 10},
    {'id': 'h3', 'title': 'Exercise & Workout', 'points': 40},
    {'id': 'h4', 'title': 'Learn English (30 mins)', 'points': 30},
    {'id': 'h5', 'title': 'Read a Book (30 mins)', 'points': 30},
    {'id': 'h6', 'title': 'Practice Silence & Speak Less', 'points': 20},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    final prefs = await SharedPreferences.getInstance();
    String today = DateTime.now().toString().substring(0, 10);
    String lastDate = prefs.getString('last_date') ?? '';

    String? habitsJson = prefs.getString('saved_habits');
    String? todosJson = prefs.getString('saved_todos');

    setState(() {
      totalXP = prefs.getInt('total_xp') ?? 0;

      if (habitsJson != null) habits = List<Map<String, dynamic>>.from(jsonDecode(habitsJson));
      else habits = List.from(defaultHabits);

      if (todosJson != null) todos = List<Map<String, dynamic>>.from(jsonDecode(todosJson));
      else todos = [];

      if (today != lastDate) {
        completedHabitsToday = [];
        prefs.setString('last_date', today);
        prefs.setStringList('completed_habits_today', []);
      } else {
        completedHabitsToday = prefs.getStringList('completed_habits_today') ?? [];
      }
      isLoading = false;
    });
  }

  Future<void> _saveAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('total_xp', totalXP);
    await prefs.setString('saved_habits', jsonEncode(habits));
    await prefs.setString('saved_todos', jsonEncode(todos));
    await prefs.setStringList('completed_habits_today', completedHabitsToday);
  }

  int get currentLevel => (totalXP ~/ 100) + 1;
  double get levelProgress => (totalXP % 100) / 100;

  void _toggleHabit(String id, int points) {
    setState(() {
      if (completedHabitsToday.contains(id)) {
        completedHabitsToday.remove(id);
        totalXP = (totalXP - points).clamp(0, 999999);
      } else {
        completedHabitsToday.add(id);
        totalXP += points;
      }
    });
    _saveAllData();
  }

  void _toggleTodo(int index) {
    setState(() {
      bool isDone = todos[index]['isDone'] ?? false;
      int points = todos[index]['points'] ?? 20;

      todos[index]['isDone'] = !isDone;
      if (!isDone) totalXP += points;
      else totalXP = (totalXP - points).clamp(0, 999999);
    });
    _saveAllData();
  }

  void _showAddDialog() {
    bool isHabit = _currentTab == 0;
    final titleController = TextEditingController();
    final pointsController = TextEditingController(text: "20");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF1F5F9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: Colors.white, width: 2)),
          title: Text(isHabit ? "Add New Habit" : "Add New To-Do", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: isHabit ? "e.g. Meditate" : "e.g. Finish Work",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: "XP Reward",
                  labelStyle: const TextStyle(color: Color(0xFF0284C7)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488)),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  int pts = int.tryParse(pointsController.text) ?? 20;
                  setState(() {
                    if (isHabit) habits.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': titleController.text.trim(), 'points': pts});
                    else todos.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': titleController.text.trim(), 'points': pts, 'isDone': false});
                  });
                  _saveAllData();
                  Navigator.pop(context);
                }
              },
              child: const Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showOptionsDialog(int index, bool isHabit) {
    final String currentTitle = isHabit ? habits[index]['title'] : todos[index]['title'];
    final int currentPts = isHabit ? habits[index]['points'] : todos[index]['points'];
    final titleController = TextEditingController(text: currentTitle);
    final pointsController = TextEditingController(text: currentPts.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassCard(
          margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isHabit ? "Edit / Delete Habit" : "Edit / Delete To-Do", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E293B))),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: "Title",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: "XP Reward",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          if (isHabit) habits.removeAt(index);
                          else todos.removeAt(index);
                        });
                        _saveAllData();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Save", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        if (titleController.text.isNotEmpty) {
                          setState(() {
                            int pts = int.tryParse(pointsController.text) ?? currentPts;
                            if (isHabit) {
                              habits[index]['title'] = titleController.text.trim();
                              habits[index]['points'] = pts;
                            } else {
                              todos[index]['title'] = titleController.text.trim();
                              todos[index]['points'] = pts;
                            }
                          });
                          _saveAllData();
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(backgroundColor: Color(0xFFE2E8F0), body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          // Light Foggy Blue Background Theme Gradient (Like the Lighthouse image)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF93C5FD), // Foggy sky blue
                  Color(0xFF60A5FA), // Mid blue
                  Color(0xFF3B82F6), // Deep ocean tone
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                GlassCard(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("MY DASHBOARD", style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.bold)),
                              SizedBox(height: 2),
                              Text("LevelUp Quest", style: TextStyle(color: Color(0xFF0F172A), fontSize: 26, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF0284C7), width: 1.5),
                            ),
                            child: Text(
                              "Level $currentLevel",
                              style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total XP: $totalXP", style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 16)),
                          Text("Next: ${(currentLevel * 100)} XP", style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: levelProgress,
                          minHeight: 12,
                          backgroundColor: Colors.white.withOpacity(0.5),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0D9488)),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: _currentTab == 0 ? _buildHabitsList() : _buildTodoList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF0D9488),
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: BottomAppBar(
            color: Colors.white.withOpacity(0.25),
            elevation: 0,
            shape: const CircularNotchedRectangle(),
            notchMargin: 10,
            child: SizedBox(
              height: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  MaterialButton(
                    minWidth: 80,
                    onPressed: () => setState(() => _currentTab = 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt_rounded, color: _currentTab == 0 ? const Color(0xFF0D9488) : const Color(0xFF475569), size: 28),
                        Text("Habits", style: TextStyle(color: _currentTab == 0 ? const Color(0xFF0D9488) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40),
                  MaterialButton(
                    minWidth: 80,
                    onPressed: () => setState(() => _currentTab = 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline_rounded, color: _currentTab == 1 ? const Color(0xFF0284C7) : const Color(0xFF475569), size: 26),
                        Text("To-Do", style: TextStyle(color: _currentTab == 1 ? const Color(0xFF0284C7) : const Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHabitsList() {
    if (habits.isEmpty) return const Center(child: Text("No Habits added.", style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold)));
    return ListView.builder(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final bool isDone = completedHabitsToday.contains(habit['id']);

        return GestureDetector(
          onTap: () => _toggleHabit(habit['id'], habit['points']),
          onLongPress: () => _showOptionsDialog(index, true),
          child: GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, color: isDone ? const Color(0xFF0D9488) : const Color(0xFF64748B), size: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit['title'], style: TextStyle(color: isDone ? const Color(0xFF94A3B8) : const Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold, decoration: isDone ? TextDecoration.lineThrough : null)),
                      const SizedBox(height: 4),
                      Text("+${todo['points']} XP Reward", style: const TextStyle(color: Color(0xFF475569), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
