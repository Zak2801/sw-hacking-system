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

local CurrentStage = -1

local UI = ZKsSWHS.UI or {}


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

function UI.DrawStageBox(w, h, title)
    local boxW, boxH = w * 0.2, 60
    local x, y = -w * 0.1, h * 0.1
    -- Background
    surface.SetDrawColor(0, 0, 0, 230)
    surface.DrawRect(x, y, boxW, boxH)

    -- Border of box
    surface.SetDrawColor(65, 185, 215, 200)
    surface.DrawOutlinedRect(x, y, boxW, boxH)

    -- Border (TODO: REMOVE, THIS IS A DEBUG)
    -- surface.SetDrawColor(65, 185, 215, 15)
    -- surface.DrawOutlinedRect(0, 0, w, h)

    -- Title
    draw.SimpleText(title or "Stage", "DermaLarge", x + boxW / 2, y + boxH / 2, Color(65, 185, 215), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-----------------------------------------------------------------------------
-- Draws the hologram UI
-- @param width number The width of the drawing area
-- @param height number The height of the drawing area
-----------------------------------------------------------------------------
function UI.DrawHologram(width, height)
    local centerX, centerY = width / 2, height / 2
    local radius = math.min(width, height) / 2 - 20
    local holoColor = Color(65, 185, 215, 200)
    local holoColorFaded = Color(65, 185, 215, 50)
    local holoColorVeryFaded = Color(65, 185, 215, 20)

    -- Faded black background
    surface.SetDrawColor(0, 0, 0, 240)
    DrawFilledCircle(centerX, centerY, radius, 64)

    -- Outer circle
    surface.SetDrawColor(holoColor)
    DrawOutlinedCircle(centerX, centerY, radius, 64)

    -- Inner grid
    surface.SetDrawColor(holoColorFaded)
    local gridSize = 40
    -- Vertical lines
    for x = centerX - radius + gridSize, centerX + radius - gridSize, gridSize do
        local halfChord = math.sqrt(radius^2 - (x - centerX)^2)
        surface.DrawLine(x, centerY - halfChord, x, centerY + halfChord)
    end
    -- Horizontal lines
    for y = centerY - radius + gridSize, centerY + radius - gridSize, gridSize do
        local halfChord = math.sqrt(radius^2 - (y - centerY)^2)
        surface.DrawLine(centerX - halfChord, y, centerX + halfChord, y)
    end

    -- Add some more details for the "hologram" feel
    -- Concentric circles
    surface.SetDrawColor(holoColorVeryFaded)
    DrawOutlinedCircle(centerX, centerY, radius * 0.75, 64)
    DrawOutlinedCircle(centerX, centerY, radius * 0.5, 64)
    DrawOutlinedCircle(centerX, centerY, radius * 0.25, 64)

    -- Scanline effect
    surface.SetDrawColor(0, 0, 0, 80)
    local scanlineOffset = (CurTime() * 7) % 4 -- 50 is speed, 4 is the step
    for i = 0, height, 4 do
        local yPos = i - scanlineOffset

        -- check middle of scanline
        local checkY = yPos + 1
        if checkY < (centerY - radius) or checkY > (centerY + radius) then continue end

        local halfChord = math.sqrt(radius^2 - (checkY - centerY)^2)
        surface.DrawRect(centerX - halfChord, yPos, halfChord * 2, 2)
    end
end

function UI.EntryPoint(self)
    if not imgui then
        print("[ZKS.SWHS] Warning: 'imgui' is not available. Cannot draw 3D2D UI.")
        return
    end

    local width, height = 700, 600
    local rad = math.min(width, height) / 2 - 10
    local bMin, bMax = self:GetCollisionBounds()
    local rows, cols = 10, 10
    local padding = 1

    local HackingStageInt = self:GetStage()
    local hackingStage = ZKsSWHS.UI.Stages:Get(HackingStageInt)

    if HackingStageInt ~= CurrentStage then
        print("[ZKS.SWHS] Stage changed to: " .. (G_STAGES[HackingStageInt] or "Unknown") .. " (" .. HackingStageInt .. ")")
        CurrentStage = HackingStageInt
        hackingStage = ZKsSWHS.UI.Stages:Get(HackingStageInt)
        if hackingStage and hackingStage.init then
            print("[ZKS.SWHS] Initializing stage: " .. (G_STAGES[CurrentStage] or "Unknown"))
            hackingStage.init(self)
        end
    end

    -- Draw a 3D2D panel attached to the entity.
    if imgui.Entity3D2D(self, Vector(bMax.x + 5, -bMax.y - 2, bMax.z * 3), Angle(0, 90, 100), 0.1) then

        UI.DrawHologram(width, height)
        UI.DrawStageBox(width, height, hackingStage and hackingStage.name or "Unknown Stage")

        draw.SimpleText("Terminal", imgui.xFont("!Roboto@30"), width / 2 - 50, 30)
        
        if hackingStage and hackingStage.draw then
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
