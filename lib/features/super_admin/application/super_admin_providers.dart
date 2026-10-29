import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/academy.dart';
import 'academy_repository_provider.dart';

/// Live list of all registered academies.
final academiesStreamProvider = StreamProvider<List<Academy>>(
  (ref) => ref.watch(academyRepositoryProvider).watchAll(),
);
