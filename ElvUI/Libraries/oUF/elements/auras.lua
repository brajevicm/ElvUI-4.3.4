local _, ns = ...
local oUF = ns.oUF

local VISIBLE = 1
local HIDDEN = 0

local function UpdateTooltip(self)
	GameTooltip:SetUnitAura(self:GetParent().__owner.unit, self:GetID(), self.filter)
end

local function onEnter(self)
	if(not self:IsVisible()) then return end

	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	self:UpdateTooltip()
end

local function onLeave()
	GameTooltip:Hide()
end

local function createAuraIcon(element, index)
	local button = CreateFrame("Button", element:GetName() .. "Button" .. index, element)
	button:RegisterForClicks('RightButtonUp')

	local cd = CreateFrame("Cooldown", "$parentCooldown", button, "CooldownFrameTemplate")
	cd:SetAllPoints()

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints()

	local count = button:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 0)

	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture([[Interface\Buttons\UI-Debuff-Overlays]])
	overlay:SetAllPoints()
	overlay:SetTexCoord(.296875, .5703125, 0, .515625)
	button.overlay = overlay

	local stealable = button:CreateTexture(nil, 'OVERLAY')
	stealable:SetTexture([[Interface\TargetingFrame\UI-TargetingFrame-Stealable]])
	stealable:SetPoint('TOPLEFT', -3, 3)
	stealable:SetPoint('BOTTOMRIGHT', 3, -3)
	stealable:SetBlendMode('ADD')
	button.stealable = stealable

	button.UpdateTooltip = UpdateTooltip
	button:SetScript('OnEnter', onEnter)
	button:SetScript('OnLeave', onLeave)

	button.icon = icon
	button.count = count
	button.cd = cd

	if(element.PostCreateIcon) then element:PostCreateIcon(button) end

	return button
end

local function customFilter(element, unit, button, name)
	if((element.onlyShowPlayer and button.isPlayer) or (not element.onlyShowPlayer and name)) then
		return true
	end
end

local function updateIcon(element, unit, index, offset, filter, isDebuff, visible)
	local name, rank, texture, count, debuffType, duration, expiration, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff = UnitAura(unit, index, filter)

	if element.forceShow then
		spellID = 47540
		name, rank, texture = GetSpellInfo(spellID)
		count, debuffType, duration, expiration, caster, isStealable, shouldConsolidate, canApplyAura, isBossDebuff = 5, 'Magic', 0, 60, 'player', nil, nil, nil, nil
	end

	if(name) then
		local position = visible + offset + 1
		local button = element[position]
		if(not button) then
			button = (element.CreateIcon or createAuraIcon) (element, position)

			table.insert(element, button)
			element.createdIcons = element.createdIcons + 1
		end

		button.caster = caster
		button.filter = filter
		button.isDebuff = isDebuff
		button.isPlayer = caster == "player" or caster == "vehicle"

		local show = true
		if not element.forceShow then
			show = (element.CustomFilter or customFilter) (element, unit, button, name, rank, texture, count, debuffType, duration, expiration, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
		end

		if(show) then
			if(button.cd and not element.disableCooldown) then
				if(duration and duration > 0) then
					button.cd:SetCooldown(expiration - duration, duration)
					button.cd:Show()
				else
					button.cd:Hide()
				end
			end

			if(button.overlay) then
				if((isDebuff and element.showDebuffType) or (not isDebuff and element.showBuffType) or element.showType) then
					local color = element.__owner.colors.debuff[debuffType] or element.__owner.colors.debuff.none

					button.overlay:SetVertexColor(color[1], color[2], color[3])
					button.overlay:Show()
				else
					button.overlay:Hide()
				end
			end

			if(button.stealable) then
				if(not isDebuff and isStealable and element.showStealableBuffs and not UnitIsUnit('player', unit)) then
					button.stealable:Show()
				else
					button.stealable:Hide()
				end
			end

			if(button.icon) then button.icon:SetTexture(texture) end
			if(button.count) then button.count:SetText(count > 1 and count) end

			local size = element.size or 16
			button:SetSize(size, size)

			button:EnableMouse(not element.disableMouse)
			button:SetID(index)
			button:Show()

			if(element.PostUpdateIcon) then
				element:PostUpdateIcon(unit, button, index, position, duration, expiration, debuffType, isStealable)
			end

			return VISIBLE
		else
			return HIDDEN
		end
	end
end

local function SetPosition(element, from, to)
	local sizex = (element.size or 16) + (element['spacing-x'] or element.spacing or 0)
	local sizey = (element.size or 16) + (element['spacing-y'] or element.spacing or 0)
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthx = (element['growth-x'] == 'LEFT' and -1) or 1
	local growthy = (element['growth-y'] == 'DOWN' and -1) or 1
	local cols = math.floor(element:GetWidth() / sizex + 0.5)

	for i = from, to do
		local button = element[i]

		if(not button) then break end
		local col = (i - 1) % cols
		local row = math.floor((i - 1) / cols)

		button:ClearAllPoints()
		button:SetPoint(anchor, element, anchor, col * sizex * growthx, row * sizey * growthy)
	end
end

local function filterIcons(element, unit, filter, limit, isDebuff, offset, dontHide)
	if(not offset) then offset = 0 end
	local index = 1
	local visible = 0
	local hidden = 0
	while(visible < limit) do
		local result = updateIcon(element, unit, index, offset, filter, isDebuff, visible)
		if(not result) then
			break
		elseif(result == VISIBLE) then
			visible = visible + 1
		elseif(result == HIDDEN) then
			hidden = hidden + 1
		end

		index = index + 1
	end

	if(not dontHide) then
		for i = visible + offset + 1, #element do
			element[i]:Hide()
		end
	end

	return visible, hidden
end

local function UpdateAuras(self, event, unit)
	if(self.unit ~= unit) then return end

	local auras = self.Auras
	if(auras) then
		if(auras.PreUpdate) then auras:PreUpdate(unit) end

		local numBuffs = auras.numBuffs or 32
		local numDebuffs = auras.numDebuffs or 40
		local max = auras.numTotal or numBuffs + numDebuffs

		local visibleBuffs, hiddenBuffs = filterIcons(auras, unit, auras.buffFilter or auras.filter or 'HELPFUL', math.min(numBuffs, max), nil, 0, true)

		local hasGap
		if(visibleBuffs ~= 0 and auras.gap) then
			hasGap = true
			visibleBuffs = visibleBuffs + 1

			local button = auras[visibleBuffs]
			if(not button) then
				button = (auras.CreateIcon or createAuraIcon) (auras, visibleBuffs)
				table.insert(auras, button)
				auras.createdIcons = auras.createdIcons + 1
			end

			if(button.cd) then button.cd:Hide() end
			if(button.icon) then button.icon:SetTexture() end
			if(button.overlay) then button.overlay:Hide() end
			if(button.stealable) then button.stealable:Hide() end
			if(button.count) then button.count:SetText() end

			button:EnableMouse(false)
			button:Show()

			if(auras.PostUpdateGapIcon) then
				auras:PostUpdateGapIcon(unit, button, visibleBuffs)
			end
		end

		local visibleDebuffs, hiddenDebuffs = filterIcons(auras, unit, auras.debuffFilter or auras.filter or 'HARMFUL', math.min(numDebuffs, max - visibleBuffs), true, visibleBuffs)
		auras.visibleDebuffs = visibleDebuffs

		if(hasGap and visibleDebuffs == 0) then
			auras[visibleBuffs]:Hide()
			visibleBuffs = visibleBuffs - 1
		end

		auras.visibleBuffs = visibleBuffs
		auras.visibleAuras = auras.visibleBuffs + auras.visibleDebuffs

		local fromRange, toRange
		if(auras.PreSetPosition) then
			fromRange, toRange = auras:PreSetPosition(max)
		end

		if(fromRange or auras.createdIcons > auras.anchoredIcons) then
			(auras.SetPosition or SetPosition) (auras, fromRange or auras.anchoredIcons + 1, toRange or auras.createdIcons)
			auras.anchoredIcons = auras.createdIcons
		end

		if(auras.PostUpdate) then auras:PostUpdate(unit) end
	end

	local buffs = self.Buffs
	if(buffs) then
		if(buffs.PreUpdate) then buffs:PreUpdate(unit) end

		local numBuffs = buffs.num or 32
		local visibleBuffs, hiddenBuffs = filterIcons(buffs, unit, buffs.filter or 'HELPFUL', numBuffs)
		buffs.visibleBuffs = visibleBuffs

		local fromRange, toRange
		if(buffs.PreSetPosition) then
			fromRange, toRange = buffs:PreSetPosition(numBuffs)
		end

		if(fromRange or buffs.createdIcons > buffs.anchoredIcons) then
			(buffs.SetPosition or SetPosition) (buffs, fromRange or buffs.anchoredIcons + 1, toRange or buffs.createdIcons)
			buffs.anchoredIcons = buffs.createdIcons
		end

		if(buffs.PostUpdate) then buffs:PostUpdate(unit) end
	end

	local debuffs = self.Debuffs
	if(debuffs) then
		if(debuffs.PreUpdate) then debuffs:PreUpdate(unit) end

		local numDebuffs = debuffs.num or 40
		local visibleDebuffs, hiddenDebuffs = filterIcons(debuffs, unit, debuffs.filter or 'HARMFUL', numDebuffs, true)
		debuffs.visibleDebuffs = visibleDebuffs

		local fromRange, toRange
		if(debuffs.PreSetPosition) then
			fromRange, toRange = debuffs:PreSetPosition(numDebuffs)
		end

		if(fromRange or debuffs.createdIcons > debuffs.anchoredIcons) then
			(debuffs.SetPosition or SetPosition) (debuffs, fromRange or debuffs.anchoredIcons + 1, toRange or debuffs.createdIcons)
			debuffs.anchoredIcons = debuffs.createdIcons
		end

		if(debuffs.PostUpdate) then debuffs:PostUpdate(unit) end
	end
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	UpdateAuras(self, event, unit)

	if(event == 'ForceUpdate' or not event) then
		local buffs = self.Buffs
		if(buffs) then
			(buffs.SetPosition or SetPosition) (buffs, 1, buffs.createdIcons)
		end

		local debuffs = self.Debuffs
		if(debuffs) then
			(debuffs.SetPosition or SetPosition) (debuffs, 1, debuffs.createdIcons)
		end

		local auras = self.Auras
		if(auras) then
			(auras.SetPosition or SetPosition) (auras, 1, auras.createdIcons)
		end
	end
end

local function ForceUpdate(element)
	return Update(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	if(self.Buffs or self.Debuffs or self.Auras) then
		self:RegisterEvent("UNIT_AURA", UpdateAuras)

		local buffs = self.Buffs
		if(buffs) then
			buffs.__owner = self
			buffs.ForceUpdate = ForceUpdate

			buffs.createdIcons = buffs.createdIcons or 0
			buffs.anchoredIcons = 0

			buffs:Show()
		end

		local debuffs = self.Debuffs
		if(debuffs) then
			debuffs.__owner = self
			debuffs.ForceUpdate = ForceUpdate

			debuffs.createdIcons = debuffs.createdIcons or 0
			debuffs.anchoredIcons = 0

			debuffs:Show()
		end

		local auras = self.Auras
		if(auras) then
			auras.__owner = self
			auras.ForceUpdate = ForceUpdate

			auras.createdIcons = auras.createdIcons or 0
			auras.anchoredIcons = 0

			auras:Show()
		end

		return true
	end
end

local function Disable(self)
	if(self.Buffs or self.Debuffs or self.Auras) then
		self:UnregisterEvent('UNIT_AURA', UpdateAuras)

		if(self.Buffs) then self.Buffs:Hide() end
		if(self.Debuffs) then self.Debuffs:Hide() end
		if(self.Auras) then self.Auras:Hide() end
	end
end

oUF:AddElement('Auras', Update, Enable, Disable)