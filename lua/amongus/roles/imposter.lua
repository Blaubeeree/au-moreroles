roles.CreateTeam(ROLE.name, {
  id = TEAM_IMPOSTER,
  color = Color(255, 0, 0)
})

ROLE.id = ROLE_IMPOSTER
ROLE.desc = "Sabotage and kill everyone."
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