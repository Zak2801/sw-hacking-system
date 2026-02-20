--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\stages\cl_menu.lua
  CLIENT
  Main menu stage
---------------------------------------------------------------------------]]

ZKsSWHS = ZKsSWHS or {}
ZKsSWHS.UI = ZKsSWHS.UI or {}
local Stages = ZKsSWHS.UI.Stages


local STAGE = {}
STAGE.ID = 0
STAGE.Name = "Main Menu"


-----------------------------------------------------------------------------
-- Initializes the Main Menu stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Init = function(ent)
    STAGE.init = CurTime()
    STAGE.Completed = false
    ZKsSWHS.UI.InfoPanelText = "Hacking System Interface"
end

-----------------------------------------------------------------------------
-- Draws the Main Menu stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Draw = function(ent, w, h)
    local timeSinceInit = CurTime() - (STAGE.init or 0)
    local animDuration = 0.3
    local alpha_mul = math.Clamp(timeSinceInit / animDuration, 0, 1)
    local btnWidth, btnHeight = w / 4 * alpha_mul, 50 * alpha_mul

    local terminalColor = Color(ZKsSWHS.UI.Colors.Highlight.r, ZKsSWHS.UI.Colors.Highlight.g, ZKsSWHS.UI.Colors.Highlight.b, ZKsSWHS.UI.Colors.Highlight.a * alpha_mul)
    local wasPressed = imgui.xTextButton("Start Breach", "DermaLarge", w / 2 - btnWidth / 2, h / 2 - btnHeight / 2, btnWidth, btnHeight, 3, terminalColor, ZKsSWHS.UI.Colors.Highlight_hover)
    if wasPressed then
        ent:SetStage(ent:GetStage() + 1)
        ZKsSWHS.UI.InfoPanelText = ""
    end
end

local succ, err = pcall(function()
    Stages:Register(STAGE)
end)
if not succ then print(err) end