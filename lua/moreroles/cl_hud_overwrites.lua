GM = GAMEMODE
local VGUI_HUD = include("amongus/gamemode/vgui/vgui_hud.lua")
local VGUI_SPLASH = include("amongus/gamemode/vgui/vgui_splash.lua")
GM = nil

local MAT_BUTTONS = {
  kill = Material("au/gui/hudbuttons/kill.png"),
  use = Material("au/gui/hudbuttons/use.png"),
  report = Material("au/gui/hudbuttons/report.png"),
  vent = Material("au/gui/hudbuttons/vent.png")
}

local TRANSLATE = GAMEMODE.Lang.GetEntry
local SHUT_TIME = 3
local ROTATION_MATRIX = Matrix()
local COLOR_WHITE = Color(255, 255, 255)
local COLOR_BLACK = Color(0, 0, 0)
local COLOR_RED = Color(220, 32, 32)
local COLOR_GREEN = Color(32, 255, 32)
local COLOR_YELLOW = Color(255, 255, 30)

function VGUI_HUD:SetupButtons(state, impostor)
  local localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer()]
  local localPlayerRole = LocalPlayer():GetRole()
  local localPlayerTeam = LocalPlayer():GetTeam()

  for _, v in ipairs(self.buttons:GetChildren()) do
    v:Remove()
  end

  self.buttons:SetAlpha(0)
  self.buttons:AlphaTo(255, 2)

  if state == GAMEMODE.GameState.Preparing then
    -- The convar list.
    local cvarlist = self:Add("Panel")
    local m = ScrW() * 0.01
    cvarlist:DockMargin(m, m, m, m)
    cvarlist:SetWide(ScrW() * 0.35)
    cvarlist:Dock(LEFT)

    cvarlist.Paint = function()
      surface.SetFont("NMW AU Taskbar")
      local tW, tH = surface.GetTextSize("A")
      local conVars = GAMEMODE:IsGameCommencing() and GAMEMODE.ConVarSnapshots or GAMEMODE.ConVars
      local i = 0

      for categoryId, category in ipairs(GAMEMODE.ConVarsDisplay) do
        local _list_1 = category.ConVars

        for _, conVarTable in ipairs(category.ConVars) do
          local type = conVarTable[1]
          local conVar = conVars[conVarTable[2]]
          local conVarName = conVar:GetName()
          local value

          if "Int" == type then
            value = conVar:GetInt()
          elseif "Time" == type then
            value = TRANSLATE("hud.cvar.time")(conVar:GetInt())
          elseif "String" == type then
            value = conVar:GetString()
          elseif "Bool" == type then
            value = conVar:GetBool() and TRANSLATE("hud.cvar.enabled") or TRANSLATE("hud.cvar.disabled")
          elseif "Mod" == type then
            value = tostring(conVar:GetFloat()) .. "x"
          elseif "Select" == type then
            value = TRANSLATE("hud.cvar." .. tostring(conVarName) .. "." .. tostring(conVar:GetInt()))
          end

          if value then
            i = i + 1
            draw.SimpleTextOutlined(tostring(TRANSLATE("cvar." .. conVarName)) .. ": " .. tostring(value), "NMW AU ConVar List", tW * 0.1, (i - 1) * tH * 1.05 + (categoryId - 1) * tH * 1.05, GAMEMODE:IsGameCommencing() and COLOR_GREEN or COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 2, Color(0, 0, 0, 160))
          end
        end
      end
    end

    -- Round overlay.
    self.roundOverlay = self:Add("Panel")
    self.roundOverlay:SetZPos(30001)
    self.roundOverlay:SetSize(ScrW(), ScrH() * 0.125)
    self.roundOverlay:SetPos(0, ScrH() * 0.75)
    local roContainer = self.roundOverlay:Add("Panel")
    local margin = ScrW() * 0.25
    roContainer:DockMargin(margin, 0, margin, 0)
    roContainer:Dock(FILL)
    -- Right
    local roRight = roContainer:Add("Panel")
    roRight:SetWide(0.5 * ScrW() * 0.25)
    roRight:Dock(RIGHT)

    if GAMEMODE.MapManifest then
      local crewSize = 0.25 * roRight:GetWide()
      -- Imposter Count Container
      local impCount = roRight:Add("DOutlinedLabel")
      impCount:Dock(BOTTOM)
      impCount:SetTall(0.5 * ScrH() * 0.125)
      impCount:SetColor(Color(255, 255, 255))
      impCount:SetContentAlignment(8)
      impCount:SetText("")
      impCount:SetFont("NMW AU Start Subtext")

      impCount.Think = function()
        local imposterCount = math.min(GAMEMODE.ConVars.ImposterCount:GetInt(), GAMEMODE:GetImposterCount(GAMEMODE:GetFullyInitializedPlayerCount()))
        impCount:SetText(tostring(TRANSLATE("prepare.imposterCount")(imposterCount)))
      end

      -- Count container.
      local countContainer = roRight:Add("Panel")
      countContainer:DockPadding(0, 0, crewSize * 0.5, 0)
      countContainer:Dock(TOP)
      countContainer:SetTall(0.5 * ScrH() * 0.125)
      -- Crewmate
      local crew = countContainer:Add("Panel")
      crew:SetSize(crewSize, crewSize)
      crew:DockMargin(crewSize * 0.25, 0, 0, 0)
      crew:Dock(RIGHT)
      -- A slightly unreadable chunk of garbage code
      -- responsible for layering the crewmate sprite.
      local layers = {}

      for i = 1, 2 do
        layers[i] = crew:Add("AmongUsCrewmate")
        layers[i]:Dock(FILL)
        layers[i]:SetColor(Color(255, 0, 0))
        layers[i]:SetFlipX(true)
      end

      -- Label
      local crewCount = countContainer:Add("DOutlinedLabel")
      crewCount:SetFont("NMW AU Countdown")
      crewCount:SetText("...")
      crewCount:SetContentAlignment(6)
      crewCount:Dock(FILL)

      crewCount.Think = function()
        local playerCount = GAMEMODE:GetFullyInitializedPlayerCount()
        local needed = GAMEMODE.ConVars.MinPlayers:GetInt()
        local maxPlayers = game.MaxPlayers()
        crewCount:SetText(tostring(playerCount) .. "/" .. tostring(maxPlayers))
        crewCount:SetColor(playerCount > needed and COLOR_WHITE or playerCount == needed and COLOR_YELLOW or COLOR_RED)
      end
    end

    -- Middle
    local roMiddle = roContainer:Add("Panel")
    roMiddle:SetWide(ScrW() * 0.25)
    roMiddle:Dock(RIGHT)
    local prepText = roMiddle:Add("DOutlinedLabel")
    prepText:SetTall(0.5 * ScrH() * 0.125)
    prepText:Dock(TOP)
    prepText:SetText("")
    prepText:SetContentAlignment(5)
    prepText:SetFont("NMW AU Countdown")
    prepText:SetColor(Color(255, 255, 255))

    prepText.Think = function()
      if not GAMEMODE.MapManifest then
        prepText:SetText(TRANSLATE("prepare.invalidMap"))
      elseif GAMEMODE.ClientSideConVars.SpectatorMode:GetBool() then
        prepText:SetText(TRANSLATE("prepare.spectator"))
      elseif not GAMEMODE.ConVars.ForceAutoWarmup:GetBool() and CAMI.PlayerHasAccess(LocalPlayer(), GAMEMODE.PRIV_START_ROUND) then
        prepText:SetText(TRANSLATE("prepare.admin"))
      else
        prepText:SetText(TRANSLATE("prepare.warmup"))
      end
    end

    local prepSubtext = roMiddle:Add("DOutlinedLabel")
    prepSubtext:SetTall(0.5 * ScrH() * 0.125)
    prepSubtext:Dock(BOTTOM)
    prepSubtext:SetText("")
    prepSubtext:SetContentAlignment(5)
    prepSubtext:SetFont("NMW AU Start Subtext")
    prepSubtext:SetColor(Color(255, 255, 255))

    prepSubtext.Think = function()
      local needed = GAMEMODE.ConVars.MinPlayers:GetInt()

      if not GAMEMODE.MapManifest then
        prepSubtext:SetText(TRANSLATE("prepare.invalidMap.subText"))
      elseif GAMEMODE:GetFullyInitializedPlayerCount() < needed then
        prepSubtext:SetText(TRANSLATE("prepare.waitingForPlayers"))
      elseif not GAMEMODE.ConVars.ForceAutoWarmup:GetBool() and CAMI.PlayerHasAccess(LocalPlayer(), GAMEMODE.PRIV_START_ROUND) then
        prepSubtext:SetText(TRANSLATE("prepare.pressToStart")(string.upper(input.LookupBinding("jump") or "???")))
      else
        if not (GAMEMODE.ConVars.ForceAutoWarmup:GetBool() or GAMEMODE:IsOnAutoPilot()) then
          prepSubtext:SetText(TRANSLATE("prepare.waitingForAdmin"))
        else
          local time = math.max(0, GetGlobalFloat("NMW AU AutoPilotTimer") - CurTime())

          if time > 0 then
            prepSubtext:SetText(TRANSLATE("prepare.commencing")(time))
          else
            prepSubtext:SetText("")
          end
        end
      end
    end

    return
  end

  -- The task bar. A clustertruck of panels.
  local taskBarPanel1 = self:Add("Panel")
  taskBarPanel1:SetTall(ScrH() * 0.09)
  taskBarPanel1:Dock(TOP)
  local pad = ScrH() * 0.015
  taskBarPanel1:DockPadding(pad, pad, pad, pad)
  local taskBarPanel2 = taskBarPanel1:Add("Panel")
  taskBarPanel2:SetWide(ScrW() * 0.35)
  taskBarPanel2:Dock(LEFT)
  pad = ScrH() * 0.003
  taskBarPanel2:DockPadding(pad, pad, pad, pad)
  local outerColor = Color(0, 0, 0)

  taskBarPanel2.Paint = function(_, w, h)
    draw.RoundedBox(6, 0, 0, w, h, outerColor)
  end

  local taskBarPanel3 = taskBarPanel2:Add("Panel")
  taskBarPanel3:Dock(FILL)
  pad = ScrH() * 0.008
  taskBarPanel3:DockPadding(pad, pad, pad, pad)
  local innerColor = Color(170, 188, 188)
  local taskBarOuterColor = Color(51, 51, 51)
  pad = ScrH() * 0.005

  taskBarPanel3.Paint = function(_, w, h)
    draw.RoundedBox(4, 0, 0, w, h, innerColor)
    draw.RoundedBox(4, pad, pad, w - pad * 2, h - pad * 2, taskBarOuterColor)
  end

  local taskBarPanel4 = taskBarPanel3:Add("Panel")
  taskBarPanel4:Dock(FILL)
  self.taskBarLabel = taskBarPanel4:Add("DOutlinedLabel")
  self.taskBarLabel:SetColor(Color(255, 255, 255))
  self.taskBarLabel:SetZPos(1)
  self.taskBarLabel:SetFont("NMW AU Taskbar")
  self.taskBarLabel:SetText("  " .. TRANSLATE("tasks.totalCompleted"))
  self.taskBarLabel:SetContentAlignment(4)

  -- If there's a time limit, dock the timer to the right side.
  if GAMEMODE:GetTimeLimit() > 0 then
    local gameTimer = self.taskBarLabel:Add("DOutlinedLabel")
    gameTimer:SetWide(ScrW() * 0.08)
    gameTimer:Dock(RIGHT)
    gameTimer:SetText("...")
    gameTimer:SetContentAlignment(6)
    gameTimer:SetFont("NMW AU Taskbar")
    gameTimer:SetColor(Color(255, 255, 255))
    local isRed = false

    gameTimer.Think = function()
      local time = GAMEMODE:GetTimeLimit()

      if time <= 60 and not isRed then
        isRed = true
        gameTimer:SetColor(Color(255, 0, 0))
      end

      gameTimer:SetText(string.FormattedTime(time, "%02i:%02i") .. "  ")
    end
  end

  self.taskbar = taskBarPanel4:Add("Panel")
  local taskBarInnerColor = Color(68, 216, 68)

  self.taskbar.Paint = function(_, w, h)
    surface.SetDrawColor(taskBarInnerColor)

    return surface.DrawRect(0, 0, w, h)
  end

  self.taskbar:NewAnimation(0, 0, 0, function()
    local refW, refH = self.taskbar:GetParent():GetSize()
    self.taskbar:SetSize(0, refH)
    self.taskBarLabel:SetSize(refW, refH)
  end)

  -- The task list.
  self.taskBoxContainer = self:Add("Panel")
  local taskLabel
  local margin = ScrH() * 0.015
  self.taskBoxContainer:DockMargin(margin, 0, 0, 0)
  self.taskBoxContainer:SetWide(ScrW() * 0.35)
  self.taskBoxContainer:Dock(LEFT)
  -- Label container.
  local taskBoxTitle = self.taskBoxContainer:Add("Panel")
  taskBoxTitle:Dock(TOP)
  taskBoxTitle:SetTall(ScrH() * 0.05)
  taskLabel = taskBoxTitle:Add("DOutlinedLabel")
  taskLabel:Dock(LEFT)
  local key = string.upper(input.LookupBinding("gmod_undo") or "?")
  local text = "(" .. tostring(key) .. ") " .. tostring(TRANSLATE(localPlayerRole.HasTasks and "hud.tasks" or "hud.fakeTasks"))
  taskLabel:SetText("  " .. tostring(text) .. "  ")
  taskLabel:SetFont("NMW AU Taskbar")
  taskLabel:SetContentAlignment(5)
  local taskLabel_OldPaint = taskLabel.Paint

  taskLabel.Paint = function(_, w, h)
    surface.SetDrawColor(255, 255, 255, 16)
    surface.DrawRect(0, 0, w, h)
    taskLabel_OldPaint(_, w, h)
  end

  taskLabel:SizeToContentsX()
  self.tasks = {}
  self.taskBox = self.taskBoxContainer:Add("Panel")
  self.taskBox:Dock(FILL)
  local padding = ScrW() * 0.005
  self.taskBox:DockPadding(padding, 0, 0, 0)

  self.taskBox.PerformLayout = function()
    local max

    for _, child in ipairs(self.taskBox:GetChildren()) do
      local sizeX = child:GetContentSize()

      if not max or sizeX > max then
        max = sizeX
      end
    end

    local _, childHeight = self.taskBox:ChildrenSize()
    self.taskBox.__maxWidth = padding * 2 + (max or 0)
    self.taskBox.__maxHeight = childHeight
  end

  self.taskBox:InvalidateLayout()

  self.taskBox.Paint = function(_, w, h)
    surface.SetDrawColor(255, 255, 255, 16)
    surface.DrawRect(0, 0, self.taskBox.__maxWidth or 0, self.taskBox.__maxHeight)
  end

  -- add role description to taskbox
  if localPlayerRole.desc then
    local roleDesc = self:AddTaskEntry()
    roleDesc:SetText(localPlayerRole.desc)
    roleDesc:SetColor(localPlayerRole.color)
  end

  if localPlayerTable then
    -- Use button. Content-aware.
    self.use = self.buttons:Add("Panel")
    self.use:SetWide(self.buttons:GetTall())
    self.use:DockMargin(0, 0, ScreenScale(5), 0)
    self.use:Dock(RIGHT)

    function self.use:Think()
      if IsValid(GAMEMODE.UseHighlight) then
        self:SetAlpha(255)
      else
        self:SetAlpha(32)
      end
    end

    self.use.Paint = function(_, w, h)
      local ent = GAMEMODE.UseHighlight
      local mat = self.UseButtonOverride or IsValid(ent) and (ent:GetClass() == "prop_vent" or ent:GetClass() == "func_vent") and MAT_BUTTONS.vent

      if not mat then
        mat = MAT_BUTTONS.use
      end

      -- Like, jesus christ man.
      surface.SetDrawColor(COLOR_WHITE)
      surface.SetMaterial(mat)
      render.PushFilterMag(TEXFILTER.ANISOTROPIC)
      render.PushFilterMin(TEXFILTER.ANISOTROPIC)
      surface.DrawTexturedRect(0, 0, w, h)
      render.PopFilterMag()
      render.PopFilterMin()
    end

    -- Report button. Content-aware.
    self.report = self.buttonsTwo:Add("Panel")
    self.report:SetWide(self.buttonsTwo:GetTall())
    self.report:DockMargin(0, 0, ScreenScale(5), 0)
    self.report:Dock(RIGHT)

    function self.report.Think()
      if IsValid(GAMEMODE.ReportHighlight) then
        self.report:SetAlpha(255)
      else
        self.report:SetAlpha(32)
      end
    end

    local mat = MAT_BUTTONS.report

    self.report.Paint = function(_, w, h)
      -- Here we are again.
      surface.SetDrawColor(COLOR_WHITE)
      surface.SetMaterial(mat)
      render.PushFilterMag(TEXFILTER.ANISOTROPIC)
      render.PushFilterMin(TEXFILTER.ANISOTROPIC)
      surface.DrawTexturedRect(0, 0, w, h)
      render.PopFilterMag()
      render.PopFilterMin()
    end

    -- Kill button for imposerts. Content-aware.
    if localPlayerRole and localPlayerRole.CanKill then
      self.kill = self.buttons:Add("Panel")
      self.kill:SetWide(self.buttons:GetTall())
      self.kill:DockMargin(0, 0, ScreenScale(5), 0)
      self.kill:Dock(RIGHT)

      self.kill.Paint = function(_, w, h)
        -- Honestly I wish I had a wrapper for this kind of monstrosities.
        surface.SetMaterial(MAT_BUTTONS.kill)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        local alpha

        if GAMEMODE.GameData.KillCooldown >= CurTime() then
          alpha = 32
        elseif IsValid(GAMEMODE.KillHighlight) and GAMEMODE.KillHighlight:GetTeam() ~= localPlayerTeam then
          alpha = 255
        else
          alpha = 32
        end

        surface.SetDrawColor(COLOR_WHITE.r, COLOR_WHITE.g, COLOR_WHITE.b, alpha)
        surface.DrawTexturedRect(0, 0, w, h)
        render.PopFilterMag()
        render.PopFilterMin()

        if GAMEMODE.GameData.KillCooldownOverride or (GAMEMODE.GameData.KillCooldown and GAMEMODE.GameData.KillCooldown >= CurTime()) then
          local time = GAMEMODE.GameData.KillCooldownOverride or math.max(0, GAMEMODE.GameData.KillCooldown - CurTime())

          if time > 0 then
            draw.SimpleTextOutlined(string.format("%d", math.floor(time)), "NMW AU Cooldown", w * 0.5, h * 0.5, COLOR_WHITE, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 4, COLOR_BLACK)
          end
        end
      end
    end

    -- The player icon!
    -- for some reason this thing wants to be DPanel
    -- why??
    self.playerIcon = self.buttons:Add("DPanel")
    self.playerIcon:SetWide(self.buttons:GetTall())
    self.playerIcon:Dock(LEFT)
    local size = self.playerIcon:GetWide()
    local circle = GAMEMODE.Render.CreateCircle(size / 2, size / 2, size / 2, 90)

    self.playerIcon.Paint = function()
      surface.SetAlphaMultiplier(0.8)
      surface.SetDrawColor(localPlayerTable.color)
      draw.NoTexture()
      surface.DrawPoly(circle)
      surface.SetAlphaMultiplier(1)
    end

    local model = self.playerIcon:Add("DModelPanel")
    model:Dock(FILL)
    model:SetModel(LocalPlayer():GetModel())
    model:SetFOV(36)
    model:SetCamPos(model:GetCamPos() - Vector(0, 0, 4))
    local modelEntity = model:GetEntity()
    local playerColor = localPlayerTable.color:ToVector()
    modelEntity.GetPlayerColor = function() return playerColor end
    modelEntity:SetAngles(Angle(0, 90, 0))
    modelEntity:SetPos(modelEntity:GetPos() - Vector(0, 0, 4))
    model.LayoutEntity = function() end
    local textColor = localPlayerRole.color
    local model_oldPaint = model.Paint

    model.Paint = function(_, w, h)
      -- le old huge chunk of stencil code. shall we?
      render.ClearStencil()
      render.SetStencilEnable(true)
      render.SetStencilTestMask(0xFF)
      render.SetStencilWriteMask(0xFF)
      render.SetStencilReferenceValue(0x01)
      render.SetStencilCompareFunction(STENCIL_NEVER)
      render.SetStencilFailOperation(STENCIL_REPLACE)
      render.SetStencilZFailOperation(STENCIL_REPLACE)
      surface.DrawPoly(circle)
      render.SetStencilCompareFunction(STENCIL_LESSEQUAL)
      render.SetStencilFailOperation(STENCIL_KEEP)
      render.SetStencilZFailOperation(STENCIL_KEEP)
      model:SetAlpha(255 * (GAMEMODE.GameData.DeadPlayers[localPlayerTable] and 0.65 or 1))
      model_oldPaint(_, w, h)
      render.SetStencilEnable(false)
      surface.DisableClipping(true)
      draw.SimpleTextOutlined(localPlayerTable.nickname or "", "NMW AU Taskbar", w / 2, -size * 0.1, textColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, 160))
      surface.DisableClipping(false)
    end
  end
end

function VGUI_SPLASH:DisplayPlayers(reason)
  local localPlayerTable = GAMEMODE.GameData.Lookup_PlayerByEntity[LocalPlayer()]
  local localPlayerRole = LocalPlayer():GetRole()
  local localPlayerTeam = LocalPlayer():GetTeam()
  local displayTime = reason and 8 or GAMEMODE.SplashScreenTime - SHUT_TIME

  self:AlphaTo(0, 0.25, displayTime, function()
    self:Remove()
  end)

  self.crewmate_screen = self:Add("Panel")
  self.crewmate_screen:SetSize(self:GetWide(), self:GetTall())
  self.crewmate_screen:SetAlpha(0)

  self.crewmate_screen:AlphaTo(255, 0.25, 0, function()
    -- Are we an imposter, son?
    local imposter = GAMEMODE.GameData.Imposters[localPlayerTable]
    -- Are we winning, son?
    local victory = reason and reason == localPlayerTeam.id
    -- Are we coloring, son?
    local theme_color = reason and roles.GetByID(reason).color or localPlayerRole.color

    -- Play a contextual sound depending on why we're showing the screen.
    if reason then
      surface.PlaySound(reason == GAMEMODE.GameOverReason.Crewmate and "au/victory_crew.ogg" or "au/victory_imposter.ogg")
    else
      surface.PlaySound("au/start.ogg")
    end

    local roleText = self:Add("DLabel")
    roleText:SetSize(self:GetWide(), self:GetTall() * 0.3)
    roleText:SetPos(0, self:GetTall() * 0.05)
    roleText:SetContentAlignment(5)
    roleText:SetFont("NMW AU Role")
    roleText:SetColor(theme_color)

    if reason then
      roleText:SetText(tostring(TRANSLATE(victory and "splash.victory" or "splash.defeat")))
    else
      roleText:SetText(string.upper(localPlayerRole.name[1]) .. string.sub(localPlayerRole.name, 2))
    end

    roleText:SetAlpha(0)
    roleText:AlphaTo(255, displayTime / 1.5)
    roleText:MoveTo(0, self:GetTall() * 0.1, displayTime * 0.75)

    -- Create the "N imposers among us" text if necessary.
    if not reason and not imposter then
      local text = tostring(TRANSLATE("splash.text")(not not localPlayerTable, GAMEMODE.ImposterCount))
      local roleSubtext = self.crewmate_screen:Add("DLabel")
      roleSubtext:SetSize(self:GetWide(), self:GetTall() * 0.3)
      roleSubtext:SetPos(0, self:GetTall() * 0.2)
      roleSubtext:SetContentAlignment(5)
      roleSubtext:SetColor(Color(255, 255, 255))
      roleSubtext:SetText(string.format(text, GAMEMODE.ImposterCount))
      roleSubtext:SetFont("NMW AU Role Subtext")
      roleSubtext:SetAlpha(0)
      roleSubtext:AlphaTo(255, displayTime / 1.5, 0.5)
      roleSubtext:MoveTo(0, self:GetTall() * 0.225, displayTime * 0.6, 0.5)
    end

    -- This is dumb, but whatever.
    -- I'm basically using this as a timer.
    local placeholder = self.crewmate_screen:Add("Panel")
    placeholder:SetAlpha(0)
    placeholder:AlphaTo(255, displayTime / 4, 0.5)
    -- Create a bar to contain all players.
    local playerBar = self.crewmate_screen:Add("Panel")
    local size = (math.min(self:GetTall(), self:GetWide())) * 0.4
    playerBar:SetSize(self:GetWide(), size)
    playerBar:SetPos(0, self:GetTall() * 0.15 + self:GetTall() / 2 - playerBar:GetTall() / 2)

    -- This atrocious thing paints the blurry background behind players.
    playerBar.Paint = function(_, w, h)
      surface.DisableClipping(true)
      surface.SetDrawColor(Color(theme_color.r, theme_color.g, theme_color.b, 64))
      surface.SetMaterial(Material("au/gui/circle.png", "smooth"))
      render.PushFilterMag(TEXFILTER.ANISOTROPIC)
      render.PushFilterMin(TEXFILTER.ANISOTROPIC)
      local stretch = (w * 1.15) * (placeholder:GetAlpha() / 255)
      surface.DrawTexturedRect(w / 2 - stretch / 2, 0, stretch, h)
      render.PopFilterMag()
      render.PopFilterMin()

      return surface.DisableClipping(false)
    end

    local mdl_size = size * 0.5

    -- Helper function that creates player model containers.
    local function create_mdl(parent, playerTable, middle)
      local mdl = parent:Add("DModelPanel")
      size = (math.min(self:GetTall(), self:GetWide())) * 0.6
      mdl:SetSize(mdl_size, size)
      mdl:SetFOV(32)
      mdl:SetCamPos(mdl:GetCamPos() - Vector(0, 0, 5))
      mdl:SetModel(IsValid(playerTable.entity) and playerTable.entity:GetModel() or GAMEMODE:GetDefaultPlayerModel())
      local mdlEnt = mdl:GetEntity()
      local playerColor = playerTable.color:ToVector()
      mdlEnt.GetPlayerColor = function() return playerColor end
      mdlEnt:SetAngles(Angle(0, 45, 0))
      mdlEnt:SetPos(mdlEnt:GetPos() + Vector(0, 0, 10))
      mdl.Nickname = playerTable.nickname or "???"
      mdl.Think = function() return mdl:SetAlpha(self:GetAlpha()) end
      mdl.LayoutEntity = function() end
      local oldPaint = mdl.Paint

      mdl.Paint = function(_, w, h)
        oldPaint(_, w, h)
        local ltsx, ltsy = _:LocalToScreen(0, 0)
        local v = Vector(ltsx + w / 2, ltsy + h / 2 + w * 0.875, 0)
        ROTATION_MATRIX:Identity()
        ROTATION_MATRIX:Translate(v)
        ROTATION_MATRIX:Scale((w / mdl_size) * 0.25 * Vector(1, 1, 1))
        ROTATION_MATRIX:Translate(-v)
        cam.PushModelMatrix(ROTATION_MATRIX, true)
        surface.DisableClipping(true)
        render.PushFilterMag(TEXFILTER.ANISOTROPIC)
        render.PushFilterMin(TEXFILTER.ANISOTROPIC)
        local vPos = middle and h / 2 + w * 1.75 or h / 2 + w * 0.875
        draw.SimpleTextOutlined(mdl.Nickname or "", "NMW AU Splash Nickname", w / 2, vPos, clr, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 16, Color(0, 0, 0, 160))
        render.PopFilterMag()
        render.PopFilterMin()
        surface.DisableClipping(false)
        cam.PopModelMatrix()
      end

      return mdl
    end

    -- Now, add players to the table.
    -- In case it's a start splash screen, display our team
    -- In case it's a game over screen, display the winning team
    local players = {}

    for _, playerTable in pairs(GAMEMODE.GameData.PlayerTables) do
      if playerTable.entity ~= LocalPlayer() then
        local team = playerTable.entity:GetTeam()

        if reason then
          -- Game Over
          if reason == team.id then
            table.insert(players, playerTable)
          end
        else
          -- Game Start
          if not localPlayerRole.ShowTeammates or (team and team == localPlayerTeam) then
            table.insert(players, playerTable)
          end
        end
      end
    end

    -- Left side of the screen. Contains the first half of players.
    local barWidth

    if localPlayerTable and (not reason or (reason and victory)) then
      barWidth = playerBar:GetWide() / 2 - mdl_size / 2
    else
      barWidth = playerBar:GetWide() / 2
    end

    local leftBar = playerBar:Add("Panel")
    leftBar:SetWide(barWidth)
    leftBar:Dock(LEFT)
    local width_mod = 1

    for i = 1, math.ceil(#players / 2) do
      local mdl = create_mdl(leftBar, players[i])
      local dead = GAMEMODE.GameData.DeadPlayers[players[i]]
      mdl:SetColor(Color(0, 0, 0, dead and 127 or 255))
      local color = Color(255, 255, 255, dead and 127 or 255)
      mdl:ColorTo(color, displayTime / 4, 0.5)
      mdl:Dock(RIGHT)
      mdl:SetWide(mdl:GetWide() * width_mod)
      mdl:GetEntity():SetAngles(Angle(0, 45 + 15 * (1 - width_mod * 0.6), 0))
      mdl.Think = function() return mdl:SetAlpha(self:GetAlpha()) end
      width_mod = width_mod * 0.75
    end

    -- Right side of the screen. Contains the other half of players.
    local rightBar = playerBar:Add("Panel")
    rightBar:SetWide(barWidth)
    rightBar:Dock(RIGHT)

    if #players ~= 1 then
      width_mod = 1

      for i = 1 + (math.ceil(#players / 2)), #players do
        local mdl = create_mdl(rightBar, players[i])
        local dead = GAMEMODE.GameData.DeadPlayers[players[i]]
        mdl:SetColor(Color(0, 0, 0, dead and 127 or 255))
        local color = Color(255, 255, 255, dead and 127 or 255)
        mdl:ColorTo(color, displayTime / 4, 0.5)
        mdl:Dock(LEFT)
        mdl:SetWide(mdl:GetWide() * width_mod)
        mdl:GetEntity():SetAngles(Angle(0, 45 - 15 * (1 - width_mod * 0.6), 0))
        mdl.Think = function() return mdl:SetAlpha(self:GetAlpha()) end
        width_mod = width_mod * 0.75
      end
    end

    -- Now, if we're relevant, put us in the midle.
    if localPlayerTable and (not reason or (reason and victory)) then
      local middlePlayer = playerBar:Add("Panel")
      middlePlayer:Dock(FILL)
      local mdl = create_mdl(middlePlayer, localPlayerTable, true)
      local dead = GAMEMODE.GameData.DeadPlayers[localPlayerTable]
      mdl:SetColor(Color(255, 255, 255, dead and 127 or 255))
      mdl:Dock(FILL)
      mdl:SetFOV(30)
    end
  end)
end

function GAMEMODE:HUD_Reset()
  if IsValid(self.__splash) then
    self.__splash:Remove()
  end

  if IsValid(self.Hud) then
    self.Hud:Remove()
  end

  self.Hud = vgui.CreateFromTable(VGUI_HUD)
  self.Hud:SetPaintedManually(true)

  if self.MapManifest then
    self:HUD_InitializeMap()
  end

  if LocalPlayer():GetRole().CanSabotage then
    self:HUD_InitializeImposterMap()
  end
end

function GAMEMODE:HUD_DisplayGameOver(reason)
  if IsValid(self.Hud) then
    self:HUD_CloseMap()

    if IsValid(self.__splash) then
      self.__splash:Remove()
    end

    local splashPanel = vgui.CreateFromTable(VGUI_SPLASH)
    splashPanel:DisplayGameOver(reason)
    self.__splash = splashPanel
  end
end

function GAMEMODE:HUD_DisplayShush()
  if IsValid(self.Hud) then
    self:HUD_CloseMap()

    if IsValid(self.__splash) then
      self.__splash:Remove()
    end

    local splashPanel = vgui.CreateFromTable(VGUI_SPLASH)
    splashPanel:DisplayShush()
    self.__splash = splashPanel
  end
end

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

local nextTickCheck
hook.Remove("Tick", "NMW AU Highlight")

hook.Add("Tick", "NMW AU Highlight", function()
  -- Operate at ~20 op/s. We don't need this to be any faster
  -- since TracePlayer can potentially be terribly inefficient.
  -- Realistically this shouldn't ever be a problem.
  -- Ha-ha.
  -- Unless...?
  if SysTime() < (nextTickCheck or 0) then return end

  -- Don't trace while the meeting is in progress.
  if GAMEMODE:IsMeetingInProgress() then
    GAMEMODE.UseHighlight = nil
    GAMEMODE.ReportHighlight = nil
    GAMEMODE.KillHighlight = nil
    nextTickCheck = SysTime() + 1

    return
  end

  local localPlayer = LocalPlayer()
  local playerTable = IsValid(localPlayer) and localPlayer:GetAUPlayerTable()

  -- Wait, it's all invalid?
  if not playerTable then
    GAMEMODE.UseHighlight = nil
    GAMEMODE.ReportHighlight = nil
    GAMEMODE.KillHighlight = nil
    nextTickCheck = SysTime() + 1

    return
  end

  nextTickCheck = SysTime() + (1 / 20)
  local usable, reportable = GAMEMODE:TracePlayer(playerTable)
  local oldHighlight = GAMEMODE.UseHighlight
  GAMEMODE.UseHighlight = GAMEMODE:ShouldHighlightEntity(usable) and usable
  GAMEMODE.ReportHighlight = reportable

  -- Determine the closest player if player can kill.
  if playerTable and localPlayer:GetRole().CanKill and not playerTable.entity:IsDead() then
    local closest, min

    for _, target in pairs(player.GetAll()) do
      local targetTable = target:GetAUPlayerTable()
      -- Bail if no table.
      if not targetTable or not targetTable.entity then continue end
      -- Bail if teammate.
      if roleselection.teams[target] == localPlayer:GetTeam() then continue end
      -- Bail if dead or dormant.
      -- Both are basically the same thing, but it's better to be on the safe side.
      if target:IsDormant() or target:IsDead() then continue end
      local currentDist = target:GetPos():DistToSqr(localPlayer:EyePos() + localPlayer:GetAimVector() * 32)

      if not closest or currentDist < min then
        closest = target
        min = currentDist
      end
    end

    if closest then
      -- Do the expensive math to see if the closest target is actually within the kill radius.
      -- Please note that spoofing this check will not actually grant you the ability
      -- to kill anyone on the map regardless of the distance.
      -- This is purely visual stuff.
      local radius = GAMEMODE.BaseUseRadius * GAMEMODE.ConVarSnapshots.KillDistanceMod:GetFloat()

      if radius * radius < (closest:NearestPoint(localPlayer:GetPos())):DistToSqr(localPlayer:NearestPoint(closest:GetPos())) then
        closest = nil
      end
    end

    GAMEMODE.KillHighlight = closest
  else
    -- Should probably not do that.
    GAMEMODE.KillHighlight = nil
  end

  if GAMEMODE.Hud then
    if GAMEMODE.UseHighlight ~= oldHighlight then
      local material = IsValid(GAMEMODE.UseHighlight) and hook.Call("GMAU UseButtonOverride", nil, GAMEMODE.UseHighlight)

      if GAMEMODE.Hud.UseButtonOverride ~= material then
        GAMEMODE.Hud.UseButtonOverride = material
      end
    end

    oldHighlight = GAMEMODE.UseHighlight
  end
end)