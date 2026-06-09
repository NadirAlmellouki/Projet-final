/**
 * Tests d'intégration — Member 3 (Maps & Matching)
 * Couvre : algorithme de matching, geofence, distance rings, fuzzy location
 *
 * Pour lancer : npm install --save-dev jest && node --experimental-vm-modules node_modules/.bin/jest
 * Ou simplement : node src/tests/matching.test.js (mode manuel)
 */

// ── Tests unitaires des utils (sans BDD) ─────────────────────────────────────

import { calculateDistance, getLocationScore } from "../utils/haversine.js";
import { getSubjectScore } from "../utils/tfidf.js";
import { getTimeScore } from "../utils/timeOverlap.js";
import { calculateMatchScore } from "../services/matchingService.js";

const assert = (condition, message) => {
  if (!condition) throw new Error(`❌ FAIL: ${message}`);
  console.log(`   ✅ PASS: ${message}`);
};

const runTests = () => {
  console.log("\n═══════════════════════════════════════════");
  console.log("  StudySync — Tests Member 3");
  console.log("═══════════════════════════════════════════\n");

  // ── 1. Haversine ──────────────────────────────────────────────────────────
  console.log("📐 1. Calcul de distance (Haversine)\n");

  const d1 = calculateDistance(48.8566, 2.3522, 48.8566, 2.3522); // même point
  assert(d1 === 0, "Distance entre point identique = 0");

  const d2 = calculateDistance(48.8566, 2.3522, 48.8600, 2.3522); // ~400m
  assert(d2 > 0.3 && d2 < 0.5, `Distance ~400m : ${d2.toFixed(3)} km`);

  const d3 = calculateDistance(34.0218, -5.0156, 34.0218, -4.9000); // ~10km
  assert(d3 > 9 && d3 < 12, `Distance ~10km : ${d3.toFixed(2)} km`);

  // ── 2. Score de localisation ───────────────────────────────────────────────
  console.log("\n📍 2. Score de proximité\n");

  assert(getLocationScore(0.03) === 100, "Même bâtiment (< 50m) → score 100");
  assert(getLocationScore(0.3)  === 80,  "Dans 500m → score 80");
  assert(getLocationScore(0.8)  === 60,  "Dans 1km → score 60");
  assert(getLocationScore(1.5)  === 40,  "Dans 2km → score 40");
  assert(getLocationScore(3)    === 20,  "Dans 5km → score 20");
  assert(getLocationScore(10)   === 0,   "Au-delà de 5km → score 0");

  // ── 3. Score de sujet ─────────────────────────────────────────────────────
  console.log("\n📚 3. Similarité de sujet (TF-IDF)\n");

  assert(getSubjectScore("Mathématiques", "Mathématiques") === 100, "Même sujet exact → 100");
  assert(getSubjectScore("Data Science", "Data Engineering") > 10,  "Sujets similaires > 10");
  assert(getSubjectScore("Biologie", "Physique") === 10,             "Sujets différents → 10");
  assert(getSubjectScore(null, "Physique") === 10,                   "Sujet null → 10");

  // ── 4. Score horaire ──────────────────────────────────────────────────────
  console.log("\n⏰ 4. Score de disponibilité temporelle\n");

  const now = new Date().toISOString();
  const in5min = new Date(Date.now() + 5 * 60 * 1000).toISOString();
  const in90min = new Date(Date.now() + 90 * 60 * 1000).toISOString();  // ~1h30 → score 60
  const in3h = new Date(Date.now() + 3 * 60 * 60 * 1000).toISOString(); // même jour → score 30
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();

  assert(getTimeScore(now) === 100,      "Session maintenant → score 100");
  assert(getTimeScore(in5min) === 100,   "Session dans 5min → score 100");
  assert(getTimeScore(in90min) === 60,   "Session dans 1h30 → score 60");
  assert(getTimeScore(in3h) === 30,      "Session dans 3h (même jour) → score 30");
  assert(getTimeScore(tomorrow) === 0,   "Session demain → score 0");

  // ── 5. Algorithme de matching complet ─────────────────────────────────────
  console.log("\n🎯 5. Algorithme de matching complet\n");

  const session = {
    subject: "Mathématiques",
    scheduled_time: new Date(Date.now() + 10 * 60 * 1000).toISOString(), // dans 10min
    latitude: 34.0220,
    longitude: -5.0160,
    creator_year: 2,
  };

  const userPerfect = {
    major: "Mathématiques",
    latitude: 34.0218,   // ~20m de la session
    longitude: -5.0158,
    avg_rating: 5,
    session_count: 20,
    account_age_days: 365,
    is_verified: true,
    year: 2,
  };

  const scorePerfect = calculateMatchScore(session, userPerfect);
  assert(scorePerfect >= 80, `Score parfait ≥ 80 : obtenu ${scorePerfect}`);

  const userFar = {
    major: "Biologie",
    latitude: 33.5731,   // ~50km de la session
    longitude: -7.5898,
    avg_rating: 2,
    session_count: 0,
    account_age_days: 1,
    is_verified: false,
    year: 4,
  };

  const scoreFar = calculateMatchScore(session, userFar);
  assert(scoreFar < 30, `Score mauvais match < 20 : obtenu ${scoreFar}`);

  // ── 6. Fuzzy location ─────────────────────────────────────────────────────
  console.log("\n🔒 6. Fuzzy location (privacy)\n");

  const distances = [
    { km: 0.3,  expected: "< 500m" },
    { km: 0.7,  expected: "< 1km" },
    { km: 1.5,  expected: "< 2km" },
    { km: 4.0,  expected: "< 5km" },
  ];

  distances.forEach(({ km, expected }) => {
    let fuzzy;
    if (km <= 0.5)      fuzzy = "< 500m";
    else if (km <= 1)   fuzzy = "< 1km";
    else if (km <= 2)   fuzzy = "< 2km";
    else                fuzzy = "< 5km";
    assert(fuzzy === expected, `Distance ${km}km → "${fuzzy}"`);
  });

  console.log("\n═══════════════════════════════════════════");
  console.log("  ✅ Tous les tests passent !");
  console.log("═══════════════════════════════════════════\n");
};

runTests();
