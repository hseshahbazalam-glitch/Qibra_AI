// Reachability: unknown ≠ online.

enum Reachability { online, offline, unknown }

class ReachabilityState {
  const ReachabilityState(this.value);
  final Reachability value;

  bool get isOnline => value == Reachability.online;
  bool get isOffline => value == Reachability.offline;
  bool get isUnknown => value == Reachability.unknown;

  /// Never treat unknown as online.
  bool get mayUseNetwork => value == Reachability.online;
}

abstract final class ReachabilityMapper {
  static ReachabilityState fromConnectivityLabels(Iterable<String> labels) {
    if (labels.isEmpty) return const ReachabilityState(Reachability.unknown);
    final none = labels.every((l) => l.toLowerCase() == 'none');
    if (none) return const ReachabilityState(Reachability.offline);
    final hasTransport = labels.any((l) {
      final v = l.toLowerCase();
      return v == 'wifi' || v == 'mobile' || v == 'ethernet' || v == 'vpn' || v == 'other';
    });
    if (hasTransport) return const ReachabilityState(Reachability.online);
    return const ReachabilityState(Reachability.unknown);
  }
}
