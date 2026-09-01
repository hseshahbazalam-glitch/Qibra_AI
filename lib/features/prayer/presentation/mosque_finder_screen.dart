// lib/features/prayer/presentation/mosque_finder_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';
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
    final colors = QibraColors.of(context);
    final mosquesAsync = ref.watch(nearbyMosquesProvider);
    final currentFilter = ref.watch(selectedMosqueFilterProvider);
    final locationState = ref.watch(locationProvider);
    final cityName = locationState.location?.city;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: colors.textPrimary, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.more);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nearby Mosques',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              cityName == null || cityName.isEmpty
                  ? 'Requires your location'
                  : 'Near $cityName',
              style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: colors.primary),
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
                color: colors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search by name or address',
                        hintStyle: AppTextStyles.bodySmall
                            .copyWith(color: colors.textTertiary),
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
                if (!locationState.hasLocation) {
                  return QibraEmptyState(
                    icon: Icons.place_outlined,
                    title: 'Location needed',
                    message:
                        'Set your location to look up nearby mosques from OpenStreetMap.',
                    actionLabel: 'Use current location',
                    onAction: () {
                      ref.read(locationProvider.notifier).fetchCurrentLocation();
                    },
                  );
                }

                if (mosques.isEmpty) {
                  return const QibraEmptyState(
                    icon: Icons.mosque_outlined,
                    title: 'No mosques found',
                    message:
                        'OpenStreetMap did not return mosques near this location.',
                  );
                }

                final filtered = mosques.where((m) {
                  final matchesSearch = _searchQuery.isEmpty ||
                      m.name.toLowerCase().contains(_searchQuery) ||
                      m.address.toLowerCase().contains(_searchQuery);
                  if (!matchesSearch) return false;
                  if (currentFilter == 'Nearest') return m.distanceKm <= 1.0;
                  if (currentFilter == 'Women Area') return m.hasWomenSection;
                  if (currentFilter == 'Parking') return m.hasParking;
                  if (currentFilter == 'Accessible') {
                    return m.isWheelchairAccessible;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const QibraEmptyState(
                    icon: Icons.filter_alt_outlined,
                    title: 'No matches',
                    message:
                        'No listed mosque has this tagged amenity or name.',
                  );
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _buildMosqueCard(context, filtered[index]);
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: colors.primary),
              ),
              error: (err, _) => const QibraEmptyState(
                icon: Icons.error_outline,
                title: 'Could not load mosques',
                message: 'The map lookup failed. Try again later.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(WidgetRef ref, String currentFilter) {
    final colors = QibraColors.of(context);
    const filters = ['All', 'Nearest', 'Women Area', 'Parking', 'Accessible'];
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
                  color: isSelected ? colors.primary : colors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.primary : colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected
                          ? colors.onPrimary
                          : colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
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
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
                  ),
                  child: Icon(Icons.mosque_rounded,
                      color: colors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              mosque.name,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mosque.formattedDistance,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mosque.hasAddress ? mosque.address : 'Address not available',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (mosque.hasJamaatTimes)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: InkWell(
                onTap: () => _showJamaatTimetableModal(context, mosque),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
                  ),
                  child: Center(
                    child: Text(
                      "Jama'at Times",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showJamaatTimetableModal(BuildContext context, Mosque mosque) {
    final colors = QibraColors.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final jamaatList = [
          {'name': 'Fajr', 'time': mosque.fajrJamaat ?? 'Not available'},
          {'name': 'Dhuhr', 'time': mosque.dhuhrJamaat ?? 'Not available'},
          {'name': 'Asr', 'time': mosque.asrJamaat ?? 'Not available'},
          {'name': 'Maghrib', 'time': mosque.maghribJamaat ?? 'Not available'},
          {'name': 'Isha', 'time': mosque.ishaJamaat ?? 'Not available'},
          {'name': 'Jummah', 'time': mosque.jummahJamaat ?? 'Not available'},
        ];

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mosque.name,
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ...jamaatList.map(
                (j) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        j['name']!,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        j['time']!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
