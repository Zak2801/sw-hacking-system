--[[-------------------------------------------------------------------------
  lua\zks_swhs\minigames\cl_cipher.lua
  CLIENT
  Cipher minigame.
---------------------------------------------------------------------------]]

local MINIGAME = {}
MINIGAME.Name = "Cipher"

-----------------------------------------------------------------------------
-- Starts the minigame
-- @param node table The node the minigame is being played on.
-- @param callback function The function to call with the result (true for win, false for loss).
-----------------------------------------------------------------------------
function MINIGAME:Start(node, callback)
    self.Node = node
    self.Callback = callback
    self.StartTime = CurTime()
    self.Duration = 3 -- 3 seconds to "solve"

    -- Since this is a placeholder, we'll just use a timer to simulate the game.
    timer.Simple(self.Duration, function()
        -- Ensure the minigame hasn't been cancelled
        if self and self.Callback then
            self.Callback(true) -- always succeed for now
        end
    end)
end

-----------------------------------------------------------------------------
-- Draws the minigame UI
-----------------------------------------------------------------------------
function MINIGAME:Draw(ent, w, h)
    -- Draw something simple for now
    local frameX, frameY = w / 2, h / 2
    local frameW, frameH = 300, 100

    local pnlW, pnlH = 700, 600 
    frameX, frameY = pnlW/2, pnlH/2


    draw.RoundedBox(8, frameX - frameW/2, frameY - frameH/2, frameW, frameH, Color(20,20,20,200))
    draw.SimpleText("Solving Cipher...", "DermaLarge", frameX, frameY - 20, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    local progress = math.Clamp(((CurTime() - self.StartTime) / self.Duration), 0, 1)
    draw.RoundedBox(4, frameX - 100, frameY + 20, 200, 20, Color(50,50,50,200))
    draw.RoundedBox(4, frameX - 100, frameY + 20, 200 * progress, 20, ZKsSWHS.UI.Colors.Highlight)
end


ZKsSWHS.Minigames = ZKsSWHS.Minigames or { Registered = {} }
ZKsSWHS.Minigames.Registered["cipher"] = MINIGAME