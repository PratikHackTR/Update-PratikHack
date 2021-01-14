--[[

      _________                                 .____    ._____.    
     /   _____/ ____  __ _________   ____  ____ |    |   |__\_ |__  
     \_____  \ /  _ \|  |  \_  __ \_/ ___\/ __ \|    |   |  || __ \ 
     /        (  <_> )  |  /|  | \/\  \__\  ___/|    |___|  || \_\ \
    /_______  /\____/|____/ |__|    \___  >___  >_______ \__||___  /
            \/                          \/    \/        \/       \/ 

    SourceLib - a common library by Team TheSource
    Copyright (C) 2014  Team TheSource

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.


    Introduction:
        We were tired of updating every single script we developed so far so we decided to have it a little bit
        more dynamic with a custom library which we can update instead and every script using it will automatically
        be updated (of course only the parts which are in this lib). So let's say packet casting get's fucked up
        or we want to change the way some drawing is done, we just need to update it here and all scripts will have
        the same tweaks then.
		-- rework by kaokaoni
	
	Reworks:
		SourceUpdater	-- Better good
		Spell			-- Add Prediction, bug fix
		Interrupter		-- documented
		AntiGapCloser	-- documented
		STS				-- Bug Fix
		
		
    Contents:
        Require         -- A basic but powerful library downloader
        SourceUpdater   -- One of the most basic functions for every script we use
        Spell           -- Spells handled the way they should be handled
        DrawManager     -- Easy drawing of all kind of things, comes along with some other classes such as Circle
        DamageLib       -- Calculate the damage done do others and even print it on their healthbar
        STS             -- SimpleTargetSelector is a simple and yet powerful target selector to provide very basic target selecting
        Interrupter     -- Easy way to handle interruptable spells
        AntiGetcloser   -- Never let them get close to you
	
	removed:
		MenuWrapper		-- No more use
]]

_G.srcLib = {}
_G.srcLib.Menu = scriptConfig("[SourceLib]", "SourceLib")
_G.srcLib.version = 1.3
local autoUpdate = true

local Colors = { 
    -- O R G B
    Green   =  ARGB(255, 0, 180, 0), 
    Yellow  =  ARGB(255, 255, 215, 00),
    Red     =  ARGB(255, 255, 0, 0),
    White   =  ARGB(255, 255, 255, 255),
    Blue    =  ARGB(255, 0, 0, 255),
}
--[[

'||''|.                              ||                  
 ||   ||    ....    ... .  ... ...  ...  ... ..    ....  
 ||''|'   .|...|| .'   ||   ||  ||   ||   ||' '' .|...|| 
 ||   |.  ||      |.   ||   ||  ||   ||   ||     ||      
.||.  '|'  '|...' '|..'||   '|..'|. .||. .||.     '|...' 
                       ||                                
                      ''''                               

    Require - A simple library downloader

    Introduction:
        If you want to use this class you need to put this at the beginning of you script.

    Functions:
        Require(myName)

    Members:
        Require.downloadNeeded

    Methods:
        Require:Add(name, url)
        Require:Check()
		
	Example:
		if player.charName ~= "Brand" then return end
		require "SourceLib"

		local libDownloader = Require("Brand script")
		libDownloader:Add("VPrediction", "https://bitbucket.org/honda7/bol/raw/master/Common/VPrediction.lua")
		libDownloader:Add("SOW",         "https://bitbucket.org/honda7/bol/raw/master/Common/SOW.lua")
		libDownloader:Check()

		if libDownloader.downloadNeeded then return end
]]
class 'Require'
function __require_afterDownload(requireInstance)
    requireInstance.downloadCount = requireInstance.downloadCount - 1
    if requireInstance.downloadCount == 0 then
        print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Required libraries downloaded! Please reload!</font>")
    end
end

function Require:__init(myName)
    self.myName = myName or GetCurrentEnv().FILE_NAME
    self.downloadNeeded = false
    self.requirements = {}
end
function Require:Add(name, url)
    assert(name and type(name) == "string" and url and type(url) == "string", "Require:Add(): Some or all arguments are invalid.")
    self.requirements[name] = url
    return self
end

function Require:Check()
    for scriptName, scriptUrl in pairs(self.requirements) do
        local scriptFile = LIB_PATH .. scriptName .. ".lua"
        if FileExist(scriptFile) then
            require(scriptName)
        else
            self.downloadNeeded = true
            self.downloadCount = self.downloadCount and self.downloadCount + 1 or 1
			print("<font color=\"#6699ff\"><b>" .. requireInstance.myName .. ":</b></font> <font color=\"#FFFFFF\">Missing Library! Downloading "..scriptName..". If the library doesn't download, please download it manually.!</font>")
            DownloadFile(scriptUrl, scriptFile, function() __require_afterDownload(self) end)
        end
    end
    return self
end

--[[

.|'''|                          '||`           '||   ||`             ||`           ||                  
||       ''                      ||             ||   ||              ||            ||                  
`|'''|,  ||  '||),,(|,  '||''|,  ||  .|''|,     ||   ||  '||''|, .|''||   '''|.  ''||''  .|''|, '||''| 
 .   ||  ||   || || ||   ||  ||  ||  ||..||     ||   ||   ||  || ||  ||  .|''||    ||    ||..||  ||    
 |...|' .||. .||    ||.  ||..|' .||. `|...      `|...|'   ||..|' `|..||. `|..||.   `|..' `|...  .||.   
                         ||                               ||                                           
                        .||                              .||                                           
						

    SimpleUpdater - a simple updater class

    Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SimpleUpdater(scriptName, version, host, updatePath, filePath, versionPath)

    Members:
        SimpleUpdater.silent | bool | Defines wheather to print notifications or not

    Methods:
        SimpleUpdater:SetSilent(silent)
        SimpleUpdater:CheckUpdate()

]]
class('SimpleUpdater')
--[[
    Create a new instance of SimpleUpdater

    @param scriptName  | string        | Name of the script which should be used when printed in chat
    @param version     | float/string  | Current version of the script
    @param host        | string        | Host, for example "bitbucket.org" or "raw.github.com"
    @param updatePath  | string        | Raw path to the script which should be updated
    @param filePath    | string        | Path to the file which should be replaced when updating the script
    @param versionPath | string        | (optional) Path to a version file to check against. The version file may only contain the version.
]]
function SimpleUpdater:__init(scriptName, version, host, updatePath, filePath, versionPath)

    self.printMessage = function(message) if not self.silent then print("<font color=\"#6699ff\"><b>" .. self.UPDATE_SCRIPT_NAME .. ":</b></font> <font color=\"#FFFFFF\">" .. message .. "</font>") end end
    self.getVersion = function(version) return tonumber(string.match(version or "", "%d+%.?%d*")) end

    self.UPDATE_SCRIPT_NAME = scriptName
    self.UPDATE_HOST = host
    self.UPDATE_PATH = updatePath .. "?rand="..math.random(1,10000)
    self.UPDATE_URL = "https://"..self.UPDATE_HOST..self.UPDATE_PATH

    -- Used for version files
    self.VERSION_PATH = versionPath and versionPath .. "?rand="..math.random(1,10000)
    self.VERSION_URL = versionPath and "https://"..self.UPDATE_HOST..self.VERSION_PATH

    self.UPDATE_FILE_PATH = filePath

    self.FILE_VERSION = self.getVersion(version)
    self.SERVER_VERSION = nil

    self.silent = false

end

--[[
    Allows or disallows the updater to print info about updating

    @param  | bool   | Message output or not
    @return | class  | The current instance
]]
function SimpleUpdater:SetSilent(silent)

    self.silent = silent
    return self

end

--[[
    Check for an update and downloads it when available
]]
function SimpleUpdater:CheckUpdate()

    local webResult = GetWebResult(self.UPDATE_HOST, self.VERSION_PATH or self.UPDATE_PATH)
    if webResult then
        if self.VERSION_PATH then
            self.SERVER_VERSION = webResult
        else
            self.SERVER_VERSION = string.match(webResult, "%s*local%s+version%s+=%s+.*%d+%.%d+")
        end
        if self.SERVER_VERSION then
            self.SERVER_VERSION = self.getVersion(self.SERVER_VERSION)
            if not self.SERVER_VERSION then
                print("SourceLib: Please contact the developer of the script \"" .. (GetCurrentEnv().FILE_NAME or "DerpScript") .. "\", since the auto updater returned an invalid version.")
                return
            end
            if self.FILE_VERSION < self.SERVER_VERSION then
                self.printMessage("New version available: v" .. self.SERVER_VERSION)
                self.printMessage("Updating, please don't press F9")
                DelayAction(function () DownloadFile(self.UPDATE_URL, self.UPDATE_FILE_PATH, function () self.printMessage("Successfully updated, please reload!") end) end, 2)
            else
                self.printMessage("You've got the latest version: v" .. self.SERVER_VERSION)
            end
        else
            self.printMessage("Something went wrong! Please manually update the script!")
        end
    else
        self.printMessage("Error downloading version info!")
    end

end

--[[

 .|'''.|                                           '||'  '|'               '||            .                   
 ||..  '    ...   ... ...  ... ..    ....    ....   ||    |  ... ...     .. ||   ....   .||.    ....  ... ..  
  ''|||.  .|  '|.  ||  ||   ||' '' .|   '' .|...||  ||    |   ||'  ||  .'  '||  '' .||   ||   .|...||  ||' '' 
.     '|| ||   ||  ||  ||   ||     ||      ||       ||    |   ||    |  |.   ||  .|' ||   ||   ||       ||     
|'....|'   '|..|'  '|..'|. .||.     '|...'  '|...'   '|..'    ||...'   '|..'||. '|..'|'  '|.'  '|...' .||.    
                                                              ||                                              
                                                             ''''                                             

	SourceUpdater - a simple updater class

	Introduction:
        Scripts that want to use this class need to have a version field at the beginning of the script, like this:
            local version = YOUR_VERSION (YOUR_VERSION can either be a string a a numeric value!)
        It does not need to be exactly at the beginning, like in this script, but it has to be within the first 100
        chars of the file, otherwise the webresult won't see the field, as it gathers only about 100 chars

    Functions:
        SourceUpdater(LocalVersion, UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
		
	Methods:
		SourceUpdater:SetScriptName(ScriptName)
	
	Example:
		ToUpdate = {}
		ToUpdate.Host = "raw.githubusercontent.com"
		ToUpdate.VersionPath = "/kej1191/anonym/master/KOM/MidKing/MidKing.version"
		ToUpdate.ScriptPath =  "/kej1191/anonym/master/KOM/MidKing/MidKing.lua"
		ToUpdate.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
		ToUpdate.CallbackUpdate = function(NewVersion, OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Updated to "..NewVersion..". </b></font>") end
		ToUpdate.CallbackNoUpdate = function(OldVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">You have lastest version ("..OldVersion..")</b></font>") end
		ToUpdate.CallbackNewVersion = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">New Version found ("..NewVersion.."). Please wait until its downloaded</b></font>") end
		ToUpdate.CallbackError = function(NewVersion) print("<font color=\"#00FA9A\"><b>[MidKing] </b></font> <font color=\"#6699ff\">Error while Downloading. Please try again.</b></font>") end
		SourceUpdater(VERSION, true, ToUpdate.Host, ToUpdate.VersionPath, ToUpdate.ScriptPath, ToUpdate.SavePath, ToUpdate.CallbackUpdate,ToUpdate.CallbackNoUpdate, ToUpdate.CallbackNewVersion,ToUpdate.CallbackError)
]]
class 'SourceUpdater'
function SourceUpdater:__init(LocalVersion,UseHttps, Host, VersionPath, ScriptPath, SavePath, CallbackUpdate, CallbackNoUpdate, CallbackNewVersion,CallbackError)
	self.LocalVersion = LocalVersion
	self.Host = Host
	self.VersionPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..VersionPath)..'&rand='..math.random(99999999)
	self.ScriptPath = '/BoL/TCPUpdater/GetScript'..(UseHttps and '5' or '6')..'.php?script='..self:Base64Encode(self.Host..ScriptPath)..'&rand='..math.random(99999999)
	self.SavePath = SavePath
	self.CallbackUpdate = CallbackUpdate
	self.CallbackNoUpdate = CallbackNoUpdate
	self.CallbackNewVersion = CallbackNewVersion
	self.CallbackError = CallbackError
	AddDrawCallback(function() self:OnDraw() end)
	self:CreateSocket(self.VersionPath)
	self.DownloadStatus = 'Connect to Server for VersionInfo'
	AddTickCallback(function() self:GetOnlineVersion() end)
	self.ScriptName = nil
end
function SourceUpdater:print(str)
	print('<font color="#FFFFFF">'..os.clock()..': '..str)
end
function SourceUpdater:SetScriptName(ScriptName)
	self.ScriptName = ScriptName
end
function SourceUpdater:OnDraw()
	if self.DownloadStatus ~= 'Downloading Script (100%)' and self.DownloadStatus ~= 'Downloading VersionInfo (100%)'then
		if self.ScriptName ~= nil then
			DrawText3D(self.ScriptName ,myHero.x,myHero.y,myHero.z+70, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
		end
		DrawText3D('Download Status: '..(self.DownloadStatus or 'Unknown'),myHero.x,myHero.y,myHero.z+50, 18,ARGB(0xFF,0xFF,0xFF,0xFF))
	end
end
function SourceUpdater:CreateSocket(url)
	if not self.LuaSocket then
		self.LuaSocket = require("socket")
	else
		self.Socket:close()
		self.Socket = nil
		self.Size = nil
		self.RecvStarted = false
	end
	self.LuaSocket = require("socket")
	self.Socket = self.LuaSocket.tcp()
	self.Socket:settimeout(0, 'b')
	self.Socket:settimeout(99999999, 't')
	self.Socket:connect('sx-bol.eu', 80)
	self.Url = url
	self.Started = false
	self.LastPrint = ""
	self.File = ""
end

function SourceUpdater:Base64Encode(data)
	local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	return ((data:gsub('.', function(x)
		local r,b='',x:byte()
    
		for i=8,1,-1 do
			r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0')
		end
    
		return r;
	end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
		if (#x < 6) then
			return ''
		end
		local c=0
		for i=1,6 do
			c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0)
		end
		return b:sub(c+1,c+1)
	end)..({ '', '==', '=' })[#data%3+1])
end
function SourceUpdater:GetOnlineVersion()
	if self.GotScriptVersion then
		return
	end
	self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
	if self.Status == 'timeout' and not self.Started then
		self.Started = true
		self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
	end
  
	if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
		self.RecvStarted = true
		self.DownloadStatus = 'Downloading VersionInfo (0%)'
	end
  
	self.File = self.File .. (self.Receive or self.Snipped)
	if self.File:find('</s'..'ize>') then
  
    if not self.Size then
		self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
    end
    
    if self.File:find('<scr'..'ipt>') then
    
		local _,ScriptFind = self.File:find('<scr'..'ipt>')
		local ScriptEnd = self.File:find('</scr'..'ipt>')
      
		if ScriptEnd then
			ScriptEnd = ScriptEnd-1
		end
      
		local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
      
		self.DownloadStatus = 'Downloading VersionInfo ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
		end
    
	end
  
	if self.File:find('</scr'..'ipt>') then
		self.DownloadStatus = 'Downloading VersionInfo (100%)'
    
		local a,b = self.File:find('\r\n\r\n')
    
		self.File = self.File:sub(a,-1)
		self.NewFile = ''
    
		for line,content in ipairs(self.File:split('\n')) do
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
		end

		local HeaderEnd, ContentStart = self.File:find('<scr'..'ipt>')
		local ContentEnd, _ = self.File:find('</sc'..'ript>')
    
		if not ContentStart or not ContentEnd then
			if self.CallbackError and type(self.CallbackError) == 'function' then
				self.CallbackError()
			end
		else
			self.OnlineVersion = (Base64Decode(self.File:sub(ContentStart+1,ContentEnd-1)))
			if self.OnlineVersion == nil then
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
			end
			self.OnlineVersion = tonumber(self.OnlineVersion)
			if self.OnlineVersion > self.LocalVersion then
				if self.CallbackNewVersion and type(self.CallbackNewVersion) == 'function' then
					self.CallbackNewVersion(self.OnlineVersion,self.LocalVersion)
				end
				self:CreateSocket(self.ScriptPath)
				self.DownloadStatus = 'Connect to Server for ScriptDownload'
				AddTickCallback(function() self:DownloadUpdate() end)
			else
				if self.CallbackNoUpdate and type(self.CallbackNoUpdate) == 'function' then
					self.CallbackNoUpdate(self.LocalVersion)
				end
			end
		end
		self.GotScriptVersion = true
	end
end

function SourceUpdater:DownloadUpdate()
	if self.GotScriptUpdate then
		return
	end
	self.Receive, self.Status, self.Snipped = self.Socket:receive(1024)
  
	if self.Status == 'timeout' and not self.Started then
		self.Started = true
		self.Socket:send("GET "..self.Url.." HTTP/1.1\r\nHost: sx-bol.eu\r\n\r\n")
	end
  
	if (self.Receive or (#self.Snipped > 0)) and not self.RecvStarted then
		self.RecvStarted = true
		self.DownloadStatus = 'Downloading Script (0%)'
	end
  
	self.File = self.File .. (self.Receive or self.Snipped)
  
	if self.File:find('</si'..'ze>') then
  
		if not self.Size then
			self.Size = tonumber(self.File:sub(self.File:find('<si'..'ze>')+6,self.File:find('</si'..'ze>')-1))
		end
		if self.File:find('<scr'..'ipt>') then
			local _,ScriptFind = self.File:find('<scr'..'ipt>')
			local ScriptEnd = self.File:find('</scr'..'ipt>')
			if ScriptEnd then
				ScriptEnd = ScriptEnd-1
			end
			local DownloadedSize = self.File:sub(ScriptFind+1,ScriptEnd or -1):len()
			self.DownloadStatus = 'Downloading Script ('..math.round(100/self.Size*DownloadedSize,2)..'%)'
		end
	end
  
	if self.File:find('</scr'..'ipt>') then
		self.DownloadStatus = 'Downloading Script (100%)'
		
		local a,b = self.File:find('\r\n\r\n')
    
		self.File = self.File:sub(a,-1)
		self.NewFile = ''
    
		for line,content in ipairs(self.File:split('\n')) do
    
			if content:len() > 5 then
				self.NewFile = self.NewFile .. content
			end
      
		end
    
		local HeaderEnd, ContentStart = self.NewFile:find('<sc'..'ript>')
		local ContentEnd, _ = self.NewFile:find('</scr'..'ipt>')
    
		if not ContentStart or not ContentEnd then
			if self.CallbackError and type(self.CallbackError) == 'function' then
				self.CallbackError()
			end
		else
			local newf = self.NewFile:sub(ContentStart+1,ContentEnd-1)
			local newf = newf:gsub('\r','')
			if newf:len() ~= self.Size then
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
				return
			end
      
			local newf = Base64Decode(newf)
		  
			if type(load(newf)) ~= 'function' then
		  
				if self.CallbackError and type(self.CallbackError) == 'function' then
					self.CallbackError()
				end
			
			else
		  
				local f = io.open(self.SavePath,"w+b")
			
				f:write(newf)
				f:close()
			
				if self.CallbackUpdate and type(self.CallbackUpdate) == 'function' then
					self.CallbackUpdate(self.OnlineVersion,self.LocalVersion)
				end
			end
		end
		self.GotScriptUpdate = true
	end
end

--[[

 .|'''.|                   '||  '||  
 ||..  '  ... ...    ....   ||   ||  
  ''|||.   ||'  || .|...||  ||   ||  
.     '||  ||    | ||       ||   ||  
|'....|'   ||...'   '|...' .||. .||. 
           ||                        
          ''''                       
		Spell - Handled with ease!

    Functions:
        Spell(spellId, menu, skillshotType, range, width, delay, speed, collision)

    Members:
        Spell.range          | float  | Range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.rangeSqr       | float  | Squared range of the spell, please do NOT change this value, use Spell:SetRange() instead
        Spell.packetCast     | bool   | Set packet cast state
        -- This only applies for skillshots
        Spell.sourcePosition | vector | From where the spell is casted, default: player
        Spell.sourceRange    | vector | From where the range should be calculated, default: player
        -- This only applies for AOE skillshots
        Spell.minTargetsAoe  | int    | Set minimum targets for AOE damage

    Methods:
        Spell:SetRange(range)
        Spell:SetSource(source)
        Spell:SetSourcePosition(source)
        Spell:SetSourceRange(source)

        Spell:SetSkillshot(skillshotType, width, delay, speed, collision)
        Spell:SetAOE(useAoe, radius, minTargetsAoe)

        Spell:SetCharged(spellName, chargeDuration, minRange, maxRange, timeToMaxRange, abortCondition)
        Spell:IsCharging()
        Spell:Charge()

        Spell:SetHitChance(hitChance)
        Spell:ValidTarget(target)

        Spell:GetPrediction(target)
        Spell:CastIfDashing(target)
        Spell:CastIfImmobile(target)
        Spell:Cast(param1, param2)

        Spell:AddAutomation(automationId, func)
        Spell:RemoveAutomation(automationId)
        Spell:ClearAutomations()

        Spell:TrackCasting(spellName)
        Spell:WillHitTarget()
        Spell:RegisterCastCallback(func)

        Spell:GetLastCastTime()

        Spell:IsInRange(target, from)
        Spell:IsReady()
        Spell:GetManaUsage()
        Spell:GetCooldown()
        Spell:GetLevel()
        Spell:GetName()
]]
class 'Spell'

-- Class related constants
SKILLSHOT_LINEAR  = 0
SKILLSHOT_CIRCULAR = 1
SKILLSHOT_CONE     = 2
SKILLSHOT_OTHER    = 3
SKILLSHOT_TARGETTED= 4

-- Different SpellStates returned when Spell:Cast() is called
SPELLSTATE_TRIGGERED          = 0
SPELLSTATE_OUT_OF_RANGE       = 1
SPELLSTATE_LOWER_HITCHANCE    = 2
SPELLSTATE_COLLISION          = 3
SPELLSTATE_NOT_ENOUGH_TARGETS = 4
SPELLSTATE_NOT_DASHING        = 5
SPELLSTATE_DASHING_CANT_HIT   = 6
SPELLSTATE_NOT_IMMOBILE       = 7
SPELLSTATE_INVALID_TARGET     = 8
SPELLSTATE_NOT_TRIGGERED      = 9
SPELLSTATE_IS_READY			  = 10

local spellNum = 1
--[[
    New instance of Spell

    @param spellId       | int          | Spell ID (_Q, _W, _E, _R)
    @param menu          | scriptCofnig | (Sub)Menu to add the spell casting menu to
    @param range         | float        | Range of the spell
	@param range		 | float        | Range of the skillshot
	@param width		 | float 		| Width of the skillshot
	@param delay		 | float 		| Delay of the skillshot
	@param speed		 | float 		| Speed of the skillshot
	@param collision	 | bool			| (optional) Respect unit collision when casting
]]
function Spell:__init(spellId, range)
	assert(spellId ~= nil and range ~= nil and type(spellId) == "number" and type(range) == "number", "Spell: Can't initialize Spell without valid arguments.")
	self.menuload = false
	DelayAction(function()
		if (_G.srcLib.Prediction == nil) then
			_G.srcLib.Prediction = {}
			if FileExist(LIB_PATH .. "HPrediction.lua") and _G.srcLib.HP == nil then
				require("HPrediction")
				_G.srcLib.HP = HPrediction()
				table.insert(_G.srcLib.Prediction, "HPrediction")
			end
			if FileExist(LIB_PATH .. "KPrediction.lua") and _G.srcLib.KP == nil then
				require("KPrediction")
				_G.srcLib.KP = KPrediction()
				table.insert(_G.srcLib.Prediction, "KPrediction")
			end
			if FileExist(LIB_PATH .. "SPrediction.lua") and _G.srcLib.SP == nil then
				require("SPrediction")
				_G.srcLib.SP = SPrediction()
				table.insert(_G.srcLib.Prediction, "SPrediction")
			end
			if FileExist(LIB_PATH .. "VPrediction.lua") and _G.srcLib.VP == nil then
				require("VPrediction")
				_G.srcLib.VP = VPrediction()
				table.insert(_G.srcLib.Prediction, "VPrediction")
			end
			if FileExist(LIB_PATH.."DivinePred.lua") and FileExist(LIB_PATH.."DivinePred.luac") and _G.srcLib.dp == nil then
				require "DivinePred"
				_G.srcLib.dp = DivinePred()
				table.insert(_G.srcLib.Prediction, "DivinePred")
			end
		end
		self.packetCast = packetCast or false
		
		if (not _G.srcLib.Menu.Spell) then
			_G.srcLib.Menu:addSubMenu("Spell dev menu", "Spell")
				_G.srcLib.Menu.Spell:addParam("Debug", "dev debug", SCRIPT_PARAM_ONOFF, false)
		end

		self._automations = {}
		self._spellNum = spellNum
		spellNum = spellNum+1
		self.predictionType = 1
	end, 1)
	self.spellId = spellId
	self:SetRange(range)
	self:SetSource(myHero)
end
function Spell:AddToMenu(menu)
	DelayAction(function(menu)
		if type(menu) == "number" then return end
		menu = menu or scriptConfig("[SourceLib] SpellClass", "srcSpellClass")
			menu:addParam("predictionType", "Prediction Type", SCRIPT_PARAM_LIST, 1, _G.srcLib.Prediction)
			menu:addParam("packetCast", "Packet Cast", SCRIPT_PARAM_ONOFF, false)
			menu:addParam("Hitchance", "Hitchance", SCRIPT_PARAM_SLICE, 1.4, 0, 3, 1)
		
		self.menuload = true
		AddTickCallback(function()
			-- Prodiction found, apply value
			if _G.srcLib.Menu.Spell ~= nil and self.menuload then
				self:SetPredictionType(menu.predictionType)
				self:SetPacketCast(menu.packetCast)
				self:SetHitChance(menu.Hitchance)
			end
		end)
	end, 2, {menu, self.menuload})
end
--[[
    Update the spell range with the new given value

    @param range | float | Range of the spell
    @return      | class | The current instance
]]
function Spell:SetRange(range)
    assert(range and type(range) == "number", "Spell: range is invalid")
    self.range = range
    self.rangeSqr = math.pow(range, 2)
    return self
end
--[[
    Update both the sourcePosition and sourceRange from where everything will be calculated

    @param source | Cunit | Source position, for example player
    @return       | class | The current instance
]]
function Spell:SetSource(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    self.sourceRange    = source
    return self
end
--[[
    Update the source posotion from where the spell will be shot

    @param source | Cunit | Source position from where the spell will be shot, player by default
    @ return      | class | The current instance
]]
function Spell:SetSourcePosition(source)
    assert(source, "Spell: source can't be nil!")
    self.sourcePosition = source
    return self
end
--[[
    Update the source unit from where the range will be calculated

    @param source | Cunit | Source object unit from where the range should be calculed
    @return       | class | The current instance
]]
function Spell:SetSourceRange(source)
    assert(source, "Spell: source can't be nil!")
    self.sourceRange = source
    return self
end
--[[
    Define this spell as skillshot (can't be reversed)

    @param skillshotType | int   | Type of this skillshot
    @param width         | float | Width of the skillshot
    @param delay         | float | (optional) Delay in seconds
    @param speed         | float | (optional) Speed in units per second
    @param collision     | bool  | (optional) Respect unit collision when casting
    @rerurn              | class | The current instance
]]
function Spell:SetSkillshot(skillshotType, width, delay, speed, collision)
    if(self.menuload) then
		assert(skillshotType ~= nil, "Spell: Need at least the skillshot type!")
		self.skillshotType = skillshotType
		if (skillshotType ~= SKILLSHOT_OTHER) then
			self.width = width or 0
			self.delay = delay or 0
			self.speed = speed
			self.collision = collision or false
			self:HPSettings()
			self:DPSettings()
			self:KPSettings()
		end
		if not self.hitChance then self.hitChance = 1.4 end
		return self
	else
		DelayAction(function() self:SetSkillshot(skillshotType, width, delay, speed, collision) end, 1)
	end
end

function Spell:KPSettings()
	if _G.srcLib.KP ~= nil then
		if self.skillshotType == SKILLSHOT_LINEAR then
			if self.speed ~= math.huge then 
				if self.collision then
					self.KPSS = KPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collision_M = self.collision, collision_H = self.collision})
				else
					self.KPSS = KPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.KPSS = KPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collision_M = self.collision, collision_H = self.collision })
			end
		elseif self.skillshotType == SKILLSHOT_CIRCULAR then
			if self.delay > 1 then
				if self.speed ~= math.huge then 
					self.KPSS = KPSkillshot({type = "DelayCircle", range = self.range, speed = self.speed, radius = self.width, delay = self.delay})
				else
					self.KPSS = KPSkillshot({type = "PromptCircle", range = self.range, radius = self.width, delay = self.delay})
				end
			else
				if self.speed ~= math.huge then 
					self.KPSS = KPSkillshot({type = "DelayCircle", range = self.range, speed = self.speed, radius = self.width, delay = self.delay})
				else
					self.KPSS = KPSkillshot({type = "PromptCircle", range = self.range, radius = self.width, delay = self.delay})
				end
			end
		elseif self.skillshotType == SKILLSHOT_CONE then
			if self.speed ~= math.huge then 
				if self.collision then
					self.KPSS = KPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collision_M = self.collision, collision_H = self.collision})
				else
					self.KPSS = KPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.KPSS = KPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collision_M = self.collision, collision_H = self.collision})
			end
			-- not yet serport in sourcelib
			if self.delay == 0 then
				--self.KPSS = HPSkillshot({type ="PromptArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			else
				--self.KPSS = HPSkillshot({type ="DelayArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			end
		end
	end
end

function Spell:HPSettings()
	if _G.srcLib.HP ~= nil then
		if self.skillshotType == SKILLSHOT_LINEAR then
			if self.speed ~= math.huge then 
				if self.collision then
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
				else
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.HPSS = HPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision })
			end
		elseif self.skillshotType == SKILLSHOT_CIRCULAR then
			if self.delay > 1 then
				if self.speed ~= math.huge then 
					self.HPSS = HPSkillshot({type = "DelayCircle", range = self.range, speed = self.speed, radius = self.width, delay = self.delay, IsLowAccuracy = true})
				else
					self.HPSS = HPSkillshot({type = "PromptCircle", range = self.range, radius = self.width, delay = self.delay, IsLowAccuracy = true})
				end
			else
				if self.speed ~= math.huge then 
					self.HPSS = HPSkillshot({type = "DelayCircle", range = self.range, speed = self.speed, radius = self.width, delay = self.delay})
				else
					self.HPSS = HPSkillshot({type = "PromptCircle", range = self.range, radius = self.width, delay = self.delay})
				end
			end
		elseif self.skillshotType == SKILLSHOT_CONE then
			if self.speed ~= math.huge then 
				if self.collision then
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
				else
					self.HPSS = HPSkillshot({type = "DelayLine", range = self.range, speed = self.speed, width = 2*self.width, delay = self.delay})
				end
			else
				self.HPSS = HPSkillshot({type = "PromptLine", range = self.range, width = 2*self.width, delay = self.delay, collisionM = self.collision, collisionH = self.collision})
			end
			-- not yet serport in sourcelib
			if self.delay == 0 then
				--self.HPSS = HPSkillshot({type ="PromptArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			else
				--self.HPSS = HPSkillshot({type ="DelayArc", collisionH = _collisionH, collisionM = _collisionM, speed = _speed, width = _width, range = _range, delay = _delay})
			end
		end
	end
end
--[[
]]
function Spell:DPSettings()
	if _G.srcLib.dp ~= nil then
		local col = self.collision and ((myHero.charName=="Lux" or myHero.charName=="Veigar") and 1 or 0) or math.huge
		if self.skillshotType == SKILLSHOT_LINEAR then
			Spell = LineSS(self.speed, self.range, self.width, self.delay * 1000, col)
		elseif self.skillshotType == SKILLSHOT_CIRCULAR then
			Spell = CircleSS(self.speed, self.range, self.width, self.delay * 1000, col)
		elseif self.skillshotType == SKILLSHOT_CONE then --why small c
			Spell = coneSS(self.speed, self.range, self.width, self.delay * 1000, col)
		end
		_G.srcLib.dp:bindSS(SpellToString(self.spellId), Spell, 1)
	end
end
--[[
    Sets the prediction type

    @param typeId | int | type ID (VPrediction, SPrediction, DivinePred, HPrediction)
]]
function Spell:SetPredictionType(typeId)
    assert(typeId and type(typeId) == 'number', 'Spell:SetPredictionType(): typeId is invalid!')
    self.predictionType = typeId
end
function Spell:SetPacketCast(typebool)
    --assert(typebool and type(typebool) == 'bool', 'Spell:SetPacketCast(): typebool is invalid!')
    self.packetCast = typebool
end
--[[
    Set the AOE status of this spell, this can be changed later

    @param useAoe        | bool  | New AOE state
    @param radius        | float | Radius of the AOE damage
    @param minTargetsAoe | int   | Minimum targets to be hitted by the AOE damage
    @rerurn              | class | The current instance
]]
function Spell:SetAOE(useAoe, radius, minTargetsAoe)
	-- couse error
	--[[    self.useAoe = useAoe or false
    self.radius = radius or self.width
    self.minTargetsAoe = minTargetsAoe or 0
    return self
	]]
end
--[[
    Define this spell as charged spell

    @param spellName      | string   | Name of the spell, example: VarusQ
    @param chargeDuration | float    | Seconds of the spell to charge, after the time the charge expires
	@param minRange       | float    | Min range the spell will have start charging
    @param maxRange       | float    | Max range the spell will have after fully charging
    @param timeToMaxRange | float    | Time in seconds to reach max range after casting the spell
    @param abortCondition | function | (optional) A function which returns true when the charge process should be stopped.
]]
function Spell:SetCharged(spellName, chargeDuration, minRange, maxRange, timeToMaxRange, abortCondition)
    assert(self.skillshotType, "Spell:SetCharged(): Only skillshots can be defined as charged spells!")
    assert(spellName and type(spellName) == "string" and chargeDuration and type(chargeDuration) == "number", "Spell:SetCharged(): Some or all arguments are invalid!")
    assert(self.__charged == nil, "Spell:SetCharged(): Already marked as charged spell!")
    self.__charged           = true
    self.__charged_aborted   = true
    self.__charged_spellName = spellName
    self.__charged_duration  = chargeDuration
	self.__charged_initialRange = minRange
    self.__charged_maxRange       = maxRange
    self.__charged_chargeTime     = timeToMaxRange
    self.__charged_abortCondition = abortCondition or function () return false end
    self.__charged_active   = false
    self.__charged_castTime = 0
    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end
	--[[
	Packet Error Close until fix
    
	if not self.__sendPacketCallback then
	    AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
        self.__sendPacketCallback = true
    end
    ]]
	if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end
    return self
end
--[[
    Returns whether the spell is currently charging or not

    @return | bool | Spell charging or not
]]
function Spell:IsCharging()
    return self.__charged_abortCondition() == false and self.__charged_active
end
--[[
    Charges the spell
]]
function Spell:Charge()
    assert(self.__charged, "Spell:Charge(): Spell is not defined as chargeable spell!")
    if not self:IsCharging() then
        CastSpell(self.spellId, mousePos.x, mousePos.z)
    end
end
-- Internal function, do not use!
function Spell:_AbortCharge()
    if self.__charged and self.__charged_active then
        self.__charged_aborted = true
        self.__charged_active  = false
        self:SetRange(self.__charged_maxRange)
    end
end
--[[
    Set the hitChance of the predicted target position when to cast

    @param hitChance | int   | New hitChance for predicted positions
    @rerurn          | class | The current instance
]]
function Spell:SetHitChance(hitChance)
    self.hitChance = hitChance or 1.4
    return self
end
--[[
    Checks if the given target is valid for the spell

    @param target | userdata | Target to be checked if valid
    @return       | bool     | Valid target or not
]]
function Spell:ValidTarget(target, range)
    return ValidTarget(target, range or self.range)
end
--[[
    Returns the prediction results from VPrediction/Prodiction/SPrediction/HPrediction/DPrediction

    @return | various data | Prediction information
]]
function Spell:GetPrediction(target)
    if self.skillshotType ~= nil and _G.srcLib.Prediction ~= nil then
        -- VPrediction
        if _G.srcLib.Prediction[self.predictionType] == "VPrediction" then -- self.Prediction[self.predictionType] == "HPrediction"
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    return _G.srcLib.VP:GetLineAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return _G.srcLib.VP:GetCircularAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetCircularCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return _G.srcLib.VP:GetConeAOECastPosition(target, self.delay, self.radius, self.range, self.speed, self.sourcePosition)
                else
                    return _G.srcLib.VP:GetLineCastPosition(target, self.delay, self.width, self.range, self.speed, self.sourcePosition, self.collision)
                end
            end
        -- Prodiction
        elseif _G.srcLib.Prediction[self.predictionType] == "Prediction" then
            if self.useAoe then
                if self.skillshotType == SKILLSHOT_LINEAR then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                 elseif self.skillshotType == SKILLSHOT_CONE then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    local hitChance = self.collision and info.collision() and -1 or info.hitchance
                    return pos, hitChance, #objects
                end
            else
                local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                local hitChance = self.collision and info.collision() and -1 or info.hitchance
                return pos, hitChance, info.pos
            end

            -- Someday it will look the same as with VPrediction ;D
            --[[
            if self.skillshotType == SKILLSHOT_LINEAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetLineAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetCircularAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    local pos, info, objects = Prodiction.GetConeAOEPrediction(target, self.range, self.speed, self.delay, self.radius, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, type(objects) == "table" and #objects or 10
                else
                    local pos, info = Prodiction.GetPrediction(target, self.range, self.speed, self.delay, self.width, self.sourcePosition)
                    return pos, self.collision and info.collision() and -1 or info.hitchance, info.pos
                end
            end
            ]]
		--SPrediction <Someday rework after SP all done>
		elseif _G.srcLib.Prediction[self.predictionType] == "SPrediction" then
			if self.skillshotType == SKILLSHOT_LINEAR then
                return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
            elseif self.skillshotType == SKILLSHOT_CIRCULAR then
                if self.useAoe then
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                else
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                end
             elseif self.skillshotType == SKILLSHOT_CONE then
                if self.useAoe then
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                else
                    return _G.srcLib.SP:Predict(target, self.range, self.speed, self.delay, self.width, self.collision, self.sourcePosition)
                end
            end
		--HPrediction <HTTF>
		elseif _G.srcLib.Prediction[self.predictionType] == "HPrediction" then
			if self.useAoe then
				return _G.srcLib.HP:GetPredict(self.HPSS, target, self.sourcePosition, true)
			else
				return _G.srcLib.HP:GetPredict(self.HPSS, target, self.sourcePosition)
			end
		--KPrediction <HTTF>
		elseif _G.srcLib.Prediction[self.predictionType] == "KPrediction" then
			if self.useAoe then
				return _G.srcLib.KP:GetPrediction(self.KPSS, target, self.sourcePosition, true)
			else
				return _G.srcLib.KP:GetPrediction(self.KPSS, target, self.sourcePosition)
			end
		--DivinePred <Divine> so hard to use that
		elseif _G.srcLib.Prediction[self.predictionType] == "DivinePred" then
			local Target = DPTarget(target)
			local fuck, the, divine = _G.srcLib.dp:predict(SpellToString(self.spellId), Target, Vector(self.sourcePosition))
			local you = -1
			if fuck == SkillShot.STATUS.SUCCESS_HIT then
				you = 3
			end
			return the, you, divine
        end
    end
end
--[[
    Tries to cast the spell when the target is dashing

    @param target | Cunit | Dashing target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfDashing(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then
		if _G.srcLib.Menu.Spell.Debug then
			print("SPELLSTATE_INVALID_TARGET")
		end
		return SPELLSTATE_INVALID_TARGET 
	end
	if _G.srcLib.VP == nil then return end
    if self.skillshotType ~= nil then
        local isDashing, canHit, position = _G.srcLib.VP:IsDashing(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_OUT_OF_RANGE")
			end
			return SPELLSTATE_OUT_OF_RANGE 
		end
        if isDashing and canHit then
            -- Collision
            if not self.collision or self.collision and not _G.srcLib.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true) then
                return self:__Cast(self.spellId, position.x, position.z)
            else
				if _G.srcLib.Menu.Spell.Debug then
					print("SPELLSTATE_COLLISION")
				end
                return SPELLSTATE_COLLISION
            end
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    else
        local isDashing, canHit, position = _G.srcLib.VP:IsDashing(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
        if isDashing and canHit then
            return self:__Cast(position.x, position.z)
        elseif not isDashing then return SPELLSTATE_NOT_DASHING
        else return SPELLSTATE_DASHING_CANT_HIT end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Tries to cast the spell when the target is immobile

    @param target | Cunit | Immobile target to attack
    @param return | int   | SpellState of the current spell
]]
function Spell:CastIfImmobile(target)
    -- Don't calculate stuff when target is invalid
    if not ValidTarget(target) then return SPELLSTATE_INVALID_TARGET end
	if _G.srcLib.VP == nil then return end
    if self.skillshotType ~= nil then
        local isImmobile, position = _G.srcLib.VP:IsImmobile(target, self.delay + 0.07 + GetLatency() / 2000, self.width, self.speed, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, position) then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            -- Collision
            if not self.collision or (self.collision and not _G.srcLib.VP:CheckMinionCollision(target, position, self.delay + 0.07 + GetLatency() / 2000, self.width, self.range, self.speed, self.sourcePosition, false, true)) then
                return self:__Cast(position.x, position.z)
            else
                return SPELLSTATE_COLLISION
            end
        else return SPELLSTATE_NOT_IMMOBILE end
    else
        local isImmobile, position = _G.srcLib.VP:IsImmobile(target, 0.25 + 0.07 + GetLatency() / 2000, 1, math.huge, self.sourcePosition)
        -- Out of range
        if self.rangeSqr < _GetDistanceSqr(self.sourceRange, target) then return SPELLSTATE_OUT_OF_RANGE end
        if isImmobile then
            return self:__Cast(target)
        else
            return SPELLSTATE_NOT_IMMOBILE
        end
    end
    return SPELLSTATE_NOT_TRIGGERED
end
--[[
    Cast the spell, respecting previously made decisions about skillshots and AOE stuff

    @param param1 | userdata/float | When param2 is nil then this can be the target object, otherwise this is the X coordinate of the skillshot position
    @param param2 | float          | Z coordinate of the skillshot position
    @param return | int            | SpellState of the current spell
]]
function Spell:Cast(param1, param2)
	local castPosition, hitChance, position, nTargets = nil, nil, nil, nil
    if self.skillshotType ~= nil and param1 ~= nil and param2 == nil then
        -- Don't calculate stuff when target is invalid
        if not ValidTarget(param1) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_INVALID_TARGET")
			end
			return SPELLSTATE_INVALID_TARGET 
		end
		-- Is ready
		--[[
		
		if self:IsReady() then
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_IS_READY")
			end
			return SPELLSTATE_IS_READY 
		end
		
		]]
        if self.skillshotType == SKILLSHOT_LINEAR or self.skillshotType == SKILLSHOT_CONE then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.range < GetDistance(self.sourceRange, castPosition) then
					if _G.srcLib.Menu.Spell.Debug then
						print("SPELLSTATE_OUT_OF_RANGE".." "..self.range)
					end
					return SPELLSTATE_OUT_OF_RANGE 
				end
            end
        elseif self.skillshotType == SKILLSHOT_CIRCULAR then
            if self.useAoe then
                castPosition, hitChance, nTargets = self:GetPrediction(param1)
            else
                castPosition, hitChance, position = self:GetPrediction(param1)
                -- Out of range
                if self.range + self.width + GetDistance(param1.minBBox) < GetDistance(self.sourceRange, castPosition) then 
					if _G.srcLib.Menu.Spell.Debug then
						print("SPELLSTATE_OUT_OF_RANGE")
					end
					return SPELLSTATE_OUT_OF_RANGE 
				end
            end
		elseif self.skillshotType == SKILLSHOT_TARGETTED then
			self:__Cast(param1)
        end
        -- Validation (for Prodiction)
        if not castPosition then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_NOT_TRIGGERED")
			end
			return SPELLSTATE_NOT_TRIGGERED
		end
        -- AOE not enough targets
        if nTargets and nTargets < self.minTargetsAoe then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_NOT_ENOUGH_TARGETS")
			end
			return SPELLSTATE_NOT_ENOUGH_TARGETS 
		end
        -- Collision detected
        if self.collision and hitChance < 0 then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_COLLISION")
			end
			return SPELLSTATE_COLLISION 
		end
        -- Hitchance too low
        if (hitChance and hitChance < self.hitChance) or hitChance == nil then 
			if _G.srcLib.Menu.Spell.Debug then
				print(hitChance .." "..self.hitChance)
				print("SPELLSTATE_LOWER_HITCHANCE")
			end
			return SPELLSTATE_LOWER_HITCHANCE 
		end
        -- Out of range
		
		if self.range < GetDistance(self.sourceRange, castPosition) then 
			if _G.srcLib.Menu.Spell.Debug then
				print("SPELLSTATE_OUT_OF_RANGE")
			end
			return SPELLSTATE_OUT_OF_RANGE 
		end
		
        param1 = castPosition.x
        param2 = castPosition.z
    end
    -- Cast charged spell
    if castPosition ~= nil and self.__charged and self:IsCharging() then
		print(tostring(GetDistance(castPosition) < (self.range)) .. " " .. tostring(GetDistance(castPosition) < (self.range)))
		if self.range ~= self.__charged_maxRange and GetDistance(castPosition) < (self.range) or self.range == self.__charged_maxRange and GetDistance(castPosition) < (self.range) then
			local d3vector = D3DXVECTOR3(castPosition.x, castPosition.y, castPosition.z)
			CastSpell2(self.spellId, d3vector)
		end
		if _G.srcLib.Menu.Spell.Debug then
			print("SPELLSTATE_TRIGGERED")
		end
        return SPELLSTATE_TRIGGERED
    end
    -- Cast the spell
	if _G.srcLib.Menu.Spell.Debug then
		print("SPELLSTATE_CALL_CASTSPELL")
	end
    return self:__Cast(param1, param2)
end
--[[
    Internal function, do not use this!
]]
function Spell:__Cast(param1, param2)
    if self.packetCast then
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
            else
                Packet("S_CAST", {spellId = self.spellId, toX = param1, toY = param2, fromX = param1, fromY = param2}):send()
            end
        elseif param1 ~= nil then
            Packet("S_CAST", {spellId = self.spellId, toX = param1.x, toY = param1.z, fromX = param1.x, fromY = param1.z, targetNetworkId = param1.networkID}):send()
        else
            Packet("S_CAST", {spellId = self.spellId, toX = player.x, toY = player.z, fromX = player.x, fromY = player.z, targetNetworkId = player.networkID}):send()
        end
    else
        if param1 ~= nil and param2 ~= nil then
            if type(param1) ~= "number" and type(param2) ~= "number" and VectorType(param1) and VectorType(param2) then
                --Packet("S_CAST", {spellId = self.spellId, toX = param2.x, toY = param2.z, fromX = param1.x, fromY = param1.z}):send()
				CastSpell(self.spellId, param1, param2)
            else
                CastSpell(self.spellId, param1, param2)
            end
        elseif param1 ~= nil then
            CastSpell(self.spellId, param1)
        else
            CastSpell(self.spellId)
        end
    end
    return SPELLSTATE_TRIGGERED
end
--[[
    Add an automation to the spell to let it cast itself when a certain condition is met

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
    @param func         | function   | Function to be called when checking, should return a bool value indicating if it should be casted and optionally the cast params (ex: target or x and z)
]]
function Spell:AddAutomation(automationId, func)
    assert(automationId, "Spell: automationId is invalid!")
    assert(func and type(func) == "function", "Spell: func is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then return end
    end
    table.insert(self._automations, { id == automationId, func = func })
    -- Register callbacks
    if not self.__tickCallback then
        AddTickCallback(function() self:OnTick() end)
        self.__tickCallback = true
    end
end
--[[
    Remove and automation by it's id

    @param automationId | string/int | The ID of the automation, example "AntiGapCloser"
]]
function Spell:RemoveAutomation(automationId)
    assert(automationId, "Spell: automationId is invalid!")
    for index, automation in ipairs(self._automations) do
        if automation.id == automationId then
            table.remove(self._automations, index)
            break
        end
    end
end
--[[
    Clear all automations assinged to this spell
]]
function Spell:ClearAutomations()
    self._automations = {}
end
--[[
    Track the spell like in OnProcessSpell to add more features to this Spell instance

    @param spellName | string/table | Case insensitive name(s) of the spell
    @return          | class        | The current instance
]]
function Spell:TrackCasting(spellName)
    assert(spellName, "Spell:TrackCasting(): spellName is invalid!")
    assert(self.__tracked_spellNames == nil, "Spell:TrackCasting(): This spell is already tracked!")
    assert(type(spellName) == "string" or type(spellName) == "table", "Spell:TrackCasting(): Type of spellName is invalid: " .. type(spellName))
    self.__tracked_spellNames = type(spellName) == "table" and spellName or { spellName }
    -- Register callbacks
    if not self.__processSpellCallback then
        AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
        self.__processSpellCallback = true
    end
    return self
end

function Spell:WillHit(target)
	local castPosition, hitChance, position = self:GetPrediction(target)
	if hitChance > self.hitChance then
		return true
	end
	return false
end

--[[
    When the spell is casted and about to hit a target, this will return the following
	
	@param pName  | string      | Name of the object
	@param pWidth | int		   | Width of the object
	@param pType  | string	   | Type of the object
    @return		  | CUnit,float | The target unit, the remaining time in seconds it will take to hit the target, otherwise nil
]]
function Spell:WillHitTarget(pName, pWidth, pType)
	local _type = pWidth or "missileclient"
	local width = pWidth or self.width
    for i = 1, objManager.iCount, 1 do
        local obj = objManager:getObject(i)
        if obj ~= nil and obj.spellName == pName and obj.type == _type then
			local Pos = Vector(obj);
			for index, hero in GetEnemyHeroes() do
				if hero and GetDistanceSqr(hero, Pos) < width then
					return
				end
			end
		end
	end
	return false
end
--[[
    Register a function which will be triggered when the spell is being casted the function will be given the spell object as parameter

    @param func | function | Function to be called when the spell is being processed (casted)
]]
function Spell:RegisterCastCallback(func)
    assert(func and type(func) == "function" and self.__tracked_castCallback == nil, "Spell:RegisterCastCallback(): func is either invalid or a callback is already registered!")
    self.__tracked_castCallback = func
end
--[[
    Get if the target is in range
	
    @return | bool | In range or not
]]
function Spell:IsInRange(target, from)
    return self.rangeSqr >= _GetDistanceSqr(target, from or self.sourcePosition)
end
--[[
    Get if the spell is ready or not

    @return | bool | Spell state ready or not
]]
function Spell:IsReady()
    return player:CanUseSpell(self.spellId) == READY
end
--[[
    Get the mana usage of the spell

    @return | float | Mana usage of the spell
]]
function Spell:GetManaUsage()
    return player:GetSpellData(self.spellId).mana
end
--[[
    Get the CURRENT cooldown of the spell

    @return | float | Current cooldown of the spell
]]
function Spell:GetCooldown(current)
    return current and player:GetSpellData(self.spellId).currentCd or player:GetSpellData(self.spellId).totalCooldown
end
--[[
    Get the stat points assinged to this spell (level)

    @return | int | Stat points assinged to this spell (level)
]]
function Spell:GetLevel()
    return player:GetSpellData(self.spellId).level
end
--[[
    Get the name of the spell

    @return | string | Name of the the spell
]]
function Spell:GetName()
    return player:GetSpellData(self.spellId).name
end
--[[
    Internal callback, don't use this!
]]
function Spell:OnTick()
    -- Automations
    if self._automations and #self._automations > 0 then
        for _, automation in ipairs(self._automations) do
            local doCast, param1, param2 = automation.func()
            if doCast == true then
                self:Cast(param1, param2)
            end
        end
    end
    -- Charged spells
    if self.__charged then
        if self:IsCharging() then
            self:SetRange(math.min(self.__charged_initialRange + (self.__charged_maxRange - self.__charged_initialRange) * ((os.clock() - self.__charged_castTime) / self.__charged_chargeTime), self.__charged_maxRange))
        elseif not self.__charged_aborted and os.clock() - self.__charged_castTime > 0.1 then
            self:_AbortCharge()
        end
    end

end

--[[
    Internal callback, don't use this!
]]
function Spell:OnProcessSpell(unit, spell)
    if unit and unit.valid and unit.isMe and spell and spell.name then
        -- Tracked spells
        if self.__tracked_spellNames then
            for _, trackedSpell in ipairs(self.__tracked_spellNames) do
                if trackedSpell:lower() == spell.name:lower() then
                    self.__tracked_lastCastTime = os.clock()
                    self.__tracked_castCallback(spell)
                end
            end
        end
        -- Charged spells
        if self.__charged and self.__charged_spellName[1]:lower() == spell.name:lower() then
            self.__charged_active       = true
            self.__charged_aborted      = false
            self.__charged_castTime     = os.clock()
            self.__charged_count        = self.__charged_count and self.__charged_count + 1 or 1
            DelayAction(function(chargeCount)
                if self.__charged_count == chargeCount then
                    self:_AbortCharge()
                end
            end, self.__charged_duration, { self.__charged_count })
        end
    end
end

--[[
    Internal callback, don't use this!
]]
function Spell:OnSendPacket(p)

    -- Charged spells
    if self.__charged then
        if p.header == 230 then
            if os.clock() - self.__charged_castTime <= 0.1 then
                p:Block()
            end
        elseif p.header == Packet.headers.S_CAST then
            local packet = Packet(p)
            if packet:get("spellId") == self.spellId then
                if os.clock() - self.__charged_castTime <= self.__charged_duration then
                    self:_AbortCharge()
                    local newPacket = CLoLPacket(230)
                    newPacket:EncodeF(player.networkID)
                    newPacket:Encode1(0x80)
                    newPacket:EncodeF(mousePos.x)
                    newPacket:EncodeF(mousePos.y)
                    newPacket:EncodeF(mousePos.z)
                    SendPacket(newPacket)
                    p:Block()
                end
            end
        end
    end

end

function Spell:__eq(other)

    return other and other._spellNum and other._spellNum == self._spellNum or false

end

--[[

'||''|.                               '||    ||'                                                  
 ||   ||  ... ..   ....   ... ... ...  |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||    ||  ||' '' '' .||   ||  ||  |   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||    ||  ||     .|' ||    ||| |||    | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||...|'  .||.    '|..'|'    |   |    .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                          .|....'                 

    DrawManager - Tired of having to draw everything over and over again? Then use this!

    Functions:
        DrawManager()

    Methods:
        DrawManager:AddCircle(circle)
        DrawManager:RemoveCircle(circle)
        DrawManager:CreateCircle(position, radius, width, color)
        DrawManager:OnDraw()
		DrawManager:AddToMenu(menu)

]]
class 'DrawManager'

--[[
    New instance of DrawManager
]]
function DrawManager:__init()

    self.objects = {}

end

--[[
    Add an existing circle to the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:AddCircle(_circle, _paramText)

    assert(_circle, "DrawManager: circle is invalid!")

    for _, object in ipairs(self.objects) do
        assert(object ~= _circle, "DrawManager: object was already in DrawManager")
    end

    table.insert(self.objects, {circle = _circle, paramText = _paramText})
end

--[[
    Removes a circle from the draw manager

    @param circle | class | _Circle instance
]]
function DrawManager:RemoveCircle(circle)
    assert(circle, "DrawManager:RemoveCircle(): circle is invalid!")

    for index, object in ipairs(self.objects) do
        if object.circle == circle then
            table.remove(self.objects, index)
        end
    end
end

--[[
    Create a new circle and add it aswell to the DrawManager instance

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
	@param paramText| string | Param text of Menu
    @return         | class  | Instance of the newly create Circle class
]]
function DrawManager:CreateCircle(position, radius, width, color, paramText)

    local circle = _Circle(position, radius, width, color)
    self:AddCircle(circle, paramText)
    return circle

end


--[[
	Adds the Circle contols to the menu.
	@param menu | menu | Instance of script config to add this DrawManager to
]]
function DrawManager:AddToMenu(menu)
	
	for index, object in ipairs(self.objects) do
		object.circle:AddToMenu(menu, object.paramText, true, true, true)
	end
	
	AddDrawCallback(function() self:OnDraw() end)
end


--[[
    DO NOT CALL THIS MANUALLY! This will be called automatically.
]]
function DrawManager:OnDraw()
    for _, object in ipairs(self.objects) do
        if object.circle.enabled then
            object.circle:Draw()
        end
    end
end

--[[

                  ..|'''.|  ||                  '||          
                .|'     '  ...  ... ..    ....   ||    ....  
                ||          ||   ||' '' .|   ''  ||  .|...|| 
                '|.      .  ||   ||     ||       ||  ||      
                 ''|....'  .||. .||.     '|...' .||.  '|...' 

    Functions:
        _Circle(position, radius, width, color)

    Members:
        _Circle.enabled  | bool   | Enable or diable the circle (displayed)
        _Circle.mode     | int    | See circle modes below
        _Circle.position | vector | Center of the circle
        _Circle.radius   | float  | Radius of the circle
        -- These are not changeable when a menu is set
        _Circle.width    | int    | Width of the circle outline
        _Circle.color    | table  | Color of the circle in a tale format { a, r, g, b }
        _Circle.quality  | float  | Quality of the circle, the higher the smoother the circle

    Methods:
        _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)
        _Circle:SetEnabled(enabled)
        _Circle:Set2D()
        _Circle:Set3D()
        _Circle:SetMinimap()
        _Circle:SetQuality(qualtiy)
        _Circle:SetDrawCondition(condition)
        _Circle:LinkWithSpell(spell, drawWhenReady)
        _Circle:Draw()
]]
class '_Circle'

-- Circle modes
CIRCLE_2D      = 0
CIRCLE_3D      = 1
CIRCLE_MINIMAP = 2

-- Number of currently created circles
local circleCount = 1

--[[
    New instance of Circle

    @param position | vector | Center of the circle
    @param radius   | float  | Radius of the circle
    @param width    | int    | Width of the circle outline
    @param color    | table  | Color of the circle in a tale format { a, r, g, b }
]]
function _Circle:__init(position, radius, width, color)

    assert(position and position.x and (position.y and position.z or position.y), "_Circle: position is invalid!")
    assert(radius and type(radius) == "number", "_Circle: radius is invalid!")
    assert(not color or color and type(color) == "table" and #color == 4, "_Circle: color is invalid!")

    self.enabled   = true
    self.condition = nil

    self.menu        = nil
    self.menuEnabled = nil
    self.menuColor   = nil
    self.menuWidth   = nil
    self.menuQuality = nil

    self.mode = CIRCLE_3D

    self.position = position
    self.radius   = radius
    self.width    = width or 1
    self.color    = color or { 255, 255, 255, 255 }
    self.quality  = radius / 5

    self._circleId  = "circle" .. circleCount
    self._circleNum = circleCount

    circleCount = circleCount + 1

end

--[[
    Adds this circle to a given menu

    @param menu       | scriptConfig | Instance of script config to add this circle to
    @param paramText  | string       | Text for the menu entry
    @param addColor   | bool         | Add color option
    @param addWidth   | bool         | Add width option
    @param addQuality | bool         | Add quality option
    @return           | class        | The current instance
]]
function _Circle:AddToMenu(menu, paramText, addColor, addWidth, addQuality)

    assert(menu, "_Circle: menu is invalid!")
    assert(self.menu == nil, "_Circle: Already bound to a menu!")

    menu:addSubMenu(paramText or "Circle " .. self._circleNum, self._circleId)
    self.menu = menu[self._circleId]

    -- Enabled
    local paramId = self._circleId .. "enabled"
    self.menu:addParam(paramId, "Enabled", SCRIPT_PARAM_ONOFF, self.enabled)
    self.menuEnabled = self.menu._param[#self.menu._param]

    if addColor or addWidth or addQuality then

        -- Color
        if addColor then
            paramId = self._circleId .. "color"
            self.menu:addParam(paramId, "Color", SCRIPT_PARAM_COLOR, self.color)
            self.menuColor = self.menu._param[#self.menu._param]
        end

        -- Width
        if addWidth then
            paramId = self._circleId .. "width"
            self.menu:addParam(paramId, "Width", SCRIPT_PARAM_SLICE, self.width, 1, 5)
            self.menuWidth = self.menu._param[#self.menu._param]
        end

        -- Quality
        if addQuality then
            paramId = self._circleId .. "quality"
            self.menu:addParam(paramId, "Quality", SCRIPT_PARAM_SLICE, math.round(self.quality), 10, math.round(self.radius / 5))
            self.menuQuality = self.menu._param[#self.menu._param]
        end

    end

    return self

end

--[[
    Set the enable status of the circle

    @param enabled | bool  | Enable state of this circle
    @return        | class | The current instance
]]
function _Circle:SetEnabled(enabled)

    self.enabled = enabled
    return self

end

--[[
    Set this circle to be displayed 2D

    @return | class | The current instance
]]
function _Circle:Set2D()

    self.mode = CIRCLE_2D
    return self

end

--[[
    Set this circle to be displayed 3D

    @return | class | The current instance
]]
function _Circle:Set3D()

    self.mode = CIRCLE_3D
    return self

end

--[[
    Set this circle to be displayed on the minimap

    @return | class | The current instance
]]
function _Circle:SetMinimap()

    self.mode = CIRCLE_MINIMAP
    return self

end

--[[
    Set the display quality of this circle

    @return | class | The current instance
]]
function _Circle:SetQuality(qualtiy)

    assert(qualtiy and type(qualtiy) == "number", "_Circle: quality is invalid!")
    self.quality = quality
    return self

end

--[[
    Set the display width of this circle

    @return | class | The current instance
]]
function _Circle:SetWidth(width)

    assert(width and type(width) == "number", "_Circle: quality is invalid!")
    self.width = width
    return self

end

--[[
    Set the draw condition of this circle

    @return | class | The current instance
]]
function _Circle:SetDrawCondition(condition)

    assert(condition and type(condition) == "function", "_Circle: condition is invalid!")
    self.condition = condition
    return self

end

--[[
    Links the spell range with the circle radius

    @param spell         | class | Instance of Spell class
    @param drawWhenReady | bool  | Decides whether to draw the circle when the spell is ready or not
    @return              | class | The current instance
]]
function _Circle:LinkWithSpell(spell, drawWhenReady)

    assert(spell, "_Circle:LinkWithSpell(): spell is invalid")
    self._linkedSpell = spell
    self._linkedSpellReady = drawWhenReady or false
    return self

end

--[[
    Draw this circle, should only be called from OnDraw()
]]
function _Circle:Draw()

    -- Don't draw if condition is not met
    if self.condition ~= nil and self.condition() == false then return end

    -- Update values if linked spell is given
    if self._linkedSpell then
        if self._linkedSpellReady and not self._linkedSpell:IsReady() then return end
        -- Update the radius with the spell range
        self.radius = self._linkedSpell.range
    end

    -- Menu found
    if self.menu then 
        if self.menuEnabled ~= nil then
            if not self.menu[self.menuEnabled.var] then return end
        end
        if self.menuColor ~= nil then
            self.color = self.menu[self.menuColor.var]
        end
        if self.menuWidth ~= nil then
            self.width = self.menu[self.menuWidth.var]
        end
        if self.menuQuality ~= nil then
            self.quality = self.menu[self.menuQuality.var]
        end
    end

    local center = WorldToScreen(D3DXVECTOR3(self.position.x, self.position.y, self.position.z))
    if not self:PointOnScreen(center.x, center.y) and self.mode ~= CIRCLE_MINIMAP then
        return
    end

    if self.mode == CIRCLE_2D then
        DrawCircle2D(self.position.x, self.position.y, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_3D then
        DrawCircle3D(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    elseif self.mode == CIRCLE_MINIMAP then
        DrawCircleMinimap(self.position.x, self.position.y, self.position.z, self.radius, self.width, TARGB(self.color), self.quality)
    else
        print("Circle: Something is wrong with the circle.mode!")
    end

end

function _Circle:PointOnScreen(x, y)
    return x <= WINDOW_W and x >= 0 and y >= 0 and y <= WINDOW_H
end

function _Circle:__eq(other)
    return other._circleId and other._circleId == self._circleId or false
end

--[[

'||''|.                                              '||'       ||  '||      
 ||   ||   ....   .. .. ..    ....     ... .   ....   ||       ...   || ...  
 ||    || '' .||   || || ||  '' .||   || ||  .|...||  ||        ||   ||'  || 
 ||    || .|' ||   || || ||  .|' ||    |''   ||       ||        ||   ||    | 
.||...|'  '|..'|' .|| || ||. '|..'|'  '||||.  '|...' .||.....| .||.  '|...'  
                                     .|....'                                 

    DamageLib - Holy cow, so precise!

    Functions:
        DamageLib(source)

    Members:
        DamageLib.source | Cunit | Source unit for which the damage should be calculated

    Methods:
        DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
        DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)
        DamageLib:CalcSpellDamage(target, spell)
        DamageLib:CalcComboDamage(target, combo)
        DamageLib:IsKillable(target, combo)
        DamageLib:AddToMenu(menu, combo)

    -Available spells by default (not added yet):
        _AA: Returns the auto-attack damage.
        _IGNITE: Returns the ignite damage.
        _ITEMS: Returns the damage dealt by all the items actives.

    -Damage types:
        _MAGIC
        _PHYSICAL
        _TRUE

    -Scaling types: _AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA 
]]
class 'DamageLib'

--Damage types
_MAGIC, _PHYSICAL, _TRUE = 0, 1, 2

--Percentage scale type's 
_AP, _AD, _BONUS_AD, _HEALTH, _ARMOR, _MR, _MAXHEALTH, _MAXMANA = 1, 2, 3, 4, 5, 6, 7, 8

--Percentage scale functions
local _ScalingFunctions = {
    [_AP] = function(x, y) return x * y.source.ap end,
    [_AD] = function(x, y) return x * y.source.totalDamage end,
    [_BONUS_AD] = function(x, y) return x * y.source.addDamage end,
    [_ARMOR] = function(x, y) return x * y.source.armor end,
    [_MR] = function(x, y) return x * y.source.magicArmor end,
    [_MAXHEALTH] = function(x, y) return x * y.source.maxHeath end,
    [_MAXMANA] = function(x, y) return x * y.source.maxMana end,
}

--[[
    New instance of DamageLib

    @param source | Cunit | Source unit (attacker, player by default)
]]
function DamageLib:__init(source)

    self.sources = {}
    self.source = source or player

    --Damage multiplicators:
    self.Magic_damage_m    = 1
    self.Physical_damage_m = 1

    -- Most common damage sources
    self:RegisterDamageSource(_IGNITE, _TRUE, 0, 0, _TRUE, _AP, 0, function() return _IGNITE and (self.source:CanUseSpell(_IGNITE) == READY) end, function() return (50 + 20 * self.source.level) end)
    self:RegisterDamageSource(ItemManagement:GetItem("DFG"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManagement:GetItem("DFG"):GetSlot() and (self.source:CanUseSpell(ItemManagement:GetItem("DFG"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(ItemManagement:GetItem("BOTRK"):GetId(), _MAGIC, 0, 0, _MAGIC, _AP, 0, function() return ItemManagement:GetItem("BOTRK"):GetSlot() and (self.source:CanUseSpell(ItemManagement:GetItem("BOTRK"):GetSlot()) == READY) end, function(target) return 0.15 * target.maxHealth end)
    self:RegisterDamageSource(_AA, _PHYSICAL, 0, 0, _PHYSICAL, _AD, 1)

end

--[[
    Register a new spell

    @param spellId        | int      | (unique) Spell id to add.
    
    @param damagetype     | int      | The type(s) of the base and perlevel damage (_MAGIC, _PHYSICAL, _TRUE).
    @param basedamage     | int      | Base damage(s) of the spell.
    @param perlevel       | int      | Damage(s) scaling per level.

    @param scalingtype    | int      | Type(s) of the percentage scale (_MAGIC, _PHYSICAL, _TRUE).
    @param scalingstat    | int      | Stat(s) that the damage scales with.
    @param percentscaling | int      | Percentage(s) the stat scales with.

    @param condition      | function | (optional) A function that returns true / false depending if the damage will be taken into account or not, the target is passed as param.
    @param extra          | function | (optional) A function returning extra damage, the target is passed as param.
    
    -Example Spells: 
    Teemo Q:  80 / 125 / 170 / 215 / 260 (+ 80% AP) (MAGIC)
    DamageLib:RegisterDamageSource(_Q, _MAGIC, 35, 45, _MAGIC, _AP, 0.8, function() return (player:CanUseSpell(_Q) == READY) end)

    Akalis E: 30 / 55 / 80 / 105 / 130 (+ 30% AP) (+ 60% AD) (PHYSICAL) 
    DamageLib:RegisterDamageSource(_E, _PHYSICAL, 5, 25, {_PHYSICAL,_PHYSICAL}, {_AP, _AD}, {0.3, 0.6}, function() return (player:GetSpellData(_Q).currentCd < 2) or (player:CanUseSpell(_Q) == READY) end)

    * damagetype, basedamage, perlevel and scalingtype, scalingstat, percentscaling can be tables if there are 2 or more damage types.
]]
function DamageLib:RegisterDamageSource(spellId, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    condition = condition or function() return true end
    if spellId then
        self.sources[spellId] = {damagetype = damagetype, basedamage = basedamage, perlevel = perlevel, condition = condition, extra = extra, scalingtype = scalingtype, percentscaling = percentscaling, scalingstat = scalingstat}
    end

end

function DamageLib:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)

    local amount = (_ScalingFunctions[scalingstat] or function() return 0 end)(percentscaling, self)

    if scalingtype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, amount)
    elseif scalingtype == _PHYSICAL then
        return self.Physical_damage_m * self.Physical_damage_m * self.source:CalcDamage(target, amount)
    elseif scalingtype == _TRUE then
        return amount
    end

    return 0

end

function DamageLib:GetTrueDamage(target, spell, damagetype, basedamage, perlevel, scalingtype, scalingstat, percentscaling, condition, extra)

    basedamage = basedamage or 0
    perlevel = perlevel or 0
    condition = condition(target)
    scalingtype = scalingtype or 0
    scalingstat = scalingstat or _AP
    percentscaling = percentscaling or 0
    extra = extra or function() return 0 end
    local ScalingDamage = 0

    if not condition then return 0 end

    if type(scalingtype) == "number" then
        ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype, scalingstat, percentscaling)
    elseif type(scalingtype) == "table" then
        for i, v in ipairs(scalingtype) do
            ScalingDamage = ScalingDamage + self:GetScalingDamage(target, scalingtype[i], scalingstat[i], percentscaling[i])
        end
    end

    if damagetype == _MAGIC then
        return self.Magic_damage_m * self.source:CalcMagicDamage(target, basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target)) + ScalingDamage
    end
    if damagetype == _PHYSICAL then
        return self.Physical_damage_m * self.source:CalcDamage(target, basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target)) + ScalingDamage
    end
    if damagetype == _TRUE then
        return basedamage + perlevel * self.source:GetSpellData(spell).level + extra(target) + ScalingDamage
    end

    return 0

end

function DamageLib:CalcSpellDamage(target, spell)

    if not spell then return 0 end
    local spelldata = self.sources[spell]
    local result = 0
    assert(spelldata, "DamageLib: The spell has to be added first!")

    local _type = type(spelldata.damagetype)

    if _type == "number" then
        result = self:GetTrueDamage(target, spell, spelldata.damagetype, spelldata.basedamage, spelldata.perlevel, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    elseif _type == "table" then
        for i = 1, #spelldata.damagetype, 1 do                 
            result = result + self:GetTrueDamage(target, spell, spelldata.damagetype[i], spelldata.basedamage[i], spelldata.perlevel[i], 0, 0, 0, spelldata.condition)
        end
        result = result + self:GetTrueDamage(target, spell, 0, 0, 0, spelldata.scalingtype, spelldata.scalingstat, spelldata.percentscaling, spelldata.condition, spelldata.extra)
    end

    return result

end

function DamageLib:CalcComboDamage(target, combo)

    local totaldamage = 0

    for i, spell in ipairs(combo) do
        if spell == ItemManagement:GetItem("DFG"):GetId() and ItemManagement:GetItem("DFG"):IsReady() then
            self.Magic_damage_m = 1.2
        end
    end

    for i, spell in ipairs(combo) do
        totaldamage = totaldamage + self:CalcSpellDamage(target, spell)
    end

    self.Magic_damage_m = 1

    return totaldamage

end

--[[
    Returns if the unit will die after taking the combo damage.

    @param target | Cunit | Target.
    @param combo  | table | The combo table.
]]
function DamageLib:IsKillable(target, combo)
    return target.health <= self:CalcComboDamage(target, combo)
end

--[[
    Adds the Health bar indicators to the menu.

    @param menu  | scriptConfig | AllClass menu or submenu instance.
    @param combo | table        | The combo table.
]]
function DamageLib:AddToMenu(menu, combo)

    self.menu = menu
    self.combo = combo
    self.ticklimit = 5 --5 ticks per seccond
    self.barwidth = 100
    self.cachedDamage = {}
    menu:addParam("DrawPredictedHealth", "Draw damage after combo.", SCRIPT_PARAM_ONOFF , true)
    self.enabled = menu.DrawPredictedHealth
    AddTickCallback(function() self:OnTick() end)
    AddDrawCallback(function() self:OnDraw() end)

end

function DamageLib:OnTick()

    if not self.menu["DrawPredictedHealth"] then return end
    self.lasttick = self.lasttick or 0
    if os.clock() - self.lasttick > 1 / self.ticklimit then
        self.lasttick = os.clock()
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                self.cachedDamage[enemy.hash] = self:CalcComboDamage(enemy, self.combo)
            end
        end
    end

end

function DamageLib:OnDraw()

    if not self.menu["DrawPredictedHealth"] then return end
    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) then
            self:DrawIndicator(enemy)
        end
    end

end

function DamageLib:DrawIndicator(enemy)

    local damage = self.cachedDamage[enemy.hash] or 0
    local SPos, EPos = GetHPBarPos(enemy)

    -- Validate data
    if not SPos then return end

    if damage > 0 then
        color = damage > enemy.health and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0)

        pos = SPos;
        after = math.max(0, enemy.health - damage) / enemy.maxHealth;
        posY = pos.y - 18;
        posDamageX = pos.x + 12 + 103 * after;
        position = pos.x - 5 + 103 * (enemy.health / enemy.maxHealth);

        diff = (position - posDamageX) + 3;

        pos1 = pos.x + 8 + (107 * after);
        for i = 0, diff do
            DrawLine(pos1 + i, posY, pos1 + i, posY + 10, 1, color);
        end

        DrawText( string.format("%s : %s => %s", "After Combo", math.ceil(enemy.health), math.max(0, math.ceil(enemy.health - damage))), 18, pos1, posY - 20, color);
    end

--    local barwidth = EPos.x - SPos.x
--    local Position = EPos.x - math.max(0, ((enemy.health - damage) / enemy.maxHealth) * 100)

--    DrawText("|", 16, math.floor(Position), math.floor(SPos.y-23), ARGB(255,0,255,0))
--    DrawText("After HP: "..math.floor(enemy.health - damage), 13, math.floor(SPos.x), math.floor(SPos.y), (enemy.health - damage) > 0 and ARGB(255, 0, 255, 0) or  ARGB(255, 255, 0, 0))

end

function GetHPBarPos(enemy)
	enemy.barData = {PercentageOffset = {x = -0.05, y = 0}}--GetEnemyBarData()
	local barPos = GetUnitHPBarPos(enemy)
	local barPosOffset = GetUnitHPBarOffset(enemy)
	local barOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local barPosPercentageOffset = { x = enemy.barData.PercentageOffset.x, y = enemy.barData.PercentageOffset.y }
	local BarPosOffsetX = 171
	local BarPosOffsetY = 46
	local CorrectionY = 39
	local StartHpPos = 31

	barPos.x = math.floor(barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + StartHpPos)
	barPos.y = math.floor(barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY)

	local StartPos = Vector(barPos.x , barPos.y, 0)
	local EndPos =  Vector(barPos.x + 108 , barPos.y , 0)
	return Vector(StartPos.x, StartPos.y, 0), Vector(EndPos.x, EndPos.y, 0)
end
--[[

 .|'''.|  |''||''|  .|'''.|  
 ||..  '     ||     ||..  '  
  ''|||.     ||      ''|||.  
.     '||    ||    .     '|| 
|'....|'    .||.   |'....|'  

    Simple Target Selector (STS) - Why using the regular one when you can have it even more simple.
	
	Introduction:
        Use targetselector more simply

    Functions:
        SimpleTS(mode)

    Methods:
        SimpleTS:AddToMenu(menu)
        SimpleTS:GetTarget(range, n, forcemode)
]]
class 'SimpleTS'

function STS_GET_PRIORITY(target)
    if not STS_MENU or not STS_MENU.STS[target.hash] then
        return 1
    else
        return STS_MENU.STS[target.hash]
    end
end

STS_MENU = nil
STS_NEARMOUSE                     = {id = 1, name = "Near mouse", sortfunc = function(a, b) return _GetDistanceSqr(mousePos, a) < _GetDistanceSqr(mousePos, b) end}
STS_LESS_CAST_MAGIC               = {id = 2, name = "Less cast (magic)", sortfunc = function(a, b) return (player:CalcMagicDamage(a, 100) / a.health) > (player:CalcMagicDamage(b, 100) / b.health) end}
STS_LESS_CAST_PHYSICAL            = {id = 3, name = "Less cast (physical)", sortfunc = function(a, b) return (player:CalcDamage(a, 100) / a.health) > (player:CalcDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_MAGIC      = {id = 4, name = "Less cast priority (magic)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcMagicDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcMagicDamage(b, 100) / b.health) end}
STS_PRIORITY_LESS_CAST_PHYSICAL   = {id = 5, name = "Less cast priority (physical)", sortfunc = function(a, b) return STS_GET_PRIORITY(a) * (player:CalcDamage(a, 100) / a.health) > STS_GET_PRIORITY(b) * (player:CalcDamage(b, 100) / b.health) end}
STS_CLOSEST					  	  = {id = 6, name = "Near myHero", sortfunc = function(a, b) return GetDistance(a) < GetDistance(b) end}
STS_LOW_HP_PRIORITY               = {id = 7, name = "Low HP priority", sortfunc = function(a, b) return a.health < b.health end }
STS_AVAILABLE_MODES = {STS_NEARMOUSE, STS_LESS_CAST_MAGIC, STS_LESS_CAST_PHYSICAL, STS_PRIORITY_LESS_CAST_MAGIC, STS_PRIORITY_LESS_CAST_PHYSICAL, STS_CLOSEST, STS_LOW_HP_PRIORITY}
--[[
	Create a new instance of TargetSelector
	
	@param mode | mode | Mode of the TargetSelector
]]
function SimpleTS:__init(mode)
    self.mode = mode and mode or STS_LESS_CAST_PHYSICAL
    AddDrawCallback(function() self:OnDraw() end)
    AddMsgCallback(function(msg, key) self:OnMsg(msg, key) end)
end
--[[
	Check enemy in range
	
	
	@param target   | CUnit   | Unit will be check
	@param range    | int     | Checking range
	@param selected | boolean | is checked
	@return			| boolean | In Range or not

]]
function SimpleTS:IsValid(target, range, selected)
    if ValidTarget(target) and (_GetDistanceSqr(target) <= range or (self.hitboxmode and (_GetDistanceSqr(target) <= (math.sqrt(range) + GetDistance(myHero.minBBox) + GetDistance(target.minBBox)) ^ 2))) then
        if selected or (not (HasBuff(target, "UndyingRage") and (target.health == 1)) and not HasBuff(target, "JudicatorIntervention")) then
            return true
        end
    end
end
--[[
	SimpleTS add to menu
	
	@param menu | menu | Be added to the menu
]]
function SimpleTS:AddToMenu(menu)
    self.menu = menu or scriptConfig("[SourceLib] SimpleTS", "srcSimpleTSClass")
    self.menu:addSubMenu("Target Priority", "STS")
    for i, target in ipairs(GetEnemyHeroes()) do
            self.menu.STS:addParam(target.hash, target.charName, SCRIPT_PARAM_SLICE, 1, 1, 5, 0)
    end
    self.menu.STS:addParam("Info", "Info", SCRIPT_PARAM_INFO, "5 Highest priority")

    local modelist = {}
    for i, mode in ipairs(STS_AVAILABLE_MODES) do
        table.insert(modelist, mode.name)
    end

    self.menu:addParam("mode", "Targetting mode: ", SCRIPT_PARAM_LIST, 1, modelist)
    self.menu["mode"] = self.mode.id

    self.menu:addParam("Selected", "Focus selected target", SCRIPT_PARAM_ONOFF, true)

    STS_MENU = self.menu
end

function SimpleTS:OnMsg(msg, key)
    if msg == WM_LBUTTONDOWN then
        local MinimumDistance = math.huge
        local SelectedTarget
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy) then
                if _GetDistanceSqr(enemy, mousePos) <= MinimumDistance then
                    MinimumDistance = _GetDistanceSqr(enemy, mousePos)
                    SelectedTarget = enemy
                end
            end
        end
        if SelectedTarget and MinimumDistance < 150 * 150 then
            self.STarget = SelectedTarget
        else
            self.STarget = nil
        end
    end
end
--[[
	who is selected target?
	
	@return | CUnit | Selected unit
]]
function SimpleTS:SelectedTarget()
    return self.STarget
end
--[[
	Get target to kill
	
	@param range 	 | int  | range
	@param n 		 | int  | (optional) how many get target
	@param forcemode | mode | (optional) target be search with this mode

]]
function SimpleTS:GetTarget(range, n, forcemode)
    assert(range, "SimpleTS: range can't be nil")
    range = range
    local PosibleTargets = {}
    local selected = self:SelectedTarget()

    if self.menu then
        self.mode = STS_AVAILABLE_MODES[self.menu.mode]
        if self.menu.Selected and selected and selected.type == player.type and self:IsValid(selected, range, true) then
            return selected
        end
    end

    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) and GetDistance(enemy) < range and not enemy.dead then --self:IsValid(enemy, range) not perfect
            table.insert(PosibleTargets, enemy)
        end
    end
    table.sort(PosibleTargets, forcemode and forcemode.sortfunc or self.mode.sortfunc)

    return PosibleTargets[n and n or 1]
end

function SimpleTS:OnDraw()
    local selected = self:SelectedTarget()
    if self.menu and self.menu.Selected and ValidTarget(selected) then
        DrawCircle3D(selected.x, selected.y, selected.z, 100, 2, ARGB(175, 0, 255, 0), 25)
    end
end

--[[

'||'   .                      '||    ||'                                                  
 ||  .||.    ....  .. .. ..    |||  |||   ....   .. ...    ....     ... .   ....  ... ..  
 ||   ||   .|...||  || || ||   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' '' 
 ||   ||   ||       || || ||   | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||     
.||.  '|.'  '|...' .|| || ||. .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.    
                                                                  .|....'                 

    ItemManager - Better handle them properly

    Functions:
        ItemManager() -- Adding

    Methods:
        ItemManager:ItemCast(param, param1, param2)
		ItemManager:GetItemSlot(param, unit)
		ItemManager:IsReady(param)
		ItemManager:InRange(param, target)
		ItemManager:GetRange(param)

]]
-- item type
ITEM_TARGETING = 0
ITEM_NONTARGETING = 1
ITEM_MYSELF = 2
ITEM_POTION = 3
ITEM_BUFF = 4


class "ItemManager"
function ItemManager:__init()
    self.items = {
			--TARGETING
            ["dfg"] 				= {id = 3128, range = 650, type = ITEM_TARGETING, name = ""},
            ["botrk"]				= {id = 3153, range = 450, type = ITEM_TARGETING, name = "itemswordoffeastandfamine"},
			["bilgewaterculess"]	= {id = 3144, range = 450, type = ITEM_TARGETING, name = "Bilgewatercutlass"},
			
			-- NONTARGETING
			
			-- myself
			["youmuus"] 			= {id = 3142, range = 450, type = ITEM_MYSELF, name = "Youmusblade"},
			
			-- POTIONS
			["elixirofwrath"]		= {id = 0001, range = 450, type = ITEM_POTION, name = "Elixirofwrath"},
        }
	
	if (not _G.srcLib.Menu.ItemManager) then
		_G.srcLib.Menu:addSubMenu("ItemManager dev menu", "ItemManager")
			_G.srcLib.Menu.ItemManager:addParam("Debug", "dev debug", SCRIPT_PARAM_ONOFF, false)
	end
end
--[[
	Ez command
	
	@param param    | int or string    | Item id or name
    @param param1	| Vector or target | Target x pos or Target unit
	@parma param2   | Vector           | Target z pos
	@return ItemManager:ItemCast(param, param1, param2)

]]
function ItemManager:Cast(param, param1, param2)
	return self:ItemCast(param, param1, param2)
end
--[[
    Casts all known offensive items on the given target
	
	@param param    | int or string    | Item id or name
    @param param1	| Vector or target | Target x pos or Target unit
	@parma param2   | Vector           | Target z pos
]]
function ItemManager:ItemCast(param, param1, param2)
	local slot
	if (type(param) == "string") then
		slot = self:GetItemSlot(self.items[param:lower()].id)
	elseif (type(param) == "number") then
		slot = self:GetItemSlot(param)
	else
		print("ItemManager: ItemCast(param, target) : param is invalid type(not string or number)")
		return
	end
	if (param1 ~= nil and param2 ~= nil) then
		CastSpell(slot, param1, param2)
	elseif (param ~= nil and param == nil) then
		CastSpell(slot, param1)
	else
		CastSpell(slot)
	end
end
--[[
    Return Item slot with item name or id
	
	@param param | int or string | Item id or name
	@param unit  | Cunit		 | (optional) Searching target
    @return		 | integer		 | Item slot
]]
function ItemManager:GetItemSlot(param, unit)
	unit 		= unit or myHero
	
	if (type(param) == "number") then 
		for slot = ITEM_1, ITEM_7 do
			local item = unit:GetSpellData(slot).name
			local name = self:GetName(id)
			if ((#item > 0) and name ~= nil and (item:lower() == name:lower())) then
				return slot
			end
		end
		return nil
	elseif(type(param) == "string") then
		for slot = ITEM_1, ITEM_7 do
			local item = unit:GetSpellData(slot).name
			if ((#item > 0) and item ~= nil and (item:lower() == self.items[param:lower()].name:lower())) then
				return slot
			end
		end
		return nil
	else
		print("ItemManager: GetItemSlot(param, unit) : param is invalid type(not string or number)")
	end
end

--[[
    Returns if the item is ready to be casted (only working when it's an active item)

	@param param | int or string  | Item name or id
    @return		 | boolean 		  | State of the item
]]
function ItemManager:IsReady(param)
	if (type(param) == "string") then
		return self:GetItemSlot(param) and (player:CanUseSpell(self:GetItemSlot(param)) == READY)
	elseif (type(param) == "number") then
		return self:GetItemSlot(param) and (player:CanUseSpell(self:GetItemSlot(param)) == READY)
	else
		print("ItemManager: IsReady(param) : param is invalid type(not string or number)")
		return
	end
end
--[[
    Returns if the item (actually player) is in range of the target

	@param param  | int or string  | Item name or id
    @param target | CUnit          | Target unit
    @return       | boolean        | In range or not
]]
function ItemManager:InRange(param, target)
	if(type(param) == "string") then
		return GetDistance(target) <= self:GetRange(param)
	elseif(type(param) == "number") then
		return GetDistance(target) <= self:GetRange(param)
	else
		print("ItemManager: InRange(param, target) : param is invalid type(not string or number)")
		return
	end
end

function ItemManager:GetRange(param)
	if(type(param) == "string") then
		return self.items[param].range
	elseif(type(param) == "number") then
		for index, item in self.items do
			if item.id == param then
				return item.range
			end
		end
		return 0;
	else
		print("ItemManager: GetRange(param) : param is invalid type(not string or number)")
		return
	end
end
function ItemManager:GetName(id)
	for index, item in ipairs(self.items) do
		if item.id == id then
			return item.name
		end
	end
end
--[[

'||'   .                      '||    ||'                                                   ''|, 
 ||  .||.    ....  .. .. ..    |||  |||   ....   .. ...    ....     ... .   ....  ... ..   '  || 
 ||   ||   .|...||  || || ||   |'|..'||  '' .||   ||  ||  '' .||   || ||  .|...||  ||' ''    .|' 
 ||   ||   ||       || || ||   | '|' ||  .|' ||   ||  ||  .|' ||    |''   ||       ||       //   
.||.  '|.'  '|...' .|| || ||. .|. | .||. '|..'|' .||. ||. '|..'|'  '||||.  '|...' .||.     ((... 
                                                                  .|....'                 

    ItemManager - Better handle them properly

    Functions:
        _ItemManager(menu) -- Adding

    Methods:
        _ItemManager:CastOffensiveItems(target)
        _ItemManager:GetItem(name)

]]
class "_ItemManager"

function _ItemManager:__init(menu)
    self.items = {
            ["DFG"] 				= {id = 3128, range = 650, cancastonenemy = true, name = ""},
            ["BOTRK"]				= {id = 3153, range = 450, cancastonenemy = true, name = "itemswordoffeastandfamine"}, -- currently work
			--["YOUMUUS"] 			= {id = 3142, range = 450, cancastonenemy = false, name = "Youmusblade"} -- currently work
			["BilgeWaterCuless"]	= {id = 3144, range = 450, cancastonenemy = true, name = "Bilgewatercutlass"}, -- currently work
			--["Elixirofwrath"]		= {id = 0001, range = 450, cancastonenemy = false, name = "Elixirofwrath"} -- currently work
        }

    self.requesteditems = {}
	
	--self.menu = menu or scriptConfig("[SourceLib] ItemManager", "srcItemManagerClass")
	--	self.menu:addParam("nontargetingrange", "Use non targeting spell in range", SCRIPT_PARAM_SLICE, 450, 0, 1000)
	--	_G.srcLib.itemmanagerMenu = self.menu
end

--[[
    Casts all known offensive items on the given target

    @param target      | CUnit | Target unit
]]
function _ItemManager:CastOffensiveItems(target)
    for name, itemdata in pairs(self.items) do
        local item = self:GetItem(name)
        if item:InRange(target) then
			item:Cast(target)
        end
    end
end

--[[
    Gets the items by name.

    @param name   | string | Name of the item (not the ingame name, the name used when registering, like DFG)
    @param return | class  | Instance of the item that was requested or nil if not found
]]
function _ItemManager:GetItem(name)
    assert(name and self.items[name], "ItemManager: Item not found")
    if not self.requesteditems[name] then
        self.requesteditems[name] = Item(self.items[name].id, self.items[name].range, self.items[name].name)
    end
    return self.requesteditems[name]
end

-- Make a global ItemManager instance. This means you don't need to make an instance for yourself.
ItemManagement = _ItemManager()


--[[

'||'   .                      
 ||  .||.    ....  .. .. ..   
 ||   ||   .|...||  || || ||  
 ||   ||   ||       || || ||  
.||.  '|.'  '|...' .|| || ||. 

    Item - Best used in ItemManager

    Functions:
        Item(id, range)

    Methods:
        Item:GetId()
        Item:GetRange(sqr)
        Item:GetSlot()
        Item:UpdateSlot()
        Item:IsReady()
        Item:InRange(target)
        Item:Cast(param1, param2)
]]
class "Item"

--[[
    Create a new instance of Item

    @param id    | integer | Item id 
    @param range | float   | (optional) Range of the item
	@param name  | string  | (optional) Name of the item
]]
function Item:__init(id, range)

    assert(id and type(id) == "number", "Item: id is invalid!")
    assert(not range or range and type(range) == "number", "Item: range is invalid!")

    self.id = id
    self.range = range
    self.rangeSqr = range and range * range
    self.slot = GetInventorySlotItem(id)

end

--[[
    Returns the id of the item

    @return | integer | Item id
]]
function Item:GetId()
    return self.id
end

--[[
    Updates the item slot to the current one (if changed)
]]
function Item:UpdateSlot()
    self.slot = GetInventorySlotItem(self.id)
end
--[[
    Returns the range of the item, only working when the item was defined with a range.

    @param sqr | boolean | Range squared or not
    @return    | float   | Range of the item
]]
function Item:GetRange(sqr)
    return sqr and self.rangeSqr or self.range
end

--[[
    Return the slot the item is in

    @return | integer | Slot it
]]
function Item:GetSlot()
    self:UpdateSlot()
    return self.slot
end

--[[
    Updates the item slot to the current one (if changed)
]]
function Item:UpdateSlot()
    self.slot = self:GetSlotItem(self.id)
end

--[[
    Returns if the item is ready to be casted (only working when it's an active item)

    @return | boolean | State of the item
]]
function Item:IsReady()
    self:UpdateSlot()
    return self.slot and (player:CanUseSpell(self.slot) == READY)
end

--[[
    Returns if the item (actually player) is in range of the target

    @param target | CUnit   | Target unit
    @return       | boolean | In range or not
]]
function Item:InRange(target)
    return _GetDistanceSqr(target) <= self.rangeSqr
end

--[[
    Casts the item

    @param param1 | CUnit/float | Either the target unit itself or as part of the position the X coordinate
    @param param2 | float       | (only use when param1 is given) The Z coordinate
    @return       | integer     | The spell state
]]
function Item:Cast(param1, param2)
    self:UpdateSlot()
    if self.slot then
        if param1 ~= nil and param2 ~= nil then
            CastSpell(self.slot, param1, param2)
        elseif param1 ~= nil then
            CastSpell(self.slot, param1)
        else
            CastSpell(self.slot)
        end
        return SPELLSTATE_TRIGGERED
    end
end

--[[

'||'            .                                               .                   
 ||  .. ...   .||.    ....  ... ..  ... ..  ... ...  ... ...  .||.    ....  ... ..  
 ||   ||  ||   ||   .|...||  ||' ''  ||' ''  ||  ||   ||'  ||  ||   .|...||  ||' '' 
 ||   ||  ||   ||   ||       ||      ||      ||  ||   ||    |  ||   ||       ||     
.||. .||. ||.  '|.'  '|...' .||.    .||.     '|..'|.  ||...'   '|.'  '|...' .||.    
                                                      ||                            
                                                     ''''                           

    Interrupter - They will never cast!

    Function:
		Interrupter(menu, cb)
	
	Methods:
		Interrupter:AddToMenu(menu)
		Interrupter:AddCallback(unit, spell)
	
	Example:
		Interrupter(menu):AddCallback(function(target) self:CastE(target) end)
]]
class 'Interrupter'

local _INTERRUPTIBLE_SPELLS = {
    ["KatarinaR"]                          = { charName = "Katarina",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Meditate"]                           = { charName = "MasterYi",     DangerLevel = 1, MaxDuration = 2.5, CanMove = false },
    ["Drain"]                              = { charName = "FiddleSticks", DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["Crowstorm"]                          = { charName = "FiddleSticks", DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["GalioIdolOfDurand"]                  = { charName = "Galio",        DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["MissFortuneBulletTime"]              = { charName = "MissFortune",  DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["VelkozR"]                            = { charName = "Velkoz",       DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["InfiniteDuress"]                     = { charName = "Warwick",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AbsoluteZero"]                       = { charName = "Nunu",         DangerLevel = 4, MaxDuration = 2.5, CanMove = false },
    ["ShenStandUnited"]                    = { charName = "Shen",         DangerLevel = 3, MaxDuration = 2.5, CanMove = false },
    ["FallenOne"]                          = { charName = "Karthus",      DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["AlZaharNetherGrasp"]                 = { charName = "Malzahar",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },
    ["Pantheon_GrandSkyfall_Jump"]         = { charName = "Pantheon",     DangerLevel = 5, MaxDuration = 2.5, CanMove = false },

}
--[[
	Create a new instance of Interrupter
	
	@param menu | menu     | (optional) add to menu
	@param cb	| function | (optional) will called function

]]
function Interrupter:__init(menu, cb)
    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end
end
--[[
	Add to menu interrupter
	
	@param menu | menu | add to menu
]]
function Interrupter:AddToMenu(menu)
    assert(menu, "Interrupter: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, data in pairs(_INTERRUPTIBLE_SPELLS) do
        if table.contains(EnemyChampioncharNames, data.charName) then
            menu:addParam(string.gsub(spellName, "_", ""), data.charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu
end
--[[
	Add function be called when should be cancel dangerous spell
	
	@param cd | function | will be called function
]]
function Interrupter:AddCallback(cb)
    assert(cb and type(cb) == "function", "Interrupter: callback is invalid!")
    table.insert(self.callbacks, cb)
end
--[[
	Call the function
	
	@param unit  | Cunit | target unit
	@param spell | spell | spell data
]]
function Interrupter:TriggerCallbacks(unit, spell)
    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end
end

function Interrupter:OnProcessSpell(unit, spell)
    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _INTERRUPTIBLE_SPELLS[spell.name] then
            local SpellToInterrupt = _INTERRUPTIBLE_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local data = {unit = unit, DangerLevel = SpellToInterrupt.DangerLevel, endT = os.clock() + SpellToInterrupt.MaxDuration, CanMove = SpellToInterrupt.CanMove}
                table.insert(self.activespells, data)
                self:TriggerCallbacks(data.unit, data)
            end
        end
    end
end

function Interrupter:OnTick()
    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end
end


--[[

    |                .    ||   ..|'''.|                           '||                                 
   |||    .. ...   .||.  ...  .|'     '   ....   ... ...    ....   ||    ...    ....    ....  ... ..  
  |  ||    ||  ||   ||    ||  ||    .... '' .||   ||'  || .|   ''  ||  .|  '|. ||. '  .|...||  ||' '' 
 .''''|.   ||  ||   ||    ||  '|.    ||  .|' ||   ||    | ||       ||  ||   || . '|.. ||       ||     
.|.  .||. .||. ||.  '|.' .||.  ''|...'|  '|..'|'  ||...'   '|...' .||.  '|..|' |'..|'  '|...' .||.    
                                                  ||                                                  
                                                 ''''                                                 

    AntiGapcloser - Stay away please, thanks.

    Function:
		AntiGapcloser(menu, cb)
	
	Methods:
		AntiGapcloser:AddToMenu(menu)
		AntiGapcloser:AddCallback(unit, spell)
	
	Example:
		AntiGapcloser(menu):AddCallback(function(target) self:CastE(target) end)
]]
class 'AntiGapcloser'

local _GAPCLOSER_TARGETED, _GAPCLOSER_SKILLSHOT = 1, 2
--Add only very fast skillshots/targeted spells since vPrediction will handle the slow dashes that will trigger OnDash
local _GAPCLOSER_SPELLS = {
    ["AatroxQ"]              = "Aatrox",
    ["AkaliShadowDance"]     = "Akali",
    ["Headbutt"]             = "Alistar",
    ["FioraQ"]               = "Fiora",
    ["DianaTeleport"]        = "Diana",
    ["EliseSpiderQCast"]     = "Elise",
    ["FizzPiercingStrike"]   = "Fizz",
    ["GragasE"]              = "Gragas",
    ["HecarimUlt"]           = "Hecarim",
    ["JarvanIVDragonStrike"] = "JarvanIV",
    ["IreliaGatotsu"]        = "Irelia",
    ["JaxLeapStrike"]        = "Jax",
    ["KhazixE"]              = "Khazix",
    ["khazixelong"]          = "Khazix",
    ["LeblancSlide"]         = "LeBlanc",
    ["LeblancSlideM"]        = "LeBlanc",
    ["BlindMonkQTwo"]        = "LeeSin",
    ["LeonaZenithBlade"]     = "Leona",
    ["UFSlash"]              = "Malphite",
    ["Pantheon_LeapBash"]    = "Pantheon",
    ["PoppyHeroicCharge"]    = "Poppy",
    ["RenektonSliceAndDice"] = "Renekton",
    ["RivenTriCleave"]       = "Riven",
    ["SejuaniArcticAssault"] = "Sejuani",
    ["slashCast"]            = "Tryndamere",
    ["ViQ"]                  = "Vi",
    ["MonkeyKingNimbus"]     = "MonkeyKing",
    ["XenZhaoSweep"]         = "XinZhao",
    ["YasuoDashWrapper"]     = "Yasuo"
}

function AntiGapcloser:__init(menu, cb)
    self.callbacks = {}
    self.activespells = {}
    AddTickCallback(function() self:OnTick() end)
    AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    if menu then
        self:AddToMenu(menu)
    end
    if cb then
        self:AddCallback(cb)
    end
end

function AntiGapcloser:AddToMenu(menu)
    assert(menu, "AntiGapcloser: menu can't be nil!")
    local SpellAdded = false
    local EnemyChampioncharNames = {}
    for i, enemy in ipairs(GetEnemyHeroes()) do
        table.insert(EnemyChampioncharNames, enemy.charName)
    end
    menu:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
    for spellName, charName in pairs(_GAPCLOSER_SPELLS) do
        if table.contains(EnemyChampioncharNames, charName) then
            menu:addParam(string.gsub(spellName, "_", ""), charName.." - "..spellName, SCRIPT_PARAM_ONOFF, true)
            SpellAdded = true
        end
    end
    if not SpellAdded then
        menu:addParam("Info", "Info", SCRIPT_PARAM_INFO, "No spell available to interrupt")
    end
    self.Menu = menu
	_G.srcLib.AntiGapCloserMenu = self.menu
end

function AntiGapcloser:AddCallback(cb)
    assert(cb and type(cb) == "function", "AntiGapcloser: callback is invalid!")
    table.insert(self.callbacks, cb)
end

function AntiGapcloser:TriggerCallbacks(unit, spell)
    for i, callback in ipairs(self.callbacks) do
        callback(unit, spell)
    end
end

function AntiGapcloser:OnProcessSpell(unit, spell)
    if not self.Menu.Enabled then return end
    if unit.team ~= myHero.team then
        if _GAPCLOSER_SPELLS[spell.name] then
            local Gapcloser = _GAPCLOSER_SPELLS[spell.name]
            if (self.Menu and self.Menu[string.gsub(spell.name, "_", "")]) or not self.Menu then
                local add = false
                if spell.target and spell.target.isMe then
                    add = true
                    startPos = Vector(unit.visionPos)
                    endPos = myHero
                elseif not spell.target then
                    local endPos1 = Vector(unit.visionPos) + 300 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    local endPos2 = Vector(unit.visionPos) + 100 * (Vector(spell.endPos) - Vector(unit.visionPos)):normalized()
                    --TODO check angles etc
                    if (_GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos1) or _GetDistanceSqr(myHero.visionPos, unit.visionPos) > _GetDistanceSqr(myHero.visionPos, endPos2))  then
                        add = true
                    end
                end

                if add then
                    local data = {unit = unit, spell = spell.name, startT = os.clock(), endT = os.clock() + 1, startPos = startPos, endPos = endPos}
                    table.insert(self.activespells, data)
                    self:TriggerCallbacks(data.unit, data)
                end
            end
        end
    end
end

function AntiGapcloser:OnTick()
    for i = #self.activespells, 1, -1 do
        if self.activespells[i].endT - os.clock() > 0 then
            self:TriggerCallbacks(self.activespells[i].unit, self.activespells[i])
        else
            table.remove(self.activespells, i)
        end
    end
end

--[[

.|''''|,        '||     '||      ||`         '||` '||                       '||\   /||`                                               
||    ||         ||      ||      ||           ||   ||                        ||\\.//||                                                
||    || '||''|  ||''|,  ||  /\  ||   '''|.   ||   || //`  .|''|, '||''|     ||     ||   '''|.  `||''|,   '''|.  .|''|, .|''|, '||''| 
||    ||  ||     ||  ||   \\//\\//   .|''||   ||   ||<<    ||..||  ||        ||     ||  .|''||   ||  ||  .|''||  ||  || ||..||  ||    
`|....|' .||.   .||..|'    \/  \/    `|..||. .||. .|| \\.  `|...  .||.      .||     ||. `|..||. .||  ||. `|..||. `|..|| `|...  .||.   
                                                                                                                     ||               
                                                                                                                  `..|'       

	OrbWalkManager - Simle orbwalker controler
]]
class('OrbWalkManager')
function OrbWalkManager:__init(ScriptName)
	self.ScriptName = ScriptName or "[SourceLib] OrbWalkManager"
	self.MMALoad = false
	self.SacLoad = false
	self.orbload = false
	self.SOWLoad = false
	self.RebornLoad = false
	self.RevampedLoaded = false
	
	self.BaseWindUpTime = 3
    self.BaseAnimationTime = 0.665
	self.DataUpdated = false
	self.AA = {LastTime = 0, LastTarget = nil, IsAttacking = false, Object = nil}
	
	self.NoAttacks = { 
        jarvanivcataclysmattack = true, 
        monkeykingdoubleattack = true, 
        shyvanadoubleattack = true, 
        shyvanadoubleattackdragon = true, 
        zyragraspingplantattack = true, 
        zyragraspingplantattack2 = true, 
        zyragraspingplantattackfire = true, 
        zyragraspingplantattack2fire = true, 
        viktorpowertransfer = true, 
        sivirwattackbounce = true,
    }
    self.Attacks = {
        caitlynheadshotmissile = true, 
        frostarrow = true, 
        garenslash2 = true, 
        kennenmegaproc = true, 
        lucianpassiveattack = true, 
        masteryidoublestrike = true, 
        quinnwenhanced = true, 
        renektonexecute = true, 
        renektonsuperexecute = true, 
        rengarnewpassivebuffdash = true, 
        trundleq = true, 
        xenzhaothrust = true, 
        xenzhaothrust2 = true, 
        xenzhaothrust3 = true, 
        viktorqbuff = true,
    }
	
	self.LoadOrbwalk = "Not Detected"
	self.SOW = nil
	
	self:OnOrbLoad()
	
	--[[
	if AddProcessAttackCallback then
        AddProcessAttackCallback(function(unit, spell) self:OnProcessAttack(unit, spell) end)
    end
	
	AddCreateObjCallback(
        function(obj)
            if obj ~= nil and self.AA.Object == nil and tostring(obj.name):lower() == "missile" and self:GetTime() - self.AA.LastTime + self:Latency() < 1.2 * self:WindUpTime() and obj.spellOwner ~= nil and obj.spellName ~= nil and obj.spellOwner.isMe and self:IsAutoAttack(obj.spellName) then
                self.AA.Object = obj
            end
        end
    )

    AddDeleteObjCallback(
        function(obj)
            if obj and self.AA.Object ~= nil and obj.networkID == self.AA.Object.networkID then
                self.AA.Object = nil
            end
        end
    )
	]]
end

function OrbWalkManager:AddToMenu(m)
	self.Config = m or scriptConfig("[SourceLibk]OrbWalkManager", "srcOrbWalker")
		self.Config:addParam("Combo", "Combo", SCRIPT_PARAM_LIST, 1, {"OrbWalkKey", "CustomKey","OFF"})
		self.Config:addParam("ComboCustomKey", "Combo custom key", SCRIPT_PARAM_ONKEYDOWN, false, 32)
		self.Config:addParam("Harass", "Harass", SCRIPT_PARAM_LIST, 1, {"OrbWalkKey", "CustomKey","OFF"})
		self.Config:addParam("HarassCustomKey", "Harass custom key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
		self.Config:addParam("LastHit", "LastHit", SCRIPT_PARAM_LIST, 1, {"OrbWalkKey", "CustomKey","OFF"})
		self.Config:addParam("LastHitCustomKey", "LastHit custom key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
		self.Config:addParam("Clear", "Clear", SCRIPT_PARAM_LIST, 1, {"OrbWalkKey", "CustomKey","OFF"})
		self.Config:addParam("ClearCustomKey", "Clear custom key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
		self.Config:addParam("OrbWalk", "Loaded OrbWalk", SCRIPT_PARAM_INFO, self.LoadOrbwalk.." Load")
end

function OrbWalkManager:IsAutoAttack(name)
    return name and ((tostring(name):lower():find("attack") and not self.NoAttacks[tostring(name):lower()]) or self.Attacks[tostring(name):lower()])
end

function OrbWalkManager:OnOrbLoad()
	if _G.MMA_IsLoaded then
		self:print("MMA LOAD")
		self.MMALoad = true
		self.orbload = true
		self.LoadOrbwalk = "MMA"
	elseif _G.AutoCarry then
		if _G.AutoCarry.Helper then
			self:print("SIDA AUTO CARRY: REBORN LOAD")
			self.RebornLoad = true
			self.orbload = true
		else
			self:print("SIDA AUTO CARRY: REVAMPED LOAD")
			self.RevampedLoaded = true
			self.orbload = true
		end
	elseif _G.Reborn_Loaded then
		self.SacLoad = true
		self.LoadOrbwalk = "SAC"
		DelayAction(function() self:OnOrbLoad() end, 1)
	else
        --self.VP = nil
        if _G.srcLib.VP then
            --self.VP = _G.srcLib.VP
        else
            require('VPrediction')
            _G.srcLib.VP = VPrediction()
        end
        self.SOWLoad = true
        self.SOW = SOW(_G.srcLib.VP)
        self.SOW:AddToMenu()
        self.LoadOrbwalk = "SOW"
        self.orbload = true
	end
end

function OrbWalkManager:print(msg)
	print("<font color=\"#6699ff\"><b>" .. self.ScriptName .. ":</b></font> <font color=\"#FFFFFF\">"..msg..".</font>")
end

function OrbWalkManager:IsComboMode()
	if not self.orbload then return end
	if(self.Config.Combo == 1) then
		if self.SacLoad then
			if _G.AutoCarry.Keys.AutoCarry then
				return true
			end
		elseif self.SOWLoad then
			if self.SOW:GetActiveMode() == "Combo" then
				return true
			end
		elseif self.MMALoad then
			if _G.MMA_IsOrbwalking() then
				return true
			end
		end
	elseif(self.Config.Combo == 2) then
		return self.Config.ComboCustomKey
	else
		return false
	end
    return false
end

function OrbWalkManager:IsHarassMode()
	if not self.orbload then return end
	if(self.Config.Harass == 1) then
		if self.SacLoad then
			if _G.AutoCarry.Keys.MixedMode then
				return true
			end
		elseif self.SOWLoad then
            if self.SOW:GetActiveMode() == "Harass" then
                return true
            end
		elseif self.MMALoad then
			if _G.MMA_IsDualCarrying() then
				return true
			end
		end
	elseif (self.Config.Harass == 2) then
		return self.Config.HarassCustomKey
	else
		return false
	end
    return false
end

function OrbWalkManager:IsClearMode()
	if not self.orbload then return end
	if(self.Config.Clear == 1) then
		if self.SacLoad then
			if _G.AutoCarry.Keys.LaneClear then
				return true
			end
		elseif self.SOWLoad then
			if self.SOW:GetActiveMode() == "Clear" then
				return true
			end
		elseif self.MMALoad then
			if _G.MMA_IsLaneClearing() then
				return true
			end
		end
	elseif(self.Config.Clear ==2) then
		return self.Config.ClearCustomKey
	else
		return false
	end
    return false
end

function OrbWalkManager:IsLastHitMode()
	if not self.orbload then return end
	if(self.Config.LastHit == 1) then
		if self.SacLoad then
			if _G.AutoCarry.Keys.LastHit then
				return true
			end
		elseif self.SOWLoad then
			if self.SOW:GetActiveMode() == "LastHit" then
				return true
			end
		elseif self.MMALoad then
			if _G.MMA_IsLastHitting() then
				return true
			end
		end
	elseif(self.Config.LastHit ==2) then
		return self.Config.LastHitCustomKey;
	else
		return false
	end
    return false
end

function OrbWalkManager:SetMove(bool)
    if not self.orbload then return end
    if bool then
        if self.MMALoad then
		    _G.MMA_AvoidMovement(false)
	    elseif self.SacLoad then
		    _G.AutoCarry.MyHero:MovementEnabled(true)
	    elseif self.SOWLoad then
            self.SOW.Move = true
	    end
    else
        if self.MMALoad then
		    _G.MMA_AvoidMovement(true)
	    elseif self.SacLoad then
		    _G.AutoCarry.MyHero:MovementEnabled(false)
	    elseif self.SOWLoad then
            self.SOW.Move = false
	    end
    end
end

function OrbWalkManager:SetAttack(bool)
    if not self.orbload then return end
    if bool then
        if self.MMALoad then
		_G.MMA_StopAttacks(false)
	    elseif self.SacLoad then
		    G.AutoCarry.MyHero:AttacksEnabled(true)
	    elseif self.SOWLoad then
            self.SOW:EnableAttacks()
	    end
    else
        if self.MMALoad then
		    _G.MMA_StopAttacks(true)
	    elseif self.SacLoad then
		     _G.AutoCarry.MyHero:AttacksEnabled(false)
	    elseif self.SOWLoad then
            self.SOW:DisableAttacks()
	    end
    end
end

function OrbWalkManager:ResetAA()
	if not self.orbload then return end
	self.AA.LastTime = self:GetTime() + self:Latency() - self:AnimationTime()
    if self.SacLoad then
        _G.AutoCarry.Orbwalker:ResetAttackTimer()
    elseif self.SOWLoad then
        self.SOW:ResetAA()
    elseif self.MMALoad then
        _G.MMA_ResetAutoAttack()
    end
end

function OrbWalkManager:CanAttack()
	if not self.orbload then return end
    if self.SacLoad  then
        return _G.AutoCarry.Orbwalker:CanShoot()
    elseif self.SOWLoad then
        self.SOW:CanAttack()
    elseif self.NOLLoad then
        return self.NOLTimeToAttack()
    end
    return self:_CanAttack()
end

function  OrbWalkManager:_CanAttack()
    return self:GetTime() - self.AA.LastTime + self:Latency() >= 1 * self:AnimationTime() - 25/1000 and not IsEvading()
end

function OrbWalkManager:OnProcessAttack(unit, spell)
    if unit and spell and unit.isMe and spell.name then
        if self:IsAutoAttack(spell.name) then
            if not self.DataUpdated then
                self.BaseAnimationTime = 1 / (spell.animationTime * myHero.attackSpeed)
                self.BaseWindUpTime = 1 / (spell.windUpTime * myHero.attackSpeed)
                self.DataUpdated = true
            end
            self.AA.LastTarget = spell.target
            self.AA.IsAttacking = false
            self.AA.LastTime = self:GetTime() - self:Latency() - self:WindUpTime()
        end
    end
end

function OrbWalkManager:GetTime()
    return 1 * os.clock()
end

function OrbWalkManager:Latency()
    return GetLatency() / 2000
end

function OrbWalkManager:WindUpTime()
    return (1 / (myHero.attackSpeed * self.BaseWindUpTime))
end

function OrbWalkManager:AnimationTime()
    return (1 / (myHero.attackSpeed * self.BaseAnimationTime))
end

--[[
	.|'''',        '||` '||`                                 
	||              ||   ||   ''         ''                  
	||      .|''|,  ||   ||   ||  (''''  ||  .|''|, `||''|,  
	||      ||  ||  ||   ||   ||   `'')  ||  ||  ||  ||  ||  
	`|....' `|..|' .||. .||. .||. `...' .||. `|..|' .||  ||. 
															 
	collision -- easy check
	
	Function:
		Collision(range, speed, delay, width)
	
	Methods:
		Collision:GetMinionCollision(start, end)
		Collision:GetHeroCollision(start, end)
		Collision:GetCollision(start, end)
		Collision:DrawCollision()
]]
class('Collision')
HERO_ALL = 1
HERO_ENEMY = 2
HERO_ALLY = 3


function Collision:__init(sRange, projSpeed, sDelay, sWidth)
	uniqueId = uniqueId + 1
	self.uniqueId = uniqueId

	self.sRange = sRange
	self.projSpeed = projSpeed
	self.sDelay = sDelay
	self.sWidth = sWidth/2

	self.enemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
	self.minionupdate = 0
end

function Collision:GetMinionCollision(pStart, pEnd)
	self.enemyMinions:update()

	local distance =  GetDistance(pStart, pEnd)
	local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
	local mCollision = {}

	if distance > self.sRange then
		distance = self.sRange
	end

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
   
	local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

	 for index, minion in pairs(self.enemyMinions.objects) do
		if minion ~= nil and minion.valid and not minion.dead then
			if GetDistance(pStart, minion) < distance then
				local pos, t, vec = prediction:GetPrediction(minion)
				local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
				local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
				local toScreen, toPoint
				if pos ~= nil then
					toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
					toPoint = Point(toScreen.x, toScreen.y)
				else
					toScreen = WorldToScreen(D3DXVECTOR3(minion.x, minion.y, minion.z))
					toPoint = Point(toScreen.x, toScreen.y)
				end


				if poly:contains(toPoint) then
					table.insert(mCollision, minion)
				else
					if pos ~= nil then
						distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
						distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
					else
						distance1 = Point(minion.x, minion.z):distance(lineSegmentLeft)
						distance2 = Point(minion.x, minion.z):distance(lineSegmentRight)
					end
					if (distance1 < (getHitBoxRadius(minion)*2+10) or distance2 < (getHitBoxRadius(minion) *2+10)) then
						table.insert(mCollision, minion)
					end
				end
			end
		end
	end
	if #mCollision > 0 then return true, mCollision else return false, mCollision end
end

function Collision:GetHeroCollision(pStart, pEnd, mode)
	if mode == nil then mode = HERO_ENEMY end
	local heros = {}

	for i = 1, heroManager.iCount do
		local hero = heroManager:GetHero(i)
		if (mode == HERO_ENEMY or mode == HERO_ALL) and hero.team ~= myHero.team then
			table.insert(heros, hero)
		elseif (mode == HERO_ALLY or mode == HERO_ALL) and hero.team == myHero.team and not hero.isMe then
			table.insert(heros, hero)
		end
	end

	local distance =  GetDistance(pStart, pEnd)
	local prediction = TargetPredictionVIP(self.sRange, self.projSpeed, self.sDelay, self.sWidth)
	local hCollision = {}

	if distance > self.sRange then
		distance = self.sRange
	end

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))
   
	local poly = Polygon(Point(startLeft.x, startLeft.y),  Point(endLeft.x, endLeft.y), Point(startRight.x, startRight.y),   Point(endRight.x, endRight.y))

	for index, hero in pairs(heros) do
		if hero ~= nil and hero.valid and not hero.dead then
			if GetDistance(pStart, hero) < distance then
				local pos, t, vec = prediction:GetPrediction(hero)
				local lineSegmentLeft = LineSegment(Point(startLeftX,startLeftZ), Point(endLeftX, endLeftZ))
				local lineSegmentRight = LineSegment(Point(startRightX,startRightZ), Point(endRightX, endRightZ))
				local toScreen, toPoint
				if pos ~= nil then
					toScreen = WorldToScreen(D3DXVECTOR3(pos.x, hero.y, pos.z))
					toPoint = Point(toScreen.x, toScreen.y)
				else
					toScreen = WorldToScreen(D3DXVECTOR3(hero.x, hero.y, hero.z))
					toPoint = Point(toScreen.x, toScreen.y)
				end


				if poly:contains(toPoint) then
					table.insert(hCollision, hero)
				else
					if pos ~= nil then
						distance1 = Point(pos.x, pos.z):distance(lineSegmentLeft)
						distance2 = Point(pos.x, pos.z):distance(lineSegmentRight)
					else
						distance1 = Point(hero.x, hero.z):distance(lineSegmentLeft)
						distance2 = Point(hero.x, hero.z):distance(lineSegmentRight)
					end
					if (distance1 < (getHitBoxRadius(hero)*2+10) or distance2 < (getHitBoxRadius(hero) *2+10)) then
						table.insert(hCollision, hero)
					end
				end
			end
		end
	end
	if #hCollision > 0 then return true, hCollision else return false, hCollision end
end

function Collision:GetCollision(pStart, pEnd)
	local b , minions = self:GetMinionCollision(pStart, pEnd)
	local t , heros = self:GetHeroCollision(pStart, pEnd, HERO_ENEMY)

	if not b then return t, heros end
	if not t then return b, minions end

	local all = {}

	for index, hero in pairs(heros) do
		table.insert(all, hero)
	end

	for index, minion in pairs(minions) do
		table.insert(all, minion)
	end

	return true, all
end

function Collision:DrawCollision(pStart, pEnd)
   
	local distance =  GetDistance(pStart, pEnd)

	if distance > self.sRange then
		distance = self.sRange
	end

	local color = 4294967295

	local V = Vector(pEnd) - Vector(pStart)
	local k = V:normalized()
	local P = V:perpendicular2():normalized()

	local t,i,u = k:unpack()
	local x,y,z = P:unpack()

	local startLeftX = pStart.x + (x *self.sWidth)
	local startLeftY = pStart.y + (y *self.sWidth)
	local startLeftZ = pStart.z + (z *self.sWidth)
	local endLeftX = pStart.x + (x * self.sWidth) + (t * distance)
	local endLeftY = pStart.y + (y * self.sWidth) + (i * distance)
	local endLeftZ = pStart.z + (z * self.sWidth) + (u * distance)
   
	local startRightX = pStart.x - (x * self.sWidth)
	local startRightY = pStart.y - (y * self.sWidth)
	local startRightZ = pStart.z - (z * self.sWidth)
	local endRightX = pStart.x - (x * self.sWidth) + (t * distance)
	local endRightY = pStart.y - (y * self.sWidth) + (i * distance)
	local endRightZ = pStart.z - (z * self.sWidth)+ (u * distance)

	local startLeft = WorldToScreen(D3DXVECTOR3(startLeftX, startLeftY, startLeftZ))
	local endLeft = WorldToScreen(D3DXVECTOR3(endLeftX, endLeftY, endLeftZ))
	local startRight = WorldToScreen(D3DXVECTOR3(startRightX, startRightY, startRightZ))
	local endRight = WorldToScreen(D3DXVECTOR3(endRightX, endRightY, endRightZ))

	local colliton, objects = self:GetCollision(pStart, pEnd)
   
	if colliton then
		color = 4294901760
	end

	for i, object in pairs(objects) do
		DrawCircle(object.x,object.y,object.z,getHitBoxRadius(object)*2+20,4294901760)
	end

	DrawLine(startLeft.x, startLeft.y, endLeft.x, endLeft.y, 1, color)
	DrawLine(startRight.x, startRight.y, endRight.x, endRight.y, 1, color)

end

function getHitBoxRadius(target)
	return GetDistance(target, target.minBBox)/2
end

--[[
.|'''',         '||` '||` '||'''|,                '||         '||\   /||`                                               
||               ||   ||   ||   ||                 ||          ||\\.//||                                                
||       '''|.   ||   ||   ||;;;;    '''|.  .|'',  || //`      ||     ||   '''|.  `||''|,   '''|.  .|''|, .|''|, '||''| 
||      .|''||   ||   ||   ||   ||  .|''||  ||     ||<<        ||     ||  .|''||   ||  ||  .|''||  ||  || ||..||  ||    
`|....' `|..||. .||. .||. .||...|'  `|..||. `|..' .|| \\.     .||     ||. `|..||. .||  ||. `|..||. `|..|| `|...  .||.   
                                                                                                       ||               
                                                                                                    `..|'               

	CallBackManager -- handle callback better now
		
	Function:
		CallBackManager()
	
	Methods:
		CallBackManager:Tick(func)
		CallBackManager:Draw(func)
		CallBackManager:ApplyBuff(func)
		CallBackManager:UpdateBuff(func)
		CallBackManager:RemoveBuff(func)
		CallBackManager:CreateObj(func)
		CallBackManager:RemoveObj(func)
		CallBackManager:Msg(func)
		CallBackManager:ProcessSpell(func)
		CallBackManager:CastSpell(func)
]]
class 'CallBackManager'
function CallBackManager:__init()
end

function CallBackManager:Tick(func)
	assert(func and type(func) == "function", "CallBackManager() : Tick(func) : function is invalid (not function)" )
	AddTickCallback(func)
end

function CallBackManager:Draw(func)
	assert(func and type(func) == "function", "CallBackManager() : Draw(func) : function is invalid (not function)" )
	AddDrawCallback(func)
end

function CallBackManager:ApplyBuff(func)
	assert(func and type(func) == "function", "CallBackManager() : ApplyBuff(func) : function is invalid (not function)" )
	AddApplyBuffCallback(func)
end

function CallBackManager:UpdateBuff(func)
	assert(func and type(func) == "function", "CallBackManager() : UpdateBuff(func) : function is invalid (not function)" )
	AddUpdateBuffCallback(func)
end

function CallBackManager:RemoveBuff(func)
	assert(func and type(func) == "function", "CallBackManager() : RemoveBuff(func) : function is invalid (not function)" )
	AddRemoveBuffCallback(func)
end

function CallBackManager:CreateObj(func)
	assert(func and type(func) == "function", "CallBackManager() : CreateObj(func) : function is invalid (not function)" )
	AddCreateObjCallback(func)
end

function CallBackManager:DeleteObj(func)
	assert(func and type(func) == "function", "CallBackManager() : RemoveObj(func) : function is invalid (not function)" )
	AddDeleteObjCallback(func)
end

function CallBackManager:Msg(func)
	assert(func and type(func) == "function", "CallBackManager() : Msg(func) : function is invalid (not function)" )
	AddMsgObjCallback(func)
end

function CallBackManager:ProcessSpell(func)
	assert(func and type(func) == "function", "CallBackManager() : ProcessSpell(func) : function is invalid (not function)" )
	AddProcessSpellCallback(func)
end

function CallBackManager:CastSpell(func)
	assert(func and type(func) == "function", "CallBackManager() : CastSpell(func) : function is invalid (not function)" )
	AddCastSpellCallback(func)
end

--[[

|''||''|  ||          '||      '||'       ||              ||    .                   
   ||    ...    ....   ||  ..   ||       ...  .. .. ..   ...  .||.    ....  ... ..  
   ||     ||  .|   ''  || .'    ||        ||   || || ||   ||   ||   .|...||  ||' '' 
   ||     ||  ||       ||'|.    ||        ||   || || ||   ||   ||   ||       ||     
  .||.   .||.  '|...' .||. ||. .||.....| .||. .|| || ||. .||.  '|.'  '|...' .||.    

    TickLimiter - Because potato computers also use SourceLib

    Functions:
        TickLimiter(func, frequency)

]]
class 'TickLimiter'

--[[
    Starts TickLimiter instance

    @param func       | function | The function to be called
    @param frequency  | integer  | The times the function will called per second.
]]
function TickLimiter:__init(func, frequency)

    assert(frequency and frequency > 0, "TickLimiter: frecuency is invalid!")
    assert(func and type(func) == "function", "TickLimiter: func is invalid!")

    self.lasttick = 0
    self.interval = 1 / frequency

    self.func = func
    AddTickCallback(function() self:OnTick() end)

end

--[[
    Internal callback
]]
function TickLimiter:OnTick()

    if os.clock() - self.lasttick >= self.interval then
        self.func()
        self.lasttick = os.clock()
    end

end

class "SOW"
function SOW:__init(VP)
	_G.SOWLoaded = true
    self.projectilespeeds = {["Velkoz"]= 2000,["TeemoMushroom"] = math.huge,["TestCubeRender"] = math.huge ,["Xerath"] = 2000.0000 ,["Kassadin"] = math.huge ,["Rengar"] = math.huge ,["Thresh"] = 1000.0000 ,["Ziggs"] = 1500.0000 ,["ZyraPassive"] = 1500.0000 ,["ZyraThornPlant"] = 1500.0000 ,["KogMaw"] = 1800.0000 ,["HeimerTBlue"] = 1599.3999 ,["EliseSpider"] = 500.0000 ,["Skarner"] = 500.0000 ,["ChaosNexus"] = 500.0000 ,["Katarina"] = 467.0000 ,["Riven"] = 347.79999 ,["SightWard"] = 347.79999 ,["HeimerTYellow"] = 1599.3999 ,["Ashe"] = 2000.0000 ,["VisionWard"] = 2000.0000 ,["TT_NGolem2"] = math.huge ,["ThreshLantern"] = math.huge ,["TT_Spiderboss"] = math.huge ,["OrderNexus"] = math.huge ,["Soraka"] = 1000.0000 ,["Jinx"] = 2750.0000 ,["TestCubeRenderwCollision"] = 2750.0000 ,["Red_Minion_Wizard"] = 650.0000 ,["JarvanIV"] = 20.0000 ,["Blue_Minion_Wizard"] = 650.0000 ,["TT_ChaosTurret2"] = 1200.0000 ,["TT_ChaosTurret3"] = 1200.0000 ,["TT_ChaosTurret1"] = 1200.0000 ,["ChaosTurretGiant"] = 1200.0000 ,["Dragon"] = 1200.0000 ,["LuluSnowman"] = 1200.0000 ,["Worm"] = 1200.0000 ,["ChaosTurretWorm"] = 1200.0000 ,["TT_ChaosInhibitor"] = 1200.0000 ,["ChaosTurretNormal"] = 1200.0000 ,["AncientGolem"] = 500.0000 ,["ZyraGraspingPlant"] = 500.0000 ,["HA_AP_OrderTurret3"] = 1200.0000 ,["HA_AP_OrderTurret2"] = 1200.0000 ,["Tryndamere"] = 347.79999 ,["OrderTurretNormal2"] = 1200.0000 ,["Singed"] = 700.0000 ,["OrderInhibitor"] = 700.0000 ,["Diana"] = 347.79999 ,["HA_FB_HealthRelic"] = 347.79999 ,["TT_OrderInhibitor"] = 347.79999 ,["GreatWraith"] = 750.0000 ,["Yasuo"] = 347.79999 ,["OrderTurretDragon"] = 1200.0000 ,["OrderTurretNormal"] = 1200.0000 ,["LizardElder"] = 500.0000 ,["HA_AP_ChaosTurret"] = 1200.0000 ,["Ahri"] = 1750.0000 ,["Lulu"] = 1450.0000 ,["ChaosInhibitor"] = 1450.0000 ,["HA_AP_ChaosTurret3"] = 1200.0000 ,["HA_AP_ChaosTurret2"] = 1200.0000 ,["ChaosTurretWorm2"] = 1200.0000 ,["TT_OrderTurret1"] = 1200.0000 ,["TT_OrderTurret2"] = 1200.0000 ,["TT_OrderTurret3"] = 1200.0000 ,["LuluFaerie"] = 1200.0000 ,["HA_AP_OrderTurret"] = 1200.0000 ,["OrderTurretAngel"] = 1200.0000 ,["YellowTrinketUpgrade"] = 1200.0000 ,["MasterYi"] = math.huge ,["Lissandra"] = 2000.0000 ,["ARAMOrderTurretNexus"] = 1200.0000 ,["Draven"] = 1700.0000 ,["FiddleSticks"] = 1750.0000 ,["SmallGolem"] = math.huge ,["ARAMOrderTurretFront"] = 1200.0000 ,["ChaosTurretTutorial"] = 1200.0000 ,["NasusUlt"] = 1200.0000 ,["Maokai"] = math.huge ,["Wraith"] = 750.0000 ,["Wolf"] = math.huge ,["Sivir"] = 1750.0000 ,["Corki"] = 2000.0000 ,["Janna"] = 1200.0000 ,["Nasus"] = math.huge ,["Golem"] = math.huge ,["ARAMChaosTurretFront"] = 1200.0000 ,["ARAMOrderTurretInhib"] = 1200.0000 ,["LeeSin"] = math.huge ,["HA_AP_ChaosTurretTutorial"] = 1200.0000 ,["GiantWolf"] = math.huge ,["HA_AP_OrderTurretTutorial"] = 1200.0000 ,["YoungLizard"] = 750.0000 ,["Jax"] = 400.0000 ,["LesserWraith"] = math.huge ,["Blitzcrank"] = math.huge ,["ARAMChaosTurretInhib"] = 1200.0000 ,["Shen"] = 400.0000 ,["Nocturne"] = math.huge ,["Sona"] = 1500.0000 ,["ARAMChaosTurretNexus"] = 1200.0000 ,["YellowTrinket"] = 1200.0000 ,["OrderTurretTutorial"] = 1200.0000 ,["Caitlyn"] = 2500.0000 ,["Trundle"] = 347.79999 ,["Malphite"] = 1000.0000 ,["Mordekaiser"] = math.huge ,["ZyraSeed"] = math.huge ,["Vi"] = 1000.0000 ,["Tutorial_Red_Minion_Wizard"] = 650.0000 ,["Renekton"] = math.huge ,["Anivia"] = 1400.0000 ,["Fizz"] = math.huge ,["Heimerdinger"] = 1500.0000 ,["Evelynn"] = 467.0000 ,["Rumble"] = 347.79999 ,["Leblanc"] = 1700.0000 ,["Darius"] = math.huge ,["OlafAxe"] = math.huge ,["Viktor"] = 2300.0000 ,["XinZhao"] = 20.0000 ,["Orianna"] = 1450.0000 ,["Vladimir"] = 1400.0000 ,["Nidalee"] = 1750.0000 ,["Tutorial_Red_Minion_Basic"] = math.huge ,["ZedShadow"] = 467.0000 ,["Syndra"] = 1800.0000 ,["Zac"] = 1000.0000 ,["Olaf"] = 347.79999 ,["Veigar"] = 1100.0000 ,["Twitch"] = 2500.0000 ,["Alistar"] = math.huge ,["Akali"] = 467.0000 ,["Urgot"] = 1300.0000 ,["Leona"] = 347.79999 ,["Talon"] = math.huge ,["Karma"] = 1500.0000 ,["Jayce"] = 347.79999 ,["Galio"] = 1000.0000 ,["Shaco"] = math.huge ,["Taric"] = math.huge ,["TwistedFate"] = 1500.0000 ,["Varus"] = 2000.0000 ,["Garen"] = 347.79999 ,["Swain"] = 1600.0000 ,["Vayne"] = 2000.0000 ,["Fiora"] = 467.0000 ,["Quinn"] = 2000.0000 ,["Kayle"] = math.huge ,["Blue_Minion_Basic"] = math.huge ,["Brand"] = 2000.0000 ,["Teemo"] = 1300.0000 ,["Amumu"] = 500.0000 ,["Annie"] = 1200.0000 ,["Odin_Blue_Minion_caster"] = 1200.0000 ,["Elise"] = 1600.0000 ,["Nami"] = 1500.0000 ,["Poppy"] = 500.0000 ,["AniviaEgg"] = 500.0000 ,["Tristana"] = 2250.0000 ,["Graves"] = 3000.0000 ,["Morgana"] = 1600.0000 ,["Gragas"] = math.huge ,["MissFortune"] = 2000.0000 ,["Warwick"] = math.huge ,["Cassiopeia"] = 1200.0000 ,["Tutorial_Blue_Minion_Wizard"] = 650.0000 ,["DrMundo"] = math.huge ,["Volibear"] = 467.0000 ,["Irelia"] = 467.0000 ,["Odin_Red_Minion_Caster"] = 650.0000 ,["Lucian"] = 2800.0000 ,["Yorick"] = math.huge ,["RammusPB"] = math.huge ,["Red_Minion_Basic"] = math.huge ,["Udyr"] = 467.0000 ,["MonkeyKing"] = 20.0000 ,["Tutorial_Blue_Minion_Basic"] = math.huge ,["Kennen"] = 1600.0000 ,["Nunu"] = 500.0000 ,["Ryze"] = 2400.0000 ,["Zed"] = 467.0000 ,["Nautilus"] = 1000.0000 ,["Gangplank"] = 1000.0000 ,["Lux"] = 1600.0000 ,["Sejuani"] = 500.0000 ,["Ezreal"] = 2000.0000 ,["OdinNeutralGuardian"] = 1800.0000 ,["Khazix"] = 500.0000 ,["Sion"] = math.huge ,["Aatrox"] = 347.79999 ,["Hecarim"] = 500.0000 ,["Pantheon"] = 20.0000 ,["Shyvana"] = 467.0000 ,["Zyra"] = 1700.0000 ,["Karthus"] = 1200.0000 ,["Rammus"] = math.huge ,["Zilean"] = 1200.0000 ,["Chogath"] = 500.0000 ,["Malzahar"] = 2000.0000 ,["YorickRavenousGhoul"] = 347.79999 ,["YorickSpectralGhoul"] = 347.79999 ,["JinxMine"] = 347.79999 ,["YorickDecayedGhoul"] = 347.79999 ,["XerathArcaneBarrageLauncher"] = 347.79999 ,["Odin_SOG_Order_Crystal"] = 347.79999 ,["TestCube"] = 347.79999 ,["ShyvanaDragon"] = math.huge ,["FizzBait"] = math.huge ,["Blue_Minion_MechMelee"] = math.huge ,["OdinQuestBuff"] = math.huge ,["TT_Buffplat_L"] = math.huge ,["TT_Buffplat_R"] = math.huge ,["KogMawDead"] = math.huge ,["TempMovableChar"] = math.huge ,["Lizard"] = 500.0000 ,["GolemOdin"] = math.huge ,["OdinOpeningBarrier"] = math.huge ,["TT_ChaosTurret4"] = 500.0000 ,["TT_Flytrap_A"] = 500.0000 ,["TT_NWolf"] = math.huge ,["OdinShieldRelic"] = math.huge ,["LuluSquill"] = math.huge ,["redDragon"] = math.huge ,["MonkeyKingClone"] = math.huge ,["Odin_skeleton"] = math.huge ,["OdinChaosTurretShrine"] = 500.0000 ,["Cassiopeia_Death"] = 500.0000 ,["OdinCenterRelic"] = 500.0000 ,["OdinRedSuperminion"] = math.huge ,["JarvanIVWall"] = math.huge ,["ARAMOrderNexus"] = math.huge ,["Red_Minion_MechCannon"] = 1200.0000 ,["OdinBlueSuperminion"] = math.huge ,["SyndraOrbs"] = math.huge ,["LuluKitty"] = math.huge ,["SwainNoBird"] = math.huge ,["LuluLadybug"] = math.huge ,["CaitlynTrap"] = math.huge ,["TT_Shroom_A"] = math.huge ,["ARAMChaosTurretShrine"] = 500.0000 ,["Odin_Windmill_Propellers"] = 500.0000 ,["TT_NWolf2"] = math.huge ,["OdinMinionGraveyardPortal"] = math.huge ,["SwainBeam"] = math.huge ,["Summoner_Rider_Order"] = math.huge ,["TT_Relic"] = math.huge ,["odin_lifts_crystal"] = math.huge ,["OdinOrderTurretShrine"] = 500.0000 ,["SpellBook1"] = 500.0000 ,["Blue_Minion_MechCannon"] = 1200.0000 ,["TT_ChaosInhibitor_D"] = 1200.0000 ,["Odin_SoG_Chaos"] = 1200.0000 ,["TrundleWall"] = 1200.0000 ,["HA_AP_HealthRelic"] = 1200.0000 ,["OrderTurretShrine"] = 500.0000 ,["OriannaBall"] = 500.0000 ,["ChaosTurretShrine"] = 500.0000 ,["LuluCupcake"] = 500.0000 ,["HA_AP_ChaosTurretShrine"] = 500.0000 ,["TT_NWraith2"] = 750.0000 ,["TT_Tree_A"] = 750.0000 ,["SummonerBeacon"] = 750.0000 ,["Odin_Drill"] = 750.0000 ,["TT_NGolem"] = math.huge ,["AramSpeedShrine"] = math.huge ,["OriannaNoBall"] = math.huge ,["Odin_Minecart"] = math.huge ,["Summoner_Rider_Chaos"] = math.huge ,["OdinSpeedShrine"] = math.huge ,["TT_SpeedShrine"] = math.huge ,["odin_lifts_buckets"] = math.huge ,["OdinRockSaw"] = math.huge ,["OdinMinionSpawnPortal"] = math.huge ,["SyndraSphere"] = math.huge ,["Red_Minion_MechMelee"] = math.huge ,["SwainRaven"] = math.huge ,["crystal_platform"] = math.huge ,["MaokaiSproutling"] = math.huge ,["Urf"] = math.huge ,["TestCubeRender10Vision"] = math.huge ,["MalzaharVoidling"] = 500.0000 ,["GhostWard"] = 500.0000 ,["MonkeyKingFlying"] = 500.0000 ,["LuluPig"] = 500.0000 ,["AniviaIceBlock"] = 500.0000 ,["TT_OrderInhibitor_D"] = 500.0000 ,["Odin_SoG_Order"] = 500.0000 ,["RammusDBC"] = 500.0000 ,["FizzShark"] = 500.0000 ,["LuluDragon"] = 500.0000 ,["OdinTestCubeRender"] = 500.0000 ,["TT_Tree1"] = 500.0000 ,["ARAMOrderTurretShrine"] = 500.0000 ,["Odin_Windmill_Gears"] = 500.0000 ,["ARAMChaosNexus"] = 500.0000 ,["TT_NWraith"] = 750.0000 ,["TT_OrderTurret4"] = 500.0000 ,["Odin_SOG_Chaos_Crystal"] = 500.0000 ,["OdinQuestIndicator"] = 500.0000 ,["JarvanIVStandard"] = 500.0000 ,["TT_DummyPusher"] = 500.0000 ,["OdinClaw"] = 500.0000 ,["EliseSpiderling"] = 2000.0000 ,["QuinnValor"] = math.huge ,["UdyrTigerUlt"] = math.huge ,["UdyrTurtleUlt"] = math.huge ,["UdyrUlt"] = math.huge ,["UdyrPhoenixUlt"] = math.huge ,["ShacoBox"] = 1500.0000 ,["HA_AP_Poro"] = 1500.0000 ,["AnnieTibbers"] = math.huge ,["UdyrPhoenix"] = math.huge ,["UdyrTurtle"] = math.huge ,["UdyrTiger"] = math.huge ,["HA_AP_OrderShrineTurret"] = 500.0000 ,["HA_AP_Chains_Long"] = 500.0000 ,["HA_AP_BridgeLaneStatue"] = 500.0000 ,["HA_AP_ChaosTurretRubble"] = 500.0000 ,["HA_AP_PoroSpawner"] = 500.0000 ,["HA_AP_Cutaway"] = 500.0000 ,["HA_AP_Chains"] = 500.0000 ,["ChaosInhibitor_D"] = 500.0000 ,["ZacRebirthBloblet"] = 500.0000 ,["OrderInhibitor_D"] = 500.0000 ,["Nidalee_Spear"] = 500.0000 ,["Nidalee_Cougar"] = 500.0000 ,["TT_Buffplat_Chain"] = 500.0000 ,["WriggleLantern"] = 500.0000 ,["TwistedLizardElder"] = 500.0000 ,["RabidWolf"] = math.huge ,["HeimerTGreen"] = 1599.3999 ,["HeimerTRed"] = 1599.3999 ,["ViktorFF"] = 1599.3999 ,["TwistedGolem"] = math.huge ,["TwistedSmallWolf"] = math.huge ,["TwistedGiantWolf"] = math.huge ,["TwistedTinyWraith"] = 750.0000 ,["TwistedBlueWraith"] = 750.0000 ,["TwistedYoungLizard"] = 750.0000 ,["Red_Minion_Melee"] = math.huge ,["Blue_Minion_Melee"] = math.huge ,["Blue_Minion_Healer"] = 1000.0000 ,["Ghast"] = 750.0000 ,["blueDragon"] = 800.0000 ,["Red_Minion_MechRange"] = 3000, ["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"]  = 1200, ["SRUAP_Turret_Chaos2"]  = 1200, ["SRUAP_Turret_Chaos3"] = 1200, ["SRUAP_Turret_Order1"]  = 1200, ["SRUAP_Turret_Order2"]  = 1200, ["SRUAP_Turret_Order3"] = 1200, ["SRUAP_Turret_Chaos4"] = 1200, ["SRUAP_Turret_Chaos5"] = 500, ["SRUAP_Turret_Order4"] = 1200, ["SRUAP_Turret_Order5"] = 500 }

	self.ProjectileSpeed = myHero.range > 300 and self:GetProjectileSpeed(myHero) or math.huge
	self.BaseWindupTime = 3
	self.BaseAnimationTime = 0.65
	self.DataUpdated = false

	self.VP = VP
	
	--Callbacks
	self.AfterAttackCallbacks = {}
	self.OnAttackCallbacks = {}
	self.BeforeAttackCallbacks = {}

	self.AttackTable =
		{
        "caitlynheadshotmissile",
        "frostarrow",
        "garenslash2",
        "kennenmegaproc",
        "masteryidoublestrike",
        "quinnwenhanced",
        "renektonexecute",
        "renektonsuperexecute",
        "rengarnewpassivebuffdash",
        "trundleq",
        "xenzhaothrust",
        "xenzhaothrust2",
        "xenzhaothrust3",
        "viktorqbuff"
		}

	self.NoAttackTable =
		{
        "volleyattack",
        "volleyattackwithsound",
        "jarvanivcataclysmattack",
        "monkeykingdoubleattack",
        "shyvanadoubleattack",
        "shyvanadoubleattackdragon",
        "zyragraspingplantattack",
        "zyragraspingplantattack2",
        "zyragraspingplantattackfire",
        "zyragraspingplantattack2fire",
        "viktorpowertransfer",
        "sivirwattackbounce",
        "asheqattacknoonhit",
        "elisespiderlingbasicattack",
        "heimertyellowbasicattack",
        "heimertyellowbasicattack2",
        "heimertbluebasicattack",
        "annietibbersbasicattack",
        "annietibbersbasicattack2",
        "yorickdecayedghoulbasicattack",
        "yorickravenousghoulbasicattack",
        "yorickspectralghoulbasicattack",
        "malzaharvoidlingbasicattack",
        "malzaharvoidlingbasicattack2",
        "malzaharvoidlingbasicattack3",
        "kindredwolfbasicattack"
		}

	self.AttackResetTable = 
		{
        "dariusnoxiantacticsonh",
        "fioraflurry",
        "garenq",
        "gravesmove",
        "hecarimrapidslash",
        "jaxempowertwo",
        "jaycehypercharge",
        "leonashieldofdaybreak",
        "luciane",
        "monkeykingdoubleattack",
        "mordekaisermaceofspades",
        "nasusq",
        "nautiluspiercinggaze",
        "netherblade",
        "gangplankqwrapper",
        "poppypassiveattack",
        "powerfist",
        "renektonpreexecute",
        "rengarq",
        "shyvanadoubleattack",
        "sivirw",
        "takedown",
        "talonnoxiandiplomacy",
        "trundletrollsmash",
        "vaynetumble",
        "vie",
        "volibearq",
        "xenzhaocombotarget",
        "yorickspectral",
        "reksaiq",
        "itemtitanichydracleave",
        "masochism",
        "illaoiw",
        "elisespiderw",
        "fiorae",
        "meditate",
        "sejuaninorthernwinds"
		}

	self.LastAttack = 0
	self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_MAXHEALTH_ASC)
	self.JungleMinions = minionManager(MINION_JUNGLE, 2000, myHero, MINION_SORT_MAXHEALTH_DEC)
	self.OtherMinions = minionManager(MINION_OTHER, 2000, myHero, MINION_SORT_HEALTH_ASC)
	
	GetSave("SOW").FarmDelay = GetSave("SOW").FarmDelay and GetSave("SOW").FarmDelay or 0
	GetSave("SOW").ExtraWindUpTime = GetSave("SOW").ExtraWindUpTime and GetSave("SOW").ExtraWindUpTime or 50
	GetSave("SOW").Mode3 = GetSave("SOW").Mode3 and GetSave("SOW").Mode3 or string.byte("X")
	GetSave("SOW").Mode2 = GetSave("SOW").Mode2 and GetSave("SOW").Mode2 or string.byte("V")
	GetSave("SOW").Mode1 = GetSave("SOW").Mode1 and GetSave("SOW").Mode1 or string.byte("C")
	GetSave("SOW").Mode0 = GetSave("SOW").Mode0 and GetSave("SOW").Mode0 or 32

	self.Attacks = true
	self.Move = true
	self.mode = -1
	self.checkcancel = 0
    self.HPP = HealthPrediction()

    self.Turrets = {}
    for i=1, objManager.maxObjects do
		local obj = objManager:getObject(i)
		if obj and obj.valid and obj.type == 'obj_AI_Turret' and obj.name:find('Shrine') == nil and not obj.dead then
			self.Turrets[#self.Turrets+1] = obj
		end
	end

	AddProcessSpellCallback(function(unit, spell) self:OnProcessSpell(unit, spell) end)
    AddProcessAttackCallback(function(unit, spell) self:OnProcessAttack(unit, spell) end)
    --AddAnimationCallback(function(u, a) self:OnAnimation(u, a) end)
end

function SOW:GetProjectileSpeed(unit)
    return self.projectilespeeds[unit.charName] and self.projectilespeeds[unit.charName] or math.huge
end

function SOW:AddToMenu(m, STS)
	if not m then
		self.Menu = scriptConfig("Simple OrbWalker", "SOW")
	else
		self.Menu = m
	end

	if STS then
		self.STS = STS
		--self.STS.VP = self.VP
	end

    self.Menu:addSubMenu("General", "General")
	
	self.Menu.General:addParam("Enabled", "Enabled", SCRIPT_PARAM_ONOFF, true)
	self.Menu.General:addParam("FarmDelay", "Farm Delay", SCRIPT_PARAM_SLICE, -150, 0, 150)
	self.Menu.General:addParam("ExtraWindUpTime", "Extra WindUp Time", SCRIPT_PARAM_SLICE, -150,  0, 150)
	
	self.Menu.General.FarmDelay = GetSave("SOW").FarmDelay
	self.Menu.General.ExtraWindUpTime = GetSave("SOW").ExtraWindUpTime

	self.Menu.General:addParam("Attack",  "Attack", SCRIPT_PARAM_LIST, 2, { "Only Farming", "Farming + Carry mode"})
	self.Menu.General:addParam("Mode",  "Orbwalking mode", SCRIPT_PARAM_LIST, 1, { "To mouse", "To target"})

	self.Menu:addSubMenu("HotKeys", "HotKeys")

	self.Menu.HotKeys:addParam("Mode3", "Last hit!", SCRIPT_PARAM_ONKEYDOWN, false, GetSave("SOW").Mode3 and GetSave("SOW").Mode3 or string.byte("X"))
	self.Mode3ParamID = #self.Menu._param
	self.Menu.HotKeys:addParam("Mode1", "Mixed Mode!", SCRIPT_PARAM_ONKEYDOWN, false, GetSave("SOW").Mode2 and GetSave("SOW").Mode2 or string.byte("C"))
	self.Mode1ParamID = #self.Menu._param
	self.Menu.HotKeys:addParam("Mode2", "Laneclear!", SCRIPT_PARAM_ONKEYDOWN, false, GetSave("SOW").Mode1 and GetSave("SOW").Mode1 or string.byte("V"))
	self.Mode2ParamID = #self.Menu._param
	self.Menu.HotKeys:addParam("Mode0", "Carry me!", SCRIPT_PARAM_ONKEYDOWN, false, GetSave("SOW").Mode0 and GetSave("SOW").Mode0 or 32)
	self.Mode0ParamID = #self.Menu._param

    self.Menu:addSubMenu("Draw", "Draw")
    self.Menu.Draw:addParam("DrawRange", "Draw AA Range", SCRIPT_PARAM_ONOFF, true)
    self.Menu.Draw:addParam("DrawEnemyAARange", "Draw Enemy AA Range", SCRIPT_PARAM_ONOFF, true)
    self.Menu.Draw:addParam("HoldZone", "HoldZone", SCRIPT_PARAM_ONOFF, true);

    self.Menu:addSubMenu("Misc", "Misc")
    self.Menu.Misc:addParam("HoldPosRadius", "Hold Position Radius", SCRIPT_PARAM_SLICE, 50, 0, 250)
    self.Menu.Misc:addParam("AttackTurret", "Auto attack turrets", SCRIPT_PARAM_ONOFF, true)
--    self.Menu.Misc:addParam("PriorizeFarm", "Priorize farm over harass", SCRIPT_PARAM_ONOFF, true)
--    self.Menu.Misc:addParam("AttackWards", "Auto attack wards", SCRIPT_PARAM_ONOFF, false)
--    self.Menu.Misc:addParam("AttackPetsnTraps", "Auto attack pets & traps", SCRIPT_PARAM_ONOFF, true)
--    self.Menu.Misc:addParam("AttackBarrel", "Auto attack gangplank barrel", SCRIPT_PARAM_ONOFF, true)

--	self.Menu._param[self.Mode3ParamID].key = 
--	self.Menu._param[self.Mode2ParamID].key = 
--	self.Menu._param[self.Mode1ParamID].key = 
--	self.Menu._param[self.Mode0ParamID].key = 
	
	AddTickCallback(function() self:OnTick() end)
	AddTickCallback(function() self:CheckConfig() end)
    AddDrawCallback(function() self:OnDraw() end)
end

function SOW:OnDraw()
    if self.Menu.Draw.DrawRange then
        DrawCircle(myHero.x, myHero.y, myHero.z, myHero.range + myHero.boundingRadius/2, Colors.Yellow)
    end
    if self.Menu.Draw.DrawEnemyAARange then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if not enemy.dead then
                DrawCircle(enemy.x, enemy.y, enemy.z, enemy.range + enemy.boundingRadius/2, Colors.Red)
            end
        end
    end
    if self.Menu.Draw.HoldZone then
        DrawCircle(myHero.x, myHero.y, myHero.z, self.Menu.Misc.HoldPosRadius, Colors.Green)
    end
end

function SOW:CheckConfig()
	GetSave("SOW").FarmDelay = self.Menu.General.FarmDelay
	GetSave("SOW").ExtraWindUpTime = self.Menu.General.ExtraWindUpTime

--	GetSave("SOW").Mode3 = self.Menu._param[self.Mode3ParamID].key
--	GetSave("SOW").Mode2 = self.Menu._param[self.Mode2ParamID].key
--	GetSave("SOW").Mode1 = self.Menu._param[self.Mode1ParamID].key
--	GetSave("SOW").Mode0 = self.Menu._param[self.Mode0ParamID].key
end

function SOW:DisableAttacks()
	self.Attacks = false
end

function SOW:EnableAttacks()
	self.Attacks = true
end

function SOW:ForceTarget(target)
	self.forcetarget = target
end

function SOW:GetTime()
	return os.clock()
end

function SOW:MyRange(target)
	local myRange = myHero.range + myHero.boundingRadius/2 --self.VP:GetHitBox(target)
	if target and ValidTarget(target) then
		myRange = myRange + myHero.boundingRadius/2
	end
	return myRange - 20
end

function SOW:InRange(target)
	local MyRange = self:MyRange(target)
	if target and GetDistanceSqr(target.visionPos, myHero.visionPos) <= MyRange * MyRange then
		return true
	end
end

function SOW:ValidTarget(target)
	if target and target.type and (target.type == "obj_BarracksDampener" or target.type == "obj_HQ")  then
		return false
	end
	return ValidTarget(target) and self:InRange(target)
end

function SOW:Attack(target)
	self.LastAttack = self:GetTime() + self:Latency()
	myHero:Attack(target)
end

function SOW:WindUpTime(exact)
	return (1 / (myHero.attackSpeed * self.BaseWindupTime)) + (exact and 0 or GetSave("SOW").ExtraWindUpTime / 1000)
end

function SOW:AnimationTime()
	return (1 / (myHero.attackSpeed * self.BaseAnimationTime))
end

function SOW:Latency()
	return GetLatency() / 2000
end

function SOW:CanAttack()
    if myHero.charName == "Jhin" and HasBuff(myHero, "JhinPassiveReload") then return false end
	if self.LastAttack <= self:GetTime() then
		return (self:GetTime() + self:Latency()  > self.LastAttack + self:AnimationTime())
	end
	return false
end

function SOW:CanMove()
	if self.LastAttack <= self:GetTime() then
		return ((self:GetTime() + self:Latency() > self.LastAttack + self:WindUpTime()) or self.ParticleCreated) and not IsEvading()
	end
end

function SOW:BeforeAttack(target)
	local result = false
	for i, cb in ipairs(self.BeforeAttackCallbacks) do
		local ri = cb(target, self.mode)
		if ri then
			result = true
		end
	end
	return result
end

function SOW:RegisterBeforeAttackCallback(f)
	table.insert(self.BeforeAttackCallbacks, f)
end

function SOW:OnAttack(target)
	for i, cb in ipairs(self.OnAttackCallbacks) do
		cb(target, self.mode)
	end
end

function SOW:RegisterOnAttackCallback(f)
	table.insert(self.OnAttackCallbacks, f)
end

function SOW:AfterAttack(target)
	for i, cb in ipairs(self.AfterAttackCallbacks) do
		cb(target, self.mode)
	end
end

function SOW:RegisterAfterAttackCallback(f)
	table.insert(self.AfterAttackCallbacks, f)
end

function SOW:MoveTo(x, y)
    myHero:MoveTo(x, y)
end
function SOW:OrbWalk(target, point)
	point = point or self.forceorbwalkpos
	if self.Attacks and self:CanAttack() and self:ValidTarget(target) and not self:BeforeAttack(target) then
		self:Attack(target)
	elseif self:CanMove() and self.Move then
		if not point then
			local OBTarget = GetTarget() or target
			if self.Menu.General.Mode == 1 or not OBTarget then
                if GetDistance(mousePos) < self.Menu.Misc.HoldPosRadius then return end
                local Mv = mousePos
				--local Mv = Vector(myHero) + 100 * (Vector(mousePos) - Vector(myHero)):normalized()
				self:MoveTo(Mv.x, Mv.z)
			elseif GetDistanceSqr(OBTarget) > 100*100 + math.pow(OBTarget.boundingRadius/2, 2) then
				local point = self.VP:GetPredictedPos(OBTarget, 0, 2*myHero.ms, myHero, false)
				if GetDistanceSqr(point) < 100*100 + math.pow(OBTarget.boundingRadius, 2) then
					point = Vector(Vector(myHero) - point):normalized() * 50
				end
				self:MoveTo(point.x, point.z)
			end
		else
			self:MoveTo(point.x, point.z)
		end
	end
end

function SOW:IsAttack(SpellName)
	return (SpellName:lower():find("attack") or table.contains(self.AttackTable, SpellName:lower())) and not table.contains(self.NoAttackTable, SpellName:lower())
end

function SOW:IsAAReset(SpellName)
	local SpellID
	if SpellName:lower() == myHero:GetSpellData(_Q).name:lower() then
		SpellID = _Q
	elseif SpellName:lower() == myHero:GetSpellData(_W).name:lower() then
		SpellID = _W
	elseif SpellName:lower() == myHero:GetSpellData(_E).name:lower() then
		SpellID = _E
	elseif SpellName:lower() == myHero:GetSpellData(_R).name:lower() then
		SpellID = _R
	end

	if SpellID then
		return table.contains(self.AttackResetTable, SpellID) --self.AttackResetTable[myHero.charName:lower()] == SpellID 
	end
	return false
end

function SOW:OnProcessSpell(unit, spell)
	if unit.isMe and self:IsAttack(spell.name) then
		if self.debugdps then
			DPS = DPS and DPS or 0
			print("DPS: "..(1000/(self:GetTime()- DPS)).." "..(1000/(self:AnimationTime())))
			DPS = self:GetTime()
		end
		if not self.DataUpdated and not spell.name:lower():find("card") then
			
			if self.debug then
				print("<font color=\"#FF0000\">Basic Attacks data updated: </font>")
				print("<font color=\"#FF0000\">BaseWindupTime: "..self.BaseWindupTime.."</font>")
				print("<font color=\"#FF0000\">BaseAnimationTime: "..self.BaseAnimationTime.."</font>")
				print("<font color=\"#FF0000\">ProjectileSpeed: "..self.ProjectileSpeed.."</font>")
			end
			self.DataUpdated = true
		end
		self.LastAttack = self:GetTime() - self:Latency()
		self.checking = true
		self.LastAttackCancelled = false
		self:OnAttack(spell.target)
		self.checkcancel = self:GetTime()
		DelayAction(function(t) self:AfterAttack(t) end, self:WindUpTime() - self:Latency(), {spell.target})

	elseif unit.isMe and self:IsAAReset(spell.name) then
		DelayAction(function() self:resetAA() end, 0.25)
	end
end

function SOW:OnProcessAttack(unit, spell)
    if unit.isMe and self:IsAttack(spell.name) then
        self.BaseAnimationTime = 1 / (spell.animationTime * myHero.attackSpeed)
		self.BaseWindupTime = 1 / (spell.windUpTime * myHero.attackSpeed)
    end
end

function SOW:resetAA()
	self.LastAttack = 0
end
--TODO: Change this.
function SOW:BonusDamage(minion)
	local AD = myHero:CalcDamage(minion, myHero.totalDamage)
	local BONUS = 0
	if myHero.charName == 'Vayne' then
		if myHero:GetSpellData(_Q).level > 0 and myHero:CanUseSpell(_Q) == SUPRESSED then
			BONUS = BONUS + myHero:CalcDamage(minion, ((0.05 * myHero:GetSpellData(_Q).level) + 0.25 ) * myHero.totalDamage)
		end
		if not VayneCBAdded then
			VayneCBAdded = true
			function VayneParticle(obj)
				if GetDistance(obj) < 1000 and obj.name:lower():find("vayne_w_ring2.troy") then
					VayneWParticle = obj
				end
			end
			AddCreateObjCallback(VayneParticle)
		end
		if VayneWParticle and VayneWParticle.valid and GetDistance(VayneWParticle, minion) < 10 then
			BONUS = BONUS + 10 + 10 * myHero:GetSpellData(_W).level + (0.03 + (0.015 * myHero:GetSpellData(_W).level)) * minion.maxHealth
		end
	elseif myHero.charName == 'Teemo' and myHero:GetSpellData(_E).level > 0 then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, (myHero:GetSpellData(_E).level * 10) + (myHero.ap * 0.3) )
	elseif myHero.charName == 'Corki' then
		BONUS = BONUS + myHero.totalDamage/10
	elseif myHero.charName == 'MissFortune' and myHero:GetSpellData(_W).level > 0 then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, (4 + 2 * myHero:GetSpellData(_W).level) + (myHero.ap/20))
	elseif myHero.charName == 'Varus' and myHero:GetSpellData(_W).level > 0 then
		BONUS = BONUS + (6 + (myHero:GetSpellData(_W).level * 4) + (myHero.ap * 0.25))
	elseif myHero.charName == 'Caitlyn' then
			if not CallbackCaitlynAdded then
				function CaitlynParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("caitlyn_headshot_rdy") then
							HeadShotParticle = obj
					end
				end
				AddCreateObjCallback(CaitlynParticle)
				CallbackCaitlynAdded = true
			end
			if HeadShotParticle and HeadShotParticle.valid then
				BONUS = BONUS + AD * 1.5
			end
	elseif myHero.charName == 'Orianna' then
		BONUS = BONUS + myHero:CalcMagicDamage(minion, 10 + 8 * ((myHero.level - 1) % 3))
	elseif myHero.charName == 'TwistedFate' then
			if not TFCallbackAdded then
				function TFParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("cardmaster_stackready.troy") then
						TFEParticle = obj
					elseif GetDistance(obj) < 100 and obj.name:lower():find("card_blue.troy") then
						TFWParticle = obj
					end
				end
				AddCreateObjCallback(TFParticle)
				TFCallbackAdded = true
			end
			if TFEParticle and TFEParticle.valid then
				BONUS = BONUS + myHero:CalcMagicDamage(minion, myHero:GetSpellData(_E).level * 15 + 40 + 0.5 * myHero.ap)  
			end
			if TFWParticle and TFWParticle.valid then
				BONUS = BONUS + math.max(myHero:CalcMagicDamage(minion, myHero:GetSpellData(_W).level * 20 + 20 + 0.5 * myHero.ap) - 40, 0) 
			end
	elseif myHero.charName == 'Draven' then
			if not CallbackDravenAdded then
				function DravenParticle(obj)
					if GetDistance(obj) < 100 and obj.name:lower():find("draven_q_buf") then
							DravenParticleo = obj
					end
				end
				AddCreateObjCallback(DravenParticle)
				CallbackDravenAdded = true
			end
			if DravenParticleo and DravenParticleo.valid then
				BONUS = BONUS + AD * (0.3 + (0.10 * myHero:GetSpellData(_Q).level))
			end
	elseif myHero.charName == 'Nasus' and VIP_USER then
		if myHero:GetSpellData(_Q).level > 0 and myHero:CanUseSpell(_Q) == SUPRESSED then
			local Qdamage = {30, 50, 70, 90, 110}
--			NasusQStacks = NasusQStacks or 0
--			BONUS = BONUS + myHero:CalcDamage(minion, 10 + 20 * (myHero:GetSpellData(_Q).level) + NasusQStacks)
--			if not RecvPacketNasusAdded then
--				function NasusOnRecvPacket(p)
--					if p.header == 0xFE and p.size == 0xC then
--						p.pos = 1
--						pNetworkID = p:DecodeF()
--						unk01 = p:Decode2()
--				 		unk02 = p:Decode1()
--						stack = p:Decode4()
--						if pNetworkID == myHero.networkID then
--							NasusQStacks = stack
--						end
--					end
--				end
--				RecvPacketNasusAdded = true
--				AddRecvPacketCallback(NasusOnRecvPacket)
--			end
		end
	elseif myHero.charName == "Ziggs" then
		if not CallbackZiggsAdded then
			function ZiggsParticle(obj)
				if GetDistance(obj) < 100 and obj.name:lower():find("ziggspassive") then
						ZiggsParticleObj = obj
				end
			end
			AddCreateObjCallback(ZiggsParticle)
			CallbackZiggsAdded = true
		end
		if ZiggsParticleObj and ZiggsParticleObj.valid then
			local base = {20, 24, 28, 32, 36, 40, 48, 56, 64, 72, 80, 88, 100, 112, 124, 136, 148, 160}
			BONUS = BONUS + myHero:CalcMagicDamage(minion, base[myHero.level] + (0.25 + 0.05 * (myHero.level % 7)) * myHero.ap)  
		end
	end

	return BONUS
end

function SOW:KillableMinion()
	local result
	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:WindUpTime(true) + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		local PredictedHealth = self.VP:GetPredictedHealth(minion, time, GetSave("SOW").FarmDelay / 1000)
		if self:ValidTarget(minion) and PredictedHealth < self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion) and PredictedHealth > -40 then
			result = minion
			break
		end
	end
	return result
end

function SOW:ShouldWait()
	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:AnimationTime() + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		if self:ValidTarget(minion) and self.VP:GetPredictedHealth2(minion, time * 2) < (self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion)) then
			return true
		end
	end
end

function SOW:ValidStuff()
	local result = self:GetTarget()

	if result then 
		return result
	end

	for i, minion in ipairs(self.EnemyMinions.objects) do
		local time = self:AnimationTime() + GetDistance(minion.visionPos, myHero.visionPos) / self.ProjectileSpeed - 0.07
		local pdamage2 = minion.health - self.VP:GetPredictedHealth(minion, time, GetSave("SOW").FarmDelay / 1000)
		local pdamage = self.VP:GetPredictedHealth2(minion, time * 2)
		if self:ValidTarget(minion) and ((pdamage) > 2*self.VP:CalcDamageOfAttack(myHero, minion, {name = "Basic"}, 0) + self:BonusDamage(minion) or pdamage2 == 0) then
			return minion
		end
	end

	for i, minion in ipairs(self.JungleMinions.objects) do
		if self:ValidTarget(minion) then
			return minion
		end
	end

	for i, minion in ipairs(self.OtherMinions.objects) do
		if self:ValidTarget(minion) then
			return minion
		end
	end
end

function SOW:GetTarget(OnlyChampions)
	local result
	local healthRatio

	if self:ValidTarget(self.forcetarget) then
		return self.forcetarget
	elseif self.forcetarget ~= nil then
		return nil
	end

	if (not self.STS or not OnlyChampions) and self:ValidTarget(GetTarget()) and (GetTarget().type == myHero.type or (not OnlyChampions)) then
		return GetTarget()
	end

	if self.STS then
		local oldhitboxmode = self.STS.hitboxmode
		self.STS.hitboxmode = true

		result = self.STS:GetTarget(myHero.range)

		self.STS.hitboxmode = oldhitboxmode
		return result
	end

	for i, champion in ipairs(GetEnemyHeroes()) do
		local hr = champion.health / myHero:CalcDamage(champion, 200)
		if self:ValidTarget(champion) and ((healthRatio == nil) or hr < healthRatio) then
			result = champion
			healthRatio = hr
		end
	end

	return result
end

function SOW:GetTurret()
    range = myHero.range + myHero.boundingRadius/2
    for i, turret in ipairs(self.Turrets) do
        if turret.dead then
            table.remove(self.Turrets, i)
        elseif GetDistance(turret) < range then
            return turret
        end
    end
    return nil
end

function SOW:Farm(mode, point)
	if mode == 1 then
		self.EnemyMinions:update()
		local target = self:KillableMinion() or self:GetTarget()
		self:OrbWalk(target, point)
		self.mode = 1
	elseif mode == 2 then
		self.EnemyMinions:update()
		self.OtherMinions:update()
		self.JungleMinions:update()

		local target = self:KillableMinion()
        local tTurret = self:GetTurret()
		if target then
			self:OrbWalk(target, point)
		elseif not self:ShouldWait() then

			if self:ValidTarget(self.lasttarget) then
				target = self.lasttarget
			else
				target = self:ValidStuff()
			end
			self.lasttarget = target
			
			self:OrbWalk(target, point)
        elseif tTurret ~= nil then
            self:OrbWalk(tTurret, point)
		else
			self:OrbWalk(nil, point)
		end
		self.mode = 2
	elseif mode == 3 then
		self.EnemyMinions:update()
		local target = self:KillableMinion()
		self:OrbWalk(target, point)
		self.mode = 3
	end
end

function SOW:OnTick()
	if not self.Menu.General.Enabled then return end
	if self.Menu.HotKeys.Mode0 then
		local target = self:GetTarget(true)
		if self.Menu.General.Attack == 2 then
			self:OrbWalk(target)
		else
			self:OrbWalk()
		end
		self.mode = 0
	elseif self.Menu.HotKeys.Mode1 then
		self:Farm(1)
	elseif self.Menu.HotKeys.Mode2 then
		self:Farm(2)
	elseif self.Menu.HotKeys.Mode3 then
		self:Farm(3)
	else
		self.mode = -1
	end
end

function SOW:GetActiveMode()
    if self.Menu.HotKeys.Mode0 then
        return "Combo"
    elseif self.Menu.HotKeys.Mode1 then
        return "Harass"
    elseif self.Menu.HotKeys.Mode2 then
        return "Clear"
    elseif self.Menu.HotKeys.Mode3 then
        return "LastHit"
    end
end

function SOW:DrawAARange(width, color)
	local p = WorldToScreen(D3DXVECTOR3(myHero.x, myHero.y, myHero.z))
	if OnScreen(p.x, p.y) then
		DrawCircle3D(myHero.x, myHero.y, myHero.z, self:MyRange() + 25, width or 1, color or ARGB(255, 255, 0, 0))
	end
end

class('HealthPrediction')
function HealthPrediction:__init()
    self.ProjectileSpeed = {["SRU_OrderMinionRanged"] = 650, ["SRU_ChaosMinionRanged"] = 650, ["SRU_OrderMinionSiege"] = 1200, ["SRU_ChaosMinionSiege"] = 1200, ["SRUAP_Turret_Chaos1"] = 1200, ["SRUAP_Turret_Chaos2"] = 1200, ["SRUAP_Turret_Order1"] = 1200, ["SRUAP_Turret_Order2"] = 1200}
    self.PredictionDamage = {}
    self.EnemyMinions = minionManager(MINION_ENEMY, 2000, myHero, MINION_SORT_HEALTH_ASC)
    AddTickCallback(function() self:OnTick() end)
    AddAnimationCallback(function(u, a) self:OnAnimation(u, a) end)
    AddProcessAttackCallback(function(u, s) self:OnProcessAttack(u, s) end)
end

function HealthPrediction:OnTick()
    for i, minion in ipairs(self.EnemyMinions.objects)do
        local D = true
        for cTime, damage in pairs(self.PredictionDamage[minions.networkID])do
            if GetGameTimer()+GetLatency()/2000 < ctime - GetLatency()/200 then
                D = false
                break
            end
        end
        if D then
            self.PredictionDamage[minions.networkID] = nil
        end
    end
end

function HealthPrediction:OnAnimation(unit, animation)
    if unit == nil then
        return
    end

    if unit.team == myHero.team and unit.spell ~= nil and unit.spell.target ~= nil and unit.spell.name:find("BasicAttack") then
        if unit.spell.target.networkID < 100 and self.PredictionDamage[unit.spell.target.networkID] == nil then
            self.PredictionDamage[unit.spell.target.networkID] = {}
        end
        if self.PredictionDamage[unit.spell.target.networkID] then
            if unit.type ~= myHero.type and self.ProjectileSpeed[unit.charName] then
                local ctime = GetGameTimer()+unit.spell.windUpTime+GetDistance(unit.spell.target, unit)/self.ProjectileSpeed[unit.charName]
                self.PredictionDamage[unit.spell.target.networkID][ctime] = self:GetAADmg(unit.spell.target, unit)
            else
                local ctime = GetGameTimer()+unit.spell.windUpTime
                self.PredictionDamage[unit.spell.target.networkID][ctime] = self:GetAADmg(unit.spell.target, unit)
            end
        end
    end
end

function HealthPrediction:OnProcessAttack(unit, spell)
    if unit == nil then
        return
    end

    if unit.team == myHero.team and unit.type == myHero.type and spell.target and spell.name:find("BasicAttack") and self.ProjectileSpeed[unit.charName] then
        if spell.target.networkID < 100 and self.PredictionDamage[spell.target.networkID] == nil then
            self.PredictionDamage[spell.target.networkID] = {}
        end
        if self.PredictionDamage[spell.target.networkID] then
            local ctime = GetGameTimer()+GetDistance(spell.target, unit)/self.ProjectileSpeed[unit.charName]
            self.PredictionDamage[spell.target.networkID][ctime] = self:GetAADmg(spell.target, unit)
        end

    end
end

function HealthPrediction:GetHealthPrediction(unit, time)
    local health = unit.health
    if self.PredictionDamage[unit.networkID] then
        local Delete = true

        for ctime, damage in pairs(self.PredictionDamage[unit.networkID]) do

            if GetGameTimer()+GetLatency()/2000 < ctime-GetLatency()/2000 then
                Delete = false
                break
            end
        end
        if Delete then
            self.PredictionDamage[unit.networkID] = nil
        else
            for ctime, damage in pairs(self.PredictionDamage[unit.networkID]) do
                if GetGameTimer()+GetLatency()/2000 >= ctime-GetLatency()/2000 then
                    self.PredictionDamage[unit.networkID][ctime] = nil
                elseif GetGameTimer()+GetLatency()/2000+time > ctime+0.09-GetLatency()/2000 then --Temp 0.075
                    health = health-damage
                end
            end
        end
    end
    return health
end

function HealthPrediction:GetAADmg(enemy, ally)
    local Armor = math.max(0, enemy.armor*ally.armorPenPercent-ally.armorPen)
    local ArmorPercent = Armor/(100+Armor)
    local TrueDmg = ally.totalDamage*(1-ArmorPercent)
    return TrueDmg
end


--[[

'||'  '|'   .    ||  '||  
 ||    |  .||.  ...   ||  
 ||    |   ||    ||   ||  
 ||    |   ||    ||   ||  
  '|..'    '|.' .||. .||. 

    Util - Just utils.
]]

SUMMONERS_RIFT   = { 1, 2 }
PROVING_GROUNDS  = 3
TWISTED_TREELINE = { 4, 10 }
CRYSTAL_SCAR     = 8
HOWLING_ABYSS    = 12

function IsMap(map)

    assert(map and (type(map) == "number" or type(map) == "table"), "IsMap(): map is invalid!")
    if type(map) == "number" then
        return GetGame().map.index == map
    else
        for _, id in ipairs(map) do
            if GetGame().map.index == id then return true end
        end
    end

end

function GetMapName()

    if IsMap(SUMMONERS_RIFT) then
        return "Summoners Rift"
    elseif IsMap(CRYSTAL_SCAR) then
        return "Crystal Scar"
    elseif IsMap(HOWLING_ABYSS) then
        return "Howling Abyss"
    elseif IsMap(TWISTED_TREELINE) then
        return "Twisted Treeline"
    elseif IsMap(PROVING_GROUNDS) then
        return "Proving Grounds"
    else
        return "Unknown map"
    end

end

function ProtectTable(t)

    local proxy = {}
    local mt = {
    __index = t,
    __newindex = function (t,k,v)
        error('attempt to update a read-only table', 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy

end

function _GetDistanceSqr(p1, p2)

    p2 = p2 or player
    if p1 and p1.networkID and (p1.networkID ~= 0) and p1.visionPos then p1 = p1.visionPos end
    if p2 and p2.networkID and (p2.networkID ~= 0) and p2.visionPos then p2 = p2.visionPos end
    return GetDistanceSqr(p1, p2)
    
end

function GetObjectsAround(radius, position, condition)

    radius = math.pow(radius, 2)
    position = position or player
    local objectsAround = {}
    for i = 1, objManager.maxObjects do
        local object = objManager:getObject(i)
        if object and object.valid and (condition and condition(object) == true or not condition) and _GetDistanceSqr(position, object) <= radius then
            table.insert(objectsAround, object)
        end
    end
    return objectsAround

end

function HasBuff(unit, buffname)

    for i = 1, unit.buffCount do
        local tBuff = unit:getBuff(i)
        if tBuff.valid and BuffIsValid(tBuff) and tBuff.name == buffname then
            return true
        end
    end
    return false

end

function GetSummonerSlot(name, unit)

    unit = unit or player
    if unit:GetSpellData(SUMMONER_1).name == name then return SUMMONER_1 end
    if unit:GetSpellData(SUMMONER_2).name == name then return SUMMONER_2 end

end

function GetEnemyHPBarPos(enemy)

    -- Prevent error spamming
    if not enemy.barData then
        if not _G.__sourceLib_barDataInformed then
            print("SourceLib: barData was not found, spudgy please...")
            _G.__sourceLib_barDataInformed = true
        end
        return
    end

    local barPos = GetUnitHPBarPos(enemy)
    local barPosOffset = GetUnitHPBarOffset(enemy)
    local barOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)
    local barPosPercentageOffset = Point(enemy.barData.PercentageOffset.x, enemy.barData.PercentageOffset.y)

    local BarPosOffsetX = 169
    local BarPosOffsetY = 47
    local CorrectionX = 16
    local CorrectionY = 4

    barPos.x = barPos.x + (barPosOffset.x - 0.5 + barPosPercentageOffset.x) * BarPosOffsetX + CorrectionX
    barPos.y = barPos.y + (barPosOffset.y - 0.5 + barPosPercentageOffset.y) * BarPosOffsetY + CorrectionY 

    local StartPos = Point(barPos.x, barPos.y)
    local EndPos = Point(barPos.x + 103, barPos.y)

    return Point(StartPos.x, StartPos.y), Point(EndPos.x, EndPos.y)

end

function CountObjectsNearPos(pos, range, radius, objects)

    local n = 0
    for i, object in ipairs(objects) do
        if _GetDistanceSqr(pos, object) <= radius * radius then
            n = n + 1
        end
    end

    return n

end

function GetBestCircularFarmPosition(range, radius, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local hit = CountObjectsNearPos(object.visionPos or object, range, radius, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
            if BestHit == #objects then
               break
            end
         end
    end

    return BestPos, BestHit

end

function CountObjectsOnLineSegment(StartPos, EndPos, width, objects)

    local n = 0
    for i, object in ipairs(objects) do
        local pointSegment, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(StartPos, EndPos, object)
        if isOnSegment and GetDistanceSqr(pointSegment, object) < width * width then
            n = n + 1
        end
    end

    return n

end

function GetBestLineFarmPosition(range, width, objects)

    local BestPos 
    local BestHit = 0
    for i, object in ipairs(objects) do
        local EndPos = Vector(myHero.visionPos) + range * (Vector(object) - Vector(myHero.visionPos)):normalized()
        local hit = CountObjectsOnLineSegment(myHero.visionPos, EndPos, width, objects)
        if hit > BestHit then
            BestHit = hit
            BestPos = Vector(object)
            if BestHit == #objects then
               break
            end
         end
    end

    return BestPos, BestHit

end

function GetPredictedPositionsTable(VP, t, delay, width, range, speed, source, collision)

    local result = {}
    for i, target in ipairs(t) do
        local CastPosition, Hitchance, Position = VP:GetCircularCastPosition(target, delay, width, range, speed, source, collision) 
        table.insert(result, Position)
    end
    return result

end

function MergeTables(t1, t2)

    for i = 1, #t2 do
        t1[#t1 + 1] = t2[i]
    end
    return t1

end

function SelectUnits(units, condition)
    
    local result = {}
    for i, unit in ipairs(units) do
        if condition(unit) then
            table.insert(result, unit)
        end
    end
    return result

end

function SpellToString(id)

    if id == _Q then return "Q" end
    if id == _W then return "W" end
    if id == _E then return "E" end
    if id == _R then return "R" end

end

function TARGB(colorTable)

    assert(colorTable and type(colorTable) == "table" and #colorTable == 4, "TARGB: colorTable is invalid!")
    return ARGB(colorTable[1], colorTable[2], colorTable[3], colorTable[4])

end

function PingClient(x, y, pingType)
    Packet("R_PING", {x = x, y = y, type = pingType and pingType or PING_FALLBACK}):receive()
end

local __util_autoAttack   = { "frostarrow" }
local __util_noAutoAttack = { "shyvanadoubleattackdragon",
                              "shyvanadoubleattack",
                              "monkeykingdoubleattack" }
function IsAASpell(spell)

    if not spell or not spell.name then return end

    for _, spellName in ipairs(__util_autoAttack) do
        if spellName == spell.name:lower() then
            return true
        end
    end

    for _, spellName in ipairs(__util_noAutoAttack) do
        if spellName == spell.name:lower() then
            return false
        end
    end

    if spell.name:lower():find("attack") then
        return true
    end

    return false

end

-- Source: http://lua-users.org/wiki/CopyTable
function TableDeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[TableDeepCopy(orig_key)] = TableDeepCopy(orig_value)
        end
        setmetatable(copy, TableDeepCopy(getmetatable(orig)))
    elseif orig_type == "Vector" then
        copy = orig:clone()
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function IsEvading()
    return _G.evade or _G.Evade
end

--[[

'||'           ||    .    ||          '||   ||                    .    ||                   
 ||  .. ...   ...  .||.  ...   ....    ||  ...  ......   ....   .||.  ...    ...   .. ...   
 ||   ||  ||   ||   ||    ||  '' .||   ||   ||  '  .|'  '' .||   ||    ||  .|  '|.  ||  ||  
 ||   ||  ||   ||   ||    ||  .|' ||   ||   ||   .|'    .|' ||   ||    ||  ||   ||  ||  ||  
.||. .||. ||. .||.  '|.' .||. '|..'|' .||. .||. ||....| '|..'|'  '|.' .||.  '|..|' .||. ||. 

]]
--(scriptName, version, host, updatePath, filePath, versionPath)
if autoUpdate then
	SimpleUpdater("[SourceLib temp fix]", _G.srcLib.version, "raw.github.com" , "/kej1191/anonym/master/Common/SourceLibk.lua" , LIB_PATH .. "SourceLibk.lua" , "/kej1191/anonym/master/Common/version/SoureLibk.version" ):CheckUpdate()
end












