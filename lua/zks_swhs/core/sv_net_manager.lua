--[[-------------------------------------------------------------------------
  lua\zks_swhs\core\sv_net_manager.lua
  SERVER
  Handles networking for the hacking system.
---------------------------------------------------------------------------]]

util.AddNetworkString("ZKS.SWHS.AbortHack")
util.AddNetworkString("ZKS.SWHS.UpdateStatus")

net.Receive("ZKS.SWHS.AbortHack", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:SetState(0)
    ent:SetStage(0)
end)

-----------------------------------------------------------------------------
-- Receives updates from the client about hacking progress.
-- @param len number The length of the net message.
-- @param ply Player The player who sent the message.
-----------------------------------------------------------------------------
net.Receive("ZKS.SWHS.UpdateStatus", function(len, ply)
    local ent = net.ReadEntity()
    local detectionAdd = net.ReadInt(16)
    local signalAdd = net.ReadInt(16)

    if not IsValid(ent) then return end
    -- Basic distance check to prevent remote hacking exploitation
    if ply:GetPos():DistToSqr(ent:GetPos()) > 10000 then return end

    if detectionAdd ~= 0 then
        ent:SetDetectionLevel(math.Clamp(ent:GetDetectionLevel() + detectionAdd, 0, 100))
    end

    if signalAdd ~= 0 then
        ent:SetSignalStability(math.Clamp(ent:GetSignalStability() + signalAdd, 0, 100))
    end
end)
