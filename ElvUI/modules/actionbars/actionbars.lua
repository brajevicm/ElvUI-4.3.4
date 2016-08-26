local E, L, V, P, G = unpack(select(2, ...));
local AB = E:NewModule('ActionBars', 'AceHook-3.0', 'AceEvent-3.0');
local LSM = LibStub("LibSharedMedia-3.0")
local Sticky = LibStub("LibSimpleSticky-1.0");
local _LOCK
local LAB = LibStub("LibActionButton-1.0")

local gsub = string.gsub

local split = string.split;
local KEY_MOUSEBUTTON = KEY_BUTTON10;
KEY_MOUSEBUTTON = gsub(KEY_MOUSEBUTTON, '10', '');
local KEY_NUMPAD = KEY_NUMPAD0;
KEY_NUMPAD = gsub(KEY_NUMPAD, '0', '');

E.ActionBars = AB
AB["handledBars"] = {}
AB["handledbuttons"] = {}
AB["barDefaults"] = {
	["bar1"] = {
		['page'] = 1,
		['bindButtons'] = "ACTIONBUTTON",
		['conditions'] = "[bonusbar:5] 11; [bar:2] 2; [bar:3] 3; [bar:4] 4; [bar:5] 5; [bar:6] 6;",
		['position'] = "BOTTOM,ElvUIParent,BOTTOM,0,4",
	},
	["bar2"] = {
		['page'] = 5,
		['bindButtons'] = "MULTIACTIONBAR2BUTTON",
		['conditions'] = "",
		['position'] = "BOTTOM,ElvUI_Bar1,TOP,0,2",
	},
	["bar3"] = {
		['page'] = 6,
		['bindButtons'] = "MULTIACTIONBAR1BUTTON",
		['conditions'] = "",
		['position'] = "LEFT,ElvUI_Bar1,RIGHT,4,0",
	},
	["bar4"] = {
		['page'] = 4,
		['bindButtons'] = "MULTIACTIONBAR4BUTTON",
		['conditions'] = "",
		['position'] = "RIGHT,ElvUIParent,RIGHT,-4,0",
	},
	["bar5"] = {
		['page'] = 3,
		['bindButtons'] = "MULTIACTIONBAR3BUTTON",
		['conditions'] = "",
		['position'] = "RIGHT,ElvUI_Bar1,LEFT,-4,0",
	},
}

AB.customExitButton = {
	func = function(button)
		if UnitExists('vehicle') then
			VehicleExit()
		else
			PetDismiss()
		end
	end,
	texture = "Interface\\Icons\\Spell_Shadow_SacrificialShield",
	tooltip = LEAVE_VEHICLE,
}

function AB:PositionAndSizeBar(barName)
	local buttonSpacing = E:Scale(self.db[barName].buttonspacing);
	local backdropSpacing = E:Scale((self.db[barName].backdropSpacing or self.db[barName].buttonspacing));
	local buttonsPerRow = self.db[barName].buttonsPerRow;
	local numButtons = self.db[barName].buttons;
	local size = E:Scale(self.db[barName].buttonsize);
	local point = self.db[barName].point;
	local numColumns = ceil(numButtons / buttonsPerRow);
	local widthMult = self.db[barName].widthMult;
	local heightMult = self.db[barName].heightMult;
	local bar = self["handledBars"][barName];

	bar.db = self.db[barName];
	bar.db.position = nil;

	if(numButtons < buttonsPerRow) then
		buttonsPerRow = numButtons;
	end

	if(numColumns < 1) then
		numColumns = 1;
	end

	local barWidth = (size * (buttonsPerRow * widthMult)) + ((buttonSpacing * (buttonsPerRow - 1)) * widthMult) + (buttonSpacing * (widthMult-1)) + (backdropSpacing*2) + ((self.db[barName].backdrop == true and E.Border or E.Spacing)*2);
	local barHeight = (size * (numColumns * heightMult)) + ((buttonSpacing * (numColumns - 1)) * heightMult) + (buttonSpacing * (heightMult-1)) + (backdropSpacing*2) + ((self.db[barName].backdrop == true and E.Border or E.Spacing)*2);
	bar:Width(barWidth);
	bar:Height(barHeight);

	bar.mouseover = self.db[barName].mouseover;

	if(self.db[barName].backdrop == true) then
		bar.backdrop:Show();
	else
		bar.backdrop:Hide();
	end

	local horizontalGrowth, verticalGrowth;
	if(point == "TOPLEFT" or point == "TOPRIGHT") then
		verticalGrowth = "DOWN";
	else
		verticalGrowth = "UP";
	end

	if(point == "BOTTOMLEFT" or point == "TOPLEFT") then
		horizontalGrowth = "RIGHT";
	else
		horizontalGrowth = "LEFT";
	end

	if(self.db[barName].mouseover) then
		bar:SetAlpha(0);
	else
		bar:SetAlpha(self.db[barName].alpha);
	end

	if(self.db[barName].inheritGlobalFade) then
		bar:SetParent(self.fadeParent);
	else
		bar:SetParent(E.UIParent);
	end

	local button, lastButton, lastColumnButton ;
	local firstButtonSpacing = backdropSpacing + (self.db[barName].backdrop == true and E.Border or E.Spacing);
	for i=1, NUM_ACTIONBAR_BUTTONS do
		button = bar.buttons[i];
		lastButton = bar.buttons[i-1];
		lastColumnButton = bar.buttons[i-buttonsPerRow];
		button:SetParent(bar);
		button:ClearAllPoints();
		button:Size(size)
		button:SetAttribute("showgrid", 1);
		ActionButton_ShowGrid(button);

		if self.db[barName].mouseover == true then
			bar:SetAlpha(0);
			if not self.hooks[bar] then
				self:HookScript(bar, 'OnEnter', 'Bar_OnEnter');
				self:HookScript(bar, 'OnLeave', 'Bar_OnLeave');	
			end

			if not self.hooks[button] then
				self:HookScript(button, 'OnEnter', 'Button_OnEnter');
				self:HookScript(button, 'OnLeave', 'Button_OnLeave');
			end
		else
			bar:SetAlpha(1);
			if self.hooks[bar] then
				self:Unhook(bar, 'OnEnter');
				self:Unhook(bar, 'OnLeave');
			end

			if self.hooks[button] then
				self:Unhook(button, 'OnEnter');	
				self:Unhook(button, 'OnLeave');	
			end
		end

		if(i == 1) then
			local x, y;
			if(point == "BOTTOMLEFT") then
				x, y = firstButtonSpacing, firstButtonSpacing;
			elseif(point == "TOPRIGHT") then
				x, y = -firstButtonSpacing, -firstButtonSpacing;
			elseif(point == "TOPLEFT") then
				x, y = firstButtonSpacing, -firstButtonSpacing;
			else
				x, y = -firstButtonSpacing, firstButtonSpacing;
			end

			button:Point(point, bar, point, x, y);
		elseif((i - 1) % buttonsPerRow == 0) then
			local x = 0;
			local y = -buttonSpacing;
			local buttonPoint, anchorPoint = "TOP", "BOTTOM";
			if(verticalGrowth == "UP") then
				y = buttonSpacing;
				buttonPoint = "BOTTOM";
				anchorPoint = "TOP";
			end
			button:Point(buttonPoint, lastColumnButton, anchorPoint, x, y);
		else
			local x = buttonSpacing;
			local y = 0;
			local buttonPoint, anchorPoint = "LEFT", "RIGHT";
			if(horizontalGrowth == "LEFT") then
				x = -buttonSpacing;
				buttonPoint = "RIGHT";
				anchorPoint = "LEFT";
			end

			button:Point(buttonPoint, lastButton, anchorPoint, x, y);
		end

		if(i > numButtons) then
			button:SetScale(0.000001);
			button:SetAlpha(0);
		else
			button:SetScale(1);
			button:SetAlpha(1);
		end

		self:StyleButton(button);
	end

	if self.db[barName].enabled or not bar.initialized then
		if not self.db[barName].mouseover then
			bar:SetAlpha(self.db[barName].alpha);
		end

		local page = self:GetPage(barName, self['barDefaults'][barName].page, self['barDefaults'][barName].conditions)
		if AB['barDefaults']['bar'..bar.id].conditions:find("[form,noform]") then
			bar:SetAttribute("hasTempBar", true)

			local newCondition = page
			newCondition = gsub(AB['barDefaults']['bar'..bar.id].conditions, " %[form,noform%] 0; ", "")
			bar:SetAttribute("newCondition", newCondition)
		else
			bar:SetAttribute("hasTempBar", false)
		end

		bar:Show()
		RegisterStateDriver(bar, "visibility", self.db[barName].visibility);
		RegisterStateDriver(bar, "page", page);

		if not bar.initialized then
			bar.initialized = true;
			AB:PositionAndSizeBar(barName)
			return
		end
	else
		bar:Hide()
		UnregisterStateDriver(bar, "visibility");
	end

	E:SetMoverSnapOffset('ElvAB_'..bar.id, bar.db.buttonspacing / 2)
end

function AB:CreateBar(id)
	local bar = CreateFrame('Frame', 'ElvUI_Bar'..id, E.UIParent, 'SecureHandlerStateTemplate');
	local point, anchor, attachTo, x, y = split(',', self['barDefaults']['bar'..id].position)
	bar:Point(point, anchor, attachTo, x, y)
	bar.id = id
	bar:CreateBackdrop('Default');
	bar:SetFrameStrata("LOW")
	local offset = E.Spacing
	bar.backdrop:SetPoint("TOPLEFT", bar, "TOPLEFT", offset, -offset)
	bar.backdrop:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -offset, offset)
	bar.buttons = {}
	bar.bindButtons = self['barDefaults']['bar'..id].bindButtons
	self:HookScript(bar, 'OnEnter', 'Bar_OnEnter');
	self:HookScript(bar, 'OnLeave', 'Bar_OnLeave');

	for i=1, 12 do
		bar.buttons[i] = LAB:CreateButton(i, format(bar:GetName().."Button%d", i), bar, nil)
		bar.buttons[i]:SetState(0, "action", i)
		for k = 1, 11 do
			bar.buttons[i]:SetState(k, "action", (k - 1) * 12 + i)
		end

		if i == 12 then
			bar.buttons[i]:SetState(11, "custom", AB.customExitButton)
		end

		self:HookScript(bar.buttons[i], 'OnEnter', 'Button_OnEnter');
		self:HookScript(bar.buttons[i], 'OnLeave', 'Button_OnLeave');
	end
	self:UpdateButtonConfig(bar, bar.bindButtons)

	if AB['barDefaults']['bar'..id].conditions:find("[form]") then
		bar:SetAttribute("hasTempBar", true)
	else
		bar:SetAttribute("hasTempBar", false)
	end

	bar:SetAttribute("_onstate-page", [[ 
		self:SetAttribute("state", newstate)
		control:ChildUpdate("state", newstate)
	]]);

	bar:SetAttribute("_onstate-show", [[
		if newstate == "hide" then
			self:Hide();
		else
			self:Show();
		end	
	]])	

	self["handledBars"]['bar'..id] = bar;
	E:CreateMover(bar, 'ElvAB_'..id, L["Bar "]..id, nil, nil, nil,'ALL,ACTIONBARS')
	self:PositionAndSizeBar('bar'..id);
	return bar
end

function AB:PLAYER_REGEN_ENABLED()
	self:UpdateButtonSettings()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function AB:CreateVehicleLeave()
	local vehicle = CreateFrame("Button", 'LeaveVehicleButton', E.UIParent, "SecureHandlerClickTemplate")
	vehicle:Size(26)
	vehicle:SetFrameStrata("HIGH")
	vehicle:Point("BOTTOMLEFT", Minimap, "BOTTOMLEFT", 2, 2)
	vehicle:SetNormalTexture("Interface\\AddOns\\ElvUI\\media\\textures\\vehicleexit")
	vehicle:SetPushedTexture("Interface\\AddOns\\ElvUI\\media\\textures\\vehicleexit")
	vehicle:SetHighlightTexture("Interface\\AddOns\\ElvUI\\media\\textures\\vehicleexit")
	vehicle:SetTemplate("Default")
	vehicle:RegisterForClicks("AnyUp")
	vehicle:SetScript("OnClick", function() VehicleExit() end)
	RegisterStateDriver(vehicle, "visibility", "[vehicleui] show;[target=vehicle,exists] show;hide")
end

function AB:ReassignBindings(event)
	if event == "UPDATE_BINDINGS" then
		self:UpdatePetBindings();
		self:UpdateStanceBindings();
	end

	self:UnregisterEvent("PLAYER_REGEN_DISABLED")

	if InCombatLockdown() then return end	
	for _, bar in pairs(self["handledBars"]) do
		if not bar then return end

		ClearOverrideBindings(bar)
		for i = 1, #bar.buttons do
			local button = (bar.bindButtons.."%d"):format(i)
			local real_button = (bar:GetName().."Button%d"):format(i)
			for k=1, select('#', GetBindingKey(button)) do
				local key = select(k, GetBindingKey(button))
				if key and key ~= "" then
					SetOverrideBindingClick(bar, false, key, real_button)
				end
			end
		end
	end
end

function AB:RemoveBindings()
	if InCombatLockdown() then return end
	for _, bar in pairs(self["handledBars"]) do
		if not bar then return end

		ClearOverrideBindings(bar)
	end

	self:RegisterEvent("PLAYER_REGEN_DISABLED", "ReassignBindings")
end

function AB:UpdateButtonSettings()
	if E.private.actionbar.enable ~= true then return end
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return; end

	for button, _ in pairs(self["handledbuttons"]) do
		if button then
			if(E.db.actionbar.selfcast) then
				button:SetAttribute("unit2", "player");
			else
				button:SetAttribute("unit2", "target");
			end
			self:StyleButton(button, button.noBackdrop)
			self:StyleFlyout(button)
		else
			self["handledbuttons"][button] = nil
		end
	end

	self:UpdatePetBindings()
	self:UpdateStanceBindings()
	for barName, bar in pairs(self["handledBars"]) do
		self:UpdateButtonConfig(bar, bar.bindButtons)
	end

	for i=1, 5 do
		self:PositionAndSizeBar('bar'..i)
	end
	self:PositionAndSizeBarPet()
	self:PositionAndSizeBarShapeShift()

	self:MultiActionBar_Update()
end

function AB:CVAR_UPDATE(event)
	for barName, bar in pairs(self["handledBars"]) do
		self:UpdateButtonConfig(bar, bar.bindButtons)
	end
end

function AB:GetPage(bar, defaultPage, condition)
	local page = self.db[bar]['paging'][E.myclass]
	if not condition then condition = '' end
	if not page then page = '' end
	if page then
		condition = condition.." "..page
	end
	condition = condition.." "..defaultPage

	return condition
end

function AB:StyleButton(button, noBackdrop)
	local name = button:GetName();
	local icon = _G[name.."Icon"];
	local count = _G[name.."Count"];
	local flash	 = _G[name.."Flash"];
	local hotkey = _G[name.."HotKey"];
	local border  = _G[name.."Border"];
	local macroName = _G[name.."Name"];
	local normal  = _G[name.."NormalTexture"];
	local normal2 = button:GetNormalTexture()
	local shine = _G[name.."Shine"];
	local combat = InCombatLockdown()
	local color = self.db.fontColor

	if flash then flash:SetTexture(nil); end
	if normal then normal:SetTexture(nil); normal:Hide(); normal:SetAlpha(0); end
	if normal2 then normal2:SetTexture(nil); normal2:Hide(); normal2:SetAlpha(0); end
	if border then border:Kill(); end

	if not button.noBackdrop then
		button.noBackdrop = noBackdrop;
	end

	if count then
		count:ClearAllPoints();
		count:Point("BOTTOMRIGHT", 0, 2);
		count:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
		count:SetTextColor(color.r, color.g, color.b)
	end

	if not button.noBackdrop and not button.backdrop then
		button:CreateBackdrop('Default', true)
		button.backdrop:SetAllPoints()
	end

	if icon then
		icon:SetTexCoord(unpack(E.TexCoords));
		icon:SetInside()
	end
	
	if shine then
		shine:SetAllPoints()
	end

	if self.db.hotkeytext then
		hotkey:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
		hotkey:SetTextColor(color.r, color.g, color.b)
	end

	if macroName then
		if self.db.macrotext then
			macroName:Show()
			macroName:FontTemplate(LSM:Fetch("font", self.db.font), self.db.fontSize, self.db.fontOutline)
			macroName:ClearAllPoints()
			macroName:Point('BOTTOM', 2, 2)
			macroName:SetJustifyH('CENTER')
		else
			macroName:Hide()
		end
	end

	--Extra Action Button
	if button.style then
		button.style:SetParent(button.backdrop)
		button.style:SetDrawLayer('BACKGROUND', -7)
	end

	button.FlyoutUpdateFunc = AB.StyleFlyout
	self:FixKeybindText(button);
	button:StyleButton();

	if(not self.handledbuttons[button]) then
		E:RegisterCooldown(button.cooldown)

		self.handledbuttons[button] = true;
	end
end

function AB:Bar_OnEnter(bar)
	if bar:GetParent() == self.fadeParent then
		if(not self.fadeParent.mouseLock) then
			E:UIFrameFadeIn(self.fadeParent, 0.2, self.fadeParent:GetAlpha(), 1)
		end
	elseif(bar.mouseover) then
		E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), bar.db.alpha)
	end
end

function AB:Bar_OnLeave(bar)
	if bar:GetParent() == self.fadeParent then
		if(not self.fadeParent.mouseLock) then
			E:UIFrameFadeOut(self.fadeParent, 0.2, self.fadeParent:GetAlpha(), 1 - self.db.globalFadeAlpha)
		end
	elseif(bar.mouseover) then
		E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
	end
end

function AB:Button_OnEnter(button)
	local bar = button:GetParent()
	if bar:GetParent() == self.fadeParent then
		if(not self.fadeParent.mouseLock) then
			E:UIFrameFadeIn(self.fadeParent, 0.2, self.fadeParent:GetAlpha(), 1)
		end
	elseif(bar.mouseover) then
		E:UIFrameFadeIn(bar, 0.2, bar:GetAlpha(), bar.db.alpha)
	end
end

function AB:Button_OnLeave(button)
	local bar = button:GetParent()
	if bar:GetParent() == self.fadeParent then
		if(not self.fadeParent.mouseLock) then
			E:UIFrameFadeOut(self.fadeParent, 0.2, self.fadeParent:GetAlpha(), 1 - self.db.globalFadeAlpha)
		end
	elseif(bar.mouseover) then
		E:UIFrameFadeOut(bar, 0.2, bar:GetAlpha(), 0)
	end
end

function AB:FadeParent_OnEvent(event)
	local cur, max = UnitHealth("player"), UnitHealthMax("player")
	local cast, channel = UnitCastingInfo("player"), UnitChannelInfo("player")
	local target, focus = UnitExists("target"), UnitExists("focus")
	local combat = UnitAffectingCombat("player")
	if (cast or channel) or (cur ~= max) or (target or focus) or combat then
		self.mouseLock = true
		E:UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
	else
		self.mouseLock = false
		E:UIFrameFadeOut(self, 0.2, self:GetAlpha(), 1 - AB.db.globalFadeAlpha)
	end
end

function AB:DisableBlizzard()
	-- Hidden parent frame
	local UIHider = CreateFrame("Frame")
	UIHider:Hide()

	MultiBarBottomLeft:SetParent(UIHider)
	MultiBarBottomRight:SetParent(UIHider)
	MultiBarLeft:SetParent(UIHider)
	MultiBarRight:SetParent(UIHider)

	-- Hide MultiBar Buttons, but keep the bars alive
	for i=1,12 do
		_G["ActionButton" .. i]:Hide()
		_G["ActionButton" .. i]:UnregisterAllEvents()
		_G["ActionButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomLeftButton" .. i]:Hide()
		_G["MultiBarBottomLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomLeftButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarBottomRightButton" .. i]:Hide()
		_G["MultiBarBottomRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarBottomRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarRightButton" .. i]:Hide()
		_G["MultiBarRightButton" .. i]:UnregisterAllEvents()
		_G["MultiBarRightButton" .. i]:SetAttribute("statehidden", true)

		_G["MultiBarLeftButton" .. i]:Hide()
		_G["MultiBarLeftButton" .. i]:UnregisterAllEvents()
		_G["MultiBarLeftButton" .. i]:SetAttribute("statehidden", true)

		if _G["VehicleMenuBarActionButton" .. i] then
			_G["VehicleMenuBarActionButton" .. i]:Hide()
			_G["VehicleMenuBarActionButton" .. i]:UnregisterAllEvents()
			_G["VehicleMenuBarActionButton" .. i]:SetAttribute("statehidden", true)
		end

		_G['BonusActionButton'..i]:Hide()
		_G['BonusActionButton'..i]:UnregisterAllEvents()
		_G['BonusActionButton'..i]:SetAttribute("statehidden", true)

		if E.myclass ~= 'SHAMAN' then
			_G['MultiCastActionButton'..i]:Hide()
			_G['MultiCastActionButton'..i]:UnregisterAllEvents()
			_G['MultiCastActionButton'..i]:SetAttribute("statehidden", true)
		end

		for index, button in pairs(ActionBarButtonEventsFrame.frames) do
			if E.myclass ~= 'SHAMAN' and button:GetName():find('MultiCastActionButton') then
				table.remove(ActionBarButtonEventsFrame.frames, index)
			elseif button:GetName() ~= "ExtraActionButton1" and not button:GetName():find('MultiCastActionButton') then
				table.remove(ActionBarButtonEventsFrame.frames, index)
			end
		end
	end

	MultiCastActionBarFrame.ignoreFramePositionManager = true

	MainMenuBar:UnregisterAllEvents()
	MainMenuBar:Hide()
	MainMenuBar:SetParent(UIHider)

	MainMenuBarArtFrame:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	MainMenuBarArtFrame:UnregisterEvent("ADDON_LOADED")
	MainMenuBarArtFrame:Hide()
	MainMenuBarArtFrame:SetParent(UIHider)

	ShapeshiftBarFrame:UnregisterAllEvents()
	ShapeshiftBarFrame:Hide()
	ShapeshiftBarFrame:SetParent(UIHider)

	BonusActionBarFrame:UnregisterAllEvents()
	BonusActionBarFrame:Hide()
	BonusActionBarFrame:SetParent(UIHider)

	PossessBarFrame:UnregisterAllEvents()
	PossessBarFrame:Hide()
	PossessBarFrame:SetParent(UIHider)

	PetActionBarFrame:UnregisterAllEvents()
	PetActionBarFrame:Hide()
	PetActionBarFrame:SetParent(UIHider)

	VehicleMenuBar:UnregisterAllEvents()
	VehicleMenuBar:Hide()
	VehicleMenuBar:SetParent(UIHider)

	if E.myclass ~= 'SHAMAN' then
		MultiCastActionBarFrame:UnregisterAllEvents()
		MultiCastActionBarFrame:Hide()
		MultiCastActionBarFrame:SetParent(UIHider)
	end

	if PlayerTalentFrame then
		PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	else
		hooksecurefunc("TalentFrame_LoadUI", function() PlayerTalentFrame:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED") end)
	end
end

function AB:UpdateButtonConfig(bar, buttonName)
	if InCombatLockdown() then self:RegisterEvent('PLAYER_REGEN_ENABLED'); return; end
	if not bar.buttonConfig then bar.buttonConfig = { hideElements = {}, colors = {} } end
	bar.buttonConfig.hideElements.macro = self.db.macrotext
	bar.buttonConfig.hideElements.hotkey = self.db.hotkeytext
	bar.buttonConfig.showGrid = GetCVar('alwaysShowActionBars') == '1' and true or false
	bar.buttonConfig.clickOnDown = GetCVar('ActionButtonUseKeyDown') == '1' and true or false
	bar.buttonConfig.colors.range = E:GetColorTable(self.db.noRangeColor)
	bar.buttonConfig.colors.mana = E:GetColorTable(self.db.noPowerColor)
	bar.buttonConfig.colors.hp = E:GetColorTable(self.db.noPowerColor)

	for i, button in pairs(bar.buttons) do
		bar.buttonConfig.keyBoundTarget = format(buttonName.."%d", i)
		button.keyBoundTarget = bar.buttonConfig.keyBoundTarget
		button.postKeybind = AB.FixKeybindText
		button:SetAttribute("buttonlock", GetCVar('lockActionBars') == '1' and true or false)
		button:SetAttribute("checkselfcast", true)
		button:SetAttribute("checkfocuscast", true)
		
		button:UpdateConfig(bar.buttonConfig)
	end
end

function AB:FixKeybindText(button)
	local hotkey = _G[button:GetName()..'HotKey'];
	local text = hotkey:GetText();
	
	if text then
		text = gsub(text, 'SHIFT%-', L['KEY_SHIFT']);
		text = gsub(text, 'ALT%-', L['KEY_ALT']);
		text = gsub(text, 'CTRL%-', L['KEY_CTRL']);
		text = gsub(text, 'BUTTON', L['KEY_MOUSEBUTTON']);
		text = gsub(text, 'MOUSEWHEELUP', L['KEY_MOUSEWHEELUP']);
		text = gsub(text, 'MOUSEWHEELDOWN', L['KEY_MOUSEWHEELDOWN']);
		text = gsub(text, 'NUMPAD', L['KEY_NUMPAD']);
		text = gsub(text, 'PAGEUP', L['KEY_PAGEUP']);
		text = gsub(text, 'PAGEDOWN', L['KEY_PAGEDOWN']);
		text = gsub(text, 'SPACE', L['KEY_SPACE']);
		text = gsub(text, 'INSERT', L['KEY_INSERT']);
		text = gsub(text, 'HOME', L['KEY_HOME']);
		text = gsub(text, 'DELETE', L['KEY_DELETE']);
		text = gsub(text, 'MOUSEWHEELUP', L['KEY_MOUSEWHEELUP']);
		text = gsub(text, 'MOUSEWHEELDOWN', L['KEY_MOUSEWHEELDOWN']);
		text = gsub(text, 'NMULTIPLY', "*");
		text = gsub(text, 'NMINUS', "N-");
		text = gsub(text, 'NPLUS', "N+");

		hotkey:SetText(text);
	end

	hotkey:ClearAllPoints()
	hotkey:Point("TOPRIGHT", 0, -3);
end

local buttons = 0
local function SetupFlyoutButton()
	for i=1, buttons do
		--prevent error if you don't have max ammount of buttons
		if _G["SpellFlyoutButton"..i] then
			AB:StyleButton(_G["SpellFlyoutButton"..i])
			_G["SpellFlyoutButton"..i]:StyleButton()
			_G["SpellFlyoutButton"..i]:CreateBackdrop("Default")
			_G["SpellFlyoutButton"..i]:HookScript('OnEnter', function(self)
				local parent = self:GetParent()
				local parentAnchorButton = select(2, parent:GetPoint())
				if not AB["handledbuttons"][parentAnchorButton] then return end

				local parentAnchorBar = parentAnchorButton:GetParent()
				AB:Bar_OnEnter(parentAnchorBar)
			end)
			_G["SpellFlyoutButton"..i]:HookScript('OnLeave', function(self)
				local parent = self:GetParent()
				local parentAnchorButton = select(2, parent:GetPoint())
				if not AB["handledbuttons"][parentAnchorButton] then return end

				local parentAnchorBar = parentAnchorButton:GetParent()
				AB:Bar_OnLeave(parentAnchorBar)
			end)
		end
	end

	SpellFlyout:HookScript('OnEnter', function(self)
		local anchorButton = select(2, self:GetPoint())
		if not AB["handledbuttons"][anchorButton] then return end

		local parentAnchorBar = anchorButton:GetParent()
		AB:Bar_OnEnter(parentAnchorBar)
	end)

	SpellFlyout:HookScript('OnLeave', function(self)
		local anchorButton = select(2, self:GetPoint())
		if not AB["handledbuttons"][anchorButton] then return end

		local parentAnchorBar = anchorButton:GetParent()
		AB:Bar_OnLeave(parentAnchorBar)
	end)	
end

function AB:StyleFlyout(button)
	if not button.FlyoutBorder then return end
	local combat = InCombatLockdown()

	SpellFlyoutHorizontalBackground:SetAlpha(0)
	SpellFlyoutVerticalBackground:SetAlpha(0)
	SpellFlyoutBackgroundEnd:SetAlpha(0)

	for i=1, GetNumFlyouts() do
		local x = GetFlyoutID(i)
		local _, _, numSlots, isKnown = GetFlyoutInfo(x)
		if isKnown then
			buttons = numSlots
			break
		end
	end

	--Change arrow direction depending on what bar the button is on
	local arrowDistance
	if ((SpellFlyout:IsShown() and SpellFlyout:GetParent() == button) or GetMouseFocus() == button) then
		arrowDistance = 5
	else
		arrowDistance = 2
	end

	if button:GetParent() and button:GetParent():GetParent() and button:GetParent():GetParent():GetName() and button:GetParent():GetParent():GetName() == "SpellBookSpellIconsFrame" then
		return
	end

	if button:GetParent() then
		local point = E:GetScreenQuadrant(button:GetParent())
		if point == "UNKNOWN" then return end

		if strfind(point, "TOP") then
			button.FlyoutArrow:ClearAllPoints()
			button.FlyoutArrow:Point("BOTTOM", button, "BOTTOM", 0, -arrowDistance)
			SetClampedTextureRotation(button.FlyoutArrow, 180)
			if not combat then button:SetAttribute("flyoutDirection", "DOWN") end
		elseif point == "RIGHT" then
			button.FlyoutArrow:ClearAllPoints()
			button.FlyoutArrow:Point("LEFT", button, "LEFT", -arrowDistance, 0)
			SetClampedTextureRotation(button.FlyoutArrow, 270)
			if not combat then button:SetAttribute("flyoutDirection", "LEFT") end
		elseif point == "LEFT" then
			button.FlyoutArrow:ClearAllPoints()
			button.FlyoutArrow:Point("RIGHT", button, "RIGHT", arrowDistance, 0)
			SetClampedTextureRotation(button.FlyoutArrow, 90)
			if not combat then button:SetAttribute("flyoutDirection", "RIGHT") end
		elseif point == "CENTER" or strfind(point, "BOTTOM") then
			button.FlyoutArrow:ClearAllPoints()
			button.FlyoutArrow:Point("TOP", button, "TOP", 0, arrowDistance)
			SetClampedTextureRotation(button.FlyoutArrow, 0)
			if not combat then button:SetAttribute("flyoutDirection", "UP") end
		end
	end
end

--BugFix: Prevent the main actionbar from displaying other actionbar pages..
function AB:MultiActionBar_Update()
	if self.db.useMaxPaging then
		if self.db['bar2'].enabled then
			if not InterfaceOptionsActionBarsPanelBottomRight:GetChecked() then
				InterfaceOptionsActionBarsPanelBottomRight:Click()
			end
		else
			if InterfaceOptionsActionBarsPanelBottomRight:GetChecked() then
				InterfaceOptionsActionBarsPanelBottomRight:Click()
			end
		end

		if self.db['bar3'].enabled then
			if not InterfaceOptionsActionBarsPanelBottomLeft:GetChecked() then
				InterfaceOptionsActionBarsPanelBottomLeft:Click()
			end
		else
			if InterfaceOptionsActionBarsPanelBottomLeft:GetChecked() then
				InterfaceOptionsActionBarsPanelBottomLeft:Click()
			end
		end

		if not self.db['bar5'].enabled and not self.db['bar4'].enabled then
			if InterfaceOptionsActionBarsPanelRight:GetChecked() then
				InterfaceOptionsActionBarsPanelRight:Click()
			end
		else
			if not InterfaceOptionsActionBarsPanelRight:GetChecked() then
				InterfaceOptionsActionBarsPanelRight:Click()
			end
		end

		if self.db['bar4'].enabled then
			InterfaceOptionsActionBarsPanelRightTwo:Enable()
			if not InterfaceOptionsActionBarsPanelRightTwo:GetChecked() then
				InterfaceOptionsActionBarsPanelRightTwo:Click()
			end
		else
			if InterfaceOptionsActionBarsPanelRightTwo:GetChecked() then
				InterfaceOptionsActionBarsPanelRightTwo:Click()
			end
		end
	else
		if not InterfaceOptionsActionBarsPanelBottomRight:GetChecked() then
			InterfaceOptionsActionBarsPanelBottomRight:Click()
		end

		if not InterfaceOptionsActionBarsPanelBottomLeft:GetChecked() then
			InterfaceOptionsActionBarsPanelBottomLeft:Click()
		end

		if not InterfaceOptionsActionBarsPanelRight:GetChecked() then
			InterfaceOptionsActionBarsPanelRight:Click()
		end

		InterfaceOptionsActionBarsPanelRightTwo:Enable()
		if not InterfaceOptionsActionBarsPanelRightTwo:GetChecked() then
			InterfaceOptionsActionBarsPanelRightTwo:Click()
		end
	end
end

local color
function AB:LAB_ButtonUpdate(button)
	color = AB.db.fontColor
	button.count:SetTextColor(color.r, color.g, color.b)
	button.hotkey:SetTextColor(color.r, color.g, color.b)
end
LAB.RegisterCallback(AB, "OnButtonUpdate", AB.LAB_ButtonUpdate)

function AB:Initialize()
	self.db = E.db.actionbar
	if E.private.actionbar.enable ~= true then return; end
	E.ActionBars = AB;

	self.fadeParent = CreateFrame("Frame", "Elv_ABFade", UIParent);
	self.fadeParent:SetAlpha(1 - self.db.globalFadeAlpha);
	self.fadeParent:RegisterEvent("PLAYER_REGEN_DISABLED");
	self.fadeParent:RegisterEvent("PLAYER_REGEN_ENABLED");
	self.fadeParent:RegisterEvent("PLAYER_TARGET_CHANGED");
	self.fadeParent:RegisterEvent("UNIT_SPELLCAST_START");
	self.fadeParent:RegisterEvent("UNIT_SPELLCAST_STOP");
	self.fadeParent:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START");
	self.fadeParent:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP");
	self.fadeParent:RegisterEvent("UNIT_HEALTH");
	self.fadeParent:RegisterEvent("PLAYER_FOCUS_CHANGED");
	self.fadeParent:SetScript("OnEvent", self.FadeParent_OnEvent);

	self:DisableBlizzard()

	self:SetupExtraButton()
	self:SetupMicroBar()

	for i=1, 5 do
		self:CreateBar(i)
	end

	self:CreateBarPet()
	self:CreateBarShapeShift()
	self:CreateVehicleLeave()

	if E.myclass == "SHAMAN" then
		self:CreateTotemBar()
	end

	self:LoadKeyBinder()
	self:RegisterEvent("UPDATE_BINDINGS", "ReassignBindings")
	self:RegisterEvent('CVAR_UPDATE')
	self:ReassignBindings()

	if not GetCVarBool('lockActionBars') then
		SetCVar('lockActionBars', 1)
	end

	SpellFlyout:HookScript("OnShow", SetupFlyoutButton)
end

E:RegisterModule(AB:GetName())