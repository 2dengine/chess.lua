local position = require("chess.pos")
local eval = require("chess.eval")

--- Hashing positions
local _mailbox64 = position.mailbox64
local _char = {}
for i = 0, 255 do
  _char[i] = string.char(i)
end
local _concat = table.concat
local _temp = {}
local _positions = {}
local function storePosition(pos)
  local h = pos.hash
  if not h then
    for i, sq in ipairs(_mailbox64) do
      _temp[i] = _char[ pos[sq] ]
    end
    _temp[65] = _char[pos.stm]
    _temp[66] = _char[pos.eps]
    _temp[67] = _char[pos.csa]
    h = _concat(_temp)
  end
  local p = _positions[h]
  if p then
    pos = p
  else
    pos.hash = h
    _positions[h] = pos
  end
  return pos
end

--- Move sorting
local _sort = table.sort
local _cache = {}
local function ascending(a, b)
  return _cache[a] < _cache[b]
end
local function descending(a, b)
  return _cache[a] > _cache[b]
end
local function sortMoves(pos, depth)
  local func = (pos.stm == 1) and ascending or descending
  pos = storePosition(pos)
  local moves = pos:moves()
  if not moves.sorted then
    for _, move in ipairs(moves) do
      local res = pos:make(move)
      res = storePosition(res)
      _cache[move] = eval(res)
      moves[move] = res
    end
    _sort(moves, func)
    for k in pairs(_cache) do
      _cache[k] = nil
    end
    moves.sorted = func
  end
  if depth > 0 then
    depth = depth - 1
    for _, move in ipairs(moves) do
      sortMoves(moves[move], depth)    
    end
  end
  return moves
end

--- Search function
local nodes = 0
local maxdepth = 0
local function minimax(pos, depth, alpha, beta, white)
  if depth == 0 then
    return eval(pos)
  end
  pos = storePosition(pos)
  --sortMoves(pos)
  nodes = nodes + 1
  depth = depth - 1
  local moves = pos:moves()
  local best, found
  if white then
    -- maximize score
    best = -math.huge
    for i = #moves, 1, -1 do
      local move = moves[i]
      local res = moves[move] or pos:make(move)
      local score = minimax(res, depth, alpha, beta, false)
      if score > best then
        best = score
        found = move
        if score > alpha then
          alpha = score
          -- pruning
          if alpha >= beta then
            break
          end
        end
      end
    end
  else
    -- minimize score
    best = math.huge
    for i = #moves, 1, -1 do
      local move = moves[i]
      local res = moves[move] or pos:make(move)
      local score = minimax(res, depth, alpha, beta, true)
      if score < best then
        best = score
        found = move
        if score < beta then
          beta = score
          -- pruning
          if beta <= alpha then
            break
          end
        end
      end
    end
  end
  return best, found
end

return function(pos, depth)
  nodes = 0
  maxdepth = depth
  pos = storePosition(pos)
  sortMoves(pos, 2)
  local best, move = minimax(pos, depth, -math.huge, math.huge, pos.stm == 1)
  for k in pairs(_positions) do
    _positions[k] = nil
  end
  return move, nodes
end