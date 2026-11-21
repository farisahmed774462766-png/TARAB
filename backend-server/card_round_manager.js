const { canStartLegalGame } = require("./table_manager");

const SUITS = ["HEARTS", "DIAMONDS", "CLUBS", "SPADES"];
const RANKS = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"];

function createDeck() {
  const deck = [];
  for (const suit of SUITS) {
    RANKS.forEach((rank, idx) => {
      deck.push({
        id: `${rank}_${suit}`,
        suit,
        rank,
        power: idx + 2,
      });
    });
  }
  return deck;
}

function shuffleDeck(deck) {
  const copy = [...deck];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
}

function startCardRound(table, cardsPerPlayer = 5) {
  if (!canStartLegalGame(table)) {
    throw new Error("لا يمكن بدء جولة قانونية قبل استيفاء شروط الطاولة (5 مقاعد)");
  }

  const occupiedSeats = table.seats.filter((s) => Boolean(s.playerId));
  const deck = shuffleDeck(createDeck());
  const hands = {};
  const scores = {};

  occupiedSeats.forEach((seat) => {
    hands[seat.playerId] = deck.splice(0, cardsPerPlayer);
    scores[seat.playerId] = 0;
  });

  const starterSeat = occupiedSeats[0];

  return {
    roundId: `RND-${table.tableId}-${Date.now()}`,
    tableId: table.tableId,
    status: "IN_PROGRESS",
    turnOrder: occupiedSeats.map((s) => s.playerId),
    currentTurnPlayerId: starterSeat.playerId,
    currentTurnSeat: starterSeat.seatNumber,
    tableCards: [],
    hands,
    scores,
    winnerId: null,
  };
}

function playCard(round, { playerId, cardId }) {
  if (!round || round.status !== "IN_PROGRESS") {
    throw new Error("الجولة غير نشطة حالياً");
  }

  if (round.currentTurnPlayerId !== playerId) {
    throw new Error("ليس دور هذا اللاعب حالياً");
  }

  const playerHand = round.hands[playerId] || [];
  const cardIndex = playerHand.findIndex((c) => c.id === cardId);
  if (cardIndex === -1) {
    throw new Error("الورقة المختارة غير موجودة في يد اللاعب");
  }

  const [playedCard] = playerHand.splice(cardIndex, 1);
  round.tableCards.push({
    playerId,
    card: playedCard,
  });

  // احتساب نقاط بسيطة بناءً على قوة الورقة
  round.scores[playerId] = (round.scores[playerId] || 0) + playedCard.power;

  // التحقق من انتهاء أوراق جميع اللاعبين
  const anyCardsLeft = Object.values(round.hands).some((hand) => hand.length > 0);
  if (!anyCardsLeft) {
    round.status = "FINISHED";
    let bestPlayer = null;
    let highestScore = -1;
    for (const [pid, pts] of Object.entries(round.scores)) {
      if (pts > highestScore) {
        highestScore = pts;
        bestPlayer = pid;
      }
    }
    round.winnerId = bestPlayer;
    round.currentTurnPlayerId = null;
    round.currentTurnSeat = null;
    return round;
  }

  // نقل الدور إلى اللاعب التالي
  const currentIdx = round.turnOrder.indexOf(playerId);
  const nextPlayerId = round.turnOrder[(currentIdx + 1) % round.turnOrder.length];
  round.currentTurnPlayerId = nextPlayerId;

  return round;
}

module.exports = {
  SUITS,
  RANKS,
  createDeck,
  shuffleDeck,
  startCardRound,
  playCard,
};
