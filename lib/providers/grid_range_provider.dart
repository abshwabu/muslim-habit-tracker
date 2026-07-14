import 'package:flutter_riverpod/legacy.dart';

/// Number of days to show in the habit grid. Default: 30.
final gridRangeProvider = StateProvider<int>((ref) => 30);
