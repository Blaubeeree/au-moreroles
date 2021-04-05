hook.Add("OnGamemodeLoaded", "InitRoleBase", function ()
  if GetConVar("gamemode"):GetString() ~= "amongus" then
    error("The current gamemode is not among us!")
  end

  -- all scripts should be located in lua/rolebase
  -- add all clientside scripts
  -- include all scripts

  -- if SERVER then
  --   -- add all resources if we need any
  --   resource.AddWorkshop("cooleWorkshopID")
  -- end
end)