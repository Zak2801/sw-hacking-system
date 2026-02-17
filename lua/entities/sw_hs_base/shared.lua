--[[-------------------------------------------------------------------------
  lua\entities\sw_he_base_entity\shared.lua
  SHARED
  Base entity for all hackable devices in the framework
---------------------------------------------------------------------------]]

ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Base"
ENT.Author = "Zaktak"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Category = "[SW-HackingSystem] - Base Entities"

-----------------------------------------------------------------------------
-- Sets up the networked variables for the entity
-- @return nil
-----------------------------------------------------------------------------
function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "State")  -- 0 = Idle, 1 = Hacking, 2 = Hacked
    self:NetworkVar("Int", 1, "Stage") -- 0 = Not started, 1 = Establish Uplink , 2 = Network Routing, 3 = Bypass Security, 4 = Payload, 5 = Complete
    self:NetworkVar("Int", 2, "DetectionLevel") -- 0-100
    self:NetworkVar("Int", 3, "SignalStability") -- 0-100
end
