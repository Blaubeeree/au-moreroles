local plymeta = FindMetaTable("Player")

function plymeta:GetRole()
  return roleselection.roles[self] or CREWMATE
end

function plymeta:GetTeam()
  return roleselection.teams[self] or roles.GetTeamByID(TEAM_CREWMATE)
end