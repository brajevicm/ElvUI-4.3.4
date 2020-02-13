local E, L, V, P, G = unpack(select(2, ...))
local UF = E:GetModule("UnitFrames")
local _, ns = ...
local ElvUF = ns.oUF
assert(ElvUF, "ElvUI was unable to locate oUF.")

local CreateFrame = CreateFrame

function UF:Construct_RaidFrames()
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self.menu = UF.SpawnMenu
	self.RaisedElementParent = CreateFrame("Frame", nil, self)
	self.RaisedElementParent.TextureParent = CreateFrame("Frame", nil, self.RaisedElementParent)
	self.RaisedElementParent:SetFrameLevel(self:GetFrameLevel() + 100)

	self.Health = UF:Construct_HealthBar(self, true, true, "RIGHT")
	self.Power = UF:Construct_PowerBar(self, true, true, "LEFT")
	self.Portrait3D = UF:Construct_Portrait(self, "model")
	self.Portrait2D = UF:Construct_Portrait(self, "texture")
	self.InfoPanel = UF:Construct_InfoPanel(self)
	self.Name = UF:Construct_NameText(self)
	self.Buffs = UF:Construct_Buffs(self)
	self.Debuffs = UF:Construct_Debuffs(self)
	self.AuraWatch = UF:Construct_AuraWatch(self)
	self.RaidDebuffs = UF:Construct_RaidDebuffs(self)
	self.DebuffHighlight = UF:Construct_DebuffHighlight(self)
	self.ResurrectIndicator = UF:Construct_ResurrectionIcon(self)
	self.GroupRoleIndicator = UF:Construct_RoleIcon(self)
	self.RaidRoleFramesAnchor = UF:Construct_RaidRoleFrames(self)
	self.MouseGlow = UF:Construct_MouseGlow(self)
	self.PhaseIndicator = UF:Construct_PhaseIcon(self)
	self.TargetGlow = UF:Construct_TargetGlow(self)
	self.ThreatIndicator = UF:Construct_Threat(self)
	self.RaidTargetIndicator = UF:Construct_RaidIcon(self)
	self.ReadyCheckIndicator = UF:Construct_ReadyCheckIcon(self)
	self.HealthPrediction = UF:Construct_HealComm(self)
	self.GPS = UF:Construct_GPS(self)
	self.Fader = UF:Construct_Fader()
	self.Cutaway = UF:Construct_Cutaway(self)

	self.customTexts = {}

	self.unitframeType = "raid"

	UF:Update_StatusBars()
	UF:Update_FontStrings()

	return self
end

function UF:Update_RaidHeader(header, db)
	header:GetParent().db = db

	local headerHolder = header:GetParent()
	headerHolder.db = db

	if not headerHolder.positioned then
		headerHolder:ClearAllPoints()
		headerHolder:Point("BOTTOMLEFT", E.UIParent, "BOTTOMLEFT", 4, 195)
		E:CreateMover(headerHolder, headerHolder:GetName().."Mover", L["Raid Frames"], nil, nil, nil, "ALL,RAID", nil, "unitframe,raid,generalGroup")

		headerHolder.positioned = true
	end
end

function UF:Update_RaidFrames(frame, db)
	frame.db = db

	frame.Portrait = frame.Portrait or (db.portrait.style == "2D" and frame.Portrait2D or frame.Portrait3D)
	frame.colors = ElvUF.colors
	frame:RegisterForClicks(self.db.targetOnMouseDown and "AnyDown" or "AnyUp")

	do
		if self.thinBorders then
			frame.SPACING = 0
			frame.BORDER = E.mult
		else
			frame.BORDER = E.Border
			frame.SPACING = E.Spacing
		end
		frame.SHADOW_SPACING = 3

		frame.ORIENTATION = db.orientation

		frame.UNIT_WIDTH = db.width
		frame.UNIT_HEIGHT = db.infoPanel.enable and (db.height + db.infoPanel.height) or db.height

		frame.USE_POWERBAR = db.power.enable
		frame.POWERBAR_DETACHED = db.power.detachFromFrame
		frame.USE_INSET_POWERBAR = not frame.POWERBAR_DETACHED and db.power.width == "inset" and frame.USE_POWERBAR
		frame.USE_MINI_POWERBAR = (not frame.POWERBAR_DETACHED and db.power.width == "spaced" and frame.USE_POWERBAR)
		frame.USE_POWERBAR_OFFSET = (db.power.width == "offset" and db.power.offset ~= 0) and frame.USE_POWERBAR and not frame.POWERBAR_DETACHED

		frame.POWERBAR_OFFSET = frame.USE_POWERBAR_OFFSET and db.power.offset or 0
		frame.POWERBAR_HEIGHT = not frame.USE_POWERBAR and 0 or db.power.height
		frame.POWERBAR_WIDTH = frame.USE_MINI_POWERBAR and (frame.UNIT_WIDTH - (frame.BORDER*2))/2 or (frame.POWERBAR_DETACHED and db.power.detachedWidth or (frame.UNIT_WIDTH - ((frame.BORDER+frame.SPACING)*2)))

		frame.USE_PORTRAIT = db.portrait and db.portrait.enable
		frame.USE_PORTRAIT_OVERLAY = frame.USE_PORTRAIT and (db.portrait.overlay or frame.ORIENTATION == "MIDDLE")
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or not frame.USE_PORTRAIT) and 0 or db.portrait.width

		frame.CLASSBAR_WIDTH = 0
		frame.CLASSBAR_YOFFSET = 0

		frame.USE_INFO_PANEL = not frame.USE_MINI_POWERBAR and not frame.USE_POWERBAR_OFFSET and db.infoPanel.enable
		frame.INFO_PANEL_HEIGHT = frame.USE_INFO_PANEL and db.infoPanel.height or 0

		frame.BOTTOM_OFFSET = UF:GetHealthBottomOffset(frame)

		frame.VARIABLES_SET = true
	end

	frame:Size(frame.UNIT_WIDTH, frame.UNIT_HEIGHT)

	UF:EnableDisable_Auras(frame)
	UF:Configure_AllAuras(frame)
	UF:Configure_InfoPanel(frame)
	UF:Configure_HealthBar(frame)
	UF:Configure_Power(frame)
	UF:Configure_Portrait(frame)
	UF:Configure_Threat(frame)
	UF:Configure_RaidDebuffs(frame)
	UF:Configure_RaidIcon(frame)
	UF:Configure_ResurrectionIcon(frame)
	UF:Configure_DebuffHighlight(frame)
	UF:Configure_RoleIcon(frame)
	UF:Configure_HealComm(frame)
	UF:Configure_GPS(frame)
	UF:Configure_RaidRoleIcons(frame)
	UF:Configure_Fader(frame)
	UF:Configure_AuraWatch(frame)
	UF:Configure_ReadyCheckIcon(frame)
	UF:Configure_CustomTexts(frame)
	UF:Configure_PhaseIcon(frame)
	UF:Configure_Cutaway(frame)
	UF:UpdateNameSettings(frame)

	frame:UpdateAllElements("ElvUI_UpdateAllElements")
end

UF.headerstoload.raid = true