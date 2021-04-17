GM = GAMEMODE
local VGUI_SPLASH = include("amongus/gamemode/vgui/vgui_splash.lua")
GM = nil
local TRANSLATE = GAMEMODE.Lang.GetEntry
local SHUT_TIME = 3
local ROTATION_MATRIX = Matrix()
local splash = {}

function splash:DisplayPlayers(reason)
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
    local theme_color = localPlayerRole.color

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
    local _list_0 = GAMEMODE.GameData.PlayerTables

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

table.Merge(VGUI_SPLASH, splash)

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