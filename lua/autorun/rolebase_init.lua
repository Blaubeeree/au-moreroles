hook.Add("OnGamemodeLoaded", "InitRoleBase", function()
  if engine.ActiveGamemode() ~= "amongus" then
    error("The current gamemode is not among us!")
  end

  -- all scripts should be located in lua/rolebase
  if SERVER then
    -- add all clientside and shared scripts
    AddCSLuaFile("rolebase/sh_role_module.lua")
    AddCSLuaFile("includes/modules/roles.lua")
    -- include all serverside scripts
    -- add all resources if we need any
    -- resource.AddWorkshop("cooleWorkshopID")
  end

  -- include all shared scripts
  include("rolebase/sh_role_module.lua")
end)