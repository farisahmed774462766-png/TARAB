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

module.exports = {
  TOTAL_SEATS,
  MIN_ENTRY_FEE,
  MAX_ENTRY_FEE,
  validateEntryFee,
  createTable,
  getOccupiedSeatsCount,
  canStartLegalGame,
};
