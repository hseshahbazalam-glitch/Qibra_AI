// lib/features/prayer/presentation/mosque_finder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../data/models/mosque_model.dart';
import '../providers/mosque_provider.dart';
import '../providers/prayer_provider.dart';

class MosqueFinderScreen extends ConsumerStatefulWidget {
  const MosqueFinderScreen({super.key});

  @override
  ConsumerState<MosqueFinderScreen> createState() => _MosqueFinderScreenState();
}

class _MosqueFinderScreenState extends ConsumerState<MosqueFinderScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mosquesAsync = ref.watch(nearbyMosquesProvider);
    final currentFilter = ref.watch(selectedMosqueFilterProvider);
    final locationState = ref.watch(locationProvider);
    final cityName = locationState.location?.city ?? 'Bangalore';

    return Scaffold(
      backgroundColor: const Color(0xFF020A08),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071E16),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.go(AppRoutes.home),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nearby Mosques',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold)),
            Text('Masjids near $cityName',
                style: const TextStyle(color: Color(0xFF00E676), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00E676)),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(nearbyMosquesProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF071E16),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF143B2C)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded,
                      color: Color(0xFF00E676), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search mosque by name or area...',
                        hintStyle:
                            TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        border: InputBorder.none,
                      ),
                      onChanged: (val) => setState(
                          () => _searchQuery = val.trim().toLowerCase()),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildFilterPills(ref, currentFilter),
          const SizedBox(height: 8),
          Expanded(
            child: mosquesAsync.when(
              data: (mosques) {
                var filtered = mosques.where((m) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      m.name.toLowerCase().contains(_searchQuery) ||
                      m.address.toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;

                  if (currentFilter == 'Nearest') { return m.distanceKm <= 1.0; }
                  if (currentFilter == 'Women Area') { return m.hasWomenSection; }
                  if (currentFilter == 'Parking') { return m.hasParking; }
                  if (currentFilter == 'Accessible')
                    return m.isWheelchairAccessible;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No mosques match this filter',
                        style: TextStyle(color: Colors.white70)),
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final mosque = filtered[index];
                    return _buildMosqueCard(context, mosque);
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E676))),
              error: (err, _) => const Center(
                  child: Text('Error loading mosques',
                      style: TextStyle(color: Colors.white))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(WidgetRef ref, String currentFilter) {
    final filters = ['All', 'Nearest', 'Women Area', 'Parking', 'Accessible'];
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = currentFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(selectedMosqueFilterProvider.notifier).state = filter;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00E676)
                      : const Color(0xFF071E16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00E676)
                          : const Color(0xFF143B2C)),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF020A08)
                          : const Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMosqueCard(BuildContext context, Mosque mosque) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF061A13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF143B2C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2E21),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF16543D)),
                  ),
                  child: const Center(
                      child: Text('??', style: TextStyle(fontSize: 24))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              mosque.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: const Color(0xFF00E676)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              mosque.formattedDistance,
                              style: const TextStyle(
                                  color: Color(0xFF00E676),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(mosque.address,
                          style: const TextStyle(
                              color: Color(0xFF94A3B8), fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showJamaatTimetableModal(context, mosque),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B2E21),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF16543D)),
                      ),
                      child: const Center(
                        child: Text('Jama\'at Times',
                            style: TextStyle(
                                color: Color(0xFF00E676),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_rounded,
                            color: Color(0xFF020A08), size: 15),
                        SizedBox(width: 4),
                        Text('Get Directions',
                            style: TextStyle(
                                color: Color(0xFF020A08),
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showJamaatTimetableModal(BuildContext context, Mosque mosque) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF071E16),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final jamaatList = [
          {'name': 'Fajr', 'time': mosque.fajrJamaat ?? '05:15 AM'},
          {'name': 'Dhuhr', 'time': mosque.dhuhrJamaat ?? '01:15 PM'},
          {'name': 'Asr', 'time': mosque.asrJamaat ?? '04:15 PM'},
          {'name': 'Maghrib', 'time': mosque.maghribJamaat ?? '06:55 PM'},
          {'name': 'Isha', 'time': mosque.ishaJamaat ?? '08:15 PM'},
          {'name': 'Jummah', 'time': mosque.jummahJamaat ?? '01:30 PM'},
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(mosque.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...jamaatList.map((j) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                        color: const Color(0xFF03100B),
                        borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(j['name']!,
                            style: const TextStyle(
                                color: Color(0xFF00E676),
                                fontWeight: FontWeight.bold)),
                        Text(j['time']!,
                            style: const TextStyle(
                                color: Colors.white, fontFamily: 'monospace')),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
