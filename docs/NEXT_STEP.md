# QIBRA AI — NEXT STEP

## CURRENT ACTION REQUIRED

### 🎯 Next Task: Step 2.1 — Premium Splash Screen

**Phase:** PHASE 2 — Premium UI & User Experience

## FILE TO CREATE/MODIFY

**Path:** `lib/features/splash/presentation/splash_screen.dart`

**Action:** REPLACE existing splash_screen.dart with premium version

## REQUIREMENTS

Build a premium, Apple-quality splash screen with:

### Visual Requirements:
- Glassmorphism effects (frosted glass)
- Soft glowing emerald + gold particles
- Animated Islamic geometric patterns
- Bismillah in beautiful Arabic calligraphy
- Custom logo animation
- Smooth 120 FPS animations

### Technical Requirements:
- Use existing design system (AppColors, AppSpacing, etc.)
- Use existing AppShadows.emeraldGlow, AppShadows.goldGlow
- Riverpod for state
- GoRouter for navigation
- Proper mounted checks
- Dispose all controllers
- No hardcoded values

### Animation Sequence:
1. Background particle animation starts immediately
2. Islamic pattern fades in (0-800ms)
3. Logo scales up with bounce (400-1200ms)
4. Bismillah fades in (1000-1600ms)
5. App name reveals letter by letter (1400-2200ms)
6. Loading indicator appears (2000ms+)
7. Auto navigate after 3.5 seconds

### Interactions:
- Auth state check
- Navigate to onboarding (first time)
- Navigate to login (logged out)
- Navigate to home (logged in)

## CONTEXT FROM PHASE 1

The current splash screen exists at:
`lib/features/splash/presentation/splash_screen.dart`

It has basic animations but needs to be upgraded to premium quality per Phase 2 UI Style requirements:
- Apple Quality
- Material 3 Expressive
- Glassmorphism
- Luxury feel

## RULES REMINDER

- ONE FILE AT A TIME
- Wait for confirmation
- Use existing widgets from shared/
- Explain in Hinglish
- Production-ready code only
- Follow response format from AI_CONTEXT.md

## AFTER STEP 2.1 COMPLETES

**Next will be:** Step 2.2 — Onboarding Screen 1
**File:** New file — first premium onboarding slide

## COMMAND TO START

Give AI this instruction:
```
Start with Step 2.1 — Premium Splash Screen.
Read AI_CONTEXT.md and PROJECT_STATUS.md first.
Follow the response format exactly.
Handle only this ONE file.
Wait for my confirmation before proceeding.
```