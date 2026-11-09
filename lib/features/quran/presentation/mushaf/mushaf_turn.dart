// lib/features/quran/presentation/mushaf/mushaf_turn.dart
// ============================================================
// QIBRA AI — MUSHAF PAGE-TURN ENGINE (Pass M)
//
// The premium ask: turning a mushaf page by hand must FEEL like a
// book — not a carousel slide. No pub.dev flip package is allowed in
// this pass (the sandbox cannot vet one), so this is the house
// 'page-lift' model built from first principles: drag-tracked
// foreshortening with a perspective hinge, dynamic light on the
// lifting leaf, a cast shadow that rides the moving edge, a gilded
// fore-edge that exists ONLY for the duration of a turn, and a quiet
// spine on the binding side. Full shader-curl math is deliberately
// not attempted — lift + shadow carry ~90% of the physical read at
// 60fps and stay fully controllable.
//
// PASS M2 (device-jank contract, pinned by the M suite):
//   • Page content is built EXACTLY TWICE per turn — once, when the
//     direction latches — and never again while the finger moves.
//   • Drag ticks write a ValueNotifier<double>; an AnimatedBuilder
//     re-applies transforms/shading around the latched widgets. No
//     setState runs per tick, so no content build, no layout pass of
//     SelectableText/RichText while the page is in flight.
//   • The moving shadow and gild bands are fixed-size layers slid by
//     Transform.translate (composition only — no relayout per frame).
//   • In-motion renders use the host's non-selectable twin when it
//     supplies one (a moving page is never selectable by hand).
//
// PASS M3 (turn lifeline — device-caught hotfix):
//   The settle controller is created EXACTLY ONCE, in initState, and
//   disposed EXACTLY ONCE, in dispose(). A per-call
//   dispose-then-recreate on a SingleTickerProviderStateMixin state
//   throws on the second ticker creation (the mixin's slot is a
//   lifetime lease) — that is the device's second-turn crash, and the
//   disposed-field cascade that followed it. Re-settling is now a
//   RETARGET of the one controller; the tick/status listeners are
//   attached once, in initState, and never again.
//
// PASS M4 — feel + edge fidelity (deliberate retune):
//   E (edge-cut): the leaf's rectangular ClipRect chopped the
//   perspective-MAGNIFIED free edge (the lifted side renders up to
//   1/(1 − p·w·cosθ) taller than the box — a few px at 400 logical
//   px, more on wide devices), so the gilded side visibly lost its
//   corners mid-turn. The clip is now a CustomClipper over the leaf's
//   EXACT projected quad with a 1.2px inflation and antiAlias — the
//   clip hugs the paper and only clips what is not page. The cast-
//   shadow band also no longer paints a hard alpha fringe 8px onto
//   the far side of the fold: it feathers to transparent within its
//   own bounds and its trailing edge stops AT the free edge.
//   W (turn physics): the fixed 200/240 ms curve settles are replaced
//   by a CRITICALLY-DAMPED SPRING retargeted from the release frame —
//   finger velocity carries into the settle (momentum, then a
//   deliberate exponential landing; no bounce, no snap). The physics
//   is FRAME-RATE INDEPENDENT (real per-tick dt, fixed 1/120 s
//   substeps, dt clamped at 48 ms — 60 Hz and 120 Hz land the same
//   page). Drag start gains a 3px anticipation micro-lift and the cast
//   shadow grows with the same envelope; the commit haptic moves from
//   the release DECISION to the settle LANDING (lightImpact at the
//   thump — never at drag start); the revealed base page gets a ≤8px
//   parallax chase on the gild's sine envelope, back to zero at commit
//   so the swap frame carries no offset.
//
// RTL TRUTH (measured against this repo, not against vibes):
//   The codex is bound RIGHT, so the free edge is the LEFT edge: a
//   forward turn lifts it and sweeps RIGHT onto the right-hand stack.
//   That is the exact mirror of a Latin book (which lifts its RIGHT
//   edge and sweeps LEFT) and exactly what this app's pager already
//   pins ('reverse: true — left-edge swipe advances', the Q2
//   direction group). The pass brief's one-line sketch described the
//   LATIN motion while telling me to do the opposite of Latin — the
//   contradiction is disclosed in the report; the physical + pinned
//   truth wins and the Pass M test pins it. Direction is hardcoded
//   here on purpose: a mushaf never reorders itself by locale.
//
// Coexistence model: the PageView stays the settled source of truth
// (slider, jumpToPage, ayah→page mapping, the _saveProgress hook, all
// Q2 direction pins — untouched). This overlay claims only horizontal
// drags while idle and enabled; taps and vertical scrolls fall
// through unchanged. A commit lands as a bare jumpToPage — the leaf
// animation has already visually completed the move, so there is no
// double slide and no frame where both layers disagree.
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';

enum MushafTurnDirection { forward, backward }

/// Pure, testable turn math — no widgets, no state. Kept in its own
/// class so the pass test can pin every threshold without pumping.
abstract final class MushafTurnGeometry {
  /// The hinge perspective entry fed to the leaf matrix (M4: shared
  /// by the render AND the quad clipper — one source, no drift).
  static const double perspective = 0.0009;

  /// Drag fraction (of the viewport width) at which a released turn
  /// commits on position alone.
  static const double commitFraction = 0.42;

  /// Horizontal velocity (px/s, SIGNED IN THE TURN DIRECTION) that
  /// commits regardless of travelled distance.
  static const double commitVelocity = 520;

  /// The lift never quite reaches 90° — a hair of page stays on screen
  /// so the swap frame carries content, not a zero-width clip.
  static const double maxAngle = math.pi / 2 * 0.98;

  static double clampT(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// t ∈ [0,1] → the leaf's projected width fraction, anchored at the
  /// spine (screen right). Both directions are the SAME physical page
  /// at angle θ: forward θ = t·maxAngle (leaving), backward
  /// θ = (1−t)·maxAngle (arriving) — width is cos θ either way.
  static double leafWidthFrac(MushafTurnDirection dir, double t) =>
      math.max(0.02, math.cos(angleFor(dir, t)));

  /// The moving (free) edge's x as a fraction of width, measured from
  /// the left. Forward: 0 → 1 (the page's left edge travels RIGHT —
  /// never left; this is the RTL assertion the test pins).
  static double freeEdgeFrac(MushafTurnDirection dir, double t) =>
      1.0 - leafWidthFrac(dir, t);

  static double angleFor(MushafTurnDirection dir, double t) =>
      dir == MushafTurnDirection.forward
          ? clampT(t) * maxAngle
          : (1 - clampT(t)) * maxAngle;

  /// Commit iff far enough OR fast enough — but a decisive FLICK BACK
  /// always declines (the finger outranks the threshold).
  static bool commits(
    MushafTurnDirection dir,
    double t,
    double velocityX,
  ) {
    // Forward = dragged rightwards (positive dx); backward = leftwards.
    final signed = dir == MushafTurnDirection.forward
        ? velocityX
        : -velocityX;
    if (signed <= -commitVelocity) return false;
    return t >= commitFraction || signed >= commitVelocity;
  }

  // ── Pass M4 (W3/W5): the two motion envelopes ────────────────
  /// One shared 0→1→0 envelope: peaks mid-turn, exactly zero at the
  /// touch-down frame AND at commit — so nothing (lift, parallax)
  /// survives into the swap frame or rests on the settled page.
  static double swell(double t) => math.sin(math.pi * clampT(t));

  /// W3: micro-lift of the free edge while the drag lives (px).
  static double anticipation(double t) => 3.0 * swell(t);

  /// W5: the revealed page chases the leaf by ≤8px, same envelope as
  /// the gild band's inset breathe — coordinated depth, zero at commit.
  static double parallax(double t) => 8.0 * swell(t);

  /// THE leaf matrix (M4): built in one place so the clipper and the
  /// render can never disagree about the quad.
  static Matrix4 leafTransform(double angle, {double lift = 0}) =>
      Matrix4.identity()
          // Gentle depth: at full-page width a stronger entry
          // (0.0015+) visibly bows the far edge — 0.0009 reads as
          // paper, not as a lens.
          ..setEntry(3, 0, perspective)
          ..rotateY(-angle)
          ..translate(0.0, -lift);

  /// The leaf rect's four corners as RenderTransform will project them
  /// (alignment centerRight — the hinge). Pure, closed-form, no matrix
  /// allocations: the SAME math RenderTransform applies (rotate about
  /// the hinge, then divide by 1 + perspective·x) — so the clip the
  /// painter builds and the paper actually drawn can never drift.
  static List<Offset> projectedCorners(
      double w, double h, double angle, double lift) {
    final cosA = math.cos(angle);
    Offset p(double x, double y) {
      final xr = (x - w) * cosA;
      final wr = 1 + perspective * xr;
      return Offset(xr / wr + w, (y - h / 2 - lift) / wr + h / 2);
    }
    return [p(0, 0), p(w, 0), p(w, h), p(0, h)];
  }
}

/// Pass M4 (W1/W2): the settle physics — a critically damped spring
/// integrated at FIXED 1/120 s substeps from each frame's REAL dt, so
/// 60 Hz and 120 Hz screens land identically. Pure numbers: the pass
/// test pins the trajectory properties without pumping a widget.
abstract final class MushafTurnPhysics {
  /// Angular frequency (rad/s) driving a COMMIT toward the next page —
  /// ω = 34 lands the ~230 ms commit time the old fixed easeOutCubic
  /// settle had, but now FROM WHATEVER VELOCITY THE FINGER LEFT.
  static const double kCommit = 34.0;

  /// Slightly softer for a RETRACT — the page eases back onto the
  /// stack instead of snapping (≈270 ms, minus the easeOutBack bounce
  /// the spring deliberately does not do: a mushaf never pings).
  static const double kRetract = 30.0;

  /// Critical damping: velocity-continuous and monotonic — momentum
  /// carries out of the finger, then decays exponentially.
  static const double zeta = 1.0;

  /// The sim runs on fixed substeps for frame-rate determinism.
  static const double stepDt = 1 / 120;

  /// A stalled frame (backgrounded app, GC hitch) must not teleport the
  /// page — real dt above this is clamped.
  static const double maxDt = 0.048;

  /// Converged when inside the swap's visual epsilon, at rest.
  static bool converged(double x, double v, double target) =>
      (x - target).abs() < 0.004 && v.abs() < 0.05;

  /// One substep of semi-implicit Euler (energy-stable at these ω).
  static (double, double) step(
      double x, double v, double target, double omega, double dt) {
    final k = omega * omega;
    final c = 2 * omega * zeta;
    final a = -k * (x - target) - c * v;
    final v1 = v + a * dt;
    return (x + v1 * dt, v1);
  }

  /// Integrate one ANIMATION FRAME of real elapsed dt (seconds) —
  /// clamped, then substepped at stepDt. 60 Hz hands 1/60 and lands
  /// where 120 Hz hands 1/120 twice.
  static (double, double) advanceFrame(
      double x, double v, double target, double omega, double dt) {
    var left = dt < 0 ? 0.0 : (dt > maxDt ? maxDt : dt);
    var (xx, vv) = (x, v);
    while (left > 1e-9) {
      final h = left > stepDt ? stepDt : left;
      (xx, vv) = step(xx, vv, target, omega, h);
      left -= h;
    }
    return (xx, vv);
  }

  /// Seconds to settle from rest at an ω — the pin that keeps the
  /// retune in the 'deliberate' band (test asserts both ω land in it).
  static double settleTimeFromRest(double omega) {
    var x = 0.0, v = 0.0, t = 0.0;
    while (!converged(x, v, 1) && t < 10) {
      (x, v) = step(x, v, 1, omega, stepDt);
      t += stepDt;
    }
    return t;
  }
}

/// Every shading value one animated frame derives from t — gathered in
/// one place so 'the detail reads after any theme' (M2) is a property
/// of the numbers, not a coincidence. Alpha bands are deliberately
/// mid-range: visible on both light cards and the navy dark theme.
abstract final class MushafTurnShading {
  static double lightOnLeaf(double t) => 0.14 * math.sin(math.pi * t);
  /// W3: the drop GROWS as the leaf lifts (the same swell envelope as
  /// the anticipation), then retracts through the settle.
  static double castShadowAlpha(double t) =>
      0.30 * (1 - 0.55 * t) + 0.10 * MushafTurnGeometry.swell(t);
  static double gildAlpha(double t) => 0.85 * math.sin(math.pi * t);
  static double spineCrease(double t) => 0.10 + 0.08 * t;
}

/// Wraps the settled pager and renders the hand-turn layer above it.
class MushafTurnOverlay extends StatefulWidget {
  const MushafTurnOverlay({
    super.key,
    required this.child,
    required this.currentPage,
    required this.pageCount,
    required this.pageAt,
    this.pageAtStatic,
    required this.onCommitPage,
    this.enabled = true,
  });

  /// The settled pager (the screen's PageView) — never rebuilt here.
  final Widget child;

  /// 1-based settled page (whatever the PageView currently shows).
  final int currentPage;
  final int pageCount;

  /// Builds a page's content for ANY page number — the screen passes
  /// the EXACT same builder the PageView's itemBuilder uses, so leaf
  /// and revealed page are pixel-identical to the settled render.
  final Widget Function(int page) pageAt;

  /// Pass M2 (F3): the non-selectable twin used for every IN-MOTION
  /// render (leaf and revealed base). Selection only lives on the
  /// settled page; a page under a finger is never selectable anyway,
  /// so the motion renders skip SelectableText's gesture machinery.
  /// Falls back to [pageAt] when the host does not supply one.
  final Widget Function(int page)? pageAtStatic;

  /// Called once a committed turn's animation lands; the screen
  /// performs the jumpToPage here (the visual work is already done).
  final ValueChanged<int> onCommitPage;

  /// Gesture-arbitration master switch: a zoom host scaled in sets
  /// this false and the overlay degrades to a plain pass-through
  /// (zero recognizers installed).
  final bool enabled;

  @override
  State<MushafTurnOverlay> createState() => _MushafTurnOverlayState();
}

class _MushafTurnOverlayState extends State<MushafTurnOverlay>
    with SingleTickerProviderStateMixin {
  // M3 (F1): THE single controller for this State's whole life —
  // created in initState, disposed in dispose(), retargeted per
  // settle. late final + non-nullable makes the null-aware dance that
  // leaked the disposed field (the cascade) structurally impossible.
  late final AnimationController _settle;
  // M3 (F1/F2): the retarget state the permanent listeners read —
  // M4 (W1/W2) re-types it from lerp-params to SPRING state: the
  // settle carries position AND release velocity and integrates at the
  // ticker's real dt. Still ONE set of fields, still no per-call
  // objects, still one controller driving the ticks.
  double _springX = 0;
  double _springV = 0;
  double _springTo = 0;
  double _springOmega = MushafTurnPhysics.kCommit;
  bool _springLive = false;
  // Elapsed microseconds (value × 10 s) of the last tick; -1 = none yet.
  int _lastTickUs = -1;
  bool _animCommit = false;
  MushafTurnDirection _animDir = MushafTurnDirection.forward;
  // M2 (F2): the turn's progress lives in a notifier — ticks publish
  // to the AnimatedBuilder only; nothing else rebuilds mid-drag.
  final ValueNotifier<double> _turnT = ValueNotifier<double>(0);
  MushafTurnDirection? _dir;
  // M2 (F1): contents latched at turn start. pageAt/pageAtStatic are
  // called from _advance/_release/_settle boundaries only — never per
  // tick — so even a host without a cache builds each page once.
  Widget? _leafContent;
  Widget? _baseContent;
  double _dragSpan = 360;
  bool _hintVisible = false;
  bool _hintUsed = false;
  Timer? _idleTimer;
  Timer? _hintRetract;
  int _idleGeneration = 0;

  @override
  void initState() {
    super.initState();
    // M3 (F1/F2): the ONE ticker the SingleTickerProvider contract
    // allots this State (F4), created up-front — _animateTo can never
    // reach createTicker again. The settle listeners attach exactly
    // here, once (F2). Durations/curve are retarget fields set per
    // settle below.
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    )
      ..addListener(_onSettleTick)
      ..addStatusListener(_onSettleStatus);
    _armIdleHint();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _hintRetract?.cancel();
    // M3 (F1/F3): the only dispose this controller ever sees. The
    // stop() makes teardown deterministic — no in-flight ticker when
    // the dispose lands (mid-settle unmount is R2's zero-throw case;
    // this Flutter tolerates active-dispose — we simply never leave
    // one running) — and a no-op at rest. stop() can only publish a
    // dismissed status, which the permanent handler ignores: no
    // spurious content clear, no spurious commit.
    _settle.stop();
    _settle.dispose();
    _turnT.dispose();
    super.dispose();
  }

  // ── Idle corner-peel hint: once per visit, never a loop ──────
  void _armIdleHint() {
    _idleTimer?.cancel();
    if (_hintUsed) return;
    final generation = ++_idleGeneration;
    _idleTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _dir != null || generation != _idleGeneration) return;
      setState(() {
        _hintUsed = true;
        _hintVisible = true;
      });
      _hintRetract = Timer(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _hintVisible = false);
      });
    });
  }

  void _disarmIdle() {
    _idleGeneration++;
    _idleTimer?.cancel();
  }

  // ── Drag → turn ──────────────────────────────────────────────
  void _onDragStart() {
    final box = context.findRenderObject() as RenderBox?;
    _dragSpan = math.max(120.0, (box?.size.width ?? 360) - 32);
  }

  void _advance(MushafTurnDirection dir, double dx) {
    if (_dir == dir && _springLive) {
      // M4: touching down again mid-settle in the SAME direction hands
      // the page back to the finger — stop the clock, kill the spring,
      // the drag continues from wherever momentum left _turnT.
      _settle.stop();
      _springLive = false;
    }
    if (_dir != dir) {
      // Interrupting a live settle with a new drag: plain stop on the
      // one controller (its status handler ignores anything but
      // completed — mid-flight retargets never fire the commit).
      _settle.stop();
      _springLive = false;
      setState(() {
        _dir = dir;
        _turnT.value = 0;
        _leafContent = _latchLeafContent(dir);
        _baseContent = dir == MushafTurnDirection.forward
            ? _latchBaseContent()
            : null;
      });
    }
    final travel = dir == MushafTurnDirection.forward ? dx : -dx;
    _turnT.value =
        MushafTurnGeometry.clampT(_turnT.value + travel / _dragSpan);
  }

  /// Latch-time content (M2): one RepaintBoundary-wrapped build per
  /// page per turn, through the motion twin when the host has one.
  Widget _latchContent(int page) => RepaintBoundary(
        child: widget.pageAtStatic != null
            ? widget.pageAtStatic!(page)
            : widget.pageAt(page),
      );

  Widget _latchLeafContent(MushafTurnDirection dir) => _latchContent(
      dir == MushafTurnDirection.forward
          ? widget.currentPage
          : _neighbour(forward: false));

  Widget _latchBaseContent() => _latchContent(_neighbour(forward: true));

  void _onDragEnd(DragEndDetails d) {
    final dir = _dir;
    if (dir == null) {
      // A drag that never became a turn (edge of the book, or a locked
      // direction) must re-arm the idle hint it disarmed on touch-down.
      _armIdleHint();
      return;
    }
    final vx = d.velocity.pixelsPerSecond.dx;
    final signed = dir == MushafTurnDirection.forward ? vx : -vx;
    // W1: the finger's velocity becomes the spring's initial d/dt of
    // the turn fraction (capped so a 5000 px/s fling can't launch the
    // page faster than the eye can track it).
    final v0 = (signed / _dragSpan).clamp(-4.0, 4.0);
    if (MushafTurnGeometry.commits(dir, _turnT.value, vx)) {
      _animateTo(1, commit: true, dir: dir, velocity: v0);
      // W4: no haptic HERE (the old release-frame medium thump was the
      // DECISION, not the landing). The thump now arrives when the
      // page actually seats — see _finishSettle.
    } else {
      _animateTo(0, commit: false, dir: dir, velocity: v0);
      HapticFeedback.selectionClick();
    }
  }

  void _releaseWithoutTurn() {
    if (_dir != null && _settle.isAnimating != true) {
      _turnT.value = 0;
      setState(() {
        _dir = null;
        _leafContent = null;
        _baseContent = null;
      });
      _armIdleHint();
    }
  }

  void _animateTo(double target,
      {required bool commit,
      required MushafTurnDirection dir,
      double velocity = 0}) {
    // M3 (F1): NEVER create — retarget the single controller. The
    // old dispose-then-recreate is what the SingleTicker provider
    // forbids (second ticker in one State = hard assert; the device's
    // second-turn crash), and the throw left _settle pointing at a
    // disposed controller (the stop-after-dispose cascade).
    final c = _settle;
    c.stop(); // canceled=true: status listeners get dismissed, which
              // the permanent handler below ignores — only a landing
              // ever commits.
    // M4 (W1/W2): the settle is PHYSICS now, not a fixed-duration
    // curve. Position starts where the finger left it, velocity
    // carries through, the spring lands it. The controller is a pure
    // CLOCK — the long duration is never raced; convergence stops it
    // (see _onSettleTick), so pumpAndSettle, a 60 Hz frame, or a
    // battery-saver hitch all behave identically.
    _springX = _turnT.value;
    _springV = velocity;
    _springTo = target;
    _springOmega =
        commit ? MushafTurnPhysics.kCommit : MushafTurnPhysics.kRetract;
    _animCommit = commit;
    _animDir = dir;
    _springLive = true;
    _lastTickUs = -1;
    c.duration = const Duration(seconds: 10);
    c.forward(from: 0);
  }

  /// M3 (F2) + M4 (W1/W2): the permanent tick listener — attached once
  /// in initState. Each frame advances the spring by the REAL elapsed
  /// dt, in fixed 1/120 s substeps (clamped at 48 ms per frame), so
  /// 60/120/144 Hz integrate the same trajectory. The M2 rule holds:
  /// settle ticks write ONLY the notifier, never setState.
  ///
  /// The clock: the controller runs at a KNOWN 10 s duration purely as
  /// a metronome, so elapsed microseconds = value × 1e7 — the ticker's
  /// own frame math, with no dependence on any framework timer getter.
  void _onSettleTick() {
    // mounted: State.dispose stops the controller, whose notifyListeners
    // re-enters this tick — the spring must not (and cannot) publish into
    // a defunct tree (R2's unmount-mid-settle contract).
    if (!_springLive || !mounted) return;
    final us = (_settle.value * 1e7).round();
    final dt = _lastTickUs < 0
        ? 1 / 60 // first tick after forward(from: 0): one nominal frame
        : math.max(0.0, (us - _lastTickUs)) / 1e6;
    _lastTickUs = us;
    final (x, v) = MushafTurnPhysics.advanceFrame(
        _springX, _springV, _springTo, _springOmega, dt);
    _springX = x;
    _springV = v;
    if (MushafTurnPhysics.converged(x, v, _springTo)) {
      _springLive = false;
      _turnT.value = MushafTurnGeometry.clampT(_springTo);
      _settle.stop(); // the clock ENDS with the motion — never left
                      // ticking to a 10 s completed that would
                      // double-fire the landing.
      _finishSettle();
      return;
    }
    _turnT.value = MushafTurnGeometry.clampT(x);
  }

  /// M3 (F2): the permanent status handler. Physics converges on its
  /// own; this stays as the framework-side safety net (completed only
  /// fires if the clock ever actually runs out — it never does while
  /// mounted, and dispose stops the controller first).
  void _onSettleStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    _springLive = false;
    _finishSettle();
  }

  /// M3's completion contract (silent turnT reset, content release,
  /// commit-then-rearm) + M4 W4: the landing thump IS the haptic.
  void _finishSettle() {
    _turnT.value = 0;
    setState(() {
      _dir = null;
      _leafContent = null;
      _baseContent = null;
    });
    if (_animCommit) {
      HapticFeedback.lightImpact();
      final target = _animDir == MushafTurnDirection.forward
          ? math.min(widget.pageCount, widget.currentPage + 1)
          : math.max(1, widget.currentPage - 1);
      if (target != widget.currentPage) widget.onCommitPage(target);
    }
    _armIdleHint();
  }

  // ── Render ───────────────────────────────────────────────────
  bool _directionAllowed(MushafTurnDirection dir) =>
      dir == MushafTurnDirection.forward
          ? widget.currentPage < widget.pageCount
          : widget.currentPage > 1;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      // Arbitration pass-through: no recognizer, no layers at all.
      return widget.child;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragDown: (_) => _disarmIdle(),
          onHorizontalDragCancel: _releaseWithoutTurn,
          // The FIRST meaningful horizontal movement decides the
          // direction; the lock holds until release (documented in the
          // arbitration matrix). Opposite drags rewind the same leaf.
          onHorizontalDragUpdate: (d) {
            final dx = d.primaryDelta ?? d.delta.dx;
            if (_dir == null) {
              final wanted = dx < 0
                  ? MushafTurnDirection.backward
                  : MushafTurnDirection.forward;
              if (!_directionAllowed(wanted)) return;
              _onDragStart();
              _advance(wanted, dx);
            } else {
              _advance(_dir!, dx);
            }
          },
          onHorizontalDragEnd: _onDragEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.child, // the settled pager, always mounted
              // The whole motion group is one AnimatedBuilder over the
              // latched contents (M2): ticks re-run ONLY this builder —
              // transforms, band offsets, shading alphas. The pages
              // below it are the same widget instances every frame,
              // so their elements skip update entirely: zero content
              // builds, zero text relayout per tick.
              AnimatedBuilder(
                animation: _turnT,
                builder: (context, _) {
                  final dir = _dir;
                  final t = dir == null ? 0.0 : _turnT.value;
                  final edgeX = dir == null
                      ? 0.0
                      : w * MushafTurnGeometry.freeEdgeFrac(dir, t);
                  final colors = QibraColors.of(context);
                  // D2: the fore-edge glint rides the surface — one
                  // readable antique gold on paper, the AppGold pair
                  // on navy. COLOR ONLY; the M2 band mechanics and all
                  // M3 lifecycle mechanics below are untouched.
                  final gildBase = QibraPaper.isActive(context)
                      ? QibraPaper.gild
                      : AppGold.s500;
                  // Byte-identical to the pre-M2 sheen gate.
                  final settling = _settle.isAnimating == true;
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Forward: the next page rides UNDER the leaf.
                      // Backward needs no base — the pager's own frame
                      // is what the incoming leaf has not covered yet.
                      if (dir == MushafTurnDirection.forward &&
                          _baseContent != null)
                        Positioned.fill(
                          key: const ValueKey('mushaf-turn-base'),
                          // W5: the revealed page chases the leaf by
                          // ≤8px on the gild's envelope — composition
                          // only (the latched content sits inside its
                          // own RepaintBoundary), EXACTLY zero at the
                          // commit frame and at rest.
                          child: Transform.translate(
                            offset:
                                Offset(MushafTurnGeometry.parallax(t), 0),
                            child: IgnorePointer(child: _baseContent!),
                          ),
                        ),
                      if (dir != null && _leafContent != null)
                        Positioned.fill(
                          key: const ValueKey('mushaf-turn-leaf'),
                          child: RepaintBoundary(
                            // E (M4): the clip follows the leaf's
                            // PROJECTED quad (anti-aliased, 1.2px
                            // slack) — a rectangular ClipRect used to
                            // shear the magnified corners off the
                            // lifted, gilded free edge.
                            child: ClipPath(
                              clipBehavior: Clip.antiAlias,
                              clipper: MushafTurnLeafClipper(
                                angle: MushafTurnGeometry.angleFor(
                                    dir, t),
                                lift:
                                    MushafTurnGeometry.anticipation(t),
                              ),
                              child: Transform(
                                alignment: Alignment.centerRight,
                                // W3: the same 3px lift the clipper
                                // models — one matrix, both users.
                                transform:
                                    MushafTurnGeometry.leafTransform(
                                  MushafTurnGeometry.angleFor(dir, t),
                                  lift: MushafTurnGeometry
                                      .anticipation(t),
                                ),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: colors.card,
                                      child: _leafContent!,
                                    ),
                                    // L1 (M2 look): curl shading — the
                                    // fixed across-page light gradient
                                    // plus a top-edge fold band. Static
                                    // colors on purpose: they ride the
                                    // transform for free, and the read
                                    // survives any theme (M2 discipline).
                                    const Positioned.fill(
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Colors.white24,
                                                Colors.white10,
                                                Colors.black12,
                                              ],
                                              stops: [0.0, 0.65, 1.0],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Positioned(
                                      top: 0,
                                      left: 0,
                                      right: 0,
                                      height: 24,
                                      child: IgnorePointer(
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                                Colors.white24,
                                                Colors.transparent,
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (dir != null)
                        // L2 (M2 look): cast shadow riding the free
                        // edge — TWO-TONE now (soft ambient + tight
                        // contact stop) and moved by TRANSFORM ONLY:
                        // fixed-size box, translate per tick, zero
                        // relayout (F4).
                        Positioned(
                          key: const ValueKey('mushaf-turn-shadow'),
                          top: 0,
                          bottom: 0,
                          left: 0,
                          width: 64,
                          child: IgnorePointer(
                            child: Transform.translate(
                              // E (M4): the band's RIGHT edge lands ON
                              // the free edge (was edgeX − 56, which
                              // threw its last 8px — at full alpha —
                              // across the leaf's fore-edge as a hard
                              // dark fringe). Contact shadow now ends
                              // IN the fold.
                              offset: Offset(edgeX - 64, 0),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.black
                                          .withValues(alpha: 0),
                                      Colors.black.withValues(
                                        alpha:
                                            MushafTurnShading
                                                .castShadowAlpha(t) *
                                            0.45,
                                      ),
                                      Colors.black.withValues(
                                        alpha: MushafTurnShading
                                            .castShadowAlpha(t),
                                      ),
                                      // E: feather to ZERO at the band's
                                      // own end — stop continuity: no
                                      // seam left against the paper
                                      // behind the fold.
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.5, 0.82, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (dir != null)
                        // GILDED EDGE — fore-edge shimmer, turn-
                        // duration ONLY (≤8% gold discipline; never
                        // survives into the settled state). L3: the
                        // band RIDES the edge curve — its vertical
                        // inset breathes with t, so the glint grows
                        // mid-turn and retracts at commit — inside the
                        // existing AppGold ramp, no new tokens.
                        Positioned(
                          key: const ValueKey('mushaf-turn-gild'),
                          top: 0,
                          bottom: 0,
                          left: 0,
                          width: 2,
                          child: IgnorePointer(
                            child: Transform.translate(
                              offset: Offset(edgeX - 1, 0),
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: 24 * (1 - 0.6 * math.sin(math.pi * t)),
                                  bottom:
                                      24 * (1 - 0.6 * math.sin(math.pi * t)),
                                ),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        gildBase.withValues(
                                            alpha:
                                                MushafTurnShading.gildAlpha(
                                                        t) *
                                                    0.35),
                                        gildBase.withValues(
                                          alpha:
                                              MushafTurnShading.gildAlpha(t),
                                        ),
                                        (QibraPaper.isActive(context)
                                                ? QibraPaper.gild
                                                : AppGold.s700)
                                            .withValues(
                                          alpha:
                                              MushafTurnShading.gildAlpha(
                                                      t) *
                                                  0.55,
                                        ),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // The spine strip (binding side = screen right):
                      // a static crease at rest, a dynamic fold shadow
                      // + settle sheen while turning (and through the
                      // settle — 'settling' — window).
                      Positioned(
                        key: const ValueKey('mushaf-spine'),
                        right: 0,
                        top: 0,
                        width: dir == null ? 8 : 10,
                        height: h,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: dir == null
                                    ? const [
                                        Colors.transparent,
                                        Colors.black26
                                      ]
                                    : [
                                        Colors.black
                                            .withValues(alpha: 0),
                                        Colors.black.withValues(
                                          alpha: MushafTurnShading
                                              .spineCrease(t),
                                        ),
                                        Colors.white.withValues(
                                          alpha: settling
                                              ? 0.30 * (1 - t).abs()
                                              : 0.0,
                                        ),
                                      ],
                                stops: dir == null
                                    ? const [0.0, 1.0]
                                    : const [0.0, 0.72, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Positioned.fill(
                // Procedural paper grain (no asset): a deterministic
                // dot field at whisper alpha, static — it deliberately
                // ignores the animation loop.
                key: ValueKey('mushaf-paper-grain'),
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _PaperGrainPainter(),
                  ),
                ),
              ),
              if (_hintVisible && _dir == null) _buildPeelFlap(),
            ],
          ),
        );
      },
    );
  }

  int _neighbour({required bool forward}) => forward
      ? math.min(widget.pageCount, widget.currentPage + 1)
      : math.max(1, widget.currentPage - 1);

  Widget _buildPeelFlap() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // The free corner of a RIGHT-bound codex is the TOP-LEFT.
    final flap = Container(
      key: const ValueKey('mushaf-peel-flap'),
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomRight,
          end: Alignment.topLeft,
          colors: [
            Colors.black.withValues(alpha: reduceMotion ? 0.10 : 0.22),
            Colors.white.withValues(alpha: reduceMotion ? 0.06 : 0.18),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          bottomRight: Radius.circular(14),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(alpha: reduceMotion ? 0.10 : 0.26),
            blurRadius: reduceMotion ? 4 : 10,
            offset: const Offset(2, 2),
          ),
        ],
      ),
    );
    return Positioned(
      left: 0,
      top: 0,
      child: IgnorePointer(
        child: reduceMotion
            // Reduced motion: no lift animation at all — the corner
            // just fades in and out, same information, zero movement.
            ? AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _hintVisible ? 1 : 0,
                child: flap,
              )
            : TweenAnimationBuilder<double>(
                key: const ValueKey('mushaf-peel-lift'),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutBack,
                builder: (context, v, child) => Transform(
                  alignment: Alignment.bottomRight,
                  transform: Matrix4.identity()
                    ..setEntry(3, 0, 0.02)
                    ..rotateZ(-0.16 * v)
                    ..translate(-6.0 * v, -6.0 * v),
                  child: child,
                ),
                child: flap,
              ),
      ),
    );
  }
}

/// Deterministic paper grain — no asset, no per-frame cost. Fixed-seed
/// dots make every paint identical, and [shouldRepaint] stays false,
/// so the field never redraws during the turn loop.
class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (!size.isFinite || size.width <= 0 || size.height <= 0) return;
    final dark = Paint()..color = Colors.black.withValues(alpha: 0.030);
    final light = Paint()..color = Colors.white.withValues(alpha: 0.022);
    var state = 0x9E3779B9; // golden-ratio seeded LCG — stable dots
    double next() {
      state = (state * 1664525 + 1013904223) & 0xFFFFFFFF;
      return state / 0xFFFFFFFF;
    }

    const step = 14.0;
    for (var y = step / 2; y < size.height; y += step) {
      for (var x = step / 2; x < size.width; x += step) {
        final jx = (next() - 0.5) * step * 0.9;
        final jy = (next() - 0.5) * step * 0.9;
        final r = 0.5 + next() * 0.55;
        canvas.drawCircle(
          Offset(x + jx, y + jy),
          r,
          next() > 0.5 ? dark : light,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PaperGrainPainter oldDelegate) => false;
}

/// E (M4): the leaf's clip, drawn as its PROJECTED QUAD + 1.2px slack,
/// anti-aliased. The old ClipRect lived in the PARENT space (outside
/// the transform) and sheared the perspective-magnified corners of the
/// lifted free edge — the device's 'thora cut, nice side se'. The clip
/// now contains exactly the paper: corners of the projected rect are
/// INSIDE the path (pinned), while the region past the leading edge
/// stays OUT — the shadow below remains masked by the page, never a
/// rectangle's worth of it painted onto the stack.
class MushafTurnLeafClipper extends CustomClipper<Path> {
  // NOT const — CustomClipper's own constructor is non-const.
  MushafTurnLeafClipper({required this.angle, required this.lift});

  final double angle;
  final double lift;

  static const double _slack = 1.2; // sub-pixel overlap for AA seams

  @override
  Path getClip(Size size) {
    final pts = MushafTurnGeometry.projectedCorners(
        size.width, size.height, angle, lift);
    final cx = (pts[0].dx + pts[2].dx) / 2;
    final cy = (pts[0].dy + pts[2].dy) / 2;
    final path = Path();
    for (var i = 0; i < 4; i++) {
      final p = pts[i];
      final dx = p.dx - cx;
      final dy = p.dy - cy;
      final n = math.sqrt(dx * dx + dy * dy);
      final q = n == 0
          ? p
          : Offset(p.dx + dx / n * _slack, p.dy + dy / n * _slack);
      if (i == 0) {
        path.moveTo(q.dx, q.dy);
      } else {
        path.lineTo(q.dx, q.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(MushafTurnLeafClipper oldClipper) =>
      oldClipper.angle != angle || oldClipper.lift != lift;
}
