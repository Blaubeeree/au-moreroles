roleselection = roleselection or {}
roleselection.selectableRoles = roleselection.selectableRoles or {}
roleselection.roles = roleselection.roles or {}
roleselection.teams = roleselection.teams or {}
util.AddNetworkString("AU SendRole")
util.AddNetworkString("AU PurgeRoleselectionData")

local function GetSelectableRoles(update)
  if not update and not table.Empty(roleselection.selectableRoles) then return roleselection.selectableRoles end
  local plyCount = #player.GetAll()
  local roleList = roles.GetList()
  local selectableRoles = {}

  for _, role in pairs(roleList) do
    if role.id == ROLE_IMPOSTER
      or (role.id ~= ROLE_CREWMATE
      and role.cvars.enabled:GetBool()
      and role.cvars.minPlayers:GetInt() <= plyCount
      and role.cvars.random:GetInt() >= math.random(100))
    then
      selectableRoles[role.id] = math.min(role.cvars.max:GetInt(), math.floor(role.cvars.pct:GetFloat() * plyCount))
    end
  end

  roleselection.selectableRoles = selectableRoles

  return selectableRoles
end

local function SetRole(ply, role)
  roleselection.roles[ply.entity] = role
  roleselection.teams[ply.entity] = roles.GetTeamByID(role.defaultTeam)

  if role == IMPOSTER then
    GAMEMODE.GameData.Imposters[ply] = true
  end
end

local function UpgradeRoles(plys, baserole)
  for id, amount in RandomPairs(roleselection.selectableRoles) do
    local role = roles.GetByID(id)
    if role.baserole ~= baserole then continue end

    while amount > 0 and #plys > 0 do
      local ply = plys[math.random(#plys)]
      SetRole(ply, role)
      amount = amount - 1
    end
  end
end

local function BroadcastRoles()
  for _, ply in ipairs(GAMEMODE.GameData.PlayerTables) do
    ply = ply.entity
    local role = roleselection.roles[ply]
    local team = roleselection.teams[ply]
    local teammates = {}

    if role.ShowTeammates then
      for _, ply2 in ipairs(GAMEMODE.GameData.PlayerTables) do
        ply2 = ply2.entity

        if roleselection.teams[ply2] == team then
          teammates[ply2] = roleselection.roles[ply2].id
        end
      end
    end

    net.Start("AU SendRole")
    net.WriteTable(teammates)
    net.WriteUInt(role.id, 8)
    net.WriteUInt(team.id, 8)
    net.Send(ply)
  end
end

function roleselection.GetSelectableRoles()
  GetSelectableRoles(false)
end

function roleselection.SetRole(ply, role)
  SetRole(ply, role)
  BroadcastRoles()
end

function roleselection.SetTeam(ply, team)
  if type(ply.entity) == "Player" then
    ply = ply.entity
  elseif type(ply) ~= "Player" then
    return
  end

  roleselection.teams[ply] = team
  BroadcastRoles()
end

function roleselection.SelectRoles(plyTables)
  if GAMEMODE:IsGameInProgress() then return end
  plyTables = plyTables or table.Add({}, GAMEMODE.GameData.PlayerTables)
  local selectableRoles = GetSelectableRoles(true)

  -- select imposters
  while selectableRoles[ROLE_IMPOSTER] > 0 and #plyTables > 0 do
    local plyKey = math.random(#plyTables)
    local ply = plyTables[plyKey]
    SetRole(ply, IMPOSTER)
    selectableRoles[ROLE_IMPOSTER] = selectableRoles[ROLE_IMPOSTER] - 1
    table.remove(plyTables, plyKey)
  end

  UpgradeRoles(table.GetKeys(GAMEMODE.GameData.Imposters), IMPOSTER)

  -- select other baseroles
  for id, amount in RandomPairs(selectableRoles) do
    local role = roles.GetByID(id)
    if role.baserole then continue end
    local baseRolePlys = {}

    while amount > 0 and #plyTables > 0 do
      local plyKey = math.random(#plyTables)
      local ply = plyTables[plyKey]
      SetRole(ply, role)
      amount = amount - 1
      table.insert(baseRolePlys, ply)
      table.remove(plyTables, plyKey)
    end

    UpgradeRoles(baseRolePlys, role)
  end

  -- set all remaining players crewmate
  for _, ply in ipairs(plyTables) do
    SetRole(ply, CREWMATE)
  end

  UpgradeRoles(plyTables, CREWMATE)
  -- tell everyone who their teammates are
  BroadcastRoles()
end

hook.Add("GMAU GameEnd", "PurgeRoleselectionData", function()
  for k, v in pairs(roleselection) do
    if istable(v) then
      roleselection[k] = {}
    elseif not isfunction(v) then
      roleselection[k] = nil
    end
  end

  net.Start("AU PurgeRoleselectionData")
  net.Broadcast()
end)