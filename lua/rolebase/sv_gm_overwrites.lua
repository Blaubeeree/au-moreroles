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

    -- Shuffle.
    -- local memo = {}
    -- table.sort(GAMEMODE.GameData.PlayerTables, function(a, b)
    --   -- I use this for testing.
    --   -- Ignore.
    --   -- if not a.entity\IsBot!
    --   --	memo[a] = 1
    --   -- if not b.entity\IsBot!
    --   -- 	memo[b] = 1
    --   if not memo[a] then
    --     if GAMEMODE.PlayersMarkedForImposter[a.entity] then
    --       memo[a] = math.random() + 1
    --     elseif GAMEMODE.PlayersMarkedForCrew[a.entity] then
    --       memo[a] = math.random() - 1
    --     else
    --       memo[a] = math.random()
    --     end
    --   end
    --   if not memo[b] then
    --     if GAMEMODE.PlayersMarkedForImposter[b.entity] then
    --       memo[b] = math.random() + 1
    --     elseif GAMEMODE.PlayersMarkedForCrew[b.entity] then
    --       memo[b] = math.random() - 1
    --     else
    --       memo[b] = math.random()
    --     end
    --   end
    --   return memo[a] > memo[b]
    -- end)
    -- GAMEMODE.PlayersMarkedForCrew = {}
    -- GAMEMODE.PlayersMarkedForImposter = {}
    -- local imposterCount = math.min(GAMEMODE.ConVarSnapshots.ImposterCount:GetInt(), GAMEMODE:GetImposterCount(#initializedPlayers))
    for index, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
      --   if index <= imposterCount then
      --     GAMEMODE.GameData.Imposters[ply] = true
      --   end
      ply.entity:Freeze(true)
      ply.entity:SetNWInt("NMW AU Meetings", GAMEMODE.ConVarSnapshots.MeetingsPerPlayer:GetInt())
    end

    -- -- Shuffle the player table one more time.
    -- -- We don't want to broadcast the previous table
    -- -- since it'd reveal the imposters right away.
    -- memo = {}
    -- table.sort(GAMEMODE.GameData.PlayerTables, function(a, b)
    --   memo[a] = memo[a] or math.random()
    --   memo[b] = memo[b] or math.random()
    --   return memo[a] > memo[b]
    -- end)
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
    GAMEMODE.Logger.Info("There are " .. tostring(#GAMEMODE.GameData.Imposters) .. " imposter(s) among them")

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
          if IsValid(ply.entity) then
            ply.entity:Freeze(fal)
          end

          if GAMEMODE.GameData.Imposters[ply] then
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