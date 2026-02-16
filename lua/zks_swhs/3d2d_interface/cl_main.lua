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

function UI.EntryPoint(self)
    if not imgui then
        print("[ZKS.SWHS] Warning: 'imgui' is not available. Cannot draw 3D2D UI.")
        return
    end

    local width, height = 1000, 1000
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
    if imgui.Entity3D2D(self, Vector(0, 0, 30), Angle(0, 0, 0), 0.1) then
        
        local matrix = Matrix()
        matrix:Translate(Vector(-width / 2, -height / 2, 0))
        cam.PushModelMatrix(matrix)

        surface.SetDrawColor(150, 150, 150, 245)
        surface.DrawRect(0, 0, width, height)

        surface.SetDrawColor(5, 40, 40, 245)

        local cellW = (width - (cols+1)*padding) / cols
        local cellH = (height - (rows+1)*padding) / rows

        for y = 1, rows do
            for x = 1, cols do
                local px = padding + (x-1) * (cellW + padding)
                local py = padding + (y-1) * (cellH + padding)
                surface.DrawRect(px, py, cellW, cellH)
            end
        end

        surface.SetDrawColor(0, 0, 0, 240)
        local tWidth = width / 2 - cellW * 2 - padding * 2
        surface.DrawRect(tWidth, padding, cellW * 4 + padding * 4, cellH + padding * 2)
        draw.SimpleText(G_STAGES[self:GetStage()] or "Unknown Stage", "DermaLarge", tWidth + cellW * 2 + padding * 2, padding + cellH / 2 + padding, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        if hackingStage and hackingStage.draw then
            hackingStage.draw(self)
        end

        if hackingStage and hackingStage.completed then
            if hackingStage.completed(self) then
                self:SetStage(self:GetStage() + 1)
            end
        end
        
        cam.PopModelMatrix()

        imgui.End3D2D()
    end
end