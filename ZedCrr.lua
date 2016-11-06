-- XD
if myHero.charName ~= "Zed" then return end
function Check(file_name)
	local file_found=io.open(file_name, "r")      

	if file_found==nil then
		return false
	else
		return true
	end
	return file_found
end
function Rename(from, to)
	if Check(from) then
		os.rename(from, to)
	else
		return nil
	end
end
local ScriptName = "ZedPH"
printMessage = function(message) print("<font color=\"#6699ff\"><b>" .. ScriptName .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end
-- Rename(LIB_PATH.."SourceLib_Fix.lua", "SourceLibk.lua")
if Check(LIB_PATH.."SourceLibk.lua") then
	require 'SourceLibk'
else
	printMessage("Kutuphane kontrol edilmiyor guncelleme. Download lastest version")
	UPDATE_HOST = "raw.github.com"
    UPDATE_PATH = "/PratikHackTR/Update-PratikHack/master/PHLib.lua" .. "?rand="..math.random(1,10000)
    UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
	DownloadFile(UPDATE_URL, LIB_PATH .. "SourceLibk.lua", function() printMessage("Successfully Download, please reload!") end)
	return
end
local VERSION = 1.6
SimpleUpdater("[ZedPH]", VERSION, "raw.github.com" , "/PratikHackTR/Update-PratikHack/master/ZedCrr.lua" , SCRIPT_PATH .. "ZedCore.lua" , "/UnrealCore/GithubForBotOfLegends/master/Script/ZedCore/ZedCore.version" ):CheckUpdate()
local DangerousList = {
	"AatroxQ",
	"AhriSeduce",
	"CurseoftheSadMummy",
	"InfernalGuardian", 
	"EnchantedCrystalArrow",
	"AzirR", 
	"BrandWildfire",
	"CassiopeiaPetrifyingGaze",
	"DariusExecute",
	"DravenRCast",
	"EvelynnR",
	"EzrealTrueshotBarrage",
	"Terrify",
	"GalioIdolOfDurand",
	"GarenR",
	"GravesChargeShot",
	"HecarimUlt",
	"LissandraR",
	"LuxMaliceCannon",
	"UFSlash",                
	"AlZaharNetherGrasp",
	"OrianaDetonateCommand",
	"LeonaSolarFlare",
	"SejuaniGlacialPrisonStart",
	"SonaCrescendo",
	"VarusR",
	"GragasR",
	"GnarR",
	"FizzMarinerDoom",
	"SyndraR",
}
local DONOTCASTDURINGHASTHISBUFFES = {
	"JudicatorIntervention",
	"UndyingRange",
}
local SpellType = {
	Line = "SkillshotLine",
	MissileLine = "SkillshotMissileLine",
	Circular = "SkillshotCircle",
	Cone = "SkillshotCone",
	Arc = "SkillshotArc",
	Ring = "SkillshotRing",
}
local OWM = OrbWalkManager(ScriptName)
local STS = SimpleTS()
local DLib = DamageLib()
local CM = DrawManager()
function OrbwalkToPosition(position)
	if position ~= nil then
		if OWM.MMALoad then
			_G.moveToCursor(position.x, position.z)
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker and OWM.RebornLoad then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(position)
		elseif OWM.NOLLoad then
			OWM.NOL:ForcePosition(position)
		end
	else
		if OWM.MMALoad then
			return
		elseif _G.AutoCarry and _G.AutoCarry.Orbwalker and OWM.RebornLoad then
			_G.AutoCarry.Orbwalker:OverrideOrbwalkLocation(nil)
		end
	end
end
function Contain(table, value)
	for _, v in ipairs(table) do
		if(v == value)then
			return true
		end
	end
	return false
end
function Extends(v1, v2, v3)
	return Vector(v1) + (Vector(v2) - Vector(v1)):normalized() * (GetDistance(v1, v2)+v3)
end
function GetNearObjectCount(source, range, objects)
	local count = 0
	for _, o in ipairs(objects) do
		if(GetDistance(o, source) < range) then
			count = count + 1
		end
	end
	return count
end
function GetMyTryeRange()
	return myHero.range+GetDistance(myHero.minBBox)/2 + 40
end
function OnLoad()
	Main = Main()
end
function OnWndMsg(msg, wParam)
	Main:OnWndMsg(msg, wParam)
end
class("Main")
function Main:__init()
	self:Initialization()
	self.shadowdelay = 0
	self.delayw = 500
end
function Main:Initialization()
	self.Q = Spell(_Q, 900)
	self.Q:SetSkillshot(SKILLSHOT_LINEAR, 50, 0.25, 1700)
	self.W = Spell(_W, 550)
	self.E = Spell(_E, 270)
	self.R = Spell(_R, 650)
	
	self.QCollision = Collision(self.Q.range, 1700, 0.25, 50)
	
	self.LastCast = nil
	self.Shadow = {}
	
	
	self.LBClicked = false
	
	self.minionTable = minionManager(MINION_ENEMY, 1400, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.jungleTable = minionManager(MINION_JUNGLE, 1400, myHero, MINION_SORT_MAXHEALTH_DEC)
	
	CM:CreateCircle(myHero, self.Q.range, 1, {100, 255, 0, 0}, "Draw Q range")
	CM:CreateCircle(myHero, self.W.range, 1, {100, 255, 0, 0}, "Draw W range")
	CM:CreateCircle(myHero, self.E.range, 1, {100, 255, 0, 0}, "Draw E range")
	CM:CreateCircle(myHero, self.R.range, 1, {100, 255, 0, 0}, "Draw R range")
	
	DLib:RegisterDamageSource(_Q, _PHYSICAL, 75, 40, _PHYSICAL, _BONUS_AD, 1, function() return myHero:CanUseSpell(_Q) end)
	DLib:RegisterDamageSource(_E, _PHYSICAL, 60, 30, _PHYSICAL, _BONUS_AD, 0.9, function() return myHero:CanUseSpell(_E) end)
	DLib:RegisterDamageSource(_R, _PHYSICAL, 0, 0, _PHYSICAL, _AD, 1, function() return myHero:CanUseSpell(_R) end, function() return 0 end)
	DLib:RegisterDamageSource(_Bilge, _MAGIC, 100, 0, _MAGIC, _AP, 0, function() return self.Blade:IsReady() end)
	
	-- self.IgniteSlot = GetSummonerSlot("summonerdot")
	-- _IGNITE = self.IgniteSlot
	        
	self.IGNITE = IGNITE()
	
	self.Config = scriptConfig(ScriptName, ScriptName)
	
	self.Config:addSubMenu("OrbWalk", "OrbWalk")
		OWM:AddToMenu(self.Config.OrbWalk)
	
	self.Config:addSubMenu("TargetSelecter", "TargetSelecter")
		STS:AddToMenu(self.Config.TargetSelecter)
	
	self.Config:addSubMenu("DamageLib", "DamageLib")
		 DLib:AddToMenu(self.Config.DamageLib, {_Q, _E, _R})
	
	self.Config:addSubMenu("Draw", "Draw")
		CM:AddToMenu(self.Config.Draw)
	
	self.Config:addSubMenu("Combo", "Combo")
		self.Config.Combo:addParam("UseW", "Use W", SCRIPT_PARAM_LIST, 2, {"Following", "Always", "Off"})
		self.Config.Combo:addParam("UseIgnite", "Use Ignite", SCRIPT_PARAM_ONOFF, true)
		self.Config.Combo:addParam("UseUlt", "Use Ultimate", SCRIPT_PARAM_ONOFF, true)
		self.Config.Combo:addParam("TheLine", "Line Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte('T'))
	
	self.Config:addSubMenu("Harass", "Harass")
		self.Config.Harass:addParam("longhar", "Long Poke", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte('U'))
		--self.Config.Harass:addParam("UseItem", "Use Tiamat/Hydra", SCRIPT_PARAM_ONOFF, true)
		self.Config.Harass:addParam("UseW", "Use W", SCRIPT_PARAM_ONOFF, true)
	
	
	self.Config:addSubMenu("LineClear", "LineClear")
		--self.Config.LineClear:addParam("UseItem", "Use Hydra/Tiamat", SCRIPT_PARAM_ONOFF, true)
		self.Config.LineClear:addParam("UseQ", "Use Q LineClear", SCRIPT_PARAM_ONOFF, true)
		self.Config.LineClear:addParam("UseE", "Use E LineClear", SCRIPT_PARAM_ONOFF, true)
		self.Config.LineClear:addParam("Energy", "Energy >", SCRIPT_PARAM_SLICE, 45, 1, 100)
	
	self.Config:addSubMenu("LastHit", "LastHit")
		self.Config.LastHit:addParam("UseQ", "Use Q LastHit", SCRIPT_PARAM_ONOFF, true)
		self.Config.LastHit:addParam("UseE", "Use E LastHit", SCRIPT_PARAM_ONOFF, true)
		self.Config.LastHit:addParam("Energy", "Energy >", SCRIPT_PARAM_SLICE, 45, 1, 100)
	
	self.Config:addSubMenu("JungleClear", "JungleClear")
		self.Config.JungleClear:addParam("UseQ", "Use Q JungleClear", SCRIPT_PARAM_ONOFF, true)
		self.Config.JungleClear:addParam("UseW", "Use W JungleClear", SCRIPT_PARAM_ONOFF, true)
		self.Config.JungleClear:addParam("UseE", "Use E JungleClear", SCRIPT_PARAM_ONOFF, true)
		self.Config.JungleClear:addParam("Energy", "Energy >", SCRIPT_PARAM_SLICE, 45, 1, 100)
	
	self.Config:addSubMenu("Misc", "Misc")
		self.Config.Misc:addParam("UseIgnite", "Use Ignite Killsteal", SCRIPT_PARAM_ONOFF, true)
		self.Config.Misc:addParam("UseQ", "Use Q Killsteal", SCRIPT_PARAM_ONOFF, true)
		self.Config.Misc:addParam("UseE", "Use E Killsteal", SCRIPT_PARAM_ONOFF, true)
		self.Config.Misc:addParam("AutoE", "Auto E", SCRIPT_PARAM_ONOFF, true)
		self.Config.Misc:addParam("rdodge", "R Dodge Dangerous", SCRIPT_PARAM_ONOFF, true)
		for _, e in ipairs(GetEnemyHeroes()) do
			name = e:GetSpellData(_R).name;
			if(Contain(DangerousList, name))then
				self.Config.Misc:addParam("dl"..name, "Dodge "..name, SCRIPT_PARAM_ONOFF, true)
			end
		end
	
	self.Config:addSubMenu("BlackList", "bl")
		for _, enemy in ipairs(GetEnemyHeroes())do
			self.Config.bl:addParam("bl" .. enemy.charName, "use r to " .. enemy.charName, SCRIPT_PARAM_ONOFF, true)
		end
	
	self.Config:addSubMenu("SS", "SS")
		self.Q:AddToMenu(self.Config.SS)
	
	AddTickCallback(function() self:OnTick() end)
	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
	AddCreateObjCallback(function(obj) self:OnCreateObj(obj) end)
	AddDrawCallback(function() self:OnDraw() end)
	AddAnimationCallback(function(unit, anim) self:Anim(unit, anim) end)
	-- AddOnWndMsgCallback(function(msg, wParam) self:OnWndMsg(msg, wParam) end)
	-- AdvancedCallback:bind('OnTowerFocus', function(tower, unit) self:OnTowerFocus(tower,unit) end)
end
function Main:Anim(unit, anim)
	if unit.team == myHero.team and unit.name == "Shadow" then
		if(anim:lower():find("idle"))then
			table.insert(self.Shadow, unit)
		end
		if(anim:lower():find("death"))then
			for i = 1, #self.Shadow do
				if(Vector(self.Shadow[i]) == Vector(unit))then
					table.remove(self.Shadow, i)
				end
			end
		end
	end
	-- print(unit.name.." : "..anim..)
end
function Main:OnTowerFocus(tower, unit)
	if tower == nil or unit == nil or tower.team ~= myHero.team or unit.team == myHero.team then return end
	if myHero:GetDistance(unit) <= self.Q.range then
		self.targetUnderTurret = unit
		self.turrent = tower
	end
end
function Main:OnProcessSpell(unit, spell)
	if(unit.type ~= myHero.type)then return end
	if(unit.team ~= myHero.team)then
		if(self.Config.Misc.rdodge and self.R:IsReady() and self:UltStat() == 1 and self.Config.Misc["dl"..spell.name])then
			if(Contain(DangerousList, spell.name) and (GetDistance(unit) < 650 or GetDistance(spell.endPos) <= 250))then
				if(spell.name == "SyndraR")then
					self.clockon = GetTickCount() + 150
					self.countdanger = countdanger + 1;
				else
					target = STS:GetTarget(640)
					if(target ~= nil)then
						self.R:Cast(target)
					end
				end
			end
		end
	end
	if(unit.isMe and spell.name == "zedult")then
		self.tickock = GetTickCount() + 200;
	end
	-- if(unit.isMe)then
		-- self.LastCast = spell
	-- end
	if(spell.name == self.R:GetName())then
		self.rpos = Vector(spell.startPos)
	end
end
function Main:OnCreateObj(obj)
	if(obj.name == "Shadow")then
		table.insert(self.Shadow, obj)
	end
end
function Main:OnWndMsg(msg, wParam)
	if msg == 513 then
		-- print("Mouse Left Click")
		self.LBClicked = true
	elseif msg == 514 then
		-- print("Mouse Left Release")
		self.LBClicked = false
	end
end
function Main:OnDraw()
--	if self.Config.DamageLib.DrawPredictedHealth then
--		for _, enemy in ipairs(GetEnemyHeroes())do
--			self:DrawIndicator(enemy)
--		end
--	end
	if self.Config.Misc.rdodge then
		DrawText("R with evade dangerous spell : <" .. tostring(self.LBClicked) .. "> just click mouse left button", 18, 100, 100, ARGB(255, 0, 255, 0) )
	end
end
function Main:OnTick()
	if(OWM:IsComboMode())then
		self:Combo()
	end
	if(self.Config.Combo.TheLine)then
		self:TheLine()
	end
	if(OWM:IsHarassMode())then
		self:Harass()
	end
	if(OWM:IsClearMode())then
		self:JungleClear()
		self:LineClear()
	end
	if(OWM:IsLastHitMode())then
		self:LastHit()
	end
	
	-- if(self.LastCast ~= nil and self.LastCast.name == self.R:GetName() and self.Shadow ~= nil )then
		-- self.rpos = Vector(self.Shadow)
	-- end
	self:Killsteal()
end
function Main:GetComboDamage(enemy)
	damage = 0
	if self.Q:IsReady() then
		pos = self.Q:GetPrediction(enemy)
		if( self:CountHits( Vector( pos ), GetEnemyHeroes() ) > 0 )then
			damage = damage + DLib:CalcComboDamage(enemy, {_Q})/2
		else
			damage = damage + DLib:CalcComboDamage(enemy, {_Q})
		end
	end
	if self.Config.Combo.UseW and self.W:IsReady() and GetDistance(enemy) < self.W.range + GetMyTryeRange() then
		damage = damage + getDmg("AD", enemy, myHero)
	end
	if self.Config.Misc.AutoE and self.E:IsReady() then
		damage = damage + DLib:CalcComboDamage(enemy, {_E})
	end
	
	multiplier = self.R:GetLevel()*0.1 + 0.2
	if self.Config.Combo.UseUlt and self.R:IsReady() then
		damage = damage + DLib:CalcComboDamage(enemy, {_R})
		if self.Q:IsReady() then
			damage = damage + DLib:CalcComboDamage(enemy, {_Q}) * multiplier
		end
		if self.E:IsReady() then
			damage = damage + DLib:CalcComboDamage(enemy, {_E}) * multiplier
		end
	end
	return damage
end
function Main:CountHits(points, objects)
	-- result = 0
	-- for i = 1, #points+1 do
		-- point = points[i]
		-- endPoint = self:GetQCardDrawEndPoints(myHero, position)
		-- for k = 1, 3 do
			-- local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(myHero, endPoint[k], )
		-- end
	-- end
	
	result = 0
	-- poly = Polygon()
	from = Vector(myHero)
	to = Vector(points)
	From = from + ( from - to ):normalized()
	FromL = From + ( to - from ):perpendicular():normalized() * 25
	FromR = From + ( to - from ):perpendicular2():normalized() * 25
	To = to + ( to - from ):normalized()
	ToL = To + ( to - from ):perpendicular():normalized() * 25
	ToR = To + ( to - from ):perpendicular2():normalized() * 25
	
	StartL = WorldToScreen(D3DXVECTOR3(FromL.x, FromL.y, FromL.z))
	StartR = WorldToScreen(D3DXVECTOR3(FromR.x, FromR.y, FromR.z))
	
	EndL = WorldToScreen(D3DXVECTOR3(ToL.x, ToL.y, ToL.z))
	EndR = WorldToScreen(D3DXVECTOR3(ToR.x, ToR.y, ToR.z))
	
	poly = Polygon( Point(StartL.x, StartL.y), Point(StartR.x, StartR.y), Point(EndL.x, EndL.Y), Point(EndR.x, EndR.y) )
	for _, object in ipairs(objects) do
		if object.valid and objects.dead and GetDistance(object) < self.Q.range then
			objScreen = WorldToScreen(D3DXVECTOR3(object.x, object.y, object.z))
			objPoint = Point(objScreen.x, objScreen.y)
			if poly:contains(objPoint) then
				result = result + 1
			end
		end
	end
	return result
end
function Main:Combo()
	local target = GetTarget() or STS:GetTarget(1400)
	if target == nil then return end
	local overkill = DLib:CalcComboDamage(target, {_Q, _E}) + getDmg("AD", target , myHero) * 2
	
	if(self.Config.Combo.UseUlt and not self:IsBlackList(target) and not self.LBClicked and self.R:IsReady() and self:UltStat() == 1 and not self:CanDamaged(target) and (overkill > target.health or (not self.W:IsReady() and DLib:CalcSpellDamage(target, _Q) < target.health and GetDistance(target) > 400)))then
		if((GetDistance(target) > 700 and target.ms > myHero.ms or GetDistance(Vector(target)) > 800 )) then
			self:CastW(target);
			self.W:Cast()
		end
		-- print("CastR")
		CastSpell(_R, target)
		-- self.R:Cast(target);
	else
		if(target ~= nil and self.Config.Combo.UseIgnite and self.IgniteSlot ~= nil and self.IGNITE:IsReady())then
			if(self:GetComboDamage(target) > target.health or HasBuff(target, "zedulttargetmark"))then
				self.IGNITE:Cast(target)
			end
		end
		if(target~= nil and self:ShadowStage() == 1 and self.Config.Combo.UseW < 3 and GetDistance(target) > 400 and GetDistance(target) < 1300)then
			self:CastW(target)
		elseif target ~= nil and self:ShadowStage() == 1 and self.Config.Combo.UseW < 2 and GetDistance(target) < 400 and GetDistance(target) < 1300 then
			self:CastW(target)
		end
		if(target ~= nil and self:ShadowStage() == 2 and self.Config.Combo.UseW and GetDistance(Vector(self:WShadow())) < GetDistance(Vector(target)))then
			self.W:Cast()
		end
		
		-- self:UseItem(target)
		self:CastE()
		self:CastQ(target)
	end
end
function Main:TheLine()
	local target = GetTarget() or STS:GetTarget(1400)
	
	if(target == nil)then
		-- OrbwalkToPosition(mousePos)
		myHero:MoveTo(mousePos.x, mousePos.z)
	else
		myHero:MoveTo(mousePos.x, mousePos.z)
		-- OrbwalkToPosition(target)
	end
	
	if target == nil then return end
	if(not self.R:IsReady() or GetDistance(target) >= 640 ) then return end
	
	if(self:UltStat() == 1 ) then CastSpell(_R, target) end
	
	linepos = Extends(target, myHero, -500)
	
	if(target ~= nil and not self:CanDamaged(target) and  self:ShadowStage() == 1 and self:UltStat() == 2)then --  
		-- self:UseItem(target);
		-- if(self.LastCast.name ~= self.W:GetName())then
			self.W:Cast(linepos.x, linepos.z);
			self:CastE()
			self:CastQ(target)
			
			-- if(target ~= nil and Config.Combo.UseIgnite and self.IgniteSlot ~= nil and self.IGNITE:IsReady())then
				-- self.IGNITE:Cast(target)
			-- end
		-- end
	end
	
	if(target ~= nil and self:WShadow() ~= nil and self:UltStat() == 2 and GetDistance(target) > 250 and GetDistance(Vector(self:WShadow()), target) < GetDistance(target))then
		self.W:Cast()
	end
end
function Main:Harass()
	local target = GetTarget() or STS:GetTarget(1400)
	if target == nil then return end
	if(target and self.Config.Harass.longhar and self.Q:IsReady() and self.W:IsReady() and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_W).mana and GetDistance(target) > 850 and GetDistance(target) < 1400 ) then
		self:CastW(target)
	end
	
	if(target and (self:ShadowStage() == 2 or not self.W:IsReady() or not self.Config.Harass.UseW) and self.Q:IsReady() and (GetDistance(target) <= 900 or GetDistance(self:WShadow(), target) <= 900))then
		self:CastQ(target)
	end
	
	if(target and self.W:IsReady() and self.Q:IsReady() and self.Config.Harass.UseW and myHero.mana > myHero:GetSpellData(_Q).mana + myHero:GetSpellData(_W).mana)then
		if(GetDistance(target)<750)then
			self:CastW(target)
		end
	end
	
	self:CastE()
end
function Main:LineClear()
	self.minionTable:update()
	
	mana = myHero.mana >= (myHero.maxMana*self.Config.LineClear.Energy/100)
	
	if(not mana)then return end
	
	if(self.Q:IsReady() and self.Config.LineClear.UseQ)then
		pos, hit = GetBestLineFarmPosition(self.Q.range, 50, self.minionTable.objects)
		-- print(hit)
		if(hit >= 3)then
			self.Q:SetSourcePosition(myHero)
			self.Q:Cast(pos.x, pos.z)
		else
			for _, m in ipairs(self.minionTable.objects) do
				if(not (GetMyTryeRange() > GetDistance(m)) and m.health < 0.75*DLib:CalcSpellDamage(m, _Q))then
					self.Q:Cast(pos.x, pos.z)
				end
			end
		end
	end
	if(self.E:IsReady() and self.Config.LineClear.UseE)then
		value = GetNearObjectCount(myHero, self.E.range, self.minionTable.objects)
		if(value > 2)then
			self.E:Cast()
		else
			for _, m in ipairs(self.minionTable.objects) do
				if(not (GetMyTryeRange() > GetDistance(m)) and m.health < 0.75*DLib:CalcSpellDamage(m, _E))then
					self.E:Cast()
				end
			end
		end
	end
end
function Main:LastHit()
	self.minionTable:update()
	
	mana = myHero.mana >= (myHero.maxMana*self.Config.LastHit.Energy/100)
	
	if not mana then return end
	
	for _, minion in ipairs(self.minionTable.objects)do
		if(self.Config.LastHit.UseQ and self.Q:IsReady() and GetDistance(minion) < self.Q.range and minion.health < 0.75 * getDmg("Q", minion, myHero))then --DLib:CalcSpellDamage(minion, _Q)
			self.Q:SetSourcePosition(myHero)
			self.Q:Cast(minion)
		end
		
		if(self.Config.LastHit.UseQ and self.E:IsReady() and GetDistance(minion) < self.E.range and minion.health < 0.75 * getDmg("E", minion, myHero))then -- DLib:CalcSpellDamage(minion, _E)
			self.E:Cast()
		end
	end
end
function Main:UnderTowerFarm()
	if self.targetUnderTurret ~= nil and self.targetUnderTurret.dead then
		self.targetUnderTurret = nil
		self.turrent = nil
	end
end
function Main:JungleClear()
	self.jungleTable:update()
	mana = myHero.mana >= (myHero.maxMana*self.Config.JungleClear.Energy/100)
	if(#self.jungleTable.objects>0 and mana )then
		mob = self.jungleTable.objects[1]
		if(self.W:IsReady() and self.Q:IsReady() and GetDistance(mob) < self.Q.range)then
			self.W:Cast(Vector(mob).x, Vector(mob).z)
		end
		if(self.Q:IsReady() and GetDistance(mob) < self.Q.range )then
			self:CastQ(mob)
		end
		if(self.E:IsReady() and GetDistance(mob) < self.E.range )then
			self.E:Cast()
		end
	end
end
function Main:Killsteal()
	targets = GetCustomTargetTable()
	
	if #targets == 0 then return end
	
	for _, target in ipairs(targets) do
		if target == nil then return end
		if(target.valid and self.Config.Misc.UseIgnite and self.IGNITE:IsReady())then
			if(self.IGNITE:GetDamage(target) > target.health and GetDistance(target) <= self.IGNITE.range)then
				self.IGNITE:Cast(target)
			end
		end
		if(target.valid and not target.dead and self.Q:IsReady() and self.Config.Misc.UseQ and getDmg("Q", target, myHero) > target.health)then
			if(GetDistance(target) <= self.Q.range)then
				self.Q:SetSourcePosition(Vector(myHero))
				self.Q:Cast(target)
			elseif (self.WShadow() ~= nil and GetDistance(self.WShadow(), target) <= self.Q.range )then
				self.Q:SetSourcePosition(Vector(self.WShadow()))
				self.Q:Cast(target)
			elseif (self.RShadow() ~= nil and GetDistance(self.RShadow(), target) <= self.Q.range )then
				self.Q:SetSourcePosition(Vector(self.RShadow()))
				self.Q:Cast(target)
			end
		end
		if(target.valid and not target.dead and self.E:IsReady() and self.Config.Misc.UseE)then
			if getDmg("E", target, myHero) > target.health  then
				if GetDistance(target) <= self.E.range then
					self.E:Cast()
				else
					shadows = self:NearShadow(target, self.E.range)
					
					if shadows ~= nil then
                        for _, shadow in ipairs(shadows) do
					
						    if GetDistance(shadow) <= self.E.range then
							    self.E:Cast()
						    end
					    end
                    end
				end
			end
			
			-- if(DLib:CalcSpellDamage(target, _E) > t.health and (GetDistance(target) <= self.E.range or GetDistance(target, self:WShadow()) <= self.E.range))then
				-- self.E:Cast()
			-- end
		end
	end
end
function GetCustomTargetTable()
	_t = {}
	
	for _, enemy in ipairs(GetEnemyHeroes()) do
		if(GetDistance(enemy) < 2000)then
			table.insert(_t, enemy)
		end
	end
	table.sort(_t, function(a, b) return a.health < b.health end)
	return _t
end
function Main:UltStat()
	if(self.R:GetName() == "ZedR")then
		return 1
	end
	return 2
end
function Main:ShadowStage()
	if(self.W:GetName() == "ZedW")then
		return 1
	end
	return 2
end
function Main:IsBlackList(target)
	return self.Config.bl["bl" .. target.charName]
end
function Main:CanDamaged(target)
	for _, buff in ipairs(DONOTCASTDURINGHASTHISBUFFES) do
		if (HasBuff(target, buff)) then return true end
	end
	return false
end
function Main:NearShadow(object, range)
	if self.Shadow == nil then return end	
	if #self.Shadow == 0 then return end
	result = {}
	for _, data in ipairs(self.Shadow) do
		if(GetDistance(data, object) < range) then
			table.insert(result, data)
		end
	end
	if #result == 0 then return nil end
	return result
end
function Main:WShadow()
	if self.Shadow == nil then return nil end
	if #self.Shadow == 0 then return nil end
	for _, data in ipairs(self.Shadow)do
		if(data and data.valid and Vector(data) ~= Vector(self.rpos) and data.name == "Shadow") then return data end
	end
	return nil
end
function Main:RShadow()
	if self.Shadow == nil then return nil end
	if #self.Shadow == 0 then return nil end
	for _, data in ipairs(self.Shadow)do
		if(data and data.valid and Vector(data) == Vector(self.rpos) and data.name == "Shadow") then return data end
	end
	return nil
end
function Main:CastW(target)
	if(self.delayw >= GetTickCount() - self.shadowdelay or self:ShadowStage() ~= 1 or HasBuff(target, "zedulttargetmark") and self.R:IsReady()) then return end
	
	local wPos = nil
	
	if GetDistance(target) < self.W.range then
		wPos = Extends(myHero, target, GetDistance(myHero, target))
	else
		wPos = Extends(target, myHero, -200)
	end
	self.W:Cast(wPos.x, wPos.z)
	self.shadowndelay = GetTickCount()
end
function Main:CastQ(target)
	if not self.Q:IsReady() then return end
	local WShadow = self:WShadow()
	if(WShadow ~= nil and GetDistance(WShadow) <= 900 and GetDistance(target) > 450) then
		self.Q:SetSourcePosition(Vector(WShadow))
		self.Q:Cast(target)
	else
		self.Q:SetSourcePosition(Vector(myHero))
		if(GetDistance(target) < 900)then
			self.Q:Cast(target)
		end
	end
end
function Main:CastE()
	if not self.E:IsReady() then return end
	if(GetNearObjectCount(myHero, self.E.range, GetEnemyHeroes()) > 0)then
		self.E:Cast()
	end
	if(self:WShadow() ~= nil and GetNearObjectCount(self:WShadow(), self.E.range, GetEnemyHeroes()) > 0 )then
		self.E:Cast()
	end
end
function IgniteDamage()
	return 50 + 20 * myHero.level
end
class('IGNITE')
function IGNITE:__init()
	self.slot = GetSummonerSlot("summonerdot")
	self.range = 600
end
function IGNITE:IsReady()
	if self.slot == nil then return false end
	return myHero:CanUseSpell(self.slot) == READY
end
function IGNITE:GetDamage(target)
	return 50 + 20 * myHero.level
end
function IGNITE:Cast(target)
	CastSpell(self.slot, target)
end
