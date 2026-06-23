import 'package:flutter/foundation.dart';

// ValueNotifier global usado pelo GoRouter como refreshListenable.
// Atualizado pelo AuthNotifier em login/logout.
final authState = ValueNotifier<bool>(false);
