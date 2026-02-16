util.AddNetworkString("ZKS.SWHS.AbortHack")

net.Receive("ZKS.SWHS.AbortHack", function(len, ply)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    ent:SetState(0)
    ent:SetStage(0)
end)