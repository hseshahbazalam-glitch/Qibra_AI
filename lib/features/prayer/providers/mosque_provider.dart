// lib/features/prayer/providers/mosque_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mosque_model.dart';
import '../data/services/mosque_service.dart';
import 'prayer_provider.dart';

final nearbyMosquesProvider = FutureProvider.autoDispose<List<Mosque>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final lat = locationState.location?.latitude ?? 12.9716;
  final lon = locationState.location?.longitude ?? 77.5946;

  return await MosqueService.instance.getNearbyMosques(
    latitude: lat,
    longitude: lon,
  );
});

final selectedMosqueFilterProvider = StateProvider<String>((ref) => 'All');
