local plymeta = FindMetaTable("Player")

---
-- Returns the role the player has
-- @return ROLE
function plymeta:GetRole()
  return roleselection.roles[self] or CREWMATE
end

---
-- Returns the team the player belongs to
-- @return TEAM
function plymeta:GetTeam()
  return roleselection.teams[self] or roles.GetTeamByID(TEAM_CREWMATE)
end