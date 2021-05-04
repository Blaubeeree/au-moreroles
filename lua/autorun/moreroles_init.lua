hook.Add("OnGamemodeLoaded", "InitMoreRoles", function()
  if engine.ActiveGamemode() ~= "amongus" then
    error("The current gamemode is not among us!")
  end

  if SERVER then
    AddCSLuaFile("moreroles/cl_gm_overwrites.lua")
    AddCSLuaFile("moreroles/cl_hud_overwrites.lua")
    AddCSLuaFile("moreroles/cl_render_overwrites.lua")
    AddCSLuaFile("moreroles/cl_roleselection.lua")
    AddCSLuaFile("moreroles/sh_gm_overwrites.lua")
    AddCSLuaFile("moreroles/sh_player_ext.lua")
    AddCSLuaFile("moreroles/sh_role_module.lua")
    AddCSLuaFile("includes/modules/roles.lua")
    include("moreroles/sv_gm_overwrites.lua")
    include("moreroles/sv_roleselection.lua")
    resource.AddWorkshop("2476816620")
  else
    include("moreroles/cl_gm_overwrites.lua")
    include("moreroles/cl_hud_overwrites.lua")
    include("moreroles/cl_render_overwrites.lua")
    include("moreroles/cl_roleselection.lua")
  end

  include("moreroles/sh_gm_overwrites.lua")
  include("moreroles/sh_player_ext.lua")
  include("moreroles/sh_role_module.lua")
end)