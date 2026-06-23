import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:reggieapp/core/utils/date_helper.dart';
import 'package:reggieapp/domain/entities/plant.dart';
import 'package:reggieapp/presentation/providers/notification_provider.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  test('cria lembretes de rega e adubação ordenados por data', () {
    final plant = Plant(
      id: 'plant-1',
      userId: 'user-1',
      name: 'Jiboia',
      waterFrequencyDays: 3,
      fertilizeFrequencyDays: 30,
      createdAt: DateTime(2026, 6, 1),
    );

    final reminders = buildCareReminders([plant]);

    expect(reminders, hasLength(2));
    expect(reminders.first.type, CareReminderType.water);
    expect(reminders.first.scheduledAt, DateTime(2026, 6, 4));
    expect(reminders.last.type, CareReminderType.fertilize);
    expect(reminders.last.scheduledAt, DateTime(2026, 7, 1));
  });

  test('formata a data do lembrete em português sem lançar erro', () {
    expect(DateHelper.formatDisplay(DateTime(2026, 6, 23)), '23/06/2026');
  });
}
