import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF3B82F6),
      ),
      home: const MainNavigationScreen(),
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

      if (habitsJson != null) {
        habits = List<Map<String, dynamic>>.from(jsonDecode(habitsJson));
      } else {
        habits = List.from(defaultHabits);
      }

      if (todosJson != null) {
        todos = List<Map<String, dynamic>>.from(jsonDecode(todosJson));
      } else {
        todos = [];
      }

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
        totalXP -= points;
        if (totalXP < 0) totalXP = 0;
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
      if (!isDone) {
        totalXP += points;
      } else {
        totalXP -= points;
        if (totalXP < 0) totalXP = 0;
      }
    });
    _saveAllData();
  }

  void _showAddDialog(bool isHabit) {
    final titleController = TextEditingController();
    final pointsController = TextEditingController(text: "20");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isHabit ? "Add New Habit" : "Add New To-Do", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: isHabit ? "e.g. Meditate" : "e.g. Finish Work",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "XP Reward",
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  int pts = int.tryParse(pointsController.text) ?? 20;
                  setState(() {
                    if (isHabit) {
                      habits.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': titleController.text.trim(), 'points': pts});
                    } else {
                      todos.add({'id': DateTime.now().millisecondsSinceEpoch.toString(), 'title': titleController.text.trim(), 'points': pts, 'isDone': false});
                    }
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
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isHabit ? "Edit / Delete Habit" : "Edit / Delete To-Do", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: pointsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "XP Reward",
                  labelStyle: const TextStyle(color: Colors.blueAccent),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        setState(() {
                          if (isHabit) {
                            habits.removeAt(index);
                          } else {
                            todos.removeAt(index);
                          }
                        });
                        _saveAllData();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(vertical: 12)),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text("Save Changes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("My Dashboard", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text("LevelUp Quest", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                        ),
                        child: Text(
                          "Level $currentLevel",
                          style: const TextStyle(color: Color(0xFF60A5FA), fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total XP: $totalXP", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("Next Level: ${(currentLevel * 100)} XP", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: levelProgress,
                      minHeight: 10,
                      backgroundColor: const Color(0xFF0F172A),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: _currentTab == 0 ? _buildHabitsList() : _buildTodoList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(_currentTab == 0),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(_currentTab == 0 ? "Add Habit" : "Add To-Do", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTab,
        onTap: (index) => setState(() => _currentTab = index),
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF10B981),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.bolt_rounded), label: "Habits"),
          BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline_rounded), label: "To-Do"),
        ],
      ),
    );
  }

  Widget _buildHabitsList() {
    if (habits.isEmpty) {
      return const Center(child: Text("No Habits added. Tap 'Add Habit' to create one!", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        final String id = habit['id'];
        final bool isDone = completedHabitsToday.contains(id);

        return GestureDetector(
          onTap: () => _toggleHabit(id, habit['points']),
          onLongPress: () => _showOptionsDialog(index, true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDone ? const Color(0xFF10B981) : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isDone ? const Color(0xFF10B981) : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit['title'],
                        style: TextStyle(
                          color: isDone ? Colors.grey : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("+${habit['points']} XP Reward", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  isDone ? "DONE" : "CLAIM",
                  style: TextStyle(
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w900,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodoList() {
    if (todos.isEmpty) {
      return const Center(child: Text("No To-Do items. Tap 'Add To-Do' to create one!", style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        final bool isDone = todo['isDone'] ?? false;

        return GestureDetector(
          onTap: () => _toggleTodo(index),
          onLongPress: () => _showOptionsDialog(index, false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDone ? const Color(0xFF10B981) : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                Icon(
                  isDone ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  color: isDone ? const Color(0xFF10B981) : Colors.grey,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo['title'],
                        style: TextStyle(
                          color: isDone ? Colors.grey : Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text("+${todo['points']} XP Reward", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                ),
                Text(
                  isDone ? "COMPLETED" : "DO IT",
                  style: TextStyle(
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFF60A5FA),
                    fontWeight: FontWeight.w900,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}                        
