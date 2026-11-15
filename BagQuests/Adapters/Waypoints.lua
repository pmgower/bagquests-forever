-- Waypoints: TomTom if installed, otherwise the game's own map pin.
local _, ns = ...
local Waypoints = {}
ns.Waypoints = Waypoints

local tomtomUID

function Waypoints.Set(step)
  if not (step.mapID and step.x and step.y) then return false end
  local x, y = step.x / 100, step.y / 100
  if TomTom and TomTom.AddWaypoint then
    if tomtomUID and TomTom.RemoveWaypoint then pcall(TomTom.RemoveWaypoint, TomTom, tomtomUID) end
    tomtomUID = TomTom:AddWaypoint(step.mapID, x, y, { title = "BagQuests: " .. step.title, persistent = false })
    return true
  end
  if C_Map and C_Map.SetUserWaypoint and UiMapPoint and UiMapPoint.CreateFromCoordinates then
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(step.mapID, x, y))
    if C_SuperTrack and C_SuperTrack.SetSuperTrackedUserWaypoint then
      C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end
    return true
  end
  return false
end
