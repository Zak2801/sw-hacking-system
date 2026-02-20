--[[-------------------------------------------------------------------------
  lua\zks_swhs\minigames\cl_cipher.lua
  CLIENT
  Cipher minigame.
---------------------------------------------------------------------------]]

local MINIGAME = {}
MINIGAME.Name = "Cipher"

-- Configuration
MINIGAME.Duration = 30 -- Time in seconds to solve the cipher

-- Word list for the minigame
local WORD_LIST = {
    "HACK", "DATA", "CODE", "WIRE", "CHIP", "NODE", "LINK", "SYSTEM", "SECURE", "LOCK",
    "KEY", "PASS", "GRID", "FLOW", "BYTE", "ROOT", "ADMIN", "USER", "HOST", "PORT",
    "NET", "WEB", "FIRE", "WALL", "ICE", "TRACE", "PROXY", "AGENT", "PROBE"
}

--[[
    Aurebesh Fonts
    This needs to be created once, so we'll do it here.
--]]
surface.CreateFont("ZKsSWHS.UI.Fonts.Aurebesh", {
    font = "Aurebesh",
    size = 48,
    weight = 500,
    antialias = true,
})
MINIGAME.AurebeshFont = "ZKsSWHS.UI.Fonts.Aurebesh"

surface.CreateFont("ZKsSWHS.UI.Fonts.AurebeshSmall", {
    font = "Aurebesh",
    size = 24,
    weight = 500,
    antialias = true,
})
MINIGAME.AurebeshFontSmall = "ZKsSWHS.UI.Fonts.AurebeshSmall"


-----------------------------------------------------------------------------
-- Generates a random word from the WORD_LIST.
-- @return string The random word.
-----------------------------------------------------------------------------
local function GenerateRandomWord()
    return WORD_LIST[math.random(1, #WORD_LIST)]
end

-----------------------------------------------------------------------------
-- Starts the minigame
-- @param node table The node the minigame is being played on.
-- @param callback function The function to call with the result (true for win, false for loss).
-----------------------------------------------------------------------------
function MINIGAME:Start(node, callback)
    self.Node = node
    self.Callback = callback
    self.StartTime = CurTime()
    self.PlainText = GenerateRandomWord()
    LocalPlayer():ChatPrint("Cipher Minigame Started! Translate the Aurebesh cipher to English.")
    LocalPlayer():ChatPrint("DEBUG: The word to translate is '" .. self.PlainText .. "'") -- Remove this line in production!
    self.PlayerInput = ""
    self.Finished = false

    ZKsSWHS.UI.InfoPanelText = "Translate the Aurebesh cipher. Use the keyboard to input your guess."
end

-----------------------------------------------------------------------------
-- Finishes the minigame
-- @param success boolean Whether the minigame was completed successfully.
-----------------------------------------------------------------------------
function MINIGAME:Finish(success)
    self.Finished = true
    if self.Callback then
        self.Callback(success)
    end
end

-----------------------------------------------------------------------------
-- Draws the keyboard and handles input
-- @param x number The X position to start drawing the keyboard.
-- @param y number The Y position to start drawing the keyboard.
-----------------------------------------------------------------------------
function MINIGAME:DrawKeyboard(x, y)
    local keys = {
        {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"},
        {"A", "S", "D", "F", "G", "H", "J", "K", "L"},
        {"Z", "X", "C", "V", "B", "N", "M"}
    }
    local keySize = 40
    local keyGap = 5

    for i, row in ipairs(keys) do
        local rowWidth = (#row * (keySize + keyGap)) - keyGap
        local startX = x - (rowWidth / 2)
        local startY = y + ((i - 1) * (keySize + keyGap))

        for j, key in ipairs(row) do
            local keyX = startX + ((j - 1) * (keySize + keyGap))
            if imgui.xTextButton(key, "DermaDefaultBold", keyX, startY, keySize, keySize, 1) then
                if #self.PlayerInput < #self.PlainText then
                    self.PlayerInput = self.PlayerInput .. key
                end
            end
        end
    end

    -- Special keys (Backspace & Enter)
    local specialY = y + (#keys * (keySize + keyGap)) + keyGap
    if imgui.xTextButton("<- BK", "DermaDefaultBold", x - 105, specialY, 80, 30, 1) then
        self.PlayerInput = self.PlayerInput:sub(1, -2)
    end

    if imgui.xTextButton("ENTER", "DermaDefaultBold", x + 25, specialY, 80, 30, 1) then
        if self.PlayerInput:upper() == self.PlainText:upper() then
            self:Finish(true)
        else
            -- Maybe add a visual indicator for wrong answer
            self.PlayerInput = ""
        end
    end
end

-----------------------------------------------------------------------------
-- Draws the Aurebesh to English dictionary
-- @param x number The X position to start drawing.
-- @param y number The Y position to start drawing.
-----------------------------------------------------------------------------
function MINIGAME:DrawDict(x, y)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    
    -- Background for the dictionary
    draw.RoundedBox(8, x, y, 230, 300, Color(20, 20, 20, 250))
    draw.SimpleText("Dictionary", "DermaDefaultBold", x + 115, y + 10, color_white, TEXT_ALIGN_CENTER)

    local startX = x + 10
    local startY = y + 40
    local lineHeight = 20

    -- Two columns
    for i = 1, 13 do
        -- First column
        local char1 = alphabet:sub(i, i)
        draw.SimpleText(char1 .. " =", "DermaDefault", startX, startY + (i - 1) * lineHeight, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        draw.SimpleText(char1, self.AurebeshFontSmall, startX + 50, startY + (i - 1) * lineHeight, ZKsSWHS.UI.Colors.Highlight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Second column
        local char2 = alphabet:sub(i + 13, i + 13)
        if char2 ~= "" then
            draw.SimpleText(char2 .. " =", "DermaDefault", startX + 110, startY + (i - 1) * lineHeight, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(char2, self.AurebeshFontSmall, startX + 160, startY + (i - 1) * lineHeight, ZKsSWHS.UI.Colors.Highlight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end
end


-----------------------------------------------------------------------------
-- Draws the minigame UI
-----------------------------------------------------------------------------
function MINIGAME:Draw(ent, w, h)
    local centerX, centerY = w / 2, h / 2

    -- In this context, we're already inside a 3D2D context provided by cl_main.
    -- We just need to draw the content relative to the given width (w) and height (h).
    -- The hologram itself is drawn in cl_main.

    -- Title
    draw.SimpleText("Translate the Cipher", "DermaLarge", centerX, 80, ZKsSWHS.UI.Colors.Highlight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Draw the Aurebesh cipher
    draw.SimpleText(self.PlainText, self.AurebeshFont, centerX, 120, ZKsSWHS.UI.Colors.Highlight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    -- Draw the player's input
    local inputWidth = #self.PlainText * 20
    draw.SimpleText(self.PlayerInput, "DermaLarge", centerX, 190, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(color_white)
    surface.DrawRect(centerX - (inputWidth / 2), 220, inputWidth, 2)

    -- Draw the keyboard
    self:DrawKeyboard(centerX, 250)

    -- Draw the dictionary to the right, outside the main hologram circle but within the same 3d2d context
    self:DrawDict(w * 0.95, 80)

    -- Draw the timer
    local progress = math.Clamp(((CurTime() - self.StartTime) / self.Duration), 0, 1)
    if progress >= 1 and not self.Finished then
        self:Finish(false)
    end
    draw.RoundedBox(4, centerX - 100, h - 40, 200, 20, Color(50, 50, 50, 200))
    draw.RoundedBox(4, centerX - 100, h - 40, 200 * (1 - progress), 20, ZKsSWHS.UI.Colors.Highlight)
end


ZKsSWHS.Minigames = ZKsSWHS.Minigames or { Registered = {} }
ZKsSWHS.Minigames.Registered["cipher"] = MINIGAME
