// lib/features/prayer/providers/mosque_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/mosque_model.dart';
import '../data/services/mosque_service.dart';
import 'prayer_provider.dart';

final nearbyMosquesProvider =
    FutureProvider.autoDispose<List<Mosque>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final location = locationState.location;
  if (location == null) return const [];

  return MosqueService.instance.getNearbyMosques(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});

final selectedMosqueFilterProvider = StateProvider<String>((ref) => 'All');
