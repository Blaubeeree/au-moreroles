require("roles")
local rolesPath = "amongus/roles/"
local rolesFiles = file.Find(rolesPath .. "*.lua", "LUA")
local _, rolesFolders = file.Find(rolesPath .. "*", "LUA")

for _, fl in ipairs(rolesFiles) do
  if string.find(fl, "%u") then
    GAMEMODE.Logger.Error("Could not load " .. fl .. ". Do not use uppercase letters in filename!")
  end

  ROLE = {}
  ROLE.name = string.sub(fl, 0, #fl - 4)
  AddCSLuaFile(rolesPath .. fl)
  include(rolesPath .. fl)
  roles.Register(ROLE.name, ROLE)
end

for _, folder in ipairs(rolesFolders) do
  ROLE = {}
  ROLE.name = folder

  if file.Exists(rolesPath .. folder .. "/init.lua") then
    include(rolesPath .. folder .. "/init.lua")
  end

  if file.Exists(rolesPath .. folder .. "/cl_init.lua") then
    AddCSLuaFile(rolesPath .. folder .. "/cl_init.lua")

    if CLIENT then
      include(rolesPath .. folder .. "/cl_init.lua")
    end
  end

  if file.Exists(rolesPath .. folder .. "/shared.lua") then
    AddCSLuaFile(rolesPath .. folder .. "/shared.lua")
    include(rolesPath .. folder .. "/shared.lua")
  end

  roles.Register(ROLE.name, ROLE)
end

ROLE = nil

for _, role in pairs(roles.GetList()) do
  if role.Initialize then
    role:Initialize()
  end
end