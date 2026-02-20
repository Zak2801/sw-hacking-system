--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\stages\cl_uplink.lua
  CLIENT
  Establish Unplink stage
---------------------------------------------------------------------------]]

ZKsSWHS = ZKsSWHS or {}
ZKsSWHS.UI = ZKsSWHS.UI or {}
local Stages = ZKsSWHS.UI.Stages


local STAGE = {}
STAGE.ID = 1
STAGE.Name = "Establish Uplink"

-----------------------------------------------------------------------------
-- Initializes the Establish Unplink stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Init = function(self)
    self.TargetWave = {
        freq = math.Rand(2, 5),
        amp = math.Rand(30, 60),
        phase = math.Rand(0, math.pi * 2)
    }
    self.PlayerWave = {
        freq = math.Rand(1, 6),
        amp = math.Rand(20, 70),
        phase = math.Rand(0, math.pi * 2)
    }

    self.EditingParam = 1 -- 1: freq, 2: amp, 3: phase
    self.ParamNames = {"Frequency", "Amplitude", "Phase Shift"}
    self.ParamKeys = {"freq", "amp", "phase"}
    self.LastInputTime = 0

    self.Steps = {
        freq = 0.05,
        amp = 1,
        phase = 0.01
    }

    ZKsSWHS.UI.InfoPanelText = "Align your signal to the target waveform. Use [LEFT SHIFT] to switch parameters, and [UP/DOWN] to adjust."
end

-- Colors
local color_target = Color(0, 255, 0, 100)
local color_text = Color(200, 255, 200)
local color_highlight = Color(255, 255, 0)
local color_bg = Color(0, 0, 0, 150)

-----------------------------------------------------------------------------
-- Draws the Establish Unplink stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Draw = function(self, w, h)
    if not self.TargetWave then return end

    -- Drawing area
    local width = w * 0.5
    local centerX = w / 2
    local yCenter = h * 0.3
    local segments = 100


    local function DrawThickLine(x1, y1, x2, y2, thickness, color)
        surface.SetDrawColor(color)
        local angle = math.atan2(y2 - y1, x2 - x1)
        local dx = math.sin(angle) * thickness / 2
        local dy = -math.cos(angle) * thickness / 2
        
        surface.DrawPoly({
            {x = x1 - dx, y = y1 - dy},
            {x = x1 + dx, y = y1 + dy},
            {x = x2 + dx, y = y2 + dy},
            {x = x2 - dx, y = y2 - dy}
        })
    end

    -- Function to draw a wave
    local function draw_wave(wave_params, y_center, color, animated, thickness)
        local points = {}
        local startX = centerX - width / 2

        for i = 0, segments do
            local x = startX + (i / segments) * width
            local angle = (i / segments) * wave_params.freq + wave_params.phase
            if animated then
                angle = angle + CurTime() * 0.3
            end
            local y = y_center + math.sin(angle) * wave_params.amp
            table.insert(points, {x = x, y = y})
        end

        for i = 1, #points-1 do
            local p1 = points[i]
            local p2 = points[i+1]
            DrawThickLine(p1.x, p1.y, p2.x, p2.y, thickness, color)
        end
    end

    local function LerpColor(t, c1, c2)
        return Color(
            Lerp(t, c1.r, c2.r),
            Lerp(t, c1.g, c2.g),
            Lerp(t, c1.b, c2.b),
            Lerp(t, c1.a, c2.a)
        )
    end

    -- Draw Target Wave (slightly animated)
    draw_wave(self.TargetWave, yCenter, color_target, true, 4)


    -- Calculate difference for player wave color
    local dist_freq = math.abs(self.TargetWave.freq - self.PlayerWave.freq)
    local dist_amp = math.abs(self.TargetWave.amp - self.PlayerWave.amp)
    local dist_phase = math.abs(self.TargetWave.phase - self.PlayerWave.phase)
    dist_phase = math.min(dist_phase, math.pi * 2 - dist_phase) -- normalize phase distance
    local total_dist = dist_freq / 4 + dist_amp / 40 + dist_phase / (math.pi*2)
    
    local player_color = LerpColor(math.min(total_dist, 1), Color(0, 255, 0), Color(255, 0, 0))


    -- Draw Player Wave
    draw_wave(self.PlayerWave, yCenter, player_color, false, 4)


    -- Draw UI Text
    local textY = h * 0.5
    for i=1, 3 do
        local name = self.ParamNames[i]
        local key = self.ParamKeys[i]
        local target_val = self.TargetWave[key]
        local player_val = self.PlayerWave[key]
        
        local textColor = (self.EditingParam == i) and color_highlight or color_text

        draw.SimpleText(name, "DermaDefault", centerX - 200, textY, textColor, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.2f", target_val), "DermaDefault", centerX, textY, color_text, TEXT_ALIGN_CENTER)
        draw.SimpleText(string.format("%.2f", player_val), "DermaDefault", centerX + 200, textY, textColor, TEXT_ALIGN_CENTER)
        textY = textY + 40
    end
    draw.SimpleText("TARGET", "DermaDefault", centerX, textY, color_text, TEXT_ALIGN_CENTER)
    draw.SimpleText("CURRENT", "DermaDefault", centerX + 200, textY, color_text, TEXT_ALIGN_CENTER)
    draw.SimpleText("[LEFT SHIFT] to change param, [UP/DOWN] to adjust", "DermaDefault", centerX, textY + 30, color_text, TEXT_ALIGN_CENTER)


    -- Handle Input
    if self.LastInputTime < CurTime() then
        if input.IsKeyDown(KEY_UP) then
            local key = self.ParamKeys[self.EditingParam]
            self.PlayerWave[key] = self.PlayerWave[key] + self.Steps[key]
            self.LastInputTime = CurTime() + 0.1
        end
        if input.IsKeyDown(KEY_DOWN) then
            local key = self.ParamKeys[self.EditingParam]
            self.PlayerWave[key] = self.PlayerWave[key] - self.Steps[key]
            self.LastInputTime = CurTime() + 0.1
        end

        -- Wrap phase
        if self.PlayerWave.phase > math.pi * 2 then self.PlayerWave.phase = self.PlayerWave.phase - math.pi*2 end
        if self.PlayerWave.phase < 0 then self.PlayerWave.phase = self.PlayerWave.phase + math.pi*2 end

        if input.IsKeyDown(KEY_LSHIFT) then
            self.EditingParam = self.EditingParam + 1
            if self.EditingParam > 3 then self.EditingParam = 1 end
            self.LastInputTime = CurTime() + 0.4
        end
    end
    
    -- Win Condition
    local match_freq = dist_freq < 0.1
    local match_amp = dist_amp < 2
    local match_phase = dist_phase < 0.2

    if match_freq and match_amp and match_phase then
        draw.SimpleText("SIGNAL MATCHED", "DermaLarge", centerX, 100, Color(0,255,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        self:SetStage(self:GetStage() + 1)
    end
end

local succ, err = pcall(function()
    Stages:Register(STAGE)
end)
if not succ then print(err) end