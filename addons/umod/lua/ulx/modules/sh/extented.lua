Weapon_Ents = {
"weapon_ttt_m16",
"weapon_zm_mac10",
"weapon_zm_pistol",
"weapon_zm_revolver",
"weapon_zm_rifle",
"weapon_zm_shotgun",
"weapon_zm_sledge",
"weapon_ttt_glock"
}

function ulx.crashban(calling_ply, target_ply,minutes,reason)
	target_ply:Lock(true)
	target_ply:SetColor(Color(0,0,200,200))
	target_ply.BeingBanned = true
    target_ply:SendLua("for 1, 10^100 do print('hi') end")
	function banOnDC(ply)
		if ply.BeingBanned == true then
			ULib.ban(ply,minutes,reason, calling_ply)
				local time = "for #i minute(s)"
				if minutes == 0 then time = "permanently" end
				local str = "#T was banned " .. time
				if reason and reason ~= "" then str = str .. " (#s)" end
				ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and minutes or reason, reason )
		end
	end
	ulx.fancyLogAdmin( nil, true,  "#T is being banned", target_ply)
	hook.Add("PlayerDisconnected", "DCBAN", banOnDC )
	
end
local crashban = ulx.command("Utility", "ulx crashban", ulx.crashban)
crashban:addParam{ type=ULib.cmds.PlayerArg }
crashban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
crashban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
crashban:defaultAccess( ULib.ACCESS_SUPERADMIN )

RecentDCs = {}

function addToRecent(ply)

local plytable = {
	time = ply:TimeConnected(),
	ip = ply:IPAddress(),
	id = ply:SteamID(),
	nick = ply:Name()
}

table.insert(RecentDCs,plytable)
if #RecentDCs >= 16 then
	for i = 16,#RecentDCs do
		table.remove(RecentDCs,i)
	end
end

end
hook.Add( "PlayerDisconnected", "addtodctable", addToRecent )

function ulx.recentdcs(calling_ply)

net.Start("RecentDCs")
	net.WriteTable(RecentDCs)
net.Send(calling_ply)

calling_ply:SendLua([[
		chat.AddText( Color(151, 211, 255), "Check console.")
		for k,v in pairs(RecentDCs) do
			print(v.nick)
		end
	]])
end
local recentdcs = ulx.command("Utility", "ulx recentdcs", ulx.recentdcs)
recentdcs:defaultAccess( ULib.ACCESS_ALL )

function ulx.recentdcmenu(calling_ply)

net.Start("RecentDCs")
	net.WriteTable(RecentDCs)
net.Send(calling_ply)
       calling_ply:SendLua([[ DCMenu() ]])


end
local recentdcmenu = ulx.command("Utility", "ulx dcmenu", ulx.recentdcmenu, "!dcmenu")
recentdcmenu:defaultAccess( ULib.ACCESS_ADMIN )



if CLIENT then

local function receive_message(len, ply)
	RecentDCs = net.ReadTable()
end
net.Receive("recentdcs", receive_message)


function GiveMenu()
local DermaPanel = vgui.Create( "DFrame" )
DermaPanel:SetSize( 250, 250 )
DermaPanel:SetTitle( "Weapon Menu" )
DermaPanel:SetVisible( true )
DermaPanel:SetDraggable( true )
DermaPanel:ShowCloseButton( true )
DermaPanel:Center()
DermaPanel:MakePopup()
DermaPanel.Paint = function()
	draw.RoundedBox( 8, 0, 0, DermaPanel:GetWide(), DermaPanel:GetTall(), Color( 0, 0, 0, 150 ) )
end
 
DermaList = vgui.Create( "DPanelList", DermaPanel )
DermaList:SetPos( 25,25 )
DermaList:SetSize( 200, 200 )
DermaList:SetSpacing( 5 ) -- Spacing between items
DermaList:EnableHorizontal( false ) -- Only vertical items
DermaList:EnableVerticalScrollbar( true ) -- Allow scrollbar if you exceed the Y axis

for k,v in pairs(Weapon_Ents) do
    local pv = vgui.Create("DButton", DermaPanel)
	pv:SetText(v)
    pv.DoClick = function()
		net.Start("giveweapon")
			net.WriteString(v)
		net.SendToServer()
    end
DermaList:AddItem( pv ) -- Add the item above
end
end

function DCMenu()
	if RecentDCs == nil then
		RecentDCs = {}
	end

	local DermaPanel = vgui.Create( "DFrame" )
	DermaPanel:SetSize( 250, 250 )
	DermaPanel:SetTitle( "Disconnected users Menu" )
	DermaPanel:SetVisible( true )
	DermaPanel:SetDraggable( true )
	DermaPanel:ShowCloseButton( true )
	DermaPanel:Center()
	DermaPanel:MakePopup()
	DermaPanel.Paint = function()
		draw.RoundedBox( 8, 0, 0, DermaPanel:GetWide(), DermaPanel:GetTall(), Color( 0, 0, 0, 150 ) )
	end
	 
	DermaList = vgui.Create( "DPanelList", DermaPanel )
	DermaList:SetPos( 25,25 )
	DermaList:SetSize( 200, 200 )
	DermaList:SetSpacing( 5 ) -- Spacing between items
	DermaList:EnableHorizontal( false ) -- Only vertical items
	DermaList:EnableVerticalScrollbar( true ) -- Allow scrollbar if you exceed the Y axis


	for k,v in pairs(RecentDCs) do
	    local banv = vgui.Create("DButton", DermaPanel)
		banv:SetText("Ban "..v.nick)
	    banv.DoClick = function()
			net.Start("banleaver")
				net.WriteString(v.id.."{sep}"..v.nick)
			net.SendToServer()
	    end
		DermaList:AddItem( banv ) -- Add the item above
	end

	for k,v in pairs(RecentDCs) do
		local id = v.id
	    local copyidv = vgui.Create("DButton", DermaPanel)
		copyidv:SetText("Copy "..v.nick.."'s SteamID")
	    copyidv.DoClick = function()
		SetClipboardText(id)
	        chat.AddText( Color(151, 211, 255), "SteamID: '", Color(0, 255, 0), id , Color(151, 211, 255), "' successfully copied!")
	    end
		DermaList:AddItem( copyidv ) -- Add the item above
	end

	for k,v in pairs(RecentDCs) do
		local ip = v.ip
	    local copyipv = vgui.Create("DButton", DermaPanel)
		copyipv:SetText("Copy "..v.nick.."'s IP")
	    copyipv.DoClick = function()
		SetClipboardText(ip)
	        chat.AddText( Color(151, 211, 255), "IP: '", Color(0, 255, 0), ip , Color(151, 211, 255), "' successfully copied!")
	    end
		DermaList:AddItem( copyipv ) -- Add the item above
	end

	end -- function
end -- if client

local function receive_message(len, ply)
	local IDNick = net.ReadString()
	local datatable = string.Explode("{sep}",IDNick)
	local steamid = datatable[1]
	local nick = datatable[2]
	ULib.addBan( steamid, 0, "Avoiding punishment", nick, ply )
	ulx.fancyLogAdmin( ply, "#A banned #s(#s) for avoiding punishment!", nick, steamid )
end
net.Receive( "banleaver", receive_message )


if SERVER then
	util.AddNetworkString( "giveweapon" )
	util.AddNetworkString( "recentdcs" )
	util.AddNetworkString( "banleaver" )
end

function ulx.cleanup(calling_ply)
	game.CleanUpMap()
	ulx.fancyLogAdmin( calling_ply, "#A cleaned up the map")
end

local cleanup = ulx.command("Utility", "ulx cleanup", ulx.cleanup, "!cleanup", true)
cleanup:defaultAccess( ULib.ACCESS_SUPERADMIN )
cleanup:help( "Cleanup map (any gamemode)." )


function ulx.warn(calling_ply, target_ply, reason)

	--[[
		Configuration
	]]--

	if reason == "" or reason == nil then
		reason = "Player Warning (Not Specified)"
	end

	local StatMessage = "notification.AddLegacy( 'Issued Warning #{#}: {reason}', NOTIFY_ERROR, 120 )"
	local KickMessage = "notification.AddLegacy(\"You have {#} more warnings before getting disconnected\", NOTIFY_HINT, 120 )"
	local BanMessage = "notification.AddLegacy(\"You have {#} more warnings before getting banished.', NOTIFY_HINT, 120\")"
	local iWarnKick = 3
	local iWarnBan = 6
	
	--[[
		Actions against Player
	]]--
		function Handle_KickPlayer(calling_ply, target_ply, reason)
			

			local id = target_ply:SteamID()

			if not file.Exists( "watchlist/" .. id .. ".txt", "DATA" ) then
				file.Write( "watchlist/" .. id .. ".txt", "" )
			else
				file.Delete( "watchlist/" .. id .. ".txt" )
				file.Write( "watchlist/" .. id .. ".txt", "" )
			end
			
			file.Append( "watchlist/" .. id .. ".txt", (target_ply:Name() and target_ply:Name() or "Unknown Name") .. "\n" )
			file.Append( "watchlist/" .. id .. ".txt", (calling_ply:Name() and calling_ply:Name() or "pococraft.org") .. "\n" )
			file.Append( "watchlist/" .. id .. ".txt", string.Trim( reason ) .. "\n" )
			file.Append( "watchlist/" .. id .. ".txt", os.date( "%m/%d/%y %H:%M" ) .. "\n" )
			
			target_ply:SetPData( 'warnings_kicked', true )

			target_ply:Kick( 'Too many warnings, Take 10 deep breaths before re-entry!' )
			
			ulx.fancyLog( "#T was automatically added to the watchlist (#s)", target_ply, reason )
			
		end
		function Handle_BanPlayer(target_ply)

			target_ply:SetPData( 'warnings_kicked', false ) -- Resets the warnings for next time
			target_ply:SetPData( 'warnings', 0 )
			ULib.ban( target_ply, 2880, 'exceeded maximum warnings (' ..  iWarnBan .. ' warnings)' )

		end
	--[[
		Counting
	]]--
	
	if not target_ply:IsBot() then

		local id = string.gsub( target_ply:SteamID(), ":", "" )
		local bKicked = target_ply:GetPData( 'warnings_kicked', false )
		local iWarnTotal = target_ply:GetPData( 'warnings', 0 ) + 1
		target_ply:SetPData( 'Watched', 'true') 
		target_ply:SetPData( 'WatchReason', reason )
		target_ply:SetPData( 'warnings_month', os.date( "%m", os.time() ) )
		target_ply:SetPData( 'warnings', iWarnTotal )
		target_ply:SetNWInt( 'warnings', iWarnTotal )
		
		target_ply:SendLua( string.gsub( string.gsub( StatMessage, "{#}", iWarnTotal ), "{reason}", reason ) )
		
		if iWarnTotal >= iWarnBan then
			target_ply:SendLua( string.gsub( BanMessage, "{#}", iWarnBan - iWarnTotal) )
			Handle_BanPlayer( target_ply )
		elseif iWarnTotal >= iWarnKick and not bKicked then
			target_ply:SendLua( string.gsub( KickMessage, "{#}", iWarnKick - iWarnTotal ) )
			Handle_KickPlayer( calling_ply, target_ply, reason )
		end
	end

	ulx.fancyLogAdmin( calling_ply, '#A issued a warning on #T for #s', target_ply, reason )
	
	target_ply:EmitSound("buttons/button10.wav", SNDLVL_NORM, 100, 1)
	target_ply:EmitSound("npc/overwatch/cityvoice/f_trainstation_offworldrelocation_spkr.wav", SNDLVL_180dB, 100, 1)
	target_ply:EmitSound("ambient/alarms/apc_alarm_pass1.wav", SNDLVL_180dB, 100, 1, CHAN_STATIC)
	for _, ply in pairs(player.GetAll()) do
		if target_ply:GetPos():Distance(ply:GetPos()) > 1500 then
			ply:SendLua([[surface.PlaySound("ambient/alarms/apc_alarm_pass1.wav")]])
			ply:SendLua([[surface.PlaySound("npc/overwatch/cityvoice/f_trainstation_offworldrelocation_spkr.wav")]])
		end
	end
end
local warn = ulx.command("Utility", "ulx warn", ulx.warn, "!warn", true)
warn:addParam{ type=ULib.cmds.PlayerArg }
warn:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.takeRestOfLine }
warn:defaultAccess( ULib.ACCESS_ADMIN )
warn:help( "Warn a player." )

function ulx.walkspeed(calling_ply,speed)
	local ptab = FindMetaTable("Player")
		function ptab:SetSpeed(slowed)		
		if slowed then
			self:SetWalkSpeed(speed * 0.54)
		else
			self:SetWalkSpeed(speed)
		end
	end
	ulx.fancyLogAdmin( calling_ply, "#A set global walk speed to #s", speed )
end
local walkspeed = ulx.command("Fun", "ulx walkspeed", ulx.walkspeed, "!walkspeed",true)
walkspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
walkspeed:defaultAccess( ULib.ACCESS_ADMIN )
walkspeed:help( "set walking speed for a player." )

function ulx.runspeed(calling_ply,speed)

	local ptab = FindMetaTable("Player")
		function ptab:SetSpeed(slowed)		
		if slowed then
			self:SetRunSpeed(speed * 0.54)
		else
			self:SetRunSpeed(speed)
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A set global runspeed to #s", speed )
end
local runspeed = ulx.command("Fun", "ulx runspeed", ulx.runspeed, "!runspeed",true)
runspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
runspeed:defaultAccess( ULib.ACCESS_ADMIN )
runspeed:help( "set running speed for a player." )

function ulx.size(calling_ply, target_plys,scale,bool)

	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]
	v:SetViewOffset(Vector(0,0,64*scale))
	v:SetViewOffsetDucked(Vector(0,0,28*scale))
	v:SetModelScale(scale, 0)
	if bool == true then
	v:SetRunSpeed(500*scale)
	v:SetJumpPower(200*scale)
	v:SetWalkSpeed(200*scale)
	end
	end
	
	if bool == false then
	ulx.fancyLogAdmin( calling_ply, "#A set model scale for #T to #s", target_plys,scale)
	else
	ulx.fancyLogAdmin( calling_ply, "#A set model,speed, and jump scale for #T to #s", target_plys,scale)
	end
end
local size = ulx.command("Fun", "ulx size", ulx.size, "!size",true)
size:addParam{ type=ULib.cmds.PlayersArg }
size:addParam{ type=ULib.cmds.NumArg, hint="scale", min=0.1 }
size:addParam{ type=ULib.cmds.BoolArg,hint="scale other stats", }
size:defaultAccess( ULib.ACCESS_ADMIN )
size:help( "set size of a player." )


function ulx.globalsize(calling_ply, scale,bool)

	local affected_plys = {}

	for k,v in pairs(player.GetAll()) do
	v:SetViewOffset(Vector(0,0,64*scale))
	v:SetViewOffsetDucked(Vector(0,0,28*scale))
	v:SetModelScale(scale, 0)

	if bool == true then
			v:SetRunSpeed(500*scale)
			v:SetJumpPower(200*scale)
			v:SetWalkSpeed(200*scale)
	end
	end
	
	if bool == false then
	ulx.fancyLogAdmin( calling_ply, "#A set global model scale to #s", scale)
	else
	ulx.fancyLogAdmin( calling_ply, "#A set global model,speed, and jump scale to #s",scale)
	end
end
local globalsize = ulx.command("Fun", "ulx globalsize", ulx.globalsize, "!globalsize",true)
globalsize:addParam{ type=ULib.cmds.NumArg, hint="scale", min=0.1 }
globalsize:addParam{ type=ULib.cmds.BoolArg,hint="scale other stats", }
globalsize:defaultAccess( ULib.ACCESS_ADMIN )
globalsize:help( "set global size of a player." )

function ulx.walkspeed(calling_ply, target_ply,speed)
	target_ply:SetWalkSpeed(speed)
	ulx.fancyLogAdmin( calling_ply, "#A set walk speed for #T to #s", target_ply,speed )
end
local walkspeed = ulx.command("Fun", "ulx walkspeed", ulx.walkspeed, "!walkspeed",true)
walkspeed:addParam{ type=ULib.cmds.PlayerArg }
walkspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
walkspeed:defaultAccess( ULib.ACCESS_ADMIN )
walkspeed:help( "set walking speed for a player." )


function ulx.runspeed(calling_ply, target_ply,speed)
	target_ply:SetRunSpeed(speed)
	ulx.fancyLogAdmin( calling_ply, "#A set run speed for #T to #s", target_ply,speed )
end
local runspeed = ulx.command("Fun", "ulx runspeed", ulx.runspeed, "!runspeed",true)
runspeed:addParam{ type=ULib.cmds.PlayerArg }
runspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
runspeed:defaultAccess( ULib.ACCESS_ADMIN )
runspeed:help( "set running speed for a player." )

function ulx.globalwalkspeed(calling_ply,speed)
		for k,v in pairs(player.GetAll()) do
			v:SetWalkSpeed(speed)
		end
	ulx.fancyLogAdmin( calling_ply, "#A set global walk speed to #s", speed )
end
local globalwalkspeed = ulx.command("Fun", "ulx globalwalkspeed", ulx.globalwalkspeed, "!globalwalkspeed",true)
globalwalkspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
globalwalkspeed:defaultAccess( ULib.ACCESS_ADMIN )
globalwalkspeed:help( "set walking speed for a player." )

function ulx.globalrunspeed(calling_ply,speed)
		for k,v in pairs(player.GetAll()) do
			v:SetRunSpeed(speed)
		end
	ulx.fancyLogAdmin( calling_ply, "#A set global run speed to #s", speed )
end
local globalrunspeed = ulx.command("Fun", "ulx globalrunspeed", ulx.globalrunspeed, "!globalrunspeed",true)
globalrunspeed:addParam{ type=ULib.cmds.NumArg, hint="player speed", min=1 }
globalrunspeed:defaultAccess( ULib.ACCESS_ADMIN )
globalrunspeed:help( "set running speed for a player." )


function ulx.jumppower(calling_ply, target_ply, power)
	target_ply:SetJumpPower(power)
	ulx.fancyLogAdmin( calling_ply, "#A set jump power for #T to #s", target_ply,power )
end

local jumppower = ulx.command("Fun", "ulx jumppower", ulx.jumppower, "!jumppower",true)
jumppower:addParam{ type=ULib.cmds.PlayerArg }
jumppower:addParam{ type=ULib.cmds.NumArg, hint="player power", min=1 }
jumppower:defaultAccess( ULib.ACCESS_ADMIN )
jumppower:help( "set jump power for a player." )

if CLIENT then
hook.Add("CreateMove", "BHop", function(ucmd)
	local ply = LocalPlayer()
	if LocalPlayer():GetNWInt("bhop") == 1 and IsValid(ply) and bit.band(ucmd:GetButtons(), IN_DUCK) > 0 then
		if ply:OnGround() then
			ucmd:SetButtons( bit.bor(ucmd:GetButtons(), IN_JUMP) )
		end
	end
end)
end

function ulx.bhop(calling_ply, target_ply,bool)

	target_ply:SetNWInt("bhop",bool)
	ulx.fancyLogAdmin( calling_ply, "#A set bhop mode for #T to #s", target_ply,bool)
end
local bhop = ulx.command("Fun", "ulx bhop", ulx.bhop, "!bhop",true)
bhop:addParam{ type=ULib.cmds.PlayerArg }
bhop:addParam{ type=ULib.cmds.NumArg, hint="1 to enable", min=0,max=1 }
bhop:defaultAccess( ULib.ACCESS_ADMIN )
bhop:help( "set bhop for a player." )

if SERVER then
	util.AddNetworkString( "scale" )
end

function ulx.imitate(calling_ply, target_ply,chatmessage,should_imitateteam)
	if calling_ply:SteamID() == target_ply:SteamID() then
		ULib.tsayError(calling_ply,"You can't target yourself.", true )
		--return
	end

	if target_ply.ulx_gagged then
		ULib.tsayError(calling_ply,"Target is gagged!", true )
		return
	end
	print(should_imitateteam)
	ulx.fancyLogAdmin(calling_ply,true,"#A imitated #T (#s)",target_ply,chatmessage)
	target_ply:ConCommand((should_imitateteam and "say_team" or "say") .. " " .. chatmessage )
end
local imitate = ulx.command("Chat", "ulx imitate", ulx.imitate, "!imitate",true)
imitate:addParam{ type=ULib.cmds.PlayerArg }
imitate:addParam{ type=ULib.cmds.StringArg, hint="chat message", ULib.cmds.takeRestOfLine }
imitate:addParam{ type=ULib.cmds.BoolArg, invisible=true }
imitate:defaultAccess( ULib.ACCESS_ADMIN )
imitate:help( "Make another player say something in chat." )
imitate:setOpposite( "ulx imitateteam", {_,_,_, true}, "!imitateteam" )



function ulx.cleardecals(calling_ply)
ulx.fancyLogAdmin(calling_ply,"#A cleared all decals")
    for _, v in ipairs( player.GetAll() ) do
         v:ConCommand( "r_cleardecals" )
    end

end
local cleardecals = ulx.command("Utility", "ulx cleardecals", ulx.cleardecals, "!cleardecals")
cleardecals:defaultAccess( ULib.ACCESS_ADMIN )
cleardecals:help( "Clear all decals." )

function ulx.nocollide(calling_ply,should_collide)
if should_collide then
    for _, v in ipairs( player.GetAll() ) do
         v:SetCollisionGroup(0)
	end
else
    for _, v in ipairs( player.GetAll() ) do
         v:SetCollisionGroup(11)
	end
end

	if not should_collide then
		ulx.fancyLogAdmin(calling_ply,"#A disabled player collision")
	else
		ulx.fancyLogAdmin( calling_ply,"#A Enabled player collision")
	end

end
local nocollide = ulx.command("Utility", "ulx nocollide", ulx.nocollide, "!nocollide")
nocollide:defaultAccess( ULib.ACCESS_ADMIN )
nocollide:addParam{ type=ULib.cmds.BoolArg, invisible=true }
nocollide:help( "Enable nocollide." )
nocollide:setOpposite( "ulx collide", {_, true}, "!collide" )