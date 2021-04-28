hook.Add("OnGamemodeLoaded", "InitMoreRoles", function()
  if engine.ActiveGamemode() ~= "amongus" then
    error("The current gamemode is not among us!")
  end

  -- all scripts should be located in lua/moreroles
  if SERVER then
    -- add all clientside and shared scripts
    AddCSLuaFile("moreroles/cl_gm_overwrites.lua")
    AddCSLuaFile("moreroles/cl_hud_overwrites.lua")
    AddCSLuaFile("moreroles/cl_roleselection.lua")
    AddCSLuaFile("moreroles/sh_gm_overwrites.lua")
    AddCSLuaFile("moreroles/sh_player_ext.lua")
    AddCSLuaFile("moreroles/sh_role_module.lua")
    AddCSLuaFile("includes/modules/roles.lua")
    -- include all serverside scripts
    include("moreroles/sv_gm_overwrites.lua")
    include("moreroles/sv_roleselection.lua")
    -- add all resources if we need any
    -- resource.AddWorkshop("cooleWorkshopID")
  else
    -- include all clientside scripts
    include("moreroles/cl_gm_overwrites.lua")
    include("moreroles/cl_hud_overwrites.lua")
    include("moreroles/cl_roleselection.lua")
  end

  -- include all shared scripts
  include("moreroles/sh_gm_overwrites.lua")
  include("moreroles/sh_player_ext.lua")
  include("moreroles/sh_role_module.lua")
end)