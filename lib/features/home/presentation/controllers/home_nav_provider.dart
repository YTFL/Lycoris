import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Manages the selected bottom navigation bar index across the app
final homeNavIndexProvider = StateProvider<int>((ref) => 0);
