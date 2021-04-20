function GAMEMODE:TracePlayer(playerTable, filter)
  filter = filter or 0
  local startTime = SysTime()
  if not (self:IsGameInProgress()) then return end

  -- Fetch the player table if we haven't been provided one.
  if type(playerTable) == "Player" then
    playerTable = playerTable:GetAUPlayerTable()
  end

  -- Bail if the player table is invalid, or if the player is in a vent.
  if not playerTable or (SERVER and self.GameData.Vented[playerTable]) or (CLIENT and self.GameData.Vented) then return end
  local ply = playerTable.entity
  local role = ply:GetRole()
  local startPos = ply:EyePos()
  local entities = ents.FindInSphere(startPos, self.BaseUseRadius)
  -- Define all three classes of entities this function can possibly report.
  local usable, highlightable, reportable
  local distMemo = {}

  for _, ent in ipairs(entities) do
    -- Simply check if the entity isn't the player.
    if ent == ply then continue end
    -- Check if the entity is in PVS.
    -- This is the only check that can't be done on the client, unfortunately.
    if SERVER and not ply:TestPVS(ent) then continue end

    -- Calculate the nearest point to the cursor.
    if not distMemo[ent] then
      local nearestPoint = ent:NearestPoint(startPos)
      distMemo[ent] = nearestPoint:DistToSqr(ply:EyePos() + ply:GetAimVector() * 32)
    end

    local isBody = self:IsPlayerBody(ent)

    -- Store if body.
    if isBody and (filter == self.TracePlayerFilter.None or filter == self.TracePlayerFilter.Reportable) then
      -- Only return the body if the player isn't dead.  
      if self.GameData.DeadPlayers[playerTable] then continue end

      if not reportable or distMemo[ent] > distMemo[reportable] then
        reportable = ent
      end

      continue
      -- Bail if the filter is set to target bodies.
    elseif filter == self.TracePlayerFilter.Reportable then
      continue
    end

    local isUsable = not isBody and not ent:IsPlayer()
    if not isUsable then continue end
    local isHightlightable = self:ShouldHighlightEntity(ent)
    -- If we found a highlightable entity already and the current entity isn't highlightable,
    -- then bail since there's no point in checking it.
    if highlightable and not isHightlightable then continue end
    -- Return if the current found entity is farther than the last stored.
    local otherDist = distMemo[highlightable or usable]
    if otherDist and otherDist < distMemo[ent] then continue end
    -- No point entities. No view models.
    if not ent:GetModel() or ent:GetModelRadius() == 0 then continue end
    local entClass = ent:GetClass()
    -- Don't match triggers.
    if string.match(entClass, "^trigger_") then continue end

    -- Task buttons.
    if entClass == "func_task_button" or entClass == "prop_task_button" then
      local name = ent:GetTaskName()
      -- Quite simply just bail out if the player has no tasks.
      if not role.HasTasks then continue end
      -- Bail if the meeting is in progress.
      if self:IsMeetingInProgress() then continue end

      if SERVER then
        -- Bail out if the player doesn't have this task, or if it's not the current button,
        -- or if the button doesn't consent.
        if not (self.GameData.Tasks[playerTable] and self.GameData.Tasks[playerTable][name]) or ent ~= self.GameData.Tasks[playerTable][name]:GetActivationButton() or not self.GameData.Tasks[playerTable][name]:CanUse() then continue end
      else
        -- Bail out if the local player doesn't have this task, or if he's completed it already, or
        -- if the button doesn't consent.
        if not self.GameData.MyTasks[name] or self.GameData.MyTasks[name]:GetCompleted() or ent ~= self.GameData.MyTasks[name]:GetActivationButton() or not self.GameData.MyTasks[name]:CanUse() then continue end
      end
    end

    -- Prevent dead players from being able to target corpses.
    if entClass == "prop_ragdoll" and self.GameData.DeadPlayers[playerTable] then continue end
    -- Prevent regular and dead players from using vents.
    if (entClass == "func_vent" or entClass == "prop_vent") and (not role.CanVent or self.GameData.DeadPlayers[playerTable]) then continue end

    -- Only highlight sabotage buttons when they're active, and when the player isn't dead.
    if (entClass == "func_sabotage_button" or entClass == "prop_sabotage_button") then
      if self.GameData.DeadPlayers[playerTable] or not self.GameData.SabotageButtons[ent] then
        continue
      elseif self:IsMeetingInProgress() then
        continue
      end
    end

    -- Only highlight doors when requested by sabotages.
    if (entClass == "func_door" or entClass == "func_door_rotating") and (self.GameData.DeadPlayers[playerTable] or not self.GameData.SabotageButtons[ent]) then continue end
    -- Only hightlight meeting buttons for alive players.
    if (entClass == "func_meeting_button" or entClass == "prop_meeting_button") and self.GameData.DeadPlayers[playerTable] then continue end

    if isHightlightable then
      highlightable = ent
    end

    usable = ent
  end

  LAST_TRACE_PLAYER_TIME = 1000 * (SysTime() - startTime)

  if self.TracePlayerFilter.Reportable == filter then
    return reportable
  elseif self.TracePlayerFilter.Usable == filter then
    return usable
  else
    return usable, reportable
  end
end