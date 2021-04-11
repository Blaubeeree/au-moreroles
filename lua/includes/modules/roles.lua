﻿module("roles", package.seeall)
local RolesByName = RolesByName or {}
local RolesByID = RolesByID or {}
local TeamsByName = TeamsByName or {}
local TeamsByID = TeamsByID or {}

local defaultSettings = {
  color = Color(0, 0, 0),
  defaultTeam = 1,
  CanKill = false,
  CanSabotage = false,
  CanVent = false,
  HasTasks = true
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
  local name = string.upper(roleData.name)
  _G["ROLE_" .. name] = roleData.id
  _G[name] = roleData
end

local function SetupConvars(roleData)
  if not roleData.notSelectable and roleData ~= CREWMATE then
    roleData.cvars = roleData.cvars or {}

    roleData.cvars.pct = CreateConVar("au_" .. roleData.name .. "_pct", tostring(roleData.defaultCVarData.pct or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 1)

    if roleData ~= IMPOSTER then
      roleData.cvars.max = CreateConVar("au_" .. roleData.name .. "_max", tostring(roleData.defaultCVarData.max or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE})

      roleData.cvars.minPlayers = CreateConVar("au_" .. roleData.name .. "_min_players", tostring(roleData.defaultCVarData.minPlayers or 1), {FCVAR_NOTIFY, FCVAR_ARCHIVE})

      roleData.cvars.random = CreateConVar("au_" .. roleData.name .. "_random", tostring(roleData.defaultCVarData.random or 100), {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 100)

      roleData.cvars.enabled = CreateConVar("au_" .. roleData.name .. "_enabled", "1", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, "", 0, 1)
    else
      roleData.cvars.max = GAMEMODE.ConVars.ImposterCount
    end
  end
end

function Register(name, data)
  name = string.lower(name)
  if RolesByName[name] then return end
  data.id = data.id or GenerateRoleID()
  if RolesByID[data.id] then return end

  for k, v in pairs(defaultSettings) do
    data[k] = data[k] or v
  end

  RolesByID[data.id] = data
  RolesByName[name] = data
  SetupGlobals(data)
  SetupConvars(data)
end

function CreateTeam(name, data)
  name = string.lower(name)
  data.id = data.id or GenerateTeamID()
  _G["TEAM_" .. string.upper(name)] = data.id
  TeamsByName[name] = data
  TeamsByID[data.id] = data
end

function GetList()
  return RolesByName
end

function GetTeams()
  return TeamsByName
end

function GetByName(name)
  return RolesByName[name]
end

function GetByID(id)
  return RolesByID[id]
end