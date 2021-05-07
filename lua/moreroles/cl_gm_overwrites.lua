function GAMEMODE:Net_KillRequest(ply)
  net.Start("AU KillRequest")
  net.WriteEntity(ply)
  net.SendToServer()
end

hook.Remove("OnSpawnMenuOpen", "NMW AU RequestKill")

hook.Add("OnSpawnMenuOpen", "NMW AU RequestKill", function()
  local playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer()]

  if playerTable and playerTable.entity:GetRole().CanKill and IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight:IsPlayer() then
    GAMEMODE:Net_KillRequest(GAMEMODE.KillHighlight)
  end
end)

local nextTickCheck
hook.Remove("Tick", "NMW AU Highlight")

hook.Add("Tick", "NMW AU Highlight", function()
  -- Operate at ~20 op/s. We don't need this to be any faster
  -- since TracePlayer can potentially be terribly inefficient.
  -- Realistically this shouldn't ever be a problem.
  -- Ha-ha.
  -- Unless...?
  if SysTime() < (nextTickCheck or 0) then return end

  -- Don't trace while the meeting is in progress.
  if GAMEMODE:IsMeetingInProgress() then
    GAMEMODE.UseHighlight = nil
    GAMEMODE.ReportHighlight = nil
    GAMEMODE.KillHighlight = nil
    nextTickCheck = SysTime() + 1

    return
  end

  local localPlayer = LocalPlayer()
  local playerTable = IsValid(localPlayer) and localPlayer:GetAUPlayerTable()

  -- Wait, it's all invalid?
  if not playerTable then
    GAMEMODE.UseHighlight = nil
    GAMEMODE.ReportHighlight = nil
    GAMEMODE.KillHighlight = nil
    nextTickCheck = SysTime() + 1

    return
  end

  nextTickCheck = SysTime() + (1 / 20)
  local usable, reportable = GAMEMODE:TracePlayer(playerTable)
  local oldHighlight = GAMEMODE.UseHighlight
  GAMEMODE.UseHighlight = GAMEMODE:ShouldHighlightEntity(usable) and usable
  GAMEMODE.ReportHighlight = reportable

  -- Determine the closest player if player can kill.
  if playerTable and localPlayer:GetRole().CanKill and not playerTable.entity:IsDead() then
    local closest, min

    for _, target in pairs(player.GetAll()) do
      local targetTable = target:GetAUPlayerTable()
      -- Bail if no table.
      if not targetTable or not targetTable.entity then continue end
      -- Bail if teammate.
      if roleselection.teams[target] == localPlayer:GetTeam() then continue end
      -- Bail if dead or dormant.
      -- Both are basically the same thing, but it's better to be on the safe side.
      if target:IsDormant() or target:IsDead() then continue end
      local currentDist = target:GetPos():DistToSqr(localPlayer:EyePos() + localPlayer:GetAimVector() * 32)

      if not closest or currentDist < min then
        closest = target
        min = currentDist
      end
    end

    if closest then
      -- Do the expensive math to see if the closest target is actually within the kill radius.
      -- Please note that spoofing this check will not actually grant you the ability
      -- to kill anyone on the map regardless of the distance.
      -- This is purely visual stuff.
      local radius = GAMEMODE.BaseUseRadius * GAMEMODE.ConVarSnapshots.KillDistanceMod:GetFloat()

      if radius * radius < (closest:NearestPoint(localPlayer:GetPos())):DistToSqr(localPlayer:NearestPoint(closest:GetPos())) then
        closest = nil
      end
    end

    GAMEMODE.KillHighlight = closest
  else
    -- Should probably not do that.
    GAMEMODE.KillHighlight = nil
  end

  if GAMEMODE.Hud then
    if GAMEMODE.UseHighlight ~= oldHighlight then
      local material = IsValid(GAMEMODE.UseHighlight) and hook.Call("GMAU UseButtonOverride", nil, GAMEMODE.UseHighlight)

      if GAMEMODE.Hud.UseButtonOverride ~= material then
        GAMEMODE.Hud.UseButtonOverride = material
      end
    end

    oldHighlight = GAMEMODE.UseHighlight
  end
end)