roleselection = {}

function roleselection.GetSelectableBaseRoles(update)
  if not update and roleselection.selectableBaseRoles then return roleselection.selectableBaseRoles end
  local plyCount = #player.GetAll()
  local roleList = roles.GetList()
  local selectableRoles = {}

  for _, role in pairs(roleList) do
    if role.id == ROLE_IMPOSTER or (role.id ~= ROLE_CREWMATE and not role.baserole and role.cvars.enabled:GetBool() and role.cvars.minPlayers:GetInt() <= plyCount and role.cvars.random:GetInt() >= math.random(100)) then
      selectableRoles[role.id] = math.min(role.cvars.max:GetInt(), math.floor(role.cvars.pct:GetFloat() * plyCount))
    end
  end

  PrintTable(selectableRoles)
  roleselection.selectableBaseRoles = selectableRoles

  return selectableRoles
end

function roleselection.SelectRoles(plyTables)
  if GAMEMODE:IsGameInProgress() then return end
  plyTables = plyTables or table.Add({}, GAMEMODE.GameData.PlayerTables)
  roleselection.roles = roleselection.roles or {}
  local selectableRoles = roleselection.GetSelectableBaseRoles(update)

  while selectableRoles[ROLE_IMPOSTER] > 0 and #plyTables > 0 do
    local plyKey = math.random(#plyTables)
    local ply = plyTables[plyKey]
    roleselection.roles[ply] = IMPOSTER
    GAMEMODE.GameData.Imposters[ply] = true
    selectableRoles[ROLE_IMPOSTER] = selectableRoles[ROLE_IMPOSTER] - 1
    table.remove(plyTables, plyKey)
  end

  for id, amount in RandomPairs(selectableRoles) do
    local role = roles.GetByID(id)

    while amount > 0 and #plyTables > 0 do
      local plyKey = math.random(#plyTables)
      local ply = plyTables[plyKey]
      roleselection.roles[ply] = role
      amount = amount - 1
      table.remove(plyTables, plyKey)
    end
  end
end

hook.Add("GMAU GameEnd", "PurgeRoleselectionData", function()
  for k, v in pairs(roleselection) do
    if not isfunction(v) then
      roleselection[k] = nil
    end
  end
end)