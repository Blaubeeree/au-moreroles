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

