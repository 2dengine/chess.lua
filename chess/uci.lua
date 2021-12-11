local newgame = require("chess.game")
local game = newgame()

local function send(s)
  s = s.."\n"
  io.write(s)
  io.flush()
end

local cmd = {}

function cmd.uci(params)
  send("id CHESS.LUA 1.0")
  send("id author 2dengine")
  send("uciok")
end

function cmd.isready(params)
  send("readyok")
end

function cmd.ucinewgame(params)
  game = newgame()
end

function cmd.position(params)
  local fen, moves = params:match("^%s*(.+)%s+moves%s+(.*)$")
  if fen == "startpos" then
    fen = nil
  end
  game = newgame(fen)
  if moves then
    moves = moves.." "
    for an in moves:gmatch("[^%s]+") do
      local move = game:an(an)
      game:move(move)
    end
  end
end

function cmd.go(params)
  local depth = params:match("depth%s+(%d+)")
  depth = tonumber(depth) or 5
  local t1 = os.clock()
  local move, nodes = game:search(depth)
  local t2 = os.clock()
  if move then
    local sec = t2 - t1
    local nps = nodes/sec
    local info = string.format("info depth %d nodes %d nps %d", depth, nodes, nps)
    send(info)
    local an = game:an(move)
    send("bestmove "..an)
    game:move(move)
  end
end

function cmd.quit()
  os.exit()
end

send("loaded")
return function(var)
  local c, r = var:match("^%s*(%a+)(.*)$")
  if c and cmd[c] then
    cmd[c](r)
  end
end