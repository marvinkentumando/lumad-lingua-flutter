# Accurate Weekly XP Leaderboard Calculation - Implementation Plan

Fix the Weekly XP leaderboard calculation so it doesn't rely on arbitrary 30% estimations (`totalXp * 0.3`) or incorrect resets.

## User Review Required

> [!IMPORTANT]
> For legacy users without a `weeklyXp` field in Firestore, falling back to `totalXp` (or initializing `weeklyXp` to `totalXp` for the current week) is much more accurate than an arbitrary `totalXp * 0.3` guess.

## Proposed Changes

### [FirebaseService]
#### [MODIFY] [firebase_service.dart](file:///C:/Users/Aspire-3/Desktop/Lumad Lingua Flutter/lib/services/firebase_service.dart)
- Update `getLeaderboardLearners` to fall back to `totalXp` (instead of `totalXp * 0.3`) when `weeklyXp` is absent, and properly handle weekly reset logic.

### [LeaderboardScreen]
#### [MODIFY] [leaderboard_screen.dart](file:///C:/Users/Aspire-3/Desktop/Lumad Lingua Flutter/lib/screens/leaderboard_screen.dart)
- Update `_mapToEntries` to align with `getLeaderboardLearners` (fallback to `totalXp` instead of `totalXp * 0.3`).

## Verification Plan

### Automated Tests
- Static analysis (`analyze_file`).

### Manual Verification
- Check Leaderboard "This Week" view.
