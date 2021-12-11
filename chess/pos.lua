--- Internal position representation
-- Validates and generates moves

-- 10x12 indexing
local _mailbox120 =
{
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1,  1,  2,  3,  4,  5,  6,  7,  8, -1,
  -1,  9, 10, 11, 12, 13, 14, 15, 16, -1,
  -1, 17, 18, 19, 20, 21, 22, 23, 24, -1,
  -1, 25, 26, 27, 28, 29, 30, 31, 32, -1,
  -1, 33, 34, 35, 36, 37, 38, 39, 40, -1,
  -1, 41, 42, 43, 44, 45, 46, 47, 48, -1,
  -1, 49, 50, 51, 52, 53, 54, 55, 56, -1,
  -1, 57, 58, 59, 60, 61, 62, 63, 64, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
  -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
}

-- 8x8 indexing
local _mailbox64 =
{
  22, 23, 24, 25, 26, 27, 28, 29,
  32, 33, 34, 35, 36, 37, 38, 39,
  42, 43, 44, 45, 46, 47, 48, 49,
  52, 53, 54, 55, 56, 57, 58, 59,
  62, 63, 64, 65, 66, 67, 68, 69,
  72, 73, 74, 75, 76, 77, 78, 79,
  82, 83, 84, 85, 86, 87, 88, 89,
  92, 93, 94, 95, 96, 97, 98, 99,
}

-- Initial board setup
local _initial64 =
{
   9,  5,  7, 11,  1,  7,  5,  9,
   3,  3,  3,  3,  3,  3,  3,  3,
   0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,
   0,  0,  0,  0,  0,  0,  0,  0,
   4,  4,  4,  4,  4,  4,  4,  4,
  10,  6,  8, 12,  2,  8,  6, 10,
}

local _initial120 = {}
for i, sq in ipairs(_mailbox64) do
  _initial120[sq] = _initial64[i]
end

-- Castling squares and bits
local _castling120 = { [29] = 1, [22] = 2, [99] = 3, [92] = 4 }

-- Movement and attacking offsets
local _moves120
local _attacks120
do
  -- order is significant: from retreat to advance
  local P = { 9, 20, 11, 10 }
  local p = { -9, -20, -11, -10 }
  local N = { -21, -19, -12, -8, 8, 12, 19, 21 }
  local n = { 21, 19, 12, 8, -8, -12, -19, -21 }
  local B = { -11, -9, 9, 11 }
  local b = { 11, 9, -9, -11 }
  local R = { -10, -1, 1, 10 }
  local r = { 10, 1, -1, -10 }
  local K = { -10, -11, -9, -1, 1, 9, 11, 10 }
  local k = { 10, 11, 9, 1, -1, -9, -11, -10 }
  local PA = { -9, -11 }
  local pA = { 9, 11 }
  _moves120 = { K, k, P, p, N, n, B, b, R, r, K, k }
  _attacks120 = { K, k, PA, pA, N, n, B, b, R, r, K, k }
end

local empty, initial

--- Iterate all pseudo-legal moves from a list of offsets
local function iterate(pos, from, offsets, func, ...)
  -- iterate each offset
  for _, offset120 in ipairs(offsets) do
    local to = from + offset120
    -- off the board?
    if pos[to] then
      -- possible move
      if func(pos, from, to, offset120, ...) == true then
        return to
      end
    end
  end
end

--- Iterate all pseudo-legal moves from a list of offsets
local function slide(pos, from, offsets, func, ...)
  -- iterate each offset
  for _, offset120 in ipairs(offsets) do
    local to = from
    repeat
      to = to + offset120
      -- off the board?
      local p2 = pos[to]
      if p2 == nil then
        break
      end
      -- possible move
      if func(pos, from, to, offset120, ...) == true then
        return to
      end
      -- repeat until blocked for sliding pieces
    until p2 > 0
  end
end

--[[
local function ray(pos, from, offset, from, ...)
  local to = from
  while true do
    to = to + offset120
    -- off the board?
    local p2 = pos[to]
    if p2 == nil then
      break
    end
    if p2 > 0 then
      if func(pos, from, to, offset120, ...) == true then
        return to
      end
      break
    end
  end
end
]]

--[[
--- Checks if a piece on a given square matches the provided type
local function checkPiece(pos, from, to, p1)
  return pos[to] == p1
end

--- Checks if a square is isAttacked by the opponent
local function isAttacked(pos, sq)
  for p1 = 2 - pos.opp, 12, 2 do
    if iterate(pos, sq, _attacks120[p1], p1 > 6, checkPiece, p1) then
      return true
    end
  end
  return false
end
]]

local function checkPiece1(pos, from, to, dt, p1)
  return pos[to] == p1
end

local function checkPiece2(pos, from, to, dt, p1, p2)
  local q = pos[to]
  return q == p1 or q == p2
end

local function isAttacked(pos, sq)
  local q, r, b = 11, 9, 7
  if pos.stm == 1 then
    q, r, b = 12, 10, 8
  end
  -- check diagonal rays
  if slide(pos, sq, _attacks120[7], checkPiece2, q, b) then
    return true
  end
  -- check horizontal and vertical rays
  if slide(pos, sq, _attacks120[9], checkPiece2, q, r) then
    return true
  end
  -- check non-sliding pieces
  for p1 = 1 + pos.stm, 6, 2 do
    if iterate(pos, sq, _attacks120[p1], checkPiece1, p1) then
      return true
    end
  end
  return false
end

--- Makes a move without checking if the king is threatened
local function genMove(pos, from, to, safe, list)
  -- verify the move is legal when pinned or in check
  if not safe then
    local ksq = pos.ksq
    if ksq == from then
      ksq = to
    end
    local p1 = pos[from]
    local p2 = pos[to]
    pos[from] = 0
    pos[to] = p1
    -- test only sliding piece attacks unless it's a capture or king move
    local check = isAttacked(pos, ksq)
    pos[from] = p1
    pos[to] = p2
    if check then
      return
    end
  end
  local n = list.n + 1
  list[n] = from + to*120
  list.n = n
end

--- Makes a move and checks if the king is threatened
local isPawn = { [3] = true, [4] = true }
local isAdvanceTwo = { [20] = true, [-20] = true }
local function pseudoMove(pos, from, to, dt, safe, list)
  local p1 = pos[from]
  local p2 = pos[to]
  -- cannot capture own piece
  if p2 > 0 and p1%2 == p2%2 then
    return
  end
  -- pawn movement rules
  if isPawn[p1] then
    if dt%10 == 0 then
      -- pawn advance
      -- blocked
      if p2 > 0 then
        return
      end
      -- advance two
      if isAdvanceTwo[dt] then
        if _initial120[from] ~= p1 or pos[from + dt/2] > 0 then
          return
        end
      end
    else
      -- pawn capture
      if p2 == 0 then
        -- en passant
        if to ~= pos.eps then
          return
        end
        safe = false
      end
    end  
  end
  genMove(pos, from, to, safe, list)
end

--- Generates all castling moves
local function genCastlingMoves(pos, ksq, list)
  -- not in check
  --if pos.check then
    --return
  --end
  local csa = pos.csa
  if pos[ksq] == 2 then
    csa = (csa - csa%4)/4
  else
    csa = csa%4
  end
  -- king side
  if csa == 1 or csa == 3 then
    -- blocked
    if pos[ksq + 1] == 0 and pos[ksq + 2] == 0 then
      -- passes through check
      if not isAttacked(pos, ksq + 1) and not isAttacked(pos, ksq + 2) then
        genMove(pos, ksq, ksq + 2, true, list)
      end
    end
  end
  -- queen side
  if csa == 2 or csa == 3 then
    -- blocked
    if pos[ksq - 1] == 0 and pos[ksq - 2] == 0 and pos[ksq - 3] == 0 then
      -- passes through check
      if not isAttacked(pos, ksq - 1) and not isAttacked(pos, ksq - 2) then
        genMove(pos, ksq, ksq - 2, true, list)
      end
    end
  end
end

local _offset = {}
local function pseudoPin(pos, from, to, dt, p2, p3)
  local p1 = pos[to]
  -- ignore opponent's pieces
  if p1 == 0 or p1%2 ~= pos.stm then
    return
  end
  -- check along ray
  pos[to] = 0
  _offset[1] = dt
  if slide(pos, to, _offset, checkPiece2, p2, p3) then
    pos[to + 120] = true
  end
  pos[to] = p1
end

local function updatePinned(pos, ksq, check)
  -- flush pinned pieces information
  for _, sq in ipairs(_mailbox64) do
    pos[sq + 120] = nil
  end
  pos[ksq + 120] = true
  if not check then
    -- mark potentially pinned pieces
    local b, r, q = 7, 9, 11
    if pos.opp == 0 then
      b, r, q = 8, 10, 12
    end
    -- check diagonal rays
    slide(pos, ksq, _attacks120[7], pseudoPin, b, q)
    -- check horizontal and vertical rays
    slide(pos, ksq, _attacks120[9], pseudoPin, r, q)
  end
end

local function genMoves(pos)
  local ksq = pos.ksq
  local stm = pos.stm
  local check = isAttacked(pos, ksq)
  updatePinned(pos, ksq, check)
  local list = { n = 0 }
  for _, from in ipairs(_mailbox64) do
    -- side to move
    local p1 = pos[from]
    if p1 > 0 and p1%2 == stm then
      -- should we check if the resulting position is check
      local safe = not (check or pos[from + 120])
      local func = p1 > 6 and slide or iterate
      func(pos, from, _moves120[p1], pseudoMove, safe, list)
    end
  end
  if not check then
    genCastlingMoves(pos, ksq, list)
  end
  return list
end

local function getMoves(pos)
  local list = pos.available
  if not list then
    list = genMoves(pos)
    pos.available = list
  end
  return list
end

--- Checks if a move is legal
local function isLegal(pos, move)
  local list = getMoves(pos)
  for i = 1, list.n do
    if list[i] == move then
      return true
    end
  end
  return false
end

local advanceDT = { [3] = 10, [4] = -10 }
local isKing = { [1] = true, [2] = true }
local function makeMove(pos, move)
  local from = move%120
  local to = (move - from)/120
  pos = initial(pos)

  -- Piece
  local p1 = pos[from]
  pos[from] = 0
  pos[to] = p1

  -- King moves
  if isKing[p1] then
    pos.ksq = to
    -- castling (automatically move the rook)
    local dt = to - from
    if dt == 2 then
      -- king-side
      pos[from + 1] = pos[from + 3]
      pos[from + 3] = 0
    elseif dt == -2 then
      -- queen-side
      pos[from - 1] = pos[from - 4]
      pos[from - 4] = 0
    end
  end
  pos.ksq, pos.kop = pos.kop, pos.ksq
  
  -- Pawn moves
  local eps = 0
  if isPawn[p1] then
    -- pawn move
    if to == pos.eps then
      -- en passant capture
      local dt = advanceDT[p1]
      pos[to - dt] = 0
    elseif to <= 28 or to >= 92 then
      -- promotion
      -- assume we promote to queen
      pos[to] = pos.promo or (p1 + 6)
    else
      -- en passant square
      local dt = to - from
      if isAdvanceTwo[dt] then
        eps = from + dt/2
      end
    end
  end
  pos.eps = eps

  -- Castling availability
  local csa = pos.csa
  if csa > 0 then
    if from == 26 then
      csa = csa - csa%4
    elseif from == 96 then
      csa = csa%4
    else
      local bit = _castling120[from] or _castling120[to]
      if bit and csa%(bit + bit) >= bit then
        csa = csa - bit
      end
    end
    pos.csa = csa
  end
  
  -- Side to move
  pos.stm, pos.opp = pos.opp, pos.stm

--[[
  -- Half move clock
  pos.hmc = pos.hmc + 1
  if (pos[to] > 0) or (isPawn[p1]) then
    -- reset if any pawn has moved or another piece was captured
    pos.hmc = 0
  end

  -- Ply
  pos.ply = pos.ply + 1
]]
  return pos
end

empty = function()
  local pos = {}
  pos.make = makeMove
  pos.legal = isLegal
  pos.moves = getMoves
  return pos
end

--- Initializes an empty board
local _init = {}
for _, sq in ipairs(_mailbox64) do
  _init[sq] = _initial120[sq]
end
_init.stm = 1
_init.opp = 0
_init.eps = 0
_init.csa = 15
_init.ksq = _mailbox64[5]
_init.kop = _mailbox64[61]
--_init.hmc = 0
--_init.ply = 0

initial = function(pos)
  pos = pos or _init
  local pos2 = empty()
  for _, sq in ipairs(_mailbox64) do
    pos2[sq] = pos[sq]
  end
  pos2.stm = pos.stm
  pos2.opp = pos.opp
  pos2.eps = pos.eps
  pos2.csa = pos.csa
  pos2.ksq = pos.ksq
  pos2.kop = pos.kop
  return pos2
end

return
{
  empty = empty,
  initial = initial,
  mailbox120 = _mailbox120,
  mailbox64 = _mailbox64,
}