function GAMEMODE:Game_Start()
  -- Bail if the manifest is missing or malformed.
  if not (GAMEMODE.MapManifest and GAMEMODE.MapManifest.Tasks) then return end
  -- Bail if the game is already in progress.
  if GAMEMODE:IsGameInProgress() then return end
  -- Fetch a table of initialized players.
  local initializedPlayers = GAMEMODE:GetFullyInitializedPlayers()
  -- Bail if we don't have enough players.
  -- TO-DO: print chat message.
  if #initializedPlayers < GAMEMODE.ConVars.MinPlayers:GetInt() then return end
  local handle = "tryStartGame"
  GAMEMODE.GameData.Timers[handle] = true
  local time = GAMEMODE.ConVars.Countdown:GetFloat() + 0.5
  GAMEMODE:Net_BroadcastCountdown(CurTime() + time)
  GAMEMODE.Logger.Info("Starting in " .. tostring(time) .. " s.")
  GAMEMODE:SetGameCommencing(true)
  GAMEMODE:ConVarSnapshot_Take()
  GAMEMODE:Net_BroadcastConVarSnapshots(GAMEMODE:ConVarSnapshot_ExportAll())

  timer.Create(handle, time, 1, function()
    GAMEMODE:SetGameCommencing(false)
    -- Reset the player table.
    initializedPlayers = GAMEMODE:GetFullyInitializedPlayers()
    -- Bail if we don't have enough players. Again.
    -- TO-DO: print chat message.
    if #initializedPlayers < GAMEMODE.ConVars.MinPlayers:GetInt() then return end
    hook.Call("GAMEMODEAU PreGameStart")
    -- Create the time limit timer if the cvar is set.
    -- That's quite an interesting sentence.
    local timelimit = GAMEMODE.ConVarSnapshots.TimeLimit:GetInt()
    local timelimitHandle = "timelimit"

    if timelimit > 0 then
      GAMEMODE.GameData.Timers[timelimitHandle] = true
      GAMEMODE:SetTimeLimit(timelimit)

      timer.Create(timelimitHandle, 1, timelimit, function()
        local remainder = timer.RepsLeft(timelimitHandle)
        GAMEMODE:SetTimeLimit(remainder)
        if remainder == 0 then return GAMEMODE:Game_CheckWin() end
      end)

      timer.Pause(timelimitHandle)
    else
      GAMEMODE:SetTimeLimit(-1)
    end

    -- Create player "accounts" that we're going
    -- to use during the entire game.
    for i = 1, #initializedPlayers do
      local ply = initializedPlayers[i]

      local t = {
        steamid = ply:SteamID(),
        nickname = ply:Nick(),
        entity = ply,
        id = i - 1
      }

      table.insert(GAMEMODE.GameData.PlayerTables, t)
      GAMEMODE.GameData.Lookup_PlayerByID[i - 1] = t
      GAMEMODE.GameData.Lookup_PlayerByEntity[ply] = t
    end

    -- Make everyone else spectators.
    for _, ply in ipairs(player.GetAll()) do
      if not GAMEMODE.GameData.Lookup_PlayerByEntity[ply] then
        GAMEMODE:Player_HideForAlivePlayers(ply)
        GAMEMODE:Spectate_CycleMode(ply)
      end
    end

    for index, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
      ply.entity:Freeze(true)
      ply.entity:SetNWInt("NMW AU Meetings", GAMEMODE.ConVarSnapshots.MeetingsPerPlayer:GetInt())
    end

    roleselection.SelectRoles()
    -- Assign colors to players in rounds.
    local colorRounds = math.ceil(#GAMEMODE.GameData.PlayerTables / #GAMEMODE.Colors)

    for round = 1, colorRounds do
      local colors = GAMEMODE.Colors
      local slicedPlayers = {}
      local lowerBound = 1 + (round - 1) * #GAMEMODE.Colors
      local upperBound = round * #GAMEMODE.Colors

      for i = lowerBound, upperBound < 0 and #GAMEMODE.GameData.PlayerTables + upperBound or upperBound do
        slicedPlayers[#slicedPlayers + 1] = GAMEMODE.GameData.PlayerTables[i]
      end

      -- Sort by time
      table.sort(slicedPlayers, function(a, b) return a.entity:TimeConnected() < b.entity:TimeConnected() end)
      local assigned = {}

      -- Assign preferred colors first
      for _, ply in ipairs(slicedPlayers) do
        local preferred = math.floor(math.min(#GAMEMODE.Colors, math.max(1, ply.entity:GetInfoNum("au_preferred_color", 1))))

        if preferred ~= 0 and colors[preferred] then
          ply.color = colors[preferred]
          ply.entity:SetPlayerColor(ply.color:ToVector())
          colors[preferred] = nil
          assigned[ply] = true
        end
      end

      -- Iterate again, assigning random colors to the rest of the players.
      for _, ply in ipairs(slicedPlayers) do
        if not assigned[ply] then
          local color, id = table.Random(colors)
          ply.color = color
          ply.entity:SetPlayerColor(ply.color:ToVector())
          colors[id] = nil
        end
      end
    end

    -- Broadcast the important stuff that players must know about the game.
    GAMEMODE:SetGameInProgress(true)
    GAMEMODE:Net_BroadcastGameStart()
    GAMEMODE.Logger.Info("Starting the game with " .. tostring(#GAMEMODE.GameData.PlayerTables) .. " players")
    GAMEMODE.Logger.Info("There are " .. tostring(table.Count(GAMEMODE.GameData.Imposters)) .. " imposter(s) among them")

    -- Start the game after a dramatic pause.
    -- Teleport players while they're staring at the splash screen.
    timer.Create(handle, 2, 1, function()
      GAMEMODE:Game_StartRound(true)

      for _, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
        if IsValid(ply.entity) then
          ply.entity:Freeze(true)
        end
      end

      timer.Create(handle, GAMEMODE.SplashScreenTime - 2, 1, function()
        GAMEMODE.Logger.Info("Game begins! GL & HF")

        -- Set off the timeout timer.
        if timer.Exists(timelimitHandle) then
          timer.UnPause(timelimitHandle)
        end

        -- Otherwise start the game and fire up the background check timer.
        timer.Create("NMW AU CheckWin", 5, 0, function()
          if GAMEMODE:IsGameInProgress() then
            return GAMEMODE:Game_CheckWin()
          else
            return timer.Remove("NMW AU CheckWin")
          end
        end)

        -- Unfreeze everyone and broadcast buttons.
        for _, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
          if not IsValid(ply.entity) then continue end
          ply.entity:Freeze(fal)

          if ply.entity:GetRole().CanKill then
            GAMEMODE:Player_RefreshKillCooldown(ply, 10)
          end
        end

        GAMEMODE:SetGameState(GAMEMODE.GameState.Playing)
        -- Assign the tasks to players.
        GAMEMODE:Task_AssignToPlayers()
        GAMEMODE:Sabotage_Init()
        GAMEMODE:Meeting_ResetCooldown()
        -- Check if suddenly something went extremely wrong during the windup time.
        GAMEMODE:Game_CheckWin()
        -- Pack crewmates and imposters for the hook.
        local hookCrewmates, hookImposters = {}, {}

        for _, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
          table.insert(GAMEMODE.GameData.Imposters[ply] and hookImposters or hookCrewmates, ply.entity)
        end

        hook.Call("GAMEMODEAU GameStart", nil, hookCrewmates, hookImposters)
      end)
    end)
  end)
end

local oldStartRound = GAMEMODE.Game_StartRound

function GAMEMODE:Game_StartRound(first)
  oldStartRound(self, first)

  if not first then
    for ply in pairs(self.GameData.PlayerTables) do
      if ply.entity:GetRole().CanKill then
        self:Player_RefreshKillCooldown(ply, first and 10 or nil)
      end
    end
  end
end

function GAMEMODE:Game_CheckWin(reason)
  local numRoles = {}
  local rolesCanKill = {}
  local totalPlayers = 0

  -- fill variables
  for _, ply in ipairs(self.GameData.PlayerTables) do
    if IsValid(ply.entity) and not self.GameData.DeadPlayers[ply] then
      local team = ply.entity:GetTeam()

      if ply.entity:GetRole().ShowTeammates then
        numRoles[team] = numRoles[team] and numRoles[team] + 1 or 1
      end

      if ply.entity:GetRole().CanKill then
        table.insert(rolesCanKill, team)
      end

      totalPlayers = totalPlayers + 1
    end
  end

  -- check if a team has won
  for team, num in pairs(numRoles) do
    -- team wins if it has half or more of the living players
    if num >= totalPlayers / 2 then
      -- if team has exactly half of the players they only won if no other player can kill them
      if num == totalPlayers / 2 then
        for _, team2 in ipairs(rolesCanKill) do
          if team2 ~= team then continue end
        end
      end

      local teamName = string.upper(team.name[1]) .. string.sub(team.name, 2)
      self.Logger.Info("Game over. " .. teamName .. "s have won!")
      self:Game_GameOver(team.id)

      return true
    end
  end
end

function GAMEMODE:Player_MarkCrew(ply)
  roleselection.ForceRole(ply, CREWMATE)
end

function GAMEMODE:Player_MarkImposter(ply)
  roleselection.ForceRole(ply, IMPOSTER)
end

function GAMEMODE:Player_UnMark(ply)
  roleselection.ForceRole(ply, nil)
end

local function packVentLinks(vent)
  local links = {}

  if vent.Links and #vent.Links > 0 then
    for _, link in ipairs(vent.Links) do
      table.insert(links, link:GetName() or "N/A")
    end
  end

  return links
end

function GAMEMODE:Player_VentTo(playerTable, targetVentId)
  if "Player" == type(playerTable) then
    playerTable = playerTable:GetAUPlayerTable()
  end

  if not playerTable then return end
  local role = playerTable.entity:GetRole()
  local vent = self.GameData.Vented[playerTable]

  if vent and vent.Links and role.CanVent and IsValid(vent.Links[targetVentId]) and (self.GameData.VentCooldown[playerTable] or 0) <= CurTime() then
    local targetVent = vent.Links[targetVentId]
    self.GameData.Vented[playerTable] = targetVent

    if IsValid(playerTable.entity) then
      self:Net_NotifyVent(playerTable, self.VentNotifyReason.Move, packVentLinks(targetVent))
    end

    self.GameData.VentCooldown[playerTable] = CurTime() + 0.25

    if IsValid(playerTable.entity) then
      playerTable.entity:SetPos(targetVent:GetPos())

      if targetVent.ViewAngle then
        playerTable.entity:SetEyeAngles(targetVent.ViewAngle)
      end
    end
  end
end

function GAMEMODE:Player_Vent(playerTable, vent)
  if "Player" == type(playerTable) then
    playerTable = playerTable:GetAUPlayerTable()
  end

  if not playerTable then return end
  local role = playerTable.entity:GetRole()

  if not self.GameData.DeadPlayers[playerTable] and role.CanVent and not self.GameData.Vented[playerTable] then
    if IsValid(playerTable.entity) then
      self:Net_NotifyVent(playerTable, self.VentNotifyReason.Vent, packVentLinks(vent))
    end

    self.GameData.Vented[playerTable] = vent
    self.GameData.VentCooldown[playerTable] = CurTime() + 0.75
    local handle = "vent" .. playerTable.nickname

    if IsValid(playerTable.entity) then
      playerTable.entity:SetPos(vent:GetPos())

      if vent.ViewAngle then
        playerTable.entity:SetEyeAngles(vent.ViewAngle)
      end

      self:Net_BroadcastVent(playerTable.entity, vent:GetPos(), playerTable.entity:EyeAngles())
      self:Player_Hide(playerTable.entity)
      self:Player_PauseKillCooldown(playerTable)
      vent:TriggerOutput("OnVentIn", playerTable.entity)
    end

    timer.Create(handle, 0.125, 1, function()
      if IsValid(playerTable.entity) then
        playerTable.entity:SetPos(vent:GetPos())

        if vent.ViewAngle then
          playerTable.entity:SetEyeAngles(vent.ViewAngle)
        end
      end
    end)
  end
end

function GAMEMODE:Player_Kill(victimTable, attackerTable)
  if "Player" == type(victimTable) then
    victimTable = victimTable:GetAUPlayerTable()
  elseif not victimTable then
    return
  end

  if "Player" == type(attackerTable) then
    attackerTable = attackerTable:GetAUPlayerTable()
  elseif not attackerTable then
    return
  end

  -- Bail if one of the players is invalid. The game mode will handle the killing internally.
  if not (IsValid(victimTable.entity) and IsValid(victimTable.entity)) then return end
  -- Bail if not in the PVS.
  if not (victimTable.entity:TestPVS(attackerTable.entity) and attackerTable.entity:TestPVS(victimTable.entity)) then return end
  -- Bail if one of the players is dead.
  if self.GameData.DeadPlayers[attackerTable] or self.GameData.DeadPlayers[victimTable] then return end
  -- Bail if the attacker isn't allowed to kill.
  if not attackerTable.entity:GetRole().CanKill then return end
  -- Bail if victim and attacker are in the same team and the attacker knows that.
  if victimTable.entity:GetTeam() == attackerTable.entity:GetTeam() and attackerTable.entity:GetRole().ShowTeammates then return end
  -- Bail if player has a cooldown.
  if (self.GameData.KillCooldowns[attackerTable] or 0) > CurTime() then return end
  -- Bail if the kill cooldown is paused
  if self.GameData.KillCooldownRemainders[attackerTable] then return end
  -- Bail if the attacker is too far.
  -- A fairly sophisticated check.
  local radius = (self.BaseUseRadius * self.ConVarSnapshots.KillDistanceMod:GetFloat())
  if radius * radius < (victimTable.entity:NearestPoint(attackerTable.entity:GetPos())):DistToSqr(attackerTable.entity:NearestPoint(victimTable.entity:GetPos())) then return end
  local corpse = ents.Create("prop_ragdoll")
  corpse:SetPos(victimTable.entity:GetPos())
  corpse:SetAngles(victimTable.entity:GetAngles())
  corpse:SetModel(GAMEMODE:GetDefaultCorpseModel())
  corpse:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
  corpse:SetUseType(SIMPLE_USE)
  -- Garbage-tier workaround because NW vars are not accessible in OnEntityCreated.
  corpse:SetDTInt(15, victimTable.id)
  corpse:Spawn()
  corpse:Activate()
  corpse:PhysWake()

  if IsValid(attackerTable.entity) then
    local phys = corpse:GetPhysicsObject()

    if IsValid(phys) then
      phys:SetVelocity((victimTable.entity:GetPos() - attackerTable.entity:GetPos()):GetNormalized() * 250)
    end

    attackerTable.entity:SetPos(victimTable.entity:GetPos())
  end

  self:Player_SetDead(victimTable)
  self:Player_RefreshKillCooldown(attackerTable)
  self:Net_KillNotify(attackerTable)
  self:Player_CloseVGUI(victimTable)

  -- Check if the imposters have won.
  -- Don't play the kill animation if they have.
  if not self:Game_CheckWin() then
    self:Net_SendNotifyKilled(victimTable, attackerTable)
  end
end

hook.Add("KeyPress", "NMW AU UnVent", function(ply, key)
  if key == IN_USE then
    local playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

    if not GAMEMODE.GameData.Imposters[playerTable] and GAMEMODE.GameData.Vented[playerTable] and (GAMEMODE.GameData.VentCooldown[playerTable] or 0) <= CurTime() then
      GAMEMODE:Player_UnVent(playerTable)
    end
  end
end)

util.AddNetworkString("AU RevealRoles")
local oldBroadcastGameOver = GAMEMODE.Net_BroadcastGameOver

function GAMEMODE:Net_BroadcastGameOver(reason)
  local roles = {}
  local teams = {}

  for ply, role in pairs(roleselection.roles) do
    roles[ply] = role.id
  end

  for ply, team in pairs(roleselection.teams) do
    teams[ply] = team.id
  end

  net.Start("AU RevealRoles")
  net.WriteTable(roles)
  net.WriteTable(teams)
  net.Broadcast()
  oldBroadcastGameOver(self, reason)
end

util.AddNetworkString("AU KillRequest")

net.Receive("AU KillRequest", function(len, ply)
  local playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

  if playerTable and GAMEMODE.IsGameInProgress() and ply:GetRole().CanKill and not ply:IsFrozen() then
    local target = net.ReadEntity()
    target = GAMEMODE.GameData.Lookup_PlayerByEntity[target]

    if target then
      GAMEMODE:Player_Kill(target, playerTable)
    end
  end
end)

local oldTaskAssignToPlayers = GAMEMODE.Task_AssignToPlayers

function GAMEMODE:Task_AssignToPlayers()
  oldTaskAssignToPlayers(self)
  local totalTasks = 0

  for ply, tasks in pairs(GAMEMODE.GameData.Tasks) do
    if ply.entity:GetRole().HasTasks then
      totalTasks = totalTasks + table.Count(tasks)
    end
  end

  GAMEMODE.GameData.TotalTasks = totalTasks
end

hook.Remove("PlayerDisconnected", "NMW AU CheckWin")

hook.Add("PlayerDisconnected", "NMW AU CheckWin", function(ply)
  local initializedPlayers = GAMEMODE:GetFullyInitializedPlayers()

  if (GAMEMODE:IsGameInProgress() or GAMEMODE:IsGameCommencing()) and #initializedPlayers <= 1 then
    GAMEMODE.Logger.Info("Everyone left. Stopping the game.")
    GAMEMODE:Game_Restart()

    return
  end

  if GAMEMODE:IsGameInProgress() then
    local playerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[ply]

    if playerTable then
      GAMEMODE:Player_SetDead(playerTable)
      GAMEMODE:Player_CloseVGUI(playerTable)

      -- If the player had tasks, "complete" his tasks and broadcast the new count.
      if GAMEMODE.GameData.Tasks and GAMEMODE.GameData.Tasks[playerTable] and ply:GetRole().HasTasks then
        local count = table.Count(GAMEMODE.GameData.Tasks[playerTable])

        if count > 0 then
          GAMEMODE.GameData.CompletedTasks = GAMEMODE.GameData.CompletedTasks + table.Count(GAMEMODE.GameData.Tasks[playerTable])
          table.Empty(GAMEMODE.GameData.Tasks[playerTable])
          GAMEMODE:Net_BroadcastTaskCount(GAMEMODE.GameData.CompletedTasks, GAMEMODE.GameData.TotalTasks)
        end
      end

      if not GAMEMODE:IsMeetingInProgress() then
        GAMEMODE:Game_CheckWin()
      end
    end
  else
    if timer.Exists("tryStartGame") then
      GAMEMODE.Logger.Warn("Couldn't start the round! Someone left after the countdown")
      timer.Remove("tryStartGame")
      GAMEMODE:Game_CleanUp(true)
    end
  end
end)

function GAMEMODE:Sabotage_Start(playerTable, id)
  if "Player" == type(playerTable) then
    playerTable = playerTable:GetAUPlayerTable()
  end

  if not playerTable then return end
  local role = playerTable.entity:GetRole()

  if not self:IsMeetingInProgress() and role.CanSabotage and not self.GameData.Vented[playerTable] and IsValid(playerTable.entity) then
    local usable = GAMEMODE:TracePlayer(playerTable.entity, self.TracePlayerFilter.Usable)
    local instance = self.GameData.Sabotages[id]
    if self:ShouldHighlightEntity(usable) then return end

    if instance and instance:CanStart() then
      instance:Start()
    end
  end
end