import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit.dart';

class HabitManager {
  static List<Habit> habits = [];
  static late SharedPreferences _prefs;
  static final _habitsStreamController = StreamController<List<Habit>>.broadcast();
  static Stream<List<Habit>> get habitsStream => _habitsStreamController.stream;

  static void load() {
    _initSharedPreferences();
  }

  static Future<void> _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadHabitsFromPrefs();
  }

  static void _loadHabitsFromPrefs() {
    List<String> habitsJson = _prefs.getStringList('habits') ?? [];
    List<Map<String, dynamic>> habitsData = List<Map<String, dynamic>>.from(habitsJson.map((habit) => json.decode(habit)).toList());
    habits = habitsData.map((habitData) => Habit.fromJson(habitData)).toList();
    _habitsStreamController.add(habits);
  }

  static Future<void> _saveHabitsToPrefs() async {
    List<String> habitsJsonList =
        habits.map((habit) => json.encode(habit.toJson())).toList();
    await _prefs.setStringList('habits', habitsJsonList);
    _habitsStreamController.add(habits);
  }

  static void addHabit(Habit habit) {
    habits.add(habit);
    _saveHabitsToPrefs();
  }

  static List<Habit> getHabits() {
    return habits;
  }

  static List<Habit> getCompletableHabitsOnDay(DateTime day){
    return habits.where((element) => element.isCompletableOnDay(day)).toList();
  }

  static List<Habit> getCompletedHabitsOnDay(DateTime day){
    return habits.where((element) => element.completedOnDay(day)).toList();
  }

  static void reorderHabit(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    Habit habit = habits.removeAt(oldIndex);
    habits.insert(newIndex, habit);
    _habitsStreamController.add(habits);
    _saveHabitsToPrefs();
  }

  static void setHabitLastDayCompletion(String habitId, bool completed) {
    int index = habits.indexWhere((element) => element.id == habitId);
    if(habits[index].isCompletedToday() && !completed){
      habits[index].completionDates.removeLast();
    } else if(!habits[index].isCompletedToday() && completed){
      habits[index].completionDates.add(DateTime.now());
    }
    _saveHabitsToPrefs();
  }
}
