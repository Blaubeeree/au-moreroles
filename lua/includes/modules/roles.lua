module("roles", package.seeall)
_G.ROLE_IMPOSTER = 1
_G.TEAM_IMPOSTER = 1
_G.ROLE_CREWMATE = 2
_G.TEAM_CREWMATE = 2
local RolesByName = RolesByName or {}
local RolesByID = RolesByID or {}
local TeamsByName = TeamsByName or {}
local TeamsByID = TeamsByID or {}

local defaultSettings = {
  color = Color(0, 0, 0),
  defaultTeam = TEAM_CREWMATE,
  CanKill = false,
  CanSabotage = false,
  CanVent = false,
  HasTasks = true,
  ShowTeammates = false
}

local function GenerateRoleID()
  local id = math.max(#RolesByID, 3)

  while RolesByID[id] ~= nil do
    id = id + 1
  end

  return id
end

local function GenerateTeamID()
  local id = math.max(#TeamsByID, 3)

  while TeamsByID[id] ~= nil do
    id = id + 1
  end

  return id
end

local function SetupGlobals(roleData)
  local name = string.Replace(string.upper(roleData.name), " ", "")
  _G["ROLE_" .. name] = roleData.id
  _G[name] = roleData
end

local function SetupConvars(roleData)
  if roleData ~= CREWMATE then
    local name = string.Replace(string.lower(roleData.name), " ", "_")
    roleData.cvars = roleData.cvars or {}

    roleData.cvars.pct = CreateConVar("au_" .. name .. "_pct", tostring(roleData.defaultCVarData.pct or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 1)

    if roleData ~= IMPOSTER then
      roleData.cvars.max = CreateConVar("au_" .. name .. "_max", tostring(roleData.defaultCVarData.max or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE})

      roleData.cvars.minPlayers = CreateConVar("au_" .. name .. "_min_players", tostring(roleData.defaultCVarData.minPlayers or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE})

      roleData.cvars.random = CreateConVar("au_" .. name .. "_random", tostring(roleData.defaultCVarData.random or 100), {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 100)

      roleData.cvars.enabled = CreateConVar("au_" .. name .. "_enabled", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 1)
    else
      roleData.cvars.max = GAMEMODE.ConVars.ImposterCount
    end
  end
end

---
-- Registers a new role
-- @param String name The name of the new role (must be unique)
-- @param Table data The data of the new role
function Register(name, data)
  name = string.lower(name)
  if RolesByName[name] then return end
  data.id = data.id or GenerateRoleID()
  if RolesByID[data.id] then return end

  for k, v in pairs(defaultSettings) do
    if data[k] == nil then
      data[k] = v
    end
  end

  RolesByID[data.id] = data
  RolesByName[name] = data
  SetupGlobals(data)
  SetupConvars(data)
  GAMEMODE.Logger.Info("Added '" .. data.name .. "' role (ID: " .. data.id .. ")")
end

---
-- Creates a new team
-- @param String name The name of the new team
--  (for convenience should equal the name of the role it belongs to)
-- @param Table data The data of the new team
function CreateTeam(name, data)
  data.name = string.Replace(string.lower(name), " ", "_")
  data.id = data.id or GenerateTeamID()
  data.color = data.color or Color(0, 0, 0)
  _G["TEAM_" .. string.Replace(string.upper(data.name), "_", "")] = data.id
  TeamsByName[data.name] = data
  TeamsByID[data.id] = data
end

---
-- Sets the baserole for a subrole
-- @param ROLE role The role that baserole should be set
-- @param ROLE baserole The role the baserole should be set to (must not be a subrole or CREWMATE)
function SetBaseRole(role, baserole)
  baserole = RolesByID[baserole] or baserole

  if baserole == CREWMATE then
    GAMEMODE.Logger.Error("BaseRole of" .. role.name .. " can't be set to crewmate!")
  elseif role.baserole then
    GAMEMODE.Logger.Error("BaseRole of " .. role.name .. " already set (" .. role.baserole.name .. ")!")
  elseif role.id == baserole.id then
    GAMEMODE.Logger.Error("BaseRole " .. role.name .. " can't be a baserole of itself!")
  elseif baserole.baserole then
    GAMEMODE.Logger.Error("Your requested BaseRole can't be any BaseRole of another SubRole because it's a SubRole as well.")
  else
    role.baserole = baserole
    role.defaultTeam = baserole.defaultTeam
    GAMEMODE.Logger.Info("Connected '" .. role.name .. "' subrole with baserole '" .. baserole.name .. "'")
  end
end

---
-- Returns a list of all roles
-- @return table
function GetList()
  return RolesByName
end

---
-- Returns a list of all teams
-- @return table
function GetTeams()
  return TeamsByName
end

---
-- Returns a role by their name
-- @param name The name of the role
-- @return ROLE
function GetByName(name)
  return RolesByName[name]
end

---
-- Returns a role by their id
-- @param id The id of the role
-- @return ROLE
function GetByID(id)
  return RolesByID[id]
end

---
-- Returns a team by their name
-- @param name The name of the role
-- @return TEAM
function GetTeamByName(name)
  return TeamsByName[name]
end

---
-- Returns a team by their id
-- @param id The id of the role
-- @return TEAM
function GetTeamByID(id)
  return TeamsByID[id]
end