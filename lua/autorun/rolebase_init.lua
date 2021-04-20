hook.Add("OnGamemodeLoaded", "InitRoleBase", function()
  if engine.ActiveGamemode() ~= "amongus" then
    error("The current gamemode is not among us!")
  end

  -- all scripts should be located in lua/rolebase
  if SERVER then
    -- add all clientside and shared scripts
    AddCSLuaFile("rolebase/cl_hud_overwrites.lua")
    AddCSLuaFile("rolebase/cl_roleselection.lua")
    AddCSLuaFile("rolebase/sh_gm_overwrites.lua")
    AddCSLuaFile("rolebase/sh_player_ext.lua")
    AddCSLuaFile("rolebase/sh_role_module.lua")
    AddCSLuaFile("includes/modules/roles.lua")
    -- include all serverside scripts
    include("rolebase/sv_gm_overwrites.lua")
    include("rolebase/sv_roleselection.lua")
    -- add all resources if we need any
    -- resource.AddWorkshop("cooleWorkshopID")
  else
    -- include all clientside scripts
    include("rolebase/cl_hud_overwrites.lua")
    include("rolebase/cl_roleselection.lua")
  end

  -- include all shared scripts
  include("rolebase/sh_gm_overwrites.lua")
  include("rolebase/sh_player_ext.lua")
  include("rolebase/sh_role_module.lua")
end)