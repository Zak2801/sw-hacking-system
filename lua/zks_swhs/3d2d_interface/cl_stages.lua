--[[-------------------------------------------------------------------------
  lua\zks_swhs\3d2d_interface\cl_stages.lua
  CLIENT
  Establish Unplink stage
---------------------------------------------------------------------------]]

ZKsSWHS = ZKsSWHS or {}
ZKsSWHS.UI = ZKsSWHS.UI or {}
ZKsSWHS.UI.Stages = ZKsSWHS.UI.Stages or {}

local Stages = ZKsSWHS.UI.Stages

function Stages:Register(STAGE)
    local id = STAGE.ID
    local name = STAGE.Name
    local initFunc = STAGE.Init
    local drawFunc = STAGE.Draw

    if not id or not name or not initFunc or not drawFunc then
        print("[SWHS] Error: Invalid stage registration. All parameters are required.")
        return
    end

    if self[id] then
        print("[SWHS] Warning: Stage with ID " .. id .. " is already registered. Overwriting.")
    end

    self[id] = {
        name = name,
        init = initFunc,
        draw = drawFunc
    }

    print("[SWHS] Registered stage: " .. name .. " (ID: " .. id .. ")")
end

function Stages:Get(id)
    if not id then
        print("[SWHS] Error: Invalid stage ID. ID is required.")
        return nil
    end
    return self[id]
end