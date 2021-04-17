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

net.Receive("AU RevealRoles", function()
  for ply, roleID in pairs(net.ReadTable()) do
    roleselection.roles[ply] = roles.GetByID(roleID)
  end

  for ply, teamID in pairs(net.ReadTable()) do
    roleselection.teams[ply] = roles.GetTeamByID(teamID)
  end
end)

net.Receive("AU PurgeRoleselectionData", function()
  -- waiting a few seconds until the endscreen is over
  timer.Simple(5, function()
    for k, v in pairs(roleselection) do
      if istable(v) then
        roleselection[k] = {}
      elseif not isfunction(v) then
        roleselection[k] = nil
      end
    end
  end)
end)