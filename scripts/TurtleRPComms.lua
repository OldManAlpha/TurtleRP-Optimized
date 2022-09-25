--[[
  Created by Vee (http://victortemprano.com), Drixi in-game
  See Github repo at https://github.com/tempranova/turtlerp

-- Communication system
--- Notes :
--- ALL information send via the chat channel is stored by ALL players;
---  every player updates their unique key anytime a new message is sent out

-- Request types
M Mouseover
T Target
D Description

-- Data responses
MR
TR
DR

-- Player1 sends out a request for information.
  - If they have no key for that player: "<request type>:<Player2>&&NO_KEY"
  - If they have a key for that player: "<request type>:<Player2>&&<unique key>"
  - In the meantime, Player1 displays whatever they have stored locally
-- Player2 is listening, recieves the request
  - If the key matches their local key, they send nothing back
  - If the key doesn't match, they send a response: "<data type>:<Player2>&&<unique key>&&<DATA>"

]]

----
-- Player communication
----

local lastRequestType = nil
local lastPlayerName = nil
local timeOfLastSend = time()
local channelIndex = 0

-- This function often runs too early
function TurtleRP.communication_prep()
  local TurtleRPChannelJoinDelay = CreateFrame("Frame")
  TurtleRPChannelJoinDelay:Hide()
  TurtleRPChannelJoinDelay:SetScript("OnShow", function()
      this.startTime = GetTime()
  end)
  TurtleRPChannelJoinDelay:SetScript("OnHide", function()
      TurtleRP.checkTTRPChannel()
  end)
  TurtleRPChannelJoinDelay:SetScript("OnUpdate", function()
    local plus = 15 --seconds
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        TurtleRPChannelJoinDelay:Hide()
    end
  end)
  TurtleRPChannelJoinDelay:Show()
end


function TurtleRP.checkTTRPChannel()
    local lastVal = 0
    local chanList = { GetChannelList() }
    for _, value in next, chanList do
        if value == "TTRP" then
            channelIndex = lastVal
            break
        end
        lastVal = value
    end
    if channelIndex == 0 then
        JoinChannelByName("TTRP")
    end
end

function TurtleRP.communication_events()

  TurtleRP_Target_DescriptionButton:SetScript("OnClick", function()
    if UnitName("target") == UnitName("player") then
      TurtleRP.buildDescription(UnitName("player"))
    else
      TurtleRP.sendRequestForData("D", UnitName("target"))
    end
    TurtleRP_Description:Show()
    TurtleRP_Admin:Hide()
  end)

  local CheckMessages = CreateFrame("Frame")
  CheckMessages:RegisterEvent("CHAT_MSG_CHANNEL")
  CheckMessages:SetScript("OnEvent", function()
    if event == "CHAT_MSG_CHANNEL" then
      if arg4 == GetChannelName("TTRP") .. ". Ttrp" then
        TurtleRP.checkChatMessage(arg1)
      end
    end
  end)

end

function TurtleRP.sendRequestForData(requestType, playerName)
  if timeOfLastSend ~= time() or lastRequestType ~= requestType or lastPlayerName ~= playerName then
    timeOfLastSend = time()
    lastRequestType = requestType
    lastPlayerName = playerName
    if TurtleRPCharacters[playerName] ~= nil and TurtleRPCharacters[playerName]['key' .. requestType] ~= nil then
      local currentKey = TurtleRPCharacters[playerName]['key' .. requestType]
      TurtleRP.ttrpChatSend(requestType .. ':' .. playerName .. '&&' .. currentKey)
      TurtleRP.displayData(requestType, playerName)
    else
      TurtleRP.ttrpChatSend(requestType .. ':' .. playerName .. '&&NO_KEY')
    end
  end
end

function TurtleRP.checkChatMessage(msg)
  -- If it's requesting data from me
  local colonStart, colonEnd = string.find(msg, ':')
  local dataPrefix = string.sub(msg, 1, colonEnd - 1)
  local ampersandStart, ampersandEnd = string.find(msg, '&&')
  local playerName = string.sub(msg, colonEnd + 1, ampersandEnd - 2)
  if playerName == UnitName("player") then
    if TurtleRP.checkUniqueKey(dataPrefix, msg) ~= true then
      TurtleRP.sendData(dataPrefix)
    end
  else
    TurtleRP.recieveAndStoreData(dataPrefix, playerName, msg)
  end
end

function TurtleRP.checkUniqueKey(dataPrefix, msg)
  local keyValid = false
  local dataFromString = getDataFromString(msg)
  local keyData = dataFromString[2]
  if keyData ~= "NO_KEY" then
    if keyData == TurtleRPCharacterInfo["key" .. dataPrefix] then
      keyValid = true
    end
  end
  return keyValid
end

function TurtleRP.getDataFromString(msg)
  local beginningOfData = strfind(msg, "&&")
  local dataSlice = strsub(arg1, beginningOfData)
  local splitArray = string.split(dataSlice, "&&")
  return splitArray
end

function TurtleRP.sendData(dataPrefix)
  if dataPrefix == "M" then
    TurtleRP.ttrpChatSend(TurtleRP.buildDataStringToSend(dataPrefix))
  end
  if dataPrefix == "T" then
    TurtleRP.ttrpChatSend(TurtleRP.buildDataStringToSend(dataPrefix))
  end
  if dataPrefix == "D" then
    local replacedStringForLineBreakPreservation = gsub(TurtleRPCharacterInfo["description"], "%\n", "@N")
    local stringChunks = TurtleRP.splitByChunk(replacedStringForLineBreakPreservation, 200)
    local totalToSend = table.getn(stringChunks)
    if totalToSend == 0 then
      TurtleRP.ttrpChatSend('DR:' .. UnitName("player") .. "&&" .. TurtleRPCharacterInfo["keyD"] .. "&&1&& ")
    else
      for i in stringChunks do
        TurtleRP.ttrpChatSend('DR:' .. UnitName("player") .. "&&" .. TurtleRPCharacterInfo["keyD"] .. '&&' .. i .. "&&" .. stringChunks[i])
      end
    end
  end
end

function TurtleRP.buildDataStringToSend(dataPrefix)
  local dataToBuild = TurtleRP.dataKeys(dataPrefix)
  local stringToSend = dataPrefix .. "R:" .. UnitName("player")
  for i, dataRef in ipairs(dataToBuild) do
    stringToSend = stringToSend .. "&&" .. TurtleRPCharacterInfo[dataRef]
  end
  return stringToSend
end

function TurtleRP.dataKeys(dataPrefix)
  local dataKeys = {}
  if dataPrefix == "M" or dataPrefix == "MR" then
    dataKeys = { "keyM", "icon", "title", "first_name", "last_name", "ooc_info", "ic_info", "currently_ic", "ooc_pronouns", "ic_pronouns" }
  end
  if dataPrefix == "T" or dataPrefix == "TR" then
    dataKeys = { "keyT", "atAGlance1", "atAGlance1Icon", "atAGlance2", "atAGlance2Icon", "atAGlance3", "atAGlance3Icon" }
  end
  return dataKeys
end

function TurtleRP.recieveAndStoreData(dataPrefix, playerName, msg)
  local stringData = TurtleRP.getDataFromString(msg)
  if TurtleRPCharacters[playerName] == nil then
    TurtleRPCharacters[playerName] = {}
  end
  if dataPrefix == "MR" or dataPrefix == "TR" then
    local dataToSave = TurtleRP.dataKeys(dataPrefix)
    for i, dataRef in ipairs(dataToSave) do
      TurtleRPCharacters[playerName][dataRef] = stringData[i + 1]
    end
  end
  if dataPrefix == "DR" then
    if stringData[3] == "1" then
      TurtleRPCharacters[playerName]["description"] = ""
    end
    local dataToSave = TurtleRP.getDataFromString(msg)
    TurtleRPCharacters[playerName]["keyD"] = dataToSave[2]
    local replacedStringForLineBreaks = gsub(dataToSave[4], "@N", "%\n")
    TurtleRPCharacters[playerName]["description"] = TurtleRPCharacters[playerName]["description"] .. replacedStringForLineBreaks
  end
  TurtleRP.displayData(dataPrefix, playerName)
end

function TurtleRP.displayData(dataPrefix, playerName)
  if playerName == UnitName("mouseover") and (dataPrefix == "M" or dataPrefix == "MR") then
    TurtleRP.buildTooltip(playerName, "mouseover")
  end
  if playerName == UnitName("target") and (dataPrefix == "T" or dataPrefix == "TR") then
    TurtleRP.buildTargetFrame(playerName)
  end
  if playerName == UnitName("target") and (dataPrefix == "D" or dataPrefix == "DR") then
    TurtleRP.buildDescription(playerName)
  end
end

function TurtleRP.ttrpChatSend(message)
  SendChatMessage(message, "CHANNEL", nil, GetChannelName("TTRP"))
end