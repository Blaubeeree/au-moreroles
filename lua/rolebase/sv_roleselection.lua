roleselection = roleselection or {}
roleselection.selectableRoles = roleselection.selectableRoles or {}
roleselection.roles = roleselection.roles or {}

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

local function UpgradeRoles(plys, baserole)
  for id, amount in RandomPairs(roleselection.selectableRoles) do
    local role = roles.GetByID(id)
    if role.baserole ~= baserole then continue end

    while amount > 0 and #plys > 0 do
      local ply = plys[math.random(#plys)]
      roleselection.roles[ply] = role
      amount = amount - 1
    end
  end
end

function roleselection.GetSelectableRoles()
  GetSelectableRoles(false)
end

function roleselection.SelectRoles(plyTables)
  if GAMEMODE:IsGameInProgress() then return end
  plyTables = plyTables or table.Add({}, GAMEMODE.GameData.PlayerTables)
  local selectableRoles = GetSelectableRoles(true)

  -- select imposters
  while selectableRoles[ROLE_IMPOSTER] > 0 and #plyTables > 0 do
    local plyKey = math.random(#plyTables)
    local ply = plyTables[plyKey]
    roleselection.roles[ply] = IMPOSTER
    GAMEMODE.GameData.Imposters[ply] = true
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
      roleselection.roles[ply] = role
      amount = amount - 1
      table.insert(baseRolePlys, ply)
      table.remove(plyTables, plyKey)
    end

    UpgradeRoles(baseRolePlys, role)
  end

  -- set all remaining players crewmate
  for _, ply in ipairs(plyTables) do
    roleselection.roles[ply] = CREWMATE
  end

  UpgradeRoles(plyTables, CREWMATE)
end

hook.Add("GMAU GameEnd", "PurgeRoleselectionData", function()
  for k, v in pairs(roleselection) do
    if istable(v) then
      roleselection[k] = {}
    elseif not isfunction(v) then
      roleselection[k] = nil
    end
  end
end)