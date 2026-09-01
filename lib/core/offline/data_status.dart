// Honest data/service states. Unknown network is never "online".

import 'reachability.dart';

enum DataStatus {
  fresh,
  stale,
  unavailable,
  syncing,
  offline,
  failed,
  pendingSync,
}

enum ServicePlane { localOnly, networkAvailable, backendAvailable }

class ServiceAvailability {
  const ServiceAvailability({
    required this.reachability,
    this.backendEnabled = false,
    this.backendHealthy = false,
  });

  final ReachabilityState reachability;
  final bool backendEnabled;

  /// Never set true without a real health probe. Transport ≠ API.
  final bool backendHealthy;

  ServicePlane get plane {
    if (!reachability.mayUseNetwork) return ServicePlane.localOnly;
    if (!backendEnabled || !backendHealthy) {
      return ServicePlane.networkAvailable;
    }
    return ServicePlane.backendAvailable;
  }

  bool get canCallQibraApi => plane == ServicePlane.backendAvailable;

  static DataStatus fromCache({
    required CacheLikeFreshness freshness,
    required bool networkOnline,
  }) {
    switch (freshness) {
      case CacheLikeFreshness.missing:
        if (!networkOnline) return DataStatus.unavailable;
        return DataStatus.syncing;
      case CacheLikeFreshness.fresh:
        return DataStatus.fresh;
      case CacheLikeFreshness.stale:
        return DataStatus.stale;
      case CacheLikeFreshness.expired:
        return DataStatus.stale;
    }
  }
}

/// Decoupled from CacheFreshness so offline tests do not import cache I/O.
enum CacheLikeFreshness { missing, fresh, stale, expired }

enum AuthOfflineState {
  guest,
  cachedUnvalidated,
  refreshNeedsNetwork,
  localLogout,
}

abstract final class AuthOffline {
  static AuthOfflineState classify({
    required bool backendEnabled,
    required bool hasToken,
    required bool networkOnline,
    required bool accessExpired,
    required bool userRequestedLogout,
  }) {
    if (userRequestedLogout) return AuthOfflineState.localLogout;
    if (!backendEnabled || !hasToken) return AuthOfflineState.guest;
    if (accessExpired && !networkOnline) {
      return AuthOfflineState.refreshNeedsNetwork;
    }
    return AuthOfflineState.cachedUnvalidated;
  }

  static bool serverValidated({
    required bool networkOnline,
    required bool authenticated,
  }) =>
      networkOnline && authenticated;
}
