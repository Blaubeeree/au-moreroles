[steam-workshop]: https://steamcommunity.com/sharedfiles/filedetails/?id=2476816620

# Update 2022-09-13
Archiving this project because [Garry's Mod Among Us](https://github.com/NotMyWing/GarrysModAmongUs) seems to be inactive and my addon is honestly very messy (I'll maybe rewrite it some day if I'm bored :D).

# More Roles for Among Us

[![Steam Subscriptions](https://img.shields.io/steam/subscriptions/2476816620?logo=steam)][steam-workshop]
[![Steam Favorites](https://img.shields.io/steam/favorites/2476816620?logo=steam)][steam-workshop]
[![Steam Update Date](https://img.shields.io/steam/update-date/2476816620?label=last%20updated&logo=steam)][steam-workshop]

This addon makes it possible to add custom roles to [Garry's Mod Among Us](https://github.com/NotMyWing/GarrysModAmongUs), inspired by [TTT2](https://github.com/TTT-2/TTT2).

This is still a beta version so expect bugs and let me know [here](https://github.com/Blaubeeree/au-moreroles/issues) if you find some.

## Creating a Role

Your role should be located in

```
lua/amongus/roles/[rolename].lua          (shared)
```

or

```
                              init.lua    (serverside)
lua/amongus/roles/[rolename]/ cl_init.lua (clientside)
                              shared.lua  (shared)
```

Example shared file of a role with default values:

```lua
roles.CreateTeam(ROLE.name, {
  color = Color(0, 0, 0)
})

ROLE.name = nil -- defaults to filename
ROLE.color = Color(0, 0, 0)
ROLE.defaultTeam = TEAM_CREWMATE
ROLE.CanKill = false,
ROLE.CanSabotage = false,
ROLE.CanVent = false,
ROLE.HasTasks = true,
ROLE.ShowTeammates = false

ROLE.defaultCVarData = {
  pct = 1,
  max = 1,
  minPlayers = 1,
  random = 100
}

-- called after all roles are loaded
-- roles.SetBaseRole should be called here
function ROLE:Initialize() end

-- called when hud buttons are created
-- can be used to add custom buttons
hook.Add("GMAU ModifyButtons", "example", function(hud) end)

hook.Add("GMAU ShouldWin", "example", function(team)
  return true   -- team wins
  return false  -- prevent team from winning
  return nil    -- do nothing
end)

-- used to modify which roles will be given to the players
-- table selectableRoles has roleIDs as keys and the amount of players who should get the role as value
hook.Add("GMAU ModifySelectableRoles", "example", function(selectableRoles) end)
```
