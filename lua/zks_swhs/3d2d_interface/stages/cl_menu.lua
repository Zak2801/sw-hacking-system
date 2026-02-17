--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\stages\cl_menu.lua
  CLIENT
  Main menu stage
---------------------------------------------------------------------------]]

local Stages = ZKsSWHS.UI.Stages


local STAGE = {}
STAGE.ID = 0
STAGE.Name = "Main Menu"

-----------------------------------------------------------------------------
-- Initializes the Main Menu stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Init = function(self)
    self.Completed = false
end

-----------------------------------------------------------------------------
-- Draws the Main Menu stage
-- @param self table The entity
-----------------------------------------------------------------------------
STAGE.Draw = function(self, w, h)
    local btnWidth, btnHeight = w / 4, 50
    local wasPressed = imgui.xTextButton("Start Breach", "DermaLarge", w / 2 - btnWidth / 2, h / 2 - btnHeight / 2, btnWidth, btnHeight, 3)
    if wasPressed then
        self:SetStage(self:GetStage() + 1)
    end
end

local succ, err = pcall(function()
    Stages:Register(STAGE)
end)
if not succ then print(err) end