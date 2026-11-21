const TOTAL_SEATS = 5;
const MIN_ENTRY_FEE = 1000;
const MAX_ENTRY_FEE = 100000;

function validateEntryFee(fee) {
  return typeof fee === "number" && fee >= MIN_ENTRY_FEE && fee <= MAX_ENTRY_FEE;
}

function createTable({ tableId, isPrivate = false, entryFee = MIN_ENTRY_FEE }) {
  if (!validateEntryFee(entryFee)) {
    throw new Error(`رسوم الدخول يجب أن تكون بين ${MIN_ENTRY_FEE} و ${MAX_ENTRY_FEE} كوينز`);
  }

  return {
    tableId,
    isPrivate,
    entryFee,
    seats: Array.from({ length: TOTAL_SEATS }, (_, index) => ({
      seatNumber: index + 1,
      playerId: null,
      playerName: null,
      isBot: false,
      isConnected: false,
    })),
  };
}

function getOccupiedSeatsCount(table) {
  return table.seats.filter((seat) => Boolean(seat.playerId)).length;
}

function canStartLegalGame(table) {
  return getOccupiedSeatsCount(table) === TOTAL_SEATS;
}

function seatPlayer(table, { playerId, playerName, isBot = false, isConnected = true }) {
  if (!playerId) {
    throw new Error("معرّف اللاعب مطلوب لتسكين المقعد");
  }

  const alreadySeated = table.seats.some((seat) => seat.playerId === playerId);
  if (alreadySeated) {
    throw new Error("اللاعب جالس على الطاولة بالفعل");
  }

  const freeSeat = table.seats.find((seat) => !seat.playerId);
  if (!freeSeat) {
    throw new Error("الطاولة ممتلئة (5/5 مقاعد)");
  }

  freeSeat.playerId = playerId;
  freeSeat.playerName = playerName || (isBot ? `شخصية آلية ${freeSeat.seatNumber}` : `لاعب ${freeSeat.seatNumber}`);
  freeSeat.isBot = Boolean(isBot);
  freeSeat.isConnected = Boolean(isConnected);

  return {
    table,
    assignedSeat: freeSeat.seatNumber,
    canStartLegalGame: canStartLegalGame(table),
  };
}

function removePlayerFromSeat(table, playerId) {
  const targetSeat = table.seats.find((seat) => seat.playerId === playerId);
  if (!targetSeat) {
    return {
      table,
      removed: false,
      canStartLegalGame: canStartLegalGame(table),
    };
  }

  targetSeat.playerId = null;
  targetSeat.playerName = null;
  targetSeat.isBot = false;
  targetSeat.isConnected = false;

  return {
    table,
    removed: true,
    canStartLegalGame: canStartLegalGame(table),
  };
}

module.exports = {
  TOTAL_SEATS,
  MIN_ENTRY_FEE,
  MAX_ENTRY_FEE,
  validateEntryFee,
  createTable,
  getOccupiedSeatsCount,
  canStartLegalGame,
  seatPlayer,
  removePlayerFromSeat,
};
ض
