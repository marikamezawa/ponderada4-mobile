import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/auth_state.dart';
import 'core/services/notification_service.dart';
import 'data/datasources/local_auth_datasource.dart';
import 'data/datasources/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega nomes e formatos de data usados nas telas em português.
  await initializeDateFormatting('pt_BR');

  // Desktop (Linux/Windows/macOS) precisa do FFI para o SQLite
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Abre o banco SQLite (cria o schema se for a primeira execução)
  await LocalDatabase.instance.database;

  // Restaura sessão de login entre reinicializações
  final currentUser = await LocalAuthDatasource().getCurrentUser();
  authState.value = currentUser != null;

  await NotificationService().initialize();

  runApp(const ProviderScope(child: ReggieApp()));
}
