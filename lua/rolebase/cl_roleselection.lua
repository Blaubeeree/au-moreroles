roleselection = roleselection or {}
roleselection.roles = roleselection.roles or {}
roleselection.teams = roleselection.teams or {}

net.Receive("AU SendRole", function()
  for ply, roleID in pairs(net.ReadTable()) do
    local role = roles.GetByID(roleID)
    roleselection.roles[ply] = role
    roleselection.teams[ply] = roles.GetTeamByID(role.defaultTeam)
  end

  roleselection.roles[LocalPlayer()] = roles.GetByID(net.ReadUInt(8))
  roleselection.teams[LocalPlayer()] = roles.GetTeamByID(net.ReadUInt(8))
end)

net.Receive("AU PurgeRoleselectionData", function()
  for k, v in pairs(roleselection) do
    if istable(v) then
      roleselection[k] = {}
    elseif not isfunction(v) then
      roleselection[k] = nil
    end
  end
end)