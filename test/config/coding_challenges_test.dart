import 'package:flutter_test/flutter_test.dart';
import 'package:squash/config/coding_challenges.dart';

void main() {
  group('Coding Challenges Data Validation', () {
    // ============================================
    // CHALLENGE STRUCTURE
    // ============================================
    group('Challenge Structure', () {
      test('has challenges for all 5 tiers', () {
        expect(codingChallenges.containsKey(ChallengeTier.beginner), true);
        expect(codingChallenges.containsKey(ChallengeTier.novice), true);
        expect(codingChallenges.containsKey(ChallengeTier.intermediate), true);
        expect(codingChallenges.containsKey(ChallengeTier.advanced), true);
        expect(codingChallenges.containsKey(ChallengeTier.expert), true);
      });

      test('each tier has at least 2 challenges', () {
        for (final tier in ChallengeTier.values) {
          final challenges = codingChallenges[tier];
          expect(challenges, isNotNull, reason: 'Tier $tier has no challenges');
          expect(challenges!.length, greaterThanOrEqualTo(2),
              reason: 'Tier $tier needs at least 2 challenges');
        }
      });

      test('each tier has exactly 3 challenges', () {
        for (final tier in ChallengeTier.values) {
          final challenges = codingChallenges[tier]!;
          expect(challenges.length, 3, reason: 'Tier $tier should have 3 challenges');
        }
      });

      test('total of 15 challenges', () {
        int total = 0;
        for (final tier in ChallengeTier.values) {
          total += codingChallenges[tier]!.length;
        }
        expect(total, 15);
      });
    });

    // ============================================
    // CHALLENGE FIELDS
    // ============================================
    group('Challenge Fields', () {
      test('all challenges have unique IDs', () {
        final ids = <String>{};
        for (final tier in ChallengeTier.values) {
          for (final challenge in codingChallenges[tier]!) {
            expect(ids.contains(challenge.id), false,
                reason: 'Duplicate ID: ${challenge.id}');
            ids.add(challenge.id);
          }
        }
        expect(ids.length, 15);
      });

      test('all challenges have non-empty required fields', () {
        for (final tier in ChallengeTier.values) {
          for (final challenge in codingChallenges[tier]!) {
            expect(challenge.id.isNotEmpty, true,
                reason: 'Challenge has empty ID');
            expect(challenge.concept.isNotEmpty, true,
                reason: '${challenge.id} has empty concept');
            expect(challenge.title.isNotEmpty, true,
                reason: '${challenge.id} has empty title');
            expect(challenge.prompt.isNotEmpty, true,
                reason: '${challenge.id} has empty prompt');
            expect(challenge.starterCode.isNotEmpty, true,
                reason: '${challenge.id} has empty starterCode');
            expect(challenge.canonicalSolution.isNotEmpty, true,
                reason: '${challenge.id} has empty canonicalSolution');
            expect(challenge.testCase.isNotEmpty, true,
                reason: '${challenge.id} has empty testCase');
          }
        }
      });

      test('challenge tier matches its placement', () {
        for (final tier in ChallengeTier.values) {
          for (final challenge in codingChallenges[tier]!) {
            expect(challenge.tier, tier,
                reason: '${challenge.id} tier mismatch');
          }
        }
      });

      test('all challenges have hints list', () {
        for (final tier in ChallengeTier.values) {
          for (final challenge in codingChallenges[tier]!) {
            expect(challenge.hints, isNotNull,
                reason: '${challenge.id} hints is null');
            // Hints can be empty, but should exist
          }
        }
      });
    });

    // ============================================
    // ID NAMING CONVENTION
    // ============================================
    group('ID Naming Convention', () {
      test('beginner IDs start with beg_', () {
        for (final challenge in codingChallenges[ChallengeTier.beginner]!) {
          expect(challenge.id.startsWith('beg_'), true,
              reason: '${challenge.id} should start with beg_');
        }
      });

      test('novice IDs start with nov_', () {
        for (final challenge in codingChallenges[ChallengeTier.novice]!) {
          expect(challenge.id.startsWith('nov_'), true,
              reason: '${challenge.id} should start with nov_');
        }
      });

      test('intermediate IDs start with int_', () {
        for (final challenge in codingChallenges[ChallengeTier.intermediate]!) {
          expect(challenge.id.startsWith('int_'), true,
              reason: '${challenge.id} should start with int_');
        }
      });

      test('advanced IDs start with adv_', () {
        for (final challenge in codingChallenges[ChallengeTier.advanced]!) {
          expect(challenge.id.startsWith('adv_'), true,
              reason: '${challenge.id} should start with adv_');
        }
      });

      test('expert IDs start with exp_', () {
        for (final challenge in codingChallenges[ChallengeTier.expert]!) {
          expect(challenge.id.startsWith('exp_'), true,
              reason: '${challenge.id} should start with exp_');
        }
      });
    });

    // ============================================
    // CONCEPT COVERAGE
    // ============================================
    group('Concept Coverage', () {
      test('beginner covers basic concepts', () {
        final concepts =
            codingChallenges[ChallengeTier.beginner]!.map((c) => c.concept).toSet();
        expect(concepts.contains('print') || concepts.any((c) => c.contains('print')), true);
        expect(concepts.contains('variables'), true);
      });

      test('novice covers control flow', () {
        final concepts =
            codingChallenges[ChallengeTier.novice]!.map((c) => c.concept).toSet();
        expect(concepts.contains('conditionals') || concepts.contains('loops'), true);
      });

      test('intermediate covers functions and data structures', () {
        final concepts =
            codingChallenges[ChallengeTier.intermediate]!.map((c) => c.concept).toSet();
        expect(concepts.contains('functions'), true);
      });

      test('advanced covers pythonic patterns', () {
        final concepts =
            codingChallenges[ChallengeTier.advanced]!.map((c) => c.concept).toSet();
        expect(concepts.contains('comprehensions') || concepts.contains('exceptions'), true);
      });

      test('expert covers advanced topics', () {
        final concepts =
            codingChallenges[ChallengeTier.expert]!.map((c) => c.concept).toSet();
        // Should have at least generators, decorators, or classes
        expect(
            concepts.contains('generators') ||
                concepts.contains('decorators') ||
                concepts.contains('classes'),
            true);
      });
    });
  });

  // ============================================
  // getChallengesForLevel
  // ============================================
  group('getChallengesForLevel', () {
    test('returns 2 challenges for beginner', () {
      final challenges = getChallengesForLevel('beginner');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.beginner);
      }
    });

    test('returns 2 challenges for novice', () {
      final challenges = getChallengesForLevel('novice');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.novice);
      }
    });

    test('returns 2 challenges for intermediate', () {
      final challenges = getChallengesForLevel('intermediate');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.intermediate);
      }
    });

    test('returns 2 challenges for advanced', () {
      final challenges = getChallengesForLevel('advanced');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.advanced);
      }
    });

    test('returns 2 challenges for expert', () {
      final challenges = getChallengesForLevel('expert');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.expert);
      }
    });

    test('is case-insensitive', () {
      expect(getChallengesForLevel('BEGINNER').first.tier, ChallengeTier.beginner);
      expect(getChallengesForLevel('Novice').first.tier, ChallengeTier.novice);
      expect(getChallengesForLevel('EXPERT').first.tier, ChallengeTier.expert);
    });

    test('defaults to novice for unknown level', () {
      final challenges = getChallengesForLevel('unknown');
      expect(challenges.length, 2);
      for (final c in challenges) {
        expect(c.tier, ChallengeTier.novice);
      }
    });

    test('returns first 2 challenges (consistent order)', () {
      final challenges1 = getChallengesForLevel('beginner');
      final challenges2 = getChallengesForLevel('beginner');
      expect(challenges1[0].id, challenges2[0].id);
      expect(challenges1[1].id, challenges2[1].id);
    });
  });

  // ============================================
  // getChallengeById
  // ============================================
  group('getChallengeById', () {
    test('finds challenge by valid ID', () {
      final challenge = getChallengeById('beg_01');
      expect(challenge, isNotNull);
      expect(challenge!.id, 'beg_01');
      expect(challenge.tier, ChallengeTier.beginner);
    });

    test('finds challenges from different tiers', () {
      expect(getChallengeById('beg_01')?.tier, ChallengeTier.beginner);
      expect(getChallengeById('nov_01')?.tier, ChallengeTier.novice);
      expect(getChallengeById('int_01')?.tier, ChallengeTier.intermediate);
      expect(getChallengeById('adv_01')?.tier, ChallengeTier.advanced);
      expect(getChallengeById('exp_01')?.tier, ChallengeTier.expert);
    });

    test('returns null for invalid ID', () {
      expect(getChallengeById('invalid'), isNull);
      expect(getChallengeById(''), isNull);
      expect(getChallengeById('beg_99'), isNull);
    });

    test('finds all challenges by their IDs', () {
      for (final tier in ChallengeTier.values) {
        for (final challenge in codingChallenges[tier]!) {
          final found = getChallengeById(challenge.id);
          expect(found, isNotNull, reason: 'Could not find ${challenge.id}');
          expect(found!.id, challenge.id);
        }
      }
    });
  });

  // ============================================
  // CodingChallenge Class
  // ============================================
  group('CodingChallenge Class', () {
    test('can create custom challenge', () {
      const challenge = CodingChallenge(
        id: 'test_01',
        tier: ChallengeTier.beginner,
        concept: 'test',
        title: 'Test Challenge',
        prompt: 'Do something',
        starterCode: '# Start',
        canonicalSolution: 'print("done")',
        testCase: 'done',
      );

      expect(challenge.id, 'test_01');
      expect(challenge.tier, ChallengeTier.beginner);
      expect(challenge.hints, isEmpty); // Default empty list
    });

    test('can create challenge with hints', () {
      const challenge = CodingChallenge(
        id: 'test_02',
        tier: ChallengeTier.novice,
        concept: 'test',
        title: 'Test',
        prompt: 'Do something',
        starterCode: '# Start',
        canonicalSolution: 'print("done")',
        testCase: 'done',
        hints: ['Hint 1', 'Hint 2'],
      );

      expect(challenge.hints.length, 2);
      expect(challenge.hints[0], 'Hint 1');
    });
  });

  // ============================================
  // ChallengeTier Enum
  // ============================================
  group('ChallengeTier Enum', () {
    test('has 5 values', () {
      expect(ChallengeTier.values.length, 5);
    });

    test('values are in correct order', () {
      expect(ChallengeTier.values[0], ChallengeTier.beginner);
      expect(ChallengeTier.values[1], ChallengeTier.novice);
      expect(ChallengeTier.values[2], ChallengeTier.intermediate);
      expect(ChallengeTier.values[3], ChallengeTier.advanced);
      expect(ChallengeTier.values[4], ChallengeTier.expert);
    });
  });
}
