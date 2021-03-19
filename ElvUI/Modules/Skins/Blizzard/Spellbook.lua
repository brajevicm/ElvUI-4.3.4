local E, L, V, P, G = unpack(select(2, ...))
local S = E:GetModule("Skins")

local _G = _G
local pairs, select, unpack = pairs, select, unpack

local CreateFrame = CreateFrame
local hooksecurefunc = hooksecurefunc

local function LoadSkin()
	if not E.private.skins.blizzard.enable or not E.private.skins.blizzard.spellbook then return end

	SpellBookFrame:StripTextures(true)
	SpellBookFrame:SetTemplate("Transparent")
	SpellBookFrame:Width(460)

	SpellBookFrameInset:StripTextures()

	SpellBookPageText:SetTextColor(1, 1, 1)
	SpellBookPageText:Point("BOTTOMRIGHT", SpellBookFrame, -90, 15)

	S:HandleNextPrevButton(SpellBookPrevPageButton)
	SpellBookPrevPageButton:Point("BOTTOMRIGHT", SpellBookFrame, -45, 10)
	SpellBookPrevPageButton:Size(24)

	S:HandleNextPrevButton(SpellBookNextPageButton)
	SpellBookNextPageButton:Point("BOTTOMRIGHT", SpellBookPageNavigationFrame, -10, 10)
	SpellBookNextPageButton:Size(24)

	S:HandleCloseButton(SpellBookFrameCloseButton)

	-- Spell Buttons
	for i = 1, SPELLS_PER_PAGE do
		local button = _G["SpellButton"..i]
		local highlight = _G["SpellButton"..i.."Highlight"]

		for j = 1, button:GetNumRegions() do
			local region = select(j, button:GetRegions())
			if region.IsObjectType and region:IsObjectType("Texture") then
				if region:GetTexture() ~= [[Interface\Buttons\ActionBarFlyoutButton]] then
					region:SetTexture(nil)
				end
			end
		end

		button:CreateBackdrop("Default", true)
		button.backdrop:SetFrameLevel(button.backdrop:GetFrameLevel() - 1)

		button.bg = CreateFrame("Frame", nil, button)
		button.bg:CreateBackdrop("Transparent", true)
		button.bg:Point("TOPLEFT", -7, 9)
		button.bg:Point("BOTTOMRIGHT", 170, -10)
		button.bg:SetFrameLevel(button.bg:GetFrameLevel() - 2)

		_G["SpellButton"..i.."IconTexture"]:SetTexCoord(unpack(E.TexCoords))

		highlight:SetAllPoints()
		hooksecurefunc(highlight, "SetTexture", function(self, texture)
			if texture == [[Interface\Buttons\ButtonHilight-Square]] or texture == [[Interface\Buttons\UI-PassiveHighlight]] then
				self:SetTexture(1, 1, 1, 0.3)
			end
		end)

		E:RegisterCooldown(_G["SpellButton"..i.."Cooldown"])

		if i == 1 then
			button:Point("TOPLEFT", SpellBookSpellIconsFrame, 15, -75)
		elseif i == 2 or i == 4 or i == 6 or i == 8 or i == 10 or i == 12 then
			button:Point("TOPLEFT", _G["SpellButton"..i - 1], 225, 0)
		elseif i == 3 or i == 5 or i == 7 or i == 9 or i == 11 then
			button:Point("TOPLEFT", _G["SpellButton"..i - 2], "BOTTOMLEFT", 0, -27)
		end

		button.RequiredLevelString:SetTextColor(1, 1, 1)
		button.SeeTrainerString:SetTextColor(1, 1, 1)
	end

	hooksecurefunc("SpellButton_UpdateButton", function(self)
		local slot, slotType = SpellBook_GetSpellBookSlot(self)
		if not slot then return end

		local _, subSpellName = GetSpellBookItemName(slot, SpellBookFrame.bookType)
		if slotType == "FUTURESPELL" then
			local level = GetSpellAvailableLevel(slot, SpellBookFrame.bookType)

			self.SpellName:Point("LEFT", self, "RIGHT", (level and level > E.mylevel) and 8 or 24, subSpellName == "" and 10 or 12)
			self.SpellName:SetTextColor(0.6, 0.6, 0.6)
			self.SpellSubName:SetTextColor(0.6, 0.6, 0.6)
		else
			self.SpellName:Point("LEFT", self, "RIGHT", 8, subSpellName == "" and 1 or 5)
			self.SpellName:SetTextColor(1, 0.8, 0.1)
			self.SpellSubName:SetTextColor(1, 1, 1)
		end
	end)

	-- Skill Line Tabs
	for i = 1, MAX_SKILLLINE_TABS do
		local tab = _G["SpellBookSkillLineTab"..i]

		tab:StripTextures()
		tab:SetTemplate()
		tab:StyleButton(nil, true)
		tab.pushed = true

		local normal = tab:GetNormalTexture()
		normal:SetTexCoord(unpack(E.TexCoords))
		normal:SetInside()

		if i == 1 then
			tab:Point("TOPLEFT", SpellBookSideTabsFrame, "TOPRIGHT", E.PixelMode and -1 or 1, -40)
		end

		hooksecurefunc(tab:GetHighlightTexture(), "SetTexture", function(self, texPath)
			if texPath ~= nil then self:SetPushedTexture(nil) end
		end)

		hooksecurefunc(tab:GetCheckedTexture(), "SetTexture", function(self, texPath)
			if texPath ~= nil then self:SetHighlightTexture(nil) end
		end)

		_G["SpellBookSkillLineTab"..i.."Flash"]:Kill()
	end

	hooksecurefunc("SpellBookFrame_UpdateSkillLineTabs", function()
		for i = 1, MAX_SKILLLINE_TABS do
			local tab = _G["SpellBookSkillLineTab"..i]
			local _, _, _, _, isGuild = GetSpellTabInfo(i)

			if isGuild then
				local normal = tab:GetNormalTexture()
				normal:SetInside()
				normal:SetTexCoord(unpack(E.TexCoords))

				tab:StyleButton(nil, true)
			end
		end
	end)

	-- Bottom Tabs
	for i = 1, 5 do
		local tab = _G["SpellBookFrameTabButton"..i]

		S:HandleTab(tab)

		if i == 1 then
			tab:ClearAllPoints()
			tab:Point("TOPLEFT", SpellBookFrame, "BOTTOMLEFT", 0, 2)
		end
	end

	-- Professions
	for frame, numItems in pairs({["PrimaryProfession"] = 2, ["SecondaryProfession"] = 4}) do
		for i = 1, numItems do
			local item = _G[frame..i]

			item:StripTextures()
			item:CreateBackdrop("Transparent")
			item:Height(numItems == 2 and 90 or 60)

			item.missingHeader:SetTextColor(1, 0.80, 0.10)
			item.missingText:SetTextColor(1, 1, 1)
			item.missingText:FontTemplate(nil, 12, "OUTLINE")

			item.statusBar:StripTextures()
			item.statusBar:CreateBackdrop()
			item.statusBar:SetStatusBarTexture(E.media.normTex)
			item.statusBar:SetStatusBarColor(0.22, 0.39, 0.84)
			item.statusBar:Size(numItems == 2 and 180 or 120, numItems == 2 and 20 or 18)
			item.statusBar:Point("TOPLEFT", numItems == 2 and 250 or 5, numItems == 2 and -10 or -35)
			item.statusBar.rankText:Point("CENTER")
			item.statusBar.rankText:FontTemplate(nil, 12, "OUTLINE")

			if item.unlearn then
				S:HandleCloseButton(item.unlearn)
				item.unlearn:Size(26)
				item.unlearn:Point("RIGHT", item.statusBar, "LEFT", -130, -11)
				item.unlearn.Texture:SetVertexColor(1, 0, 0)

				item.unlearn:HookScript("OnEnter", function(btn) btn.Texture:SetVertexColor(1, 1, 1) end)
				item.unlearn:HookScript("OnLeave", function(btn) btn.Texture:SetVertexColor(1, 0, 0) end)
			end

			if item.icon then
				item.icon:SetTexCoord(unpack(E.TexCoords))
				item.icon:SetDesaturated(false)
				item.icon:SetAlpha(1)
			end

			if numItems == 2 then
				item:Point("TOPLEFT", 10, -(i == 1 and 30 or 130))
				item.rank:Point("TOPLEFT", 117, -26)
			end

			for j = 1, 2 do
				local button = item["button"..j]

				button:StripTextures()
				button:CreateBackdrop()
				button:SetFrameLevel(button:GetFrameLevel() + 2)

				if numItems == 2 then
					button:Point(j == 1 and "TOPLEFT" or "TOPRIGHT", j == 1 and item.button2 or item, j == 1 and "BOTTOMLEFT" or "TOPRIGHT", j == 1 and 150 or -255, j == 1 and 40 or -45)
				elseif numItems == 4 then
					button:Point("TOPRIGHT", j == 1 and item or item.button1, j == 1 and "TOPRIGHT" or "TOPLEFT", j == 1 and -105 or -110, j == 1 and -10 or 0)
				end

				button:StyleButton(true)
				button.pushed:SetAllPoints()
				button.checked:SetAllPoints()
				button.highlightTexture:SetAllPoints()
				hooksecurefunc(button.highlightTexture, "SetTexture", function(self, texture)
					if texture == [[Interface\Buttons\ButtonHilight-Square]] or texture == [[Interface\Buttons\UI-PassiveHighlight]] then
						self:SetTexture(1, 1, 1, 0.3)
					end
				end)

				button.iconTexture:SetTexCoord(unpack(E.TexCoords))
				button.iconTexture:SetAllPoints()

				if button.unlearn then
					S:HandleCloseButton(button.unlearn)
					button.unlearn:Size(26)
					button.unlearn:Point("RIGHT", button, "LEFT", 0, 0)
					button.unlearn.Texture:SetVertexColor(1, 0, 0)

					button.unlearn:HookScript("OnEnter", function(btn) btn.Texture:SetVertexColor(1, 1, 1) end)
					button.unlearn:HookScript("OnLeave", function(btn) btn.Texture:SetVertexColor(1, 0, 0) end)
				end

				button.subSpellString:SetTextColor(1, 1, 1)

				button.cooldown:SetAllPoints()
				E:RegisterCooldown(button.cooldown)
			end
		end
	end

	hooksecurefunc("UpdateProfessionButton", function(self)
		self.spellString:SetTextColor(1, 0.80, 0.10)
	end)

	-- Mounts/Companions
	for i = 1, NUM_COMPANIONS_PER_PAGE do
		local button = _G["SpellBookCompanionButton"..i]

		button:StripTextures()
		button:SetTemplate("Default", true)
		button:StyleButton()

		if i == 1 then
			button:Point("TOPLEFT", 9, -310)
		end

		button.IconTexture:SetTexCoord(unpack(E.TexCoords))
		button.IconTexture:SetInside(button)

		button.bg = CreateFrame("Frame", nil, button)
		button.bg:CreateBackdrop("Transparent", true)
		button.bg:Point("TOPLEFT", E.PixelMode and 1 or -1, E.PixelMode and -1 or 1)
		button.bg:Point("BOTTOMRIGHT", 105, E.PixelMode and 1 or -1)
	end

	SpellBookCompanionModelFrame:StripTextures()
	SpellBookCompanionModelFrame:CreateBackdrop()
	SpellBookCompanionModelFrame:Size(410, 255)
	SpellBookCompanionModelFrame:ClearAllPoints()
	SpellBookCompanionModelFrame:Point("TOP", SpellBookCompanionsFrame, "TOP", 0, -46)

	SpellBookCompanionsModelFrame:SetInside(SpellBookCompanionModelFrame.backdrop)

	S:HandleButton(SpellBookCompanionSummonButton)
	SpellBookCompanionSummonButton:Point("BOTTOM", -3, 10)
	SpellBookCompanionSummonButton:Size(140, 25)

	SpellBookCompanionSelectedName:Point("TOP", 0, 255)

	SpellBookCompanionModelFrameRotateRightButton:Kill()
	SpellBookCompanionModelFrameRotateLeftButton:Kill()
end

S:AddCallback("Spellbook", LoadSkin)