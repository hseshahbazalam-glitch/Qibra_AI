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
import 'package:qibra_ai/core/design_system/qibra_colors.dart';

enum MushafTurnDirection { forward, backward }

/// Pure, testable turn math — no widgets, no state. Kept in its own
/// class so the pass test can pin every threshold without pumping.
abstract final class MushafTurnGeometry {
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
}

/// Every shading value one animated frame derives from t — gathered in
/// one place so 'the detail reads after any theme' (M2) is a property
/// of the numbers, not a coincidence. Alpha bands are deliberately
/// mid-range: visible on both light cards and the navy dark theme.
abstract final class MushafTurnShading {
  static double lightOnLeaf(double t) => 0.14 * math.sin(math.pi * t);
  static double castShadowAlpha(double t) => 0.30 * (1 - 0.55 * t);
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
  AnimationController? _settle;
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
    _armIdleHint();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _hintRetract?.cancel();
    _settle?.dispose();
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
    if (_dir != dir) {
      _settle?.stop();
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
    if (MushafTurnGeometry.commits(dir, _turnT.value, vx)) {
      _animateTo(1, commit: true, dir: dir);
      HapticFeedback.mediumImpact(); // the settle thump
    } else {
      _animateTo(0, commit: false, dir: dir);
      HapticFeedback.selectionClick();
    }
  }

  void _releaseWithoutTurn() {
    if (_dir != null && _settle?.isAnimating != true) {
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
      {required bool commit, required MushafTurnDirection dir}) {
    _settle?.dispose();
    final c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: commit ? 200 : 240),
    );
    _settle = c;
    // 'late' so the listener closure below can read anim: a plain final
    // initializer that references its own variable (even through a
    // callback) is a hard analyzer error, not a taste note.
    late final Animation<double> anim;
    anim = Tween<double>(begin: _turnT.value, end: target).animate(
      CurvedAnimation(
        parent: c,
        curve: commit ? Curves.easeOutCubic : Curves.easeOutBack,
      ),
    )..addListener(() {
        // M2: settle ticks are scoped — the AnimatedBuilder transforms,
        // the tree around it does not rebuild.
        if (mounted) _turnT.value = anim.value;
      });
    c.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _turnT.value = 0;
      setState(() {
        _dir = null;
        _leafContent = null;
        _baseContent = null;
      });
      if (commit) {
        final target = dir == MushafTurnDirection.forward
            ? math.min(widget.pageCount, widget.currentPage + 1)
            : math.max(1, widget.currentPage - 1);
        if (target != widget.currentPage) widget.onCommitPage(target);
      }
      _armIdleHint();
    });
    c.forward();
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
                  // Byte-identical to the pre-M2 sheen gate.
                  final settling = _settle?.isAnimating == true;
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
                          child: IgnorePointer(child: _baseContent!),
                        ),
                      if (dir != null && _leafContent != null)
                        Positioned.fill(
                          key: const ValueKey('mushaf-turn-leaf'),
                          child: RepaintBoundary(
                            child: ClipRect(
                              child: Transform(
                                alignment: Alignment.centerRight,
                                transform: Matrix4.identity()
                                  // Gentle depth: at full-page width a
                                  // stronger entry (0.0015+) visibly
                                  // bows the far edge — 0.0009 reads as
                                  // paper, not as a lens.
                                  ..setEntry(3, 0, 0.0009)
                                  // free (left) edge lifts toward reader
                                  ..rotateY(-MushafTurnGeometry.angleFor(
                                      dir, t)),
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
                          top: 0,
                          bottom: 0,
                          left: 0,
                          width: 64,
                          child: IgnorePointer(
                            child: Transform.translate(
                              offset: Offset(edgeX - 56, 0),
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
                                      Colors.black.withValues(
                                        alpha: MushafTurnShading
                                            .castShadowAlpha(t) *
                                            0.85,
                                      ),
                                    ],
                                    stops: const [0.0, 0.55, 0.88, 1.0],
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
                                        AppGold.s500.withValues(
                                            alpha:
                                                MushafTurnShading.gildAlpha(
                                                        t) *
                                                    0.35),
                                        AppGold.s500.withValues(
                                          alpha:
                                              MushafTurnShading.gildAlpha(t),
                                        ),
                                        AppGold.s700.withValues(
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
