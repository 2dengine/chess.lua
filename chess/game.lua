--- Game representation
-- Parses SAN moves and PGN notation

local _position = require("chess.pos")
local _search = require("chess.search")
local _mailbox120 = _position.mailbox120
local _mailbox64 = _position.mailbox64

-- Piece type 0-12 (4 bits)
local _pieces =
{
  [0] = "-",
  "K", "k",
  "P", "p",
  "N", "n",
  "B", "b",
  "R", "r",
  "Q", "q"
}
local _piecesB = {}
local _piecesC = {}
for k, v in pairs(_pieces) do
  _piecesB[v] = k
  _piecesC[v:byte()] = k
end

-- Side to move 0-1 (2 bits)
local _sides = { [0] = "b", "w" }
local _sidesB = { b = 0, w = 1 }

-- Castling rights 0-16 (4 bits)
-- K = 1, Q = 2, k = 4, q = 8
-- csa%(p + p) >= p
local _csa =
{
  [0] = "-",
  "K", "Q", "KQ",
  "k", "Kk", "Qk",
  "KQk", "q", "Kq",
  "Qq", "KQq", "kq",
  "Kkq", "Qkq", "KQkq"
}
local _csaB = {}
for k, v in pairs(_csa) do
  _csaB[v] = k
end

local _squares =
{
  [0] = "-",
  "a1", "b1", "c1", "d1", "e1", "f1", "g1", "h1",
  "a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2",
  "a3", "b3", "c3", "d3", "e3", "f3", "g3", "h3",
  "a4", "b4", "c4", "d4", "e4", "f4", "g4", "h4",
  "a5", "b5", "c5", "d5", "e5", "f5", "g5", "h5",
  "a6", "b6", "c6", "d6", "e6", "f6", "g6", "h6",
  "a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7",
  "a8", "b8", "c8", "d8", "e8", "f8", "g8", "h8"
}
local _squaresB = {}
for k, v in pairs(_squares) do
  _squaresB[v] = k
end

local _files = {}
local _ranks = {}
for i = 1, 64 do
  local sq = _squares[i]
  _files[i] = sq:sub(1, 1)
  _ranks[i] = sq:sub(2, 2)
end

local function fromFEN(fen)
  -- break string into sections
  fen = fen.." "
  local s = {}
  for sz in fen:gmatch("(.-) ") do
    s[#s + 1] = sz
  end
  local pos = _position.initial()
  -- 1.Piece placement
  local s1 = s[1]
  if s1 then
    local x = 1
    local y = 8
    for i = 1, #s1 do
      local b = s1:byte(i)
      if b >= 49 and b <= 56 then -- 1-8
        -- empty square
        x = x + (b - 48)
      elseif b == 47 then -- /
        -- rank
        x = 1
        y = y - 1
      elseif b == 32 then -- space
        -- end of section
        break
      else
        -- piece
        local p = _piecesC[b]
        if not p then
          return
        end
        local sq = _mailbox64[x + (y - 1)*8]
        pos[sq] = p
        x = x + 1
      end
    end
  end
  -- 2.Side to move
  pos.stm = _sidesB[s[2] or 0]
  -- 3.Castling ability
  pos.csa = _csaB[s[3] or 0]
  -- 4.En Passant square
  pos.eps = _mailbox64[ _squaresB[s[4] or 0] ]
  -- 5.Halfmoves
  pos.hmc = tonumber(s[5] or 0) or 0
  if pos.hmc < 0 then
    pos.hmc = -pos.hmc
  end
  -- 6.Fullmove counter
  local fmc = tonumber(s[6] or 1) or 1
  pos.ply = (fmc - 1)*2
  if pos.stm == _sidesB.b then
    pos.ply = pos.ply + 1
  end
  return pos
end

local concat = table.concat
local function toFEN(pos)
  local s = {}
  local n = 0
  -- 1.Piece placement
  for y = 8, 1, -1 do
    for x = 1, 8 do
      local i = x + (y - 1)*8
      i = _mailbox64[i]
      local p = pos[i]
      if p and p > 0 then
        n = n + 1
        s[n] = _pieces[p]
      else
        local q = s[n]
        if type(q) == "number" then
          s[n] = q + 1
        else
          n = n + 1
          s[n] = 1
        end
      end
    end
    if y > 1 then
      n = n + 1
      s[n] = "/"
    end
  end
  local fen = {}
  fen[1] = concat(s)
  -- 2.Side to move
  fen[2] = _sides[pos.stm]
  -- 3.Castling
  fen[3] = _csa[pos.csa]
  -- 4.En Passant
  fen[4] = _squares[ _mailbox120[pos.eps] ]
  -- 5.Halfmoves
  fen[5] = pos.hmc
  -- 6.Fullmove count
  local fmc = pos.ply
  if pos.stm == _sidesB.b then
    fmc = fmc - 1
  end
  fen[6] = fmc/2 + 1
  return concat(fen, " ")
end

local function toSAN(pos, move)
  local from = move%120
  local to = (move - from)/120
  local moves = pos:moves()
  local p1 = pos[from]
  local p2 = pos[to]
  local out = ""
  -- 0.Castling
  local offset = to - from
  if (p1 == 1 or p1 == 2) and (offset == -2 or offset == 2) then
    if offset == -2 then
      out = "O-O-O"
    elseif offset == 2 then
      out = "O-O"
    end
  else
    local fromsq = _mailbox120[from]
    -- 1.Piece type
    local pawn = p1 == 3 or p1 == 4
    local s1 = ""
    if not pawn then
      s1 = _pieces[p1]:upper()
    end
    -- 2.Source
    local s2 = ""
    if p1 <= 2 then
      if p2 > 0 or to == pos.eps then
        s2 = _squares[fromsq]:sub(1, 1)
      end
    elseif p1 <= 10 then
      -- disambiguation
      local a, f, r = false, false, false
      local file = (from - 1)%10
      local rank = (from - 1 - file)/10
      --for j = 1, #moves, 2 do
      for _, w in ipairs(moves) do
        local from2 = w%120
        local to2 = (w - from2)/120
        if from ~= from2 and to == to2 and p1 == pos[from2] then
          local file2 = (from2 - 1)%10
          local rank2 = (from2 - 1 - file2)/10
          a = true
          if file == file2 then
            r = true
          elseif rank == rank2 then
            f = true
          end
        end
      end
      if a then
        local sq = _squares[fromsq]
        if f and r then
          s2 = sq
        elseif r then
          s2 = sq:sub(2, 2)
        else
          s2 = sq:sub(1, 1)
        end
      end
    end
    -- 3.Capture
    local s3 = ""
    if (p2 > 0) or (pawn and to == pos.eps) then
      s3 = "x"
    end
    -- 4.Destination
    local tosq = _mailbox120[to]
    local s4 = _squares[tosq]
    -- 5.Promotion
    local s5 = ""
    if pawn then
      if to <= 29 or to >= 92 then
        -- assume queen
        pos.promo = p1 + 8
        s5 = "=".._pieces[pos.promo]
      end
    end
    out = s1..s2..s3..s4..s5
  end
  return out
end

local function fromSAN(pos, san)
  local black = pos.stm == 0
  local move, promo = san:match("^([%w%-]+)=?([QRNB]?)")
  if promo ~= "" then
    local q = _piecesB[promo]
    pos.promo = black and (q + 1) or q
  end
  if move == "O-O" then
    return pos.ksq, pos.ksq + 2
  elseif move == "O-O-O" then
    return pos.ksq, pos.ksq - 2
  else
    local d = move:sub(-2, -1)
    local p, f, r = move:match("^([KQRBN]?)([abcdefgh]?)([%d]?)")
    local to = _squaresB[d]
    local piece = _piecesB[p] or 1
    if black then
      piece = piece + 1
    end
    local moves = pos:moves()
    local from = nil
    if #moves == 1 then
      from = moves[1]%120
    else
      for _, v in ipairs(moves) do
        local src = _mailbox64[v%120]
        if f == _files[src] or r == _ranks[src] then
          from = src
          break
        end
      end
    end
    --return from, to
    return from + to*120
  end
end

local function fen(game, s)
  local pos = game.pos
  if s then
    -- set position
    pos = fromFEN(s)
    game.pos = pos
    return pos
  else
    -- get position
    return toFEN(pos)
  end
end

local function san(game, move)
  local pos = game.pos
  if move then
    -- convert move
    if type(move) == "number" then
      return toSAN(pos, move)
    else
      return fromSAN(pos, move)
    end
  else
    -- get moves
    local moves = pos:moves()
    local list = {}
    for i, v in ipairs(moves) do
      list[i] = toSAN(pos, v)
    end
    return list
  end
end

local function fromAN(pos, an)
  local from = _squaresB[an:sub(1,2)]
  local to = _squaresB[an:sub(3,4)]
  --return _mailbox64[from], _mailbox64[to]
  return _mailbox64[from] + _mailbox64[to]*120
end

local function toAN(pos, move)
  local from = move%120
  local to = (move - from)/120
  from = _mailbox120[from]
  to = _mailbox120[to]
  return _squares[from].._squares[to]
end

local function an(game, move)
  local pos = game.pos
  if move then
    -- convert move
    if type(move) == "number" then
      return toAN(pos, move)
    else
      return fromAN(pos, move)
    end
  else
    -- get moves
    local moves = pos:moves()
    local list = {}
    for i, v in ipairs(moves) do
      list[i] = toAN(pos, v)
    end
    return list
  end
end

local function search(game, depth)
  return _search(game.pos, depth)
end

local function movePiece(game, move)
  local pos = game.pos
  if pos:legal(move) then
    pos = pos:make(move)
    game.pos = pos
    return pos
  end
end

local function getPiece(game, x, y)
  local sq = _mailbox64[(y - 1)*8 + x]
  return game.pos[sq]
end

return function(s)
  local game = {}
  
  game.pos = s and fromFEN(s) or _position.initial()
  
  game.piece = getPiece
  game.move = movePiece
  game.search = search
  game.fen = fen
  game.san = san
  game.an = an

  return game
end
