function GAMEMODE:Net_KillRequest(ply)
  net.Start("AU KillRequest")
  net.WriteEntity(ply)
  net.SendToServer()
end

hook.Remove("OnSpawnMenuOpen", "NMW AU RequestKill")

hook.Add("OnSpawnMenuOpen", "NMW AU RequestKill", function()
  local playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer()]

  if playerTable.entity:GetRole().CanKill and IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight:IsPlayer() then
    GAMEMODE:Net_KillRequest(GAMEMODE.KillHighlight)
  end
end)