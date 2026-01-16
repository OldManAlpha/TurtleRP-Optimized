--[[
  Created by Vee (http://victortemprano.com), Drixi in-game
  See Github repo at https://github.com/tempranova/turtlerp
]]

function TurtleRP.OpenDirectory()
  UIPanelWindows["TurtleRP_DirectoryFrame"] = { area = "left", pushable = 0 }
  ShowUIPanel(TurtleRP_DirectoryFrame)
  TurtleRP.updateDirectorySearch()
  TurtleRP.Directory_ScrollBar_Update()
end

function TurtleRP.SetDirectoryButtonsActive(enable)
  if enable then
    TurtleRP_DirectoryFrame_Directory_DeleteButton:Enable()
  else
    TurtleRP_DirectoryFrame_Directory_DeleteButton:Disable()
  end
end


-- Quick Helper Function to determine if user has key and then performs evaluation
function sort_users_by_key(user1, user2, sort_key, sort_by_order)
  -- if User 1 has a key proceed
    if not (user1[sort_key] == nil) then
      -- If User 2 also has a key proceed
      if not (user2[sort_key] == nil) then
        -- If sort is descending, do greater than
        if sort_by_order == 1 then
          return user1[sort_key] > user2[sort_key]
        else
          -- Less than if sort is ascending
          return user1[sort_key] < user2[sort_key]
        end
      else
        -- If user 2 does not have a key but user 1 does return true if descending
        if sort_by_order == 1 then
          return true
        else
        -- return false if not
          return false
        end
      end
    else
      -- If user 1 doesn't have a key but user 2 does have a key
      if not (user2[sort_key] == nil) then
        -- return false if descending
        if sort_by_order == 1 then
          return false
        else
          -- and return true if ascending
          return true
        end
      -- Final Catch if neither has a key, just return false
      else
        return false
      end
    end
  end

----
-- Map Directory Display
----
function TurtleRP.display_nearby_players()

  local zoneListener = CreateFrame("Frame", "TurtleRPZoneListener")
  zoneListener:RegisterEvent("ZONE_CHANGED_NEW_AREA")
  zoneListener:RegisterEvent("WORLD_MAP_UPDATE")
  zoneListener:SetScript("OnEvent", function()
    for i, frame in TurtleRP.locationFrames do
      frame:Hide()
    end
    TurtleRP.show_player_locations()
  end)
end

function TurtleRP.show_player_locations()
  if not WorldMapFrame:IsVisible() then
    return
  end
  local locationFrames = TurtleRP.locationFrames
  for _, frame in ipairs(locationFrames) do
    frame:Hide()
  end
  local onlinePlayers = TurtleRP.get_players_online()
  local frameCount = 0
  local zonesByID = TurtleRP.GetZones(GetCurrentMapContinent())
  local currentZone = GetCurrentMapZone()
  local selfName = UnitName("player")
  for charName, character in pairs(onlinePlayers) do
    if charName ~= selfName then
      local zone = character["zone"]
      local zoneX = tonumber(character["zoneX"])
      local zoneY = tonumber(character["zoneY"])
      if zone == zonesByID[currentZone] and zoneX and zoneY then
        local playerPositionFrame = locationFrames[frameCount]
        if playerPositionFrame == nil then
            playerPositionFrame = CreateFrame("Frame", "TurtleRP_MapPlayerPosition_" .. frameCount, WorldMapDetailFrame, "TurtleRP_WorldMapUnitTemplate")
            table.insert(TurtleRP.locationFrames, playerPositionFrame)
        end
        local mapWidth = WorldMapDetailFrame:GetWidth()
        local mapHeight = WorldMapDetailFrame:GetHeight()
        playerPositionFrame.full_name = charName
        if character['full_name'] ~= nil and character['full_name'] ~= "" then
            playerPositionFrame.full_name = character['full_name']
        end
        playerPositionFrame:SetPoint("CENTER", WorldMapDetailFrame, "TOPLEFT", zoneX * mapWidth, zoneY * mapHeight * -1)
        playerPositionFrame:Show()
        frameCount = frameCount + 1
      end
    end
  end
end

----
-- Directory Scroll Manager
----
TurtleRP.DirectorySearchResults = nil

function TurtleRP.updateDirectorySearch()
    local totalDirectoryChars = 0
    local totalDirectoryOnline = 0
    local searchResults = {}
    local currentArrayNumber = 1
    local showNSFW = TurtleRPSettings["show_nsfw"] == "1"
    local currentTime = time()
    for i, profile in TurtleRPCharacters do
        if profile and (showNSFW or profile['nsfw'] == "0" or profile['nsfw'] == "" or profile['nsfw'] == nil) then
            totalDirectoryChars = totalDirectoryChars + 1
            if type(TurtleRPQueryablePlayers[i]) == "number" then
                if TurtleRPQueryablePlayers[i] > (currentTime - 65) then
                    totalDirectoryOnline = totalDirectoryOnline + 1
                end
            end


            if TurtleRPCharacters[i]['full_name'] == nil then
                TurtleRPCharacters[i]['full_name'] = ""
            end
            local resultShown = true
            if TurtleRP.searchTerm ~= "" then
                if string.find(string.lower(i), string.lower(TurtleRP.searchTerm)) == nil and string.find(string.lower(profile['full_name']), string.lower(TurtleRP.searchTerm)) == nil then
                    resultShown = false
                end
            end
            if resultShown then
                searchResults[currentArrayNumber] = profile
                searchResults[currentArrayNumber]['player_name'] = i
                searchResults[currentArrayNumber]['status'] = "Offline"
                searchResults[currentArrayNumber]['zone'] = profile['zone'] and profile['zone'] or ""
                if TurtleRPQueryablePlayers[i] then
                    if type(TurtleRPQueryablePlayers[i]) == "number" then
                        if TurtleRPQueryablePlayers[i] > (currentTime - 65) then
                            searchResults[currentArrayNumber]['status'] = "Online"
                        end
                    end
                end
                currentArrayNumber = currentArrayNumber + 1
            end
        end
    end

    if TurtleRP.sortByKey ~= nil then
      table.sort(searchResults, function(a, b) return sort_users_by_key(a, b, TurtleRP.sortByKey, TurtleRP.sortByOrder) end)
    end
    TurtleRP.DirectorySearchResults = searchResults

    TurtleRP_DirectoryFrame_Directory_Total:SetText(totalDirectoryChars .. localize("directory.found") .. " (" .. totalDirectoryOnline .. localize("directory.foundOnline") .. ")")
end

function TurtleRP.Directory_ScrollBar_Update()
  FauxScrollFrame_Update(TurtleRP_DirectoryFrame_Directory_ScrollFrame, table.getn(TurtleRP.DirectorySearchResults), 17, 16)
  local currentLine = FauxScrollFrame_GetOffset(TurtleRP_DirectoryFrame_Directory_ScrollFrame)
  TurtleRP.renderDirectory(currentLine)
end

function TurtleRP.renderDirectory(directoryOffset)
  local searchResults = TurtleRP.DirectorySearchResults

  local currentFrameNumber = 1
  if directoryOffset == 0 then
    directoryOffset = directoryOffset + 1
  end
  for i=directoryOffset, directoryOffset+16 do
    local thisFrameName = "TurtleRP_DirectoryFrame_Directory_Button" .. currentFrameNumber
    getglobal(thisFrameName):Hide()
    if searchResults[i] then
      local thisCharacter = searchResults[i]
      getglobal(thisFrameName):Show()
      getglobal(thisFrameName .. "Name"):SetText(thisCharacter['player_name'])
      getglobal(thisFrameName .. 'Variable'):SetText(TurtleRP.secondColumn == "Character Name" and thisCharacter['full_name'] or thisCharacter['zone'])
      getglobal(thisFrameName .. '_StatusOffline'):Show()
      getglobal(thisFrameName .. '_StatusOnline'):Hide()
      if thisCharacter['status'] == "Online" then
        getglobal(thisFrameName .. '_StatusOffline'):Hide()
        getglobal(thisFrameName .. '_StatusOnline'):Show()
      end
    end
    currentFrameNumber = currentFrameNumber + 1
  end
  TurtleRP_DirectoryFrame_TitleText:SetText(localize("directory.title"))
  TurtleRP_DirectoryFrame_Directory_LFGFrame_InfoText:SetText(localize("directory.flavour"))
  TurtleRP_DirectoryFrame_Directory_RefreshButton:SetText(localize("directory.refreshButton"))
  TurtleRP_DirectoryFrame_Directory_CleanButton:SetText(localize("directory.cleanButton"))
  TurtleRP_DirectoryFrame_Directory_DeleteButton:SetText(localize("directory.deleteButton"))
end

local onlinePlayers = {}
function TurtleRP.get_players_online()
  for k, v in pairs(onlinePlayers) do
    onlinePlayers[k] = nil
  end
  local currentTime = time()
  for name, time in pairs(TurtleRPQueryablePlayers) do
    if type(time) == "number" and time > (currentTime - 65) then
        onlinePlayers[name] = TurtleRPCharacters[name]
    else
        TurtleRPQueryablePlayers[name] = nil -- Clean up queryable players that are no longer queryable
    end
  end
  return onlinePlayers
end

function TurtleRP.OpenDirectoryListing(frame)
  TurtleRP.OpenProfile("general")
end

function TurtleRP.Directory_FrameDropDown_Initialize()
  local info;
  local buttonTexts = { "Character Name", "Zone" }
  for i=1, getn(buttonTexts), 1 do
    info = {};
    info.text = buttonTexts[i];
    info.func = TurtleRP.Directory_FrameDropDown_OnClick;
    UIDropDownMenu_AddButton(info);
  end
end

function TurtleRP.LoadZones(...)
  local info = {}
  for i=1, arg.n, 1 do
    info[i] = arg[i]
  end
  return info
end

TurtleRP.ContinentCache = {}
function TurtleRP.GetZones(continentID)
    if not TurtleRP.ContinentCache[continentID] then
        TurtleRP.ContinentCache[continentID] = TurtleRP.LoadZones(GetMapZones(continentID))
    end
    return TurtleRP.ContinentCache[continentID]
end

function TurtleRP.Directory_FrameDropDown_OnClick()
  UIDropDownMenu_SetSelectedID(TurtleRP_Directory_FrameDropDown, this:GetID());
  TurtleRP.secondColumn = this:GetText()
  TurtleRP.updateDirectorySearch()
  TurtleRP.Directory_ScrollBar_Update()
end
