hook.Remove("PreDrawHalos", "NMW AU Highlight")

hook.Add("PreDrawHalos", "NMW AU Highlight", function()
  if not (GAMEMODE:IsGameInProgress()) then return end
  if not (IsValid(LocalPlayer()) and LocalPlayer():GetAUPlayerTable()) then return end
  local localPlayerRole = LocalPlayer():GetRole()

  -- Highlight sabotage buttons.
  for btn in pairs(GAMEMODE.GameData.SabotageButtons) do
    halo.Add({btn}, math.floor((SysTime() * 4) % 2) ~= 0 and Color(32, 255, 32) or Color(255, 32, 32), 1, 1, 10, true, true)
  end

  if IsValid(GAMEMODE.KillHighlight) then
    halo.Add({GAMEMODE.KillHighlight}, Color(255, 0, 0), 4, 4, 8, true, true)
  end

  local highlighted = {}

  if IsValid(GAMEMODE.UseHighlight) then
    local color = GAMEMODE:GetHighlightColor(GAMEMODE.UseHighlight)

    if color then
      highlighted[GAMEMODE.UseHighlight] = true

      halo.Add({GAMEMODE.UseHighlight}, color, 4, 4, 8, true, true)
    end
  end

  -- Highlight all highlightables, except tasks.
  for _, ent in pairs(ents.FindInSphere(LocalPlayer():GetPos(), 160)) do
    if ent.GetTaskName then continue end
    if highlighted[ent] then continue end
    -- Only highlight vents for players who can vent.
    if not localPlayerRole.CanVent and (ent:GetClass() == "func_vent" or ent:GetClass() == "prop_vent") then continue end
    local color = GAMEMODE:GetHighlightColor(ent)

    if color then
      halo.Add({ent}, color, 3, 3, 2, true, true)
    end
  end

  -- Highlight tasks. The reason why they're handled separately is that
  -- it's impossible to do in the upper block without re-iterating the entire task list every time.
  if localPlayerRole.HasTasks then
    for taskName, taskInstance in pairs(GAMEMODE.GameData.MyTasks) do
      if taskInstance:GetCompleted() then continue end
      local button = taskInstance:GetActivationButton()
      if not (IsValid(button)) then continue end
      if highlighted[button] then continue end
      local color = GAMEMODE:GetHighlightColor(button)
      if not taskInstance:GetPositionImportant() and 160 < button:GetPos():Distance(LocalPlayer():GetPos()) then continue end

      if button then
        halo.Add({button}, color, 3, 3, 2, true, true)
      end
    end
  end
end)

hook.Remove("PostPlayerDraw", "NMW AU Nicknames")

hook.Add("PostPlayerDraw", "NMW AU Nicknames", function(ply)
  -- Don't draw our nickname.
  -- Don't draw ghost nicknames.
  -- Don't draw invalid players' nicknames... what?
  if not ply:IsValid() or ply:IsDormant() or ply == LocalPlayer() then return end
  -- No drawing if something doesn't want us to draw.
  if true == hook.Call("GMAU PreDrawNicknames") then return end
  -- Position the text directly above the player's head.
  local pos = ply:OBBMaxs()
  pos = pos + (ply:GetPos() + Vector(-pos.x, -pos.y, 2))
  -- Calculate the text angle.
  local angle = (pos - EyePos()):Angle()
  angle = Angle(angle.p, angle.y, 0)
  angle.y = angle.y + (10 * math.sin(CurTime()))

  local calculated = {
    player = ply,
    playerPos = pos,
    textAngle = angle
  }

  -- Pass the table to hooks.
  -- If something returned `true`, pass.
  if true == hook.Call("GMAU CalcNicknames", nil, calculated) then return end
  -- Rotation shenanigans.
  calculated.textAngle:RotateAroundAxis(calculated.textAngle:Up(), -90)
  calculated.textAngle:RotateAroundAxis(calculated.textAngle:Forward(), 90)
  -- Draw the actual 3D2D text above the player in question.
  cam.Start3D2D(calculated.playerPos, calculated.textAngle, 0.075)
  -- Draw a "better" outline.
  local passes = 4

  for i = -passes / 2, passes / 2 do
    for j = -passes / 2, passes / 2 do
      if i == 0 or j == 0 then continue end
      local offsetX = 2 * i
      local offsetY = 2 * j
      draw.SimpleText(ply:Nick(), "NMW AU Floating Nickames", offsetX, offsetY, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
  end

  local team = roleselection.teams[ply]
  draw.SimpleText(ply:Nick(), "NMW AU Floating Nickames", 0, 0, team and team.color or Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
  cam.End3D2D()
end)