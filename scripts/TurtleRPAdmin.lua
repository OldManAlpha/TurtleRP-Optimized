--[[
  Created by Vee (http://victortemprano.com), Drixi in-game
  See Github repo at https://github.com/tempranova/turtlerp
]]

-----
-- Interface helpers
-----

function TurtleRP.OpenAdmin()
  UIPanelWindows["TurtleRP_AdminSB"] = { area = "left", pushable = 0 }

  ShowUIPanel(TurtleRP_AdminSB)

  TurtleRP_AdminSB_Tab1:SetNormalTexture("Interface\\Icons\\Spell_Nature_MoonGlow")
  TurtleRP_AdminSB_Tab1:Show()

  TurtleRP_AdminSB_Tab2:SetNormalTexture("Interface\\Icons\\INV_Misc_Head_Human_02")
  TurtleRP_AdminSB_Tab2:Show()

  TurtleRP_AdminSB_Tab3:SetNormalTexture("Interface\\Icons\\INV_Misc_StoneTablet_11")
  TurtleRP_AdminSB_Tab3:Show()

  TurtleRP_AdminSB_Tab4:SetNormalTexture("Interface\\Icons\\INV_Letter_03")
  TurtleRP_AdminSB_Tab4:Show()

  TurtleRP_AdminSB_Tab5:SetNormalTexture("Interface\\Icons\\Trade_Engineering")
  TurtleRP_AdminSB_Tab5:Show()

  TurtleRP_AdminSB_Tab6:SetNormalTexture("Interface\\Icons\\INV_Misc_QuestionMark")
  TurtleRP_AdminSB_Tab6:Show()

  TurtleRP_AdminSB_Content1_Tab2:Hide()

  TurtleRP_AdminSB_SpellBookFrameTabButton1:SetNormalTexture("Interface\\Spellbook\\UI-Spellbook-Tab1-Selected")
  TurtleRP_AdminSB_SpellBookFrameTabButton1.bookType = "profile"
  TurtleRP_AdminSB_SpellBookFrameTabButton2:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")
  TurtleRP_AdminSB_SpellBookFrameTabButton2.bookType = "rp_style"

  TurtleRP.localizeAdmin()
  TurtleRP.OnAdminTabClick(1)
end

function TurtleRP.OnAdminTabClick(id)
  for i=1, 6 do
    if i ~= id then
      getglobal("TurtleRP_AdminSB_Tab"..i):SetChecked(0)
      getglobal("TurtleRP_AdminSB_Content"..i):Hide()
    else
      getglobal("TurtleRP_AdminSB_Tab"..i):SetChecked(1)
      getglobal("TurtleRP_AdminSB_Content"..i):Show()
    end
  end

  TurtleRP_AdminSB_Content1_Tab2:Hide()
  TurtleRP_AdminSB_SpellBookFrameTabButton1:SetNormalTexture("Interface\\Spellbook\\UI-Spellbook-Tab1-Selected")
  TurtleRP_AdminSB_SpellBookFrameTabButton2:SetNormalTexture("Interface\\Spellbook\\UI-SpellBook-Tab-Unselected")

  if id == 1 then
    TurtleRP_AdminSB_SpellBookFrameTabButton1:Show()
    TurtleRP_AdminSB_SpellBookFrameTabButton2:Show()
  else
    TurtleRP_AdminSB_SpellBookFrameTabButton1:Hide()
    TurtleRP_AdminSB_SpellBookFrameTabButton2:Hide()
  end
end

function TurtleRP.OnBottomTabAdminClick(bookType)
  if bookType == "profile" then
    TurtleRP_AdminSB_Content1:Show()
    TurtleRP_AdminSB_SpellBookFrameTabButton1:SetNormalTexture("Interface\\Spellbook\\UI-Spellbook-Tab1-Selected")
    TurtleRP_AdminSB_Content1_Tab2:Hide()
    TurtleRP_AdminSB_SpellBookFrameTabButton2:SetNormalTexture("Interface\\SpellBook\\UI-SpellBook-Tab-Unselected")
  end

  if bookType == "rp_style" then
    TurtleRP_AdminSB_Content1:Hide()
    TurtleRP_AdminSB_SpellBookFrameTabButton1:SetNormalTexture("Interface\\SpellBook\\UI-SpellBook-Tab-Unselected")
    TurtleRP_AdminSB_Content1_Tab2:Show()
    TurtleRP_AdminSB_SpellBookFrameTabButton2:SetNormalTexture("Interface\\Spellbook\\UI-Spellbook-Tab1-Selected")
    TurtleRP.SetInitialDropdowns()
  end
end

function TurtleRP.showColorPicker(r, g, b, a, changedCallback)
 ColorPickerFrame:SetColorRGB(r, g, b);
 ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a;
 ColorPickerFrame.previousValues = {r,g,b,a};
 ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback;
 ColorPickerFrame:Hide(); -- Need to run the OnShow handler.
 ColorPickerFrame:Show();
end

function TurtleRP.colorPickerCallback(restore)
  local newR, newG, newB, newA;
  if restore then
    newR, newG, newB, newA = unpack(restore);
  else
    newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB();
  end

  local r, g, b, a = newR, newG, newB, newA;
  local hex = TurtleRP.rgb2hex(r, g, b)
  TurtleRP_AdminSB_Content1_ClassColorButton:SetBackdropColor(r, g, b)
  TurtleRPCharacterInfo['class_color'] = hex
end

-----
-- Dropdown RP Style selectors
-----
function TurtleRP.InitializeRPStyleDropdown(frame, items)
  UIDropDownMenu_Initialize(frame, function()
    local frameName = frame:GetName()
    for i, v in items do
      local info = {}
      info.text = v
      info.value = i
      info.arg1 = v
      info.checked = false
      info.menuList = i
      info.hasArrow = false
      info.func = function(text)
        getglobal(frameName .. "_Text"):SetText(text)
        UIDropDownMenu_SetSelectedValue(frame, this.value)
        CloseDropDownMenus()
      end
      UIDropDownMenu_AddButton(info)
    end
  end)
end

function TurtleRP.SetInitialDropdowns()
  local dropdownsToSet = {}
  dropdownsToSet["experience"] = TurtleRP_AdminSB_Content1_Tab2_ExperienceDropdown
  dropdownsToSet["walkups"] = TurtleRP_AdminSB_Content1_Tab2_WalkupsDropdown
  dropdownsToSet["injury"] = TurtleRP_AdminSB_Content1_Tab2_InjuryDropdown
  dropdownsToSet["romance"] = TurtleRP_AdminSB_Content1_Tab2_RomanceDropdown
  dropdownsToSet["death"] = TurtleRP_AdminSB_Content1_Tab2_DeathDropdown

  for i, v in dropdownsToSet do
    if TurtleRPCharacters[UnitName("player")][i] ~= "0" then
      local thisValue = TurtleRPCharacters[UnitName("player")][i]
      getglobal(v:GetName() .. "_Text"):SetText(TurtleRPDropdownOptions[i][thisValue])
      UIDropDownMenu_SetSelectedValue(v, thisValue)
    end
  end
end

-----
-- Icon Selector
-----
function TurtleRP.create_icon_selector()
  TurtleRP_IconSelector:Show()
  TurtleRP_IconSelector:SetFrameStrata("high")
  TurtleRP_IconSelector_FilterSearchInput:SetFrameStrata("high")
  TurtleRP_IconSelector_ScrollBox:SetFrameStrata("high")
  if TurtleRP.iconFrames == nil then
    TurtleRP.iconFrames = TurtleRP.makeIconFrames()
  end
  TurtleRP.iconSelectorFilter = ""
  TurtleRP_IconSelector_FilterSearchInput:SetText("")
  local currentLine = FauxScrollFrame_GetOffset(TurtleRP_IconSelector_ScrollBox)
  TurtleRP.renderIcons((currentLine))
end

function TurtleRP.Icon_ScrollBar_Update()
  FauxScrollFrame_Update(TurtleRP_IconSelector_ScrollBox, 450, 250, 32)
  local currentLine = FauxScrollFrame_GetOffset(TurtleRP_IconSelector_ScrollBox)
  TurtleRP.renderIcons((currentLine))
end

function TurtleRP.makeIconFrames()
  local IconFrames = {}
  local numberOnRow = 0
  local currentRow = 0
  for i=1,36 do
    local thisIconFrame = CreateFrame("Button", "TurtleRPIcon_" .. i, TurtleRP_IconSelector_ScrollBox)
    thisIconFrame:SetWidth(32)
    thisIconFrame:SetHeight(32)
    thisIconFrame:SetPoint("TOPLEFT", TurtleRP_IconSelector_ScrollBox, numberOnRow * 32, currentRow * -32)
    thisIconFrame:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    thisIconFrame:SetText(i)
    thisIconFrame:SetFont("Fonts\\FRIZQT__.ttf", 0)
    thisIconFrame:SetScript("OnClick", function()
      local thisIconIndex = thisIconFrame:GetText()
      TurtleRPCharacterInfo[TurtleRP.currentIconSelector] = thisIconIndex
      TurtleRP.save_general()
      TurtleRP.save_at_a_glance()
      TurtleRP_IconSelector:Hide()
    end)
    IconFrames[i] = thisIconFrame
    numberOnRow = numberOnRow + 1
    if (i - math.floor(i/6)*6) == 0 then
      currentRow = currentRow + 1
      numberOnRow = 0
    end
  end
  return IconFrames
end

function TurtleRP.renderIcons(iconOffset)
  if TurtleRP.iconFrames ~= nil then
    local filteredIcons = {}
    local numberAdded = 0
    for i, iconName in ipairs(TurtleRPIcons) do
      if TurtleRP.iconSelectorFilter ~= "" then
        if TurtleRPIcons[i + iconOffset] ~= nil then
          if string.find(string.lower(TurtleRPIcons[i + iconOffset]), string.lower(TurtleRP.iconSelectorFilter)) then
            filteredIcons[numberAdded + 1] = i + iconOffset
            numberAdded = numberAdded + 1
          end
        end
      else
        filteredIcons[numberAdded + 1] = i + iconOffset
        numberAdded = numberAdded + 1
      end
    end
    for i, iconFrame in ipairs(TurtleRP.iconFrames) do
      if filteredIcons[i + iconOffset] ~= nil and TurtleRPIcons[filteredIcons[i + iconOffset]] ~= nil then
        iconFrame:SetText(filteredIcons[i + iconOffset])
        iconFrame:SetBackdrop({ bgFile = "Interface\\Icons\\" .. TurtleRPIcons[filteredIcons[i + iconOffset]] })
      else
        iconFrame:SetBackdrop(nil)
      end
    end
  end
end

function TurtleRP.localizeAdmin()
  -- Profile Tab
  TurtleRP_AdminSB_Tab1.tooltip = localize("profile.title")
    -- Basic Info Subtab    
    TurtleRP_AdminSB_SpellBookFrameTabButton2:SetText(localize("profile.rp.title"))
    TurtleRP_AdminSB_SpellBookFrameTabButton1:SetText(localize("profile.basic.title"))
    TurtleRP_AdminSB_Content1_FlavourText:SetText(localize("profile.basic.flavour"))
    TurtleRP_AdminSB_Content1_NSFWText:SetText(localize("profile.basic.nsfw"))
    TurtleRP_AdminSB_Content1_NameText:SetText(localize("profile.basic.characterName"))
    TurtleRP_AdminSB_Content1_RaceText:SetText(localize("profile.basic.race"))
    TurtleRP_AdminSB_Content1_IconText:SetText(localize("profile.basic.icon"))
    TurtleRP_AdminSB_Content1_ClassText:SetText(localize("profile.basic.class"))
    TurtleRP_AdminSB_Content1_ClassColorText:SetText(localize("profile.basic.classColor"))
    TurtleRP_AdminSB_Content1_CurrentlyICText:SetText(localize("profile.basic.ic"))
    TurtleRP_AdminSB_Content1_ICInfoText:SetText(localize("profile.basic.icInfo"))
    TurtleRP_AdminSB_Content1_ICPronounsText:SetText(localize("profile.basic.icPronouns"))
    TurtleRP_AdminSB_Content1_OOCInfoText:SetText(localize("profile.basic.oocInfo"))
    TurtleRP_AdminSB_Content1_OOCPronounsText:SetText(localize("profile.basic.oocPronouns"))
    TurtleRP_AdminSB_Content1_SaveButton:SetText(localize("generic.save"))
    -- RP Style Tab
    TurtleRP_AdminSB_Content1_Tab2_FlavourText:SetText(localize("profile.rp.flavour"))
    TurtleRP_AdminSB_Content1_Tab2_ExperienceText:SetText(localize("profile.rp.experience"))
    TurtleRP_AdminSB_Content1_Tab2_WalkupsText:SetText(localize("profile.rp.walkUps"))
    TurtleRP_AdminSB_Content1_Tab2_InjuryText:SetText(localize("profile.rp.injury"))
    TurtleRP_AdminSB_Content1_Tab2_RomanceText:SetText(localize("profile.rp.romance"))
    TurtleRP_AdminSB_Content1_Tab2_DeathText:SetText(localize("profile.rp.death"))
    TurtleRP_AdminSB_Content1_Tab2_SaveButton:SetText(localize("generic.save"))
  -- At a Glance Tab
  TurtleRP_AdminSB_Tab2.tooltip = localize("glance.title")
  TurtleRP_AdminSB_Content2_FlavourText:SetText(localize("glance.flavour"))
  TurtleRP_AdminSB_Content2_AAG1Text:SetText(localize("glance.iconAndText1"))
  TurtleRP_AdminSB_Content2_AAG2Text:SetText(localize("glance.iconAndText2"))
  TurtleRP_AdminSB_Content2_AAG3Text:SetText(localize("glance.iconAndText3"))
  TurtleRP_AdminSB_Content2_SaveButton:SetText(localize("generic.save"))
  -- Description Tab
  TurtleRP_AdminSB_Tab3.tooltip = localize("description.title")
  TurtleRP_AdminSB_Content3_FlavourText:SetText(localize("description.flavour"))
  TurtleRP_AdminSB_Content3_SaveButton:SetText(localize("generic.save"))
  -- Notes Tab
  TurtleRP_AdminSB_Tab4.tooltip = localize("notes.title")
  TurtleRP_AdminSB_Content4_FlavourText:SetText(localize("notes.flavour"))
  TurtleRP_AdminSB_Content4_SaveButton:SetText(localize("generic.save"))
  -- Settings Tab
  TurtleRP_AdminSB_Tab5.tooltip = localize("settings.title")
  TurtleRP_AdminSB_Content5_PVPText:SetText(localize("settings.battlegrounds"))
  TurtleRP_AdminSB_Content5_TrayText:SetText(localize("settings.showTray"))
  TurtleRP_AdminSB_Content5_TrayResetButton:SetText(localize("settings.resetTray"))
  TurtleRP_AdminSB_Content5_NameText:SetText(localize("settings.largeTooltip"))
  TurtleRP_AdminSB_Content5_MinimapText:SetText(localize("settings.largeMinimapIcon"))
  TurtleRP_AdminSB_Content5_MinimapHideText:SetText(localize("settings.hideMinimapIcon"))
  TurtleRP_AdminSB_Content5_ShareLocText:SetText(localize("settings.shareMapLocation"))
  TurtleRP_AdminSB_Content5_ShowNSFWText:SetText(localize("settings.showNSFW"))
  TurtleRP_AdminSB_Content5_SelectProfileText:SetText(localize("settings.selectProfile"))
  TurtleRP_AdminSB_Content5_SaveButton:SetText(localize("settings.loadProfile"))
  -- About Tab
  TurtleRP_AdminSB_Tab6.tooltip = localize("about.title")
  TurtleRP_AdminSB_Content6_AboutTitle:SetText(localize("about.heading"))
  TurtleRP_AdminSB_Content6_AboutText:SetText(localize("about.flavour"))
  TurtleRP_AdminSB_Content6_IssuesTitle:SetText(localize("about.issueHeading"))
  TurtleRP_AdminSB_Content6_IssuesText:SetText(localize("about.issueFlavour"))
  TurtleRP_AdminSB_Content6_ReloadButton:SetText(localize("about.rejoinButton"))
  TurtleRP_AdminSB_Content6_ClearDirectoryButton:SetText(localize("about.clearDirectory"))
  TurtleRP_AdminSB_Content6_ClearAllDataButton:SetText(localize("about.clearAllData"))
end