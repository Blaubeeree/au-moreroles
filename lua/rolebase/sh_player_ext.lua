local plymeta = FindMetaTable("Player")

function plymeta:GetRole()
  return roleselection.roles[self]
end

function plymeta:GetTeam()
  return roleselection.teams[self]
end