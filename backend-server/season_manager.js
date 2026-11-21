const TOURNAMENT_CADENCES = ["DAILY", "WEEKLY", "MONTHLY"];

function createPlayerRankProfile({ playerId, displayName, region = "MENA", rankPoints = 0 }) {
  return {
    playerId,
    displayName,
    region,
    rankPoints: Math.max(0, Number(rankPoints) || 0),
    historicalAchievements: [],
  };
}

function recordMatchResult(profile, { won, pointsDelta = 25, matchSummary = "" }) {
  const delta = Math.max(0, Number(pointsDelta) || 0);
  if (won) {
    profile.rankPoints += delta;
  } else {
    profile.rankPoints = Math.max(0, profile.rankPoints - Math.floor(delta / 2));
  }

  profile.historicalAchievements.push({
    type: "MATCH",
    won: Boolean(won),
    pointsAfter: profile.rankPoints,
    summary: matchSummary,
    timestamp: new Date().toISOString(),
  });

  return profile;
}

function resetSeasonPoints(profiles, seasonLabel = "New Season") {
  return profiles.map((profile) => {
    const archivedSnapshot = {
      type: "SEASON_ARCHIVE",
      seasonLabel,
      finalPoints: profile.rankPoints,
      archivedAt: new Date().toISOString(),
    };

    return {
      ...profile,
      rankPoints: 0,
      historicalAchievements: [...profile.historicalAchievements, archivedSnapshot],
    };
  });
}

function createTournament({ tournamentId, title, cadence, entryFee, tier }) {
  const normalizedCadence = String(cadence || "").toUpperCase();
  if (!TOURNAMENT_CADENCES.includes(normalizedCadence)) {
    throw new Error("نوع البطولة يجب أن يكون DAILY أو WEEKLY أو MONTHLY");
  }

  return {
    tournamentId,
    title,
    cadence: normalizedCadence,
    tier: tier || "STANDARD",
    entryFee: Math.max(0, Number(entryFee) || 0),
    participants: [],
    status: "OPEN",
  };
}

module.exports = {
  TOURNAMENT_CADENCES,
  createPlayerRankProfile,
  recordMatchResult,
  resetSeasonPoints,
  createTournament,
};
