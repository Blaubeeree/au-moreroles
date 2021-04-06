roles.CreateTeam(ROLE.name, {
  id = 2,
  color = Color(255, 0, 0)
})

ROLE.id = 2
ROLE.color = Color(255, 0, 0)
ROLE.defaultTeam = TEAM_IMPOSTER
ROLE.CanKill = true
ROLE.CanSabotage = true
ROLE.CanVent = true
ROLE.HasTasks = false

ROLE.defaultCVarData = {
  pct = 0.29,
  max = 2
}