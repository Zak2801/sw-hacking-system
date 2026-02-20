--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\cl_main.lua
  CLIENT
  Main Frame of the menu
---------------------------------------------------------------------------]]

ZKsSWHS = ZKsSWHS or {}
ZKsSWHS.UI = ZKsSWHS.UI or {}
ZKsSWHS.UI.Data = ZKsSWHS.UI.Data or {}
ZKsSWHS.UI.Stages = ZKsSWHS.UI.Stages or {}

local G_STAGES = {
    [0] = "Not started",
    [1] = "Establish Uplink",
    [2] = "Network Routing",
    [3] = "Bypass Security",
    [4] = "Payload",
    [5] = "Complete"
}

local UI = ZKsSWHS.UI or {}
UI.CurrentStage = -1
UI.InfoPanelText = ""

UI.Colors = {
    Background = Color(0, 0, 0, 200),
    Border = Color(65, 185, 215, 200),
    Text = Color(200, 255, 200),
    Highlight = Color(255, 130, 0),
    Highlight_hover = Color(255, 130, 0, 100),
}

-----------------------------------------------------------------------------
-- Draws an outlined circle since surface.DrawOutlinedCircle doesn't exist
-- @param x number The center x coordinate
-- @param y number The center y coordinate
-- @param radius number The radius of the circle
-- @param segments number The number of segments to use to draw the circle
-----------------------------------------------------------------------------
local function DrawOutlinedCircle(x, y, radius, segments)
    segments = segments or 64
    local angleStep = (2 * math.pi) / segments
    local lastX = x + radius
    local lastY = y

    for i = 1, segments do
        local angle = i * angleStep
        local newX = x + radius * math.cos(angle)
        local newY = y + radius * math.sin(angle)
        surface.DrawLine(lastX, lastY, newX, newY)
        lastX = newX
        lastY = newY
    end
end

-----------------------------------------------------------------------------
-- Draws a filled circle
-- @param x number The center x coordinate
-- @param y number The center y coordinate
-- @param radius number The radius of the circle
-- @param segments number The number of segments to use to draw the circle
-----------------------------------------------------------------------------
local function DrawFilledCircle(x, y, radius, segments)
    segments = segments or 64
    local poly = {}
    for i = 0, segments do
        local ang = (i / segments) * 2 * math.pi
        table.insert(poly, {
            x = x + math.cos(ang) * radius,
            y = y + math.sin(ang) * radius
        })
    end
    surface.DrawPoly(poly)
end

-----------------------------------------------------------------------------
-- Draws a text with wrapping
-- @param text string The text to draw
-- @param font string The font to use
-- @param x number The x coordinate
-- @param y number The y coordinate
-- @param color Color The color of the text
-- @param xalign number The horizontal alignment
-- @param yalign number The vertical alignment
-- @param wrapWidth number The width to wrap the text at
-----------------------------------------------------------------------------
local function DrawWrappedText(text, font, x, y, color, xalign, yalign, wrapWidth)
    surface.SetFont(font)
    local lines = {}
    local currentLine = ""
    local currentWidth = 0
    local spaceWidth = surface.GetTextSize(" ")

    for word in string.gmatch(text, "[^%s]+") do
        local wordWidth = surface.GetTextSize(word)
        if currentWidth + (currentLine == "" and 0 or spaceWidth) + wordWidth > wrapWidth then
            table.insert(lines, currentLine)
            currentLine = word
            currentWidth = wordWidth
        else
            if currentLine ~= "" then
                currentLine = currentLine .. " "
                currentWidth = currentWidth + spaceWidth
            end
            currentLine = currentLine .. word
            currentWidth = currentWidth + wordWidth
        end
    end
    table.insert(lines, currentLine)

    local fontHeight = draw.GetFontHeight(font)
    local totalHeight = #lines * fontHeight

    local startY = y
    if yalign == TEXT_ALIGN_CENTER then
        startY = y - totalHeight / 2
    elseif yalign == TEXT_ALIGN_BOTTOM then
        startY = y - totalHeight
    end
    
    for i, line in ipairs(lines) do
        draw.SimpleText(line, font, x, startY + (i - 1) * fontHeight, color, xalign, TEXT_ALIGN_TOP)
    end
end

-----------------------------------------------------------------------------
-- Draws the box that displays the current stage of the hack.
-- @param w number The width of the panel.
-- @param h number The height of the panel.
-- @param title string The title to display.
-- @param alpha_mul number The alpha multiplier.
-- @param scale_mul number The scale multiplier.
-----------------------------------------------------------------------------
function UI.DrawStageBox(w, h, title, alpha_mul, scale_mul)
    scale_mul = scale_mul or 1
    alpha_mul = alpha_mul or 1
    local panel_cx, panel_cy = w / 2, h / 2
    local orig_boxW, orig_boxH = w, 60
    local orig_x, orig_y = 0, 0
    local box_cx = orig_x + orig_boxW / 2
    local box_cy = orig_y + orig_boxH / 2
    local box_cx_rel = box_cx - panel_cx
    local box_cy_rel = box_cy - panel_cy
    local new_box_cx = panel_cx + box_cx_rel * scale_mul
    local new_box_cy = panel_cy + box_cy_rel * scale_mul
    local boxW, boxH = orig_boxW * scale_mul, orig_boxH * scale_mul
    local x, y = new_box_cx - boxW / 2, new_box_cy - boxH / 2
    -- Background
    surface.SetDrawColor(UI.Colors.Background.r, UI.Colors.Background.g, UI.Colors.Background.b, UI.Colors.Background.a * alpha_mul)
    surface.DrawRect(x, y, boxW, boxH)
    -- Border of box
    surface.SetDrawColor(UI.Colors.Border.r, UI.Colors.Border.g, UI.Colors.Border.b, UI.Colors.Border.a * alpha_mul)
    surface.DrawOutlinedRect(x, y, boxW, boxH)
    -- Title
    local titleColor = Color(UI.Colors.Highlight.r, UI.Colors.Highlight.g, UI.Colors.Highlight.b, UI.Colors.Highlight.a * alpha_mul)
    local font_size = math.max(1, math.floor(24 * scale_mul)) -- DermaLarge is ~24
    draw.SimpleText(title or "Stage", "DermaDefaultBold", new_box_cx, new_box_cy, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-----------------------------------------------------------------------------
-- Draws a box with a title and a value.
-- @param w number The width of the panel.
-- @param h number The height of the panel.
-- @param title string The title to display.
-- @param value string The value to display.
-- @param color Color The color of the value.
-- @param y_offset number The y offset of the box.
-- @param alpha_mul number The alpha multiplier.
-- @param scale_mul number The scale multiplier.
-----------------------------------------------------------------------------
function UI.DrawInfoBox(w, h, title, value, color, y_offset, alpha_mul, scale_mul)
    scale_mul = scale_mul or 1
    alpha_mul = alpha_mul or 1
    local panel_cx, panel_cy = w / 2, h / 2
    local orig_boxW, orig_boxH = w, 40
    local orig_x, orig_y = 0, h * 0.1 + y_offset
    local box_cx = orig_x + orig_boxW / 2
    local box_cy = orig_y + orig_boxH / 2
    local box_cx_rel = box_cx - panel_cx
    local box_cy_rel = box_cy - panel_cy
    local new_box_cx = panel_cx + box_cx_rel * scale_mul
    local new_box_cy = panel_cy + box_cy_rel * scale_mul
    local boxW, boxH = orig_boxW * scale_mul, orig_boxH * scale_mul
    local x, y = new_box_cx - boxW / 2, new_box_cy - boxH / 2
    -- Background
    surface.SetDrawColor(UI.Colors.Background.r, UI.Colors.Background.g, UI.Colors.Background.b, UI.Colors.Background.a * alpha_mul)
    surface.DrawRect(x, y, boxW, boxH)
    -- Border of box
    surface.SetDrawColor(UI.Colors.Border.r, UI.Colors.Border.g, UI.Colors.Border.b, UI.Colors.Border.a * alpha_mul)
    surface.DrawOutlinedRect(x, y, boxW, boxH)
    -- Title
    local titleColor = Color(UI.Colors.Highlight.r, UI.Colors.Highlight.g, UI.Colors.Highlight.b, UI.Colors.Highlight.a * alpha_mul)
    local font_size = math.max(1, math.floor(18 * scale_mul)) -- DermaLarge is ~24
    draw.SimpleText(title, "DermaDefaultBold", new_box_cx - boxW * 0.25, new_box_cy, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    -- Value
    local value_color = color or Color(UI.Colors.Text.r, UI.Colors.Text.g, UI.Colors.Text.b, UI.Colors.Text.a * alpha_mul)
    draw.SimpleText(value, "DermaDefaultBold", new_box_cx + boxW * 0.25, new_box_cy, value_color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-----------------------------------------------------------------------------
-- Draws the info panel.
-- @param w number The width of the panel.
-- @param h number The height of the panel.
-- @param alpha_mul number The alpha multiplier.
-- @param scale_mul number The scale multiplier.
-----------------------------------------------------------------------------
function UI.DrawInfoPanel(w, h, alpha_mul, scale_mul)
    scale_mul = scale_mul or 1
    alpha_mul = alpha_mul or 1
    local panel_cx, panel_cy = w / 2, h / 2
    local orig_boxW, orig_boxH = w, h
    local orig_x, orig_y = 0, 0
    local box_cx = orig_x + orig_boxW / 2
    local box_cy = orig_y + orig_boxH / 2
    local box_cx_rel = box_cx - panel_cx
    local box_cy_rel = box_cy - panel_cy
    local new_box_cx = panel_cx + box_cx_rel * scale_mul
    local new_box_cy = panel_cy + box_cy_rel * scale_mul
    local boxW, boxH = orig_boxW * scale_mul, orig_boxH * scale_mul
    local x, y = new_box_cx - boxW / 2, new_box_cy - boxH / 2

    -- Background
    surface.SetDrawColor(UI.Colors.Background.r, UI.Colors.Background.g, UI.Colors.Background.b, UI.Colors.Background.a * alpha_mul)
    surface.DrawRect(x, y, boxW, boxH)

    -- Border of box
    surface.SetDrawColor(UI.Colors.Border.r, UI.Colors.Border.g, UI.Colors.Border.b, UI.Colors.Border.a * alpha_mul)
    surface.DrawOutlinedRect(x, y, boxW, boxH)

    -- Title
    local titleColor = Color(UI.Colors.Highlight.r, UI.Colors.Highlight.g, UI.Colors.Highlight.b, UI.Colors.Highlight.a * alpha_mul)
    local font_size = math.max(1, math.floor(24 * scale_mul)) -- DermaLarge is ~24
    draw.SimpleText("INFO:", "DermaDefaultBold", new_box_cx, y + 20 * scale_mul, titleColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)


    -- Content
    ZKsSWHS.UI.InfoPanelText = ZKsSWHS.UI.InfoPanelText or ""
    local text_color = Color(UI.Colors.Text.r, UI.Colors.Text.g, UI.Colors.Text.b, UI.Colors.Text.a * alpha_mul)
    DrawWrappedText(ZKsSWHS.UI.InfoPanelText, "DermaDefault", x + 10 * scale_mul, y + 50 * scale_mul, text_color, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, boxW - 20 * scale_mul)
end

-----------------------------------------------------------------------------
-- Draws the hologram UI
-- @param width number The width of the drawing area
-- @param height number The height of the drawing area
-----------------------------------------------------------------------------
function UI.DrawHologram(width, height, alpha_mul, scale_mul)
    scale_mul = scale_mul or 1
    alpha_mul = alpha_mul or 1
    local centerX, centerY = width / 2, height / 2
    local radius = (math.min(width, height) / 2 - 20) * scale_mul
    if radius < 1 then return end
    local holoColor = Color(UI.Colors.Border.r, UI.Colors.Border.g, UI.Colors.Border.b, UI.Colors.Border.a * alpha_mul)
    local holoColorFaded = Color(holoColor.r, holoColor.g, holoColor.b, 50 * alpha_mul)
    local holoColorVeryFaded = Color(holoColor.r, holoColor.g, holoColor.b, 20 * alpha_mul)
    -- Faded black background
    surface.SetDrawColor(UI.Colors.Background.r, UI.Colors.Background.g, UI.Colors.Background.b, UI.Colors.Background.a * alpha_mul)
    DrawFilledCircle(centerX, centerY, radius, 64)
    -- Outer circle
    surface.SetDrawColor(holoColor)
    DrawOutlinedCircle(centerX, centerY, radius, 64)
    -- Inner grid
    surface.SetDrawColor(holoColorFaded)
    local gridSize = 40
    -- Vertical lines
    for x = centerX - radius + gridSize, centerX + radius - gridSize, gridSize do
        if radius > gridSize then
            local halfChord = math.sqrt(radius ^ 2 - (x - centerX) ^ 2)
            surface.DrawLine(x, centerY - halfChord, x, centerY + halfChord)
        end
    end
    -- Horizontal lines
    for y = centerY - radius + gridSize, centerY + radius - gridSize, gridSize do
        if radius > gridSize then
            local halfChord = math.sqrt(radius ^ 2 - (y - centerY) ^ 2)
            surface.DrawLine(centerX - halfChord, y, centerX + halfChord, y)
        end
    end
    -- Add some more details for the "hologram" feel
    -- Concentric circles
    surface.SetDrawColor(holoColorVeryFaded)
    DrawOutlinedCircle(centerX, centerY, radius * 0.75, 64)
    DrawOutlinedCircle(centerX, centerY, radius * 0.5, 64)
    DrawOutlinedCircle(centerX, centerY, radius * 0.25, 64)
    -- Scanline effect
    surface.SetDrawColor(0, 0, 0, 80 * alpha_mul)
    local scanlineOffset = (CurTime() * 7) % 4 -- 50 is speed, 4 is the step
    for i = 0, height, 4 do
        local yPos = i - scanlineOffset
        -- check middle of scanline
        local checkY = yPos + 1
        if checkY < (centerY - radius) or checkY > (centerY + radius) then continue end
        local halfChord = math.sqrt(radius ^ 2 - (checkY - centerY) ^ 2)
        surface.DrawRect(centerX - halfChord, yPos, halfChord * 2, 2)
    end
end

g_Drawing3D2D = false
-----------------------------------------------------------------------------
-- The main entry point for drawing the 3D2D UI.
-- @param self table The entity to draw the UI on.
-----------------------------------------------------------------------------
function UI.EntryPoint(self)
    if not imgui then
        print("[ZKS.SWHS] Warning: 'imgui' is not available. Cannot draw 3D2D UI.")
        return
    end

    g_Drawing3D2D = true

    local width, height = 700, 600
    local rad = math.min(width, height) / 2 - 10
    local bMin, bMax = self:GetCollisionBounds()
    local rows, cols = 10, 10
    local padding = 1
    local HackingStageInt = self:GetStage()
    local hackingStage = ZKsSWHS.UI.Stages:Get(HackingStageInt)
    if HackingStageInt ~= UI.CurrentStage then
        print("[ZKS.SWHS] Stage changed to: " .. (G_STAGES[HackingStageInt] or "Unknown") .. " (" .. HackingStageInt .. ")")
        UI.CurrentStage = HackingStageInt
        hackingStage = ZKsSWHS.UI.Stages:Get(HackingStageInt)
        if hackingStage and hackingStage.init then
            print("[ZKS.SWHS] Initializing stage: " .. (G_STAGES[UI.CurrentStage] or "Unknown"))
            hackingStage.init(self)
        end
    end

    local scale_mul = 1
    local alpha_mul = 1
    if ZKsSWHS.UI.HackStartTime then
        local timeSinceStart = CurTime() - ZKsSWHS.UI.HackStartTime
        local animDuration = 0.3
        if timeSinceStart < animDuration then
            local animProgress = math.Clamp(timeSinceStart / animDuration, 0, 1)
            scale_mul = Lerp(animProgress, 0, 1)
            alpha_mul = Lerp(animProgress, 0, 1)
        end
    end

    local leftBoxW, leftBoxH = 260, 320

    if imgui.Entity3D2D(self, Vector(-10, -58, 44), Angle(0, 90, 40), 0.1) then
        surface.SetDrawColor(0, 0, 0, 150 * alpha_mul)
        surface.DrawRect(0, 0, leftBoxW, leftBoxH)
        UI.DrawStageBox(leftBoxW, leftBoxH, hackingStage and hackingStage.name or "Unknown Stage", alpha_mul, scale_mul)

        local detectionLevel = self:GetDetectionLevel() -- 0-100
        local signalStability = self:GetSignalStability() -- 0-100
        -- Detection Level
        local detection_color = Color(255, 0, 0)
        if detectionLevel < 75 then
            detection_color = Color(255, 255, 0)
        end
        if detectionLevel < 35 then
            detection_color = Color(0, 255, 0)
        end
        UI.DrawInfoBox(leftBoxW, leftBoxH, "Detection", detectionLevel .. "%", detection_color, 70, alpha_mul, scale_mul)
        -- Signal Stability
        local signal_color = Color(0, 255, 0)
        if signalStability < 75 then
            signal_color = Color(255, 255, 0)
        end
        if signalStability < 35 then
            signal_color = Color(255, 0, 0)
        end
        UI.DrawInfoBox(leftBoxW, leftBoxH, "Signal", signalStability .. "%", signal_color, 120, alpha_mul, scale_mul)


        imgui.End3D2D()
    end

    if imgui.Entity3D2D(self, Vector(-10, -13, 44), Angle(0, 90, 40), 0.1) then
        surface.SetDrawColor(0, 0, 0, 150 * alpha_mul)
        surface.DrawRect(0, 0, leftBoxW, leftBoxH)
        UI.DrawInfoPanel(leftBoxW, leftBoxH, alpha_mul, scale_mul)
        imgui.End3D2D()
    end

    -- Draw a 3D2D panel attached to the.
    if imgui.Entity3D2D(self, Vector(bMax.x - 5, -bMax.y + 28, bMax.z * 2.5), Angle(0, 90, 100), 0.1) then
        UI.DrawHologram(width, height, alpha_mul, scale_mul)
        
        local terminalColor = Color(UI.Colors.Text.r, UI.Colors.Text.g, UI.Colors.Text.b, UI.Colors.Text.a * alpha_mul)
        local font_size = math.max(1, math.floor(30 * scale_mul))
        local text_x = width / 2 + 0.1 * scale_mul
        local text_y = height / 2 + (40 - height / 2) * scale_mul
        draw.SimpleText("Terminal", "DermaDefaultBold", text_x, text_y, terminalColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        if self.CurrentMinigame and self.CurrentMinigame.Draw then
            self.CurrentMinigame:Draw(self, width, height)
        elseif hackingStage and hackingStage.draw then
            hackingStage.draw(self, width, height)
        end

        if hackingStage and hackingStage.Completed then
            if hackingStage.completed(self) then
                self:SetStage(self:GetStage() + 1)
            end
        end
        imgui.End3D2D()
    end
end