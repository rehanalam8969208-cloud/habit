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
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF3B82F6),
      ),
      home: const MainScreen(),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int tab = 0;
  int xp = 0;
  bool loading = true;
  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> todos = [];
  List<String> doneToday = [];

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
    load();
  }

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    String today = DateTime.now().toString().substring(0, 10);
    if (p.getString('date') != today) {
      doneToday = [];
      p.setString('date', today);
      p.setStringList('done', []);
    } else {
      doneToday = p.getStringList('done') ?? [];
    }
    setState(() {
      xp = p.getInt('xp') ?? 0;
      habits = p.containsKey('h') ? List<Map<String, dynamic>>.from(jsonDecode(p.getString('h')!)) : List.from(defaultHabits);
      todos = p.containsKey('t') ? List<Map<String, dynamic>>.from(jsonDecode(p.getString('t')!)) : [];
      loading = false;
    });
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    p.setInt('xp', xp);
    p.setString('h', jsonEncode(habits));
    p.setString('t', jsonEncode(todos));
    p.setStringList('done', doneToday);
  }

  int get lvl => (xp ~/ 100) + 1;

  void addDlg() {
    bool isH = tab == 0;
    final tc = TextEditingController();
    final pc = TextEditingController(text: "20");
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(isH ? "Add Habit" : "Add To-Do", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: tc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Title")),
            const SizedBox(height: 10),
            TextField(controller: pc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "XP Reward")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              if (tc.text.isNotEmpty) {
                setState(() {
                  var item = {'id': DateTime.now().toString(), 'title': tc.text, 'points': int.tryParse(pc.text) ?? 20};
                  if (isH) habits.add(item); else { item['isDone'] = false; todos.add(item); }
                });
                save();
                Navigator.pop(c);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void editDlg(int i, bool isH) {
    final tc = TextEditingController(text: isH ? habits[i]['title'] : todos[i]['title']);
    final pc = TextEditingController(text: (isH ? habits[i]['points'] : todos[i]['points']).toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(c).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isH ? "Edit Habit" : "Edit To-Do", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),
            TextField(controller: tc, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: pc, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "XP")),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () { setState(() { if(isH) habits.removeAt(i); else todos.removeAt(i); }); save(); Navigator.pop(c); }, child: const Text("Delete"))),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () { setState(() { int pt = int.tryParse(pc.text)??20; if(isH){habits[i]['title']=tc.text;habits[i]['points']=pt;}else{todos[i]['title']=tc.text;todos[i]['points']=pt;} }); save(); Navigator.pop(c); }, child: const Text("Save"))),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    var list = tab == 0 ? habits : todos;

    return Scaffold(
      extendBody: true,
      body: Container(
        color: const Color(0xFF0F172A),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("LevelUp Quest", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        Text("Lvl $lvl", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text("Total XP: $xp", style: const TextStyle(color: Colors.white75)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: (xp % 100) / 100, backgroundColor: Colors.black45, valueColor: const AlwaysStoppedAnimation(Color(0xFF10B981))),
                  ],
                ),
              ),
              Expanded(
                child: list.isEmpty ? Center(child: Text(tab == 0 ? "No Habits" : "No To-Do", style: const TextStyle(color: Colors.grey))) : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    var item = list[i];
                    bool done = tab == 0 ? doneToday.contains(item['id']) : (item['isDone'] ?? false);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          int pts = item['points'] ?? 20;
                          if (tab == 0) {
                            if (doneToday.contains(item['id'])) { doneToday.remove(item['id']); xp = (xp - pts).clamp(0, 9999); }
                            else { doneToday.add(item['id']); xp += pts; }
                          } else {
                            bool d = item['isDone'] ?? false;
                            item['isDone'] = !d;
                            if (!d) xp += pts; else xp = (xp - pts).clamp(0, 9999);
                          }
                        });
                        save();
                      },
                      onLongPress: () => editDlg(i, tab == 0),
                      child: GlassCard(
                        child: Row(
                          children: [
                            Icon(done ? Icons.check_circle : Icons.radio_button_unchecked, color: done ? const Color(0xFF10B981) : Colors.white60),
                            const SizedBox(width: 15),
                            Expanded(child: Text(item['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, decoration: done ? TextDecoration.lineThrough : null, color: done ? Colors.white38 : Colors.white))),
                            Text("+${item['points']} XP", style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: addDlg, backgroundColor: const Color(0xFF10B981), shape: const CircleBorder(), child: const Icon(Icons.add, color: Colors.white)),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF1E293B),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: Icon(Icons.bolt, color: tab == 0 ? const Color(0xFF10B981) : Colors.grey), onPressed: () => setState(() => tab = 0)),
            const SizedBox(width: 40),
            IconButton(icon: Icon(Icons.check_circle_outline, color: tab == 1 ? const Color(0xFF3B82F6) : Colors.grey), onPressed: () => setState(() => tab = 1)),
          ],
        ),
      ),
    );
  }
}
