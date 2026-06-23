import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/notification_service.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/plant.dart';
import 'plant_provider.dart';

enum CareReminderType { water, fertilize }

class CareReminder {
  final String plantId;
  final String plantName;
  final CareReminderType type;
  final DateTime scheduledAt;

  const CareReminder({
    required this.plantId,
    required this.plantName,
    required this.type,
    required this.scheduledAt,
  });

  String get title => switch (type) {
    CareReminderType.water => 'Hora de regar! 💧',
    CareReminderType.fertilize => 'Hora de adubar! 🌱',
  };

  String get message => switch (type) {
    CareReminderType.water =>
      '$plantName está com sede. Não se esqueça de regar.',
    CareReminderType.fertilize =>
      '$plantName precisa de nutrientes. Hora de adubar.',
  };

  bool isDueAt(DateTime now) => !scheduledAt.isAfter(now);
}

List<CareReminder> buildCareReminders(List<Plant> plants) {
  final reminders = <CareReminder>[];
  for (final plant in plants) {
    reminders
      ..add(
        CareReminder(
          plantId: plant.id,
          plantName: plant.name,
          type: CareReminderType.water,
          scheduledAt: plant.nextWateringDate,
        ),
      )
      ..add(
        CareReminder(
          plantId: plant.id,
          plantName: plant.name,
          type: CareReminderType.fertilize,
          scheduledAt: plant.nextFertilizingDate,
        ),
      );
  }
  reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  return reminders;
}

final careRemindersProvider = Provider<AsyncValue<List<CareReminder>>>((ref) {
  return ref.watch(plantListProvider).whenData(buildCareReminders);
});

final dueRemindersCountProvider = Provider<int>((ref) {
  final reminders = ref.watch(careRemindersProvider).valueOrNull ?? const [];
  final now = DateTime.now();
  return reminders.where((reminder) => reminder.isDueAt(now)).length;
});

final sharedPreferencesProvider = FutureProvider<LocalDatasource>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return LocalDatasource(prefs);
});

final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>((ref) {
      return NotificationsEnabledNotifier(ref);
    });

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final Ref _ref;

  NotificationsEnabledNotifier(this._ref) : super(true) {
    _load();
  }

  Future<void> _load() async {
    final local = await _ref.read(sharedPreferencesProvider.future);
    state = local.notificationsEnabled;
  }

  Future<void> toggle(bool enabled) async {
    state = enabled;
    final local = await _ref.read(sharedPreferencesProvider.future);
    await local.setNotificationsEnabled(enabled);
    if (!enabled) {
      await NotificationService().cancelAll();
    }
  }
}
