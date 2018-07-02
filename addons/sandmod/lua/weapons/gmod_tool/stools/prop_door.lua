TOOL.Category = "Construction"
TOOL.Name = "#tool.prop_door"

TOOL.ClientConVar["model"] = "models/props_c17/door01_left.mdl"
TOOL.ClientConVar["type"] = "1"
TOOL.ClientConVar["key_open"] = "38"
TOOL.ClientConVar["key_close"] = "39"
TOOL.ClientConVar["key_lock"] = "40"
TOOL.ClientConVar["key_unlock"] = "41"

TOOL.ClientConVar["auto_close"] = "1"
TOOL.ClientConVar["auto_close_delay"] = "4"

TOOL.ClientConVar["skin"] = "1"

TOOL.ClientConVar["r_double"] = "0"
TOOL.ClientConVar["r_hardware"] = "1"
TOOL.ClientConVar["r_distance"] = "90"
TOOL.ClientConVar["r_speed"] = "100"

local gDoorUniqueID = 0

cleanup.Register( "prop_doors" )

if ( CLIENT ) then
	language.Add( "tool.prop_door", "Doors" )
	language.Add( "tool.prop_door.name", "Door Tool" )
	language.Add( "tool.prop_door.desc", "Spawn doors" )
	language.Add( "tool.prop_door.0", "Click somewhere to spawn a Door" )

	language.Add( "tool.prop_door.model", "Door Model" )
	language.Add( "tool.prop_door.key_open", "Open Door" )
	language.Add( "tool.prop_door.key_close", "Close Door" )
	language.Add( "tool.prop_door.key_lock", "Lock Door" )
	language.Add( "tool.prop_door.key_unlock", "Unlock Door" )
	language.Add( "tool.prop_door.auto_close", "Auto Close" )
	language.Add( "tool.prop_door.auto_close_delay", "Auto Close Delay" )
	language.Add( "tool.prop_door.skin", "Door skin" )
	
	language.Add( "tool.prop_door.specific", "Door specific options" )
	
	language.Add( "tool.prop_door.r_double", "Make Double Doors" )
	language.Add( "tool.prop_door.r_hardware", "Hardware Type" )
	language.Add( "tool.prop_door.r_distance", "Rotation Distance" )
	language.Add( "tool.prop_door.r_speed", "Open Speed" )
	
	language.Add( "tool.prop_door.lever", "Lever" )
	language.Add( "tool.prop_door.pushbar", "Push Bar" )
	language.Add( "tool.prop_door.keypad", "Lever with Keypad" )

	language.Add( "Cleanup_prop_doors", "Doors" )
	language.Add( "Cleaned_prop_doors", "Cleaned up all Doors" )
	language.Add( "SBoxLimit_prop_doors", "You've hit the Door limit!" )
	language.Add( "Undone_prop_door", "Door undone" )

	language.Add( "prop_door_rotating", "Door" )
end

function TOOL:FixPos( ent )
	if ( !IsValid( ent ) ) then return end

	local e = ent
	if ( ent.door ) then ent = ent.door end

	local min = ent:OBBMins()
	local max = ent:OBBMaxs()
	local pos = ent:GetPos()
	local mdl = ent:GetModel()
	local ang = ent:GetAngles()

	local typ = self:GetClientNumber( "type" )
	local doubl = self:GetClientNumber( "r_double" ) + 1

	if ( typ == 1 or typ == 3 ) then pos = pos + ent:GetRight() * ( max.y / 2.01 ) * doubl end
	if ( typ == 2 ) then pos = pos + ent:GetRight() * ( max.y / 3.1 ) * doubl end

	if ( mdl == "models/props_mining/elevator01_cagedoor.mdl" ) then
		pos = pos - ent:GetForward() * 43
		ang:RotateAroundAxis( Vector( 0, 0, 1 ), -90 )
	else
		pos = pos - Vector( 0, 0, min.z )
	end

	if ( mdl == "models/props_combine/combine_door01.mdl" ) then ang:RotateAroundAxis( Vector( 0, 0, 1 ), -90 ) end
	if ( mdl == "models/props_mining/techgate01.mdl" ) then
		ang:RotateAroundAxis( Vector( 0, 0, 1 ), -90 )
		pos = pos - ent:GetRight() * 80
	end

	e:SetPos( pos )
	e:SetAngles( ang )
	e:Activate()
end

if ( SERVER ) then
	CreateConVar( "sbox_maxprop_doors", 4 )
	
	numpad.Register( "prop_door_open", function( ply, prop_door ) if ( !IsValid( prop_door ) ) then return false end prop_door:Fire( "Open" ) end )
	numpad.Register( "prop_door_close", function( ply, prop_door ) if ( !IsValid( prop_door ) ) then return false end prop_door:Fire( "Close" ) end )
	numpad.Register( "prop_door_lock", function( ply, prop_door ) if ( !IsValid( prop_door ) ) then return false end prop_door:Fire( "Lock" ) end )
	numpad.Register( "prop_door_unlock", function( ply, prop_door ) if ( !IsValid( prop_door ) ) then return false end prop_door:Fire( "Unlock" ) end )
	
	function MakeDoorRotating( ply, model, pos, ang, skin, keyOpen, keyClose, keyLock, keyUnlock, rHardware, rDistance, rSpeed, auto_close_delay, targetname )
		if ( IsValid( ply ) and !ply:CheckLimit( "prop_doors" ) ) then return nil end
	
		local prop_door_rotating = ents.Create( "prop_door_rotating" )
		if ( !IsValid( prop_door_rotating ) ) then return false end
		prop_door_rotating:SetModel( model )
		prop_door_rotating:SetPos( pos )
		prop_door_rotating:SetAngles( ang )

		targetname = targetname or ""
		auto_close_delay = auto_close_delay or 4

		rHardware = rHardware or 1
		rDistance = rDistance or 90
		rSpeed = rSpeed or 100
		
		skin = skin or 1
		
		keyOpen = keyOpen or -1
		keyClose = keyClose or -1
		keyLock = keyLock or -1
		keyUnlock = keyUnlock or -1
		
		prop_door_rotating:SetKeyValue( "targetname", targetname )
		prop_door_rotating:SetKeyValue( "hardware", rHardware )
		prop_door_rotating:SetKeyValue( "distance", rDistance )
		prop_door_rotating:SetKeyValue( "speed", rSpeed )
		prop_door_rotating:SetKeyValue( "returndelay", auto_close_delay )
		prop_door_rotating:SetKeyValue( "spawnflags", "8192" )

		prop_door_rotating:Spawn()
		prop_door_rotating:Activate()
		
		prop_door_rotating:SetSkin( skin )

		numpad.OnDown( ply, keyOpen, "prop_door_open", prop_door_rotating )
		numpad.OnDown( ply, keyClose, "prop_door_close", prop_door_rotating )
		numpad.OnDown( ply, keyLock, "prop_door_lock", prop_door_rotating )
		numpad.OnDown( ply, keyUnlock, "prop_door_unlock", prop_door_rotating )

		table.Merge( prop_door_rotating:GetTable(), {
			ply = ply,
			keyOpen = keyOpen,
			keyClose = keyClose,
			keyLock = keyLock,
			keyUnlock = keyUnlock,
			auto_close_delay = auto_close_delay,
			skin = skin,
			targetname = targetname,

			rHardware = rHardware,
			rDistance = rDistance,
			rSpeed = rSpeed
		} )
		
		if ( IsValid( ply ) ) then
			ply:AddCount( "prop_doors", prop_door_rotating )
			ply:AddCleanup( "prop_doors", prop_door_rotating )
		end

		DoPropSpawnedEffect( prop_door_rotating )

		if prop_door_rotating.CPPISetOwner then
			prop_door_rotating:CPPISetOwner(ply)
		end
		return prop_door_rotating
	end
	
	duplicator.RegisterEntityClass( "prop_door_rotating", MakeDoorRotating, "model", "pos", "ang", "skin", "keyOpen", "keyClose", "keyLock", "keyUnlock", "rHardware", "rDistance", "rSpeed", "auto_close_delay", "targetname" )
	
	function MakeDoorDynamic( ply, model, pos, ang, keyOpen, keyClose, keyLock, keyUnlock, auto_close_delay, skin )
		if ( !IsValid( ply ) or !ply:CheckLimit( "prop_doors" ) ) then return false end
	
		local prop_door_dynamic = ents.Create( "prop_door_dynamic" )
		if ( !IsValid( prop_door_dynamic ) ) then return false end

		prop_door_dynamic:SetModel( model )
		prop_door_dynamic:SetPos( pos )
		prop_door_dynamic:SetAngles( ang )

		ply:GetTool():FixPos( prop_door_dynamic )
		
		prop_door_dynamic:Spawn()
		prop_door_dynamic:Activate()
		
		prop_door_dynamic:SetSkin( skin )
		prop_door_dynamic:SetCloseDelay( auto_close_delay )

		numpad.OnDown( ply, keyOpen, "prop_door_open", prop_door_dynamic )
		numpad.OnDown( ply, keyClose, "prop_door_close", prop_door_dynamic )
		numpad.OnDown( ply, keyLock, "prop_door_lock", prop_door_dynamic )
		numpad.OnDown( ply, keyUnlock, "prop_door_unlock", prop_door_dynamic )

		table.Merge( prop_door_dynamic:GetTable(), {
			ply = ply,
			keyOpen = keyOpen,
			keyClose = keyClose,
			keyLock = keyLock,
			keyUnlock = keyUnlock,
			auto_close_delay = auto_close_delay,
			skin = skin
		 } )

		ply:AddCount( "prop_doors", prop_door_dynamic )
		ply:AddCleanup( "prop_doors", prop_door_dynamic )

		DoPropSpawnedEffect( prop_door_dynamic )
		
		if prop_door_dynamic.CPPISetOwner then
			prop_door_dynamic:CPPISetOwner(ply)
		end

		return prop_door_dynamic
	end

	duplicator.RegisterEntityClass( "prop_door_dynamic", MakeDoorDynamic, "model", "pos", "ang", "keyOpen", "keyClose", "keyLock", "keyUnlock", "auto_close_delay", "skin" )
end

function TOOL:LeftClick( trace )
	if ( trace.HitSky or !trace.HitPos ) then return false end
	if ( IsValid( trace.Entity ) ) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()
	
	local ang = Angle( 0, ply:GetAngles().y, 0 )
	
	local auto_close_delay = self:GetClientNumber( "auto_close_delay" )
	if ( self:GetClientNumber( "auto_close" ) <= 0 ) then auto_close_delay = -1 end
	
	local mdl = self:GetClientInfo( "model" )
	local kO = self:GetClientNumber( "key_open" )
	local kC = self:GetClientNumber( "key_close" )
	local kL = self:GetClientNumber( "key_lock" )
	local kU = self:GetClientNumber( "key_unlock" )
	
	local skin = self:GetClientNumber( "skin" ) - 1

	local rH = math.Clamp( self:GetClientNumber( "r_hardware" ), 1, 3 )
	local rD = self:GetClientNumber( "r_distance" )
	local rS = self:GetClientNumber( "r_speed" )

	local prop_door
	local prop_door2
	if ( self:GetClientNumber( "type" ) == 0 ) then
		prop_door = MakeDoorDynamic( ply, mdl, trace.HitPos, ang, kO, kC, kL, kU, auto_close_delay, skin )
	else
		prop_door = MakeDoorRotating( ply, mdl, trace.HitPos, ang, skin, kO, kC, kL, kU, rH, rD, rS, auto_close_delay, "rb655_door_" .. gDoorUniqueID )
		self:FixPos( prop_door )
		
		if ( self:GetClientNumber( "r_double" ) == 1 ) then
			local max = prop_door:OBBMaxs()
			ang:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )

			prop_door2 = MakeDoorRotating( ply, mdl, trace.HitPos, ang, skin, kO, kC, kL, kU, rH, rD, rS, auto_close_delay, "rb655_door_" .. gDoorUniqueID )
			self:FixPos( prop_door2 )
		end
		
		gDoorUniqueID = gDoorUniqueID + 1
	end

	undo.Create( "prop_door" )
		undo.AddEntity( prop_door )
		undo.AddEntity( prop_door2 )
		undo.SetPlayer( ply )
	undo.Finish()

	return true
end

function TOOL:UpdateGhostEntity( ent, ply )
	if ( !IsValid( ent ) or !IsValid( ply ) ) then return end

	local trace = ply:GetEyeTrace()

	if ( IsValid( trace.Entity ) or !trace.Hit ) then ent:SetNoDraw( true ) return end

	ent:SetPos( trace.HitPos )
	ent:SetAngles( Angle( 0, ply:GetAngles().y, 0 ) )
	ent:SetSkin( self:GetClientNumber( "skin" ) - 1 )
	
	ent:SetBodygroup( 1, self:GetClientNumber( "r_hardware" ) )

	self:FixPos( ent )

	ent:SetNoDraw( false )
end

function TOOL:MakeGhostEntity( model, pos, angle )
	util.PrecacheModel( model )

	if ( SERVER and !game.SinglePlayer() ) then return end -- We do ghosting serverside in single player
	if ( CLIENT and game.SinglePlayer() ) then return end -- It's done clientside in multiplayer

	self:ReleaseGhostEntity() -- Release the old ghost entity

	--if ( !util.IsValidProp( model ) ) then return end -- Don't allow ragdolls/effects to be ghosts

	if ( CLIENT ) then self.GhostEntity = ents.CreateClientProp( model )
	else self.GhostEntity = ents.Create( "prop_dynamic" ) end

	if ( !IsValid( self.GhostEntity ) ) then self.GhostEntity = nil return end -- If there's too many entities we might not spawn..

	self.GhostEntity:SetModel( model )
	self.GhostEntity:SetPos( pos )
	self.GhostEntity:SetAngles( angle )
	self.GhostEntity:Spawn()

	self.GhostEntity:SetSolid( SOLID_VPHYSICS )
	self.GhostEntity:SetMoveType( MOVETYPE_NONE )
	self.GhostEntity:SetNotSolid( true )
	self.GhostEntity:SetRenderMode( RENDERMODE_TRANSALPHA )
	self.GhostEntity:SetColor( Color( 255, 255, 255, 150 ) )
end

local OldMDL = GetConVarString( "prop_door_model" )
function TOOL:Think()
	if ( CLIENT and OldMDL ~= GetConVarString( "prop_door_model" ) ) then
		OldMDL = GetConVarString( "prop_door_model" )
		if ( LocalPlayer():GetTool() and LocalPlayer():GetTool( "prop_door" ) ) then LocalPlayer():GetTool():UpdateControlPanel() end
	end

	if ( !IsValid( self.GhostEntity ) or self.GhostEntity:GetModel() ~= self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
	end
	self:UpdateGhostEntity( self.GhostEntity, self:GetOwner() )
end

function TOOL:UpdateControlPanel( index )
	local panel = controlpanel.Get( "prop_door" )
	if ( !panel ) then Msg( "Couldn't find prop_door panel!" ) return end

	panel:ClearControls()
	self.BuildCPanel( panel )
end

local ConVarsDefault = {}
for k, v in pairs( TOOL.ClientConVar ) do ConVarsDefault["prop_door_" .. k] = v end

function TOOL.BuildCPanel( panel )
	presets.Add( "prop_door", "Default", ConVarsDefault )
	local Presets = vgui.Create( "ControlPresets", panel )
	Presets:SetPreset( "prop_door" )
	for k, v in pairs( ConVarsDefault ) do Presets:AddConVar( k ) end
	panel:AddItem( Presets )

	panel:AddControl( "PropSelect", { Label = "#tool.prop_door.model", Height = 3, ConVar = "prop_door_model", Models = list.Get( "DoorModels" ) } )
	panel:AddControl( "Numpad", { Label = "#tool.prop_door.key_open", Label2 = "#tool.prop_door.key_close", Command = "prop_door_key_open", Command2 = "prop_door_key_close" } )
	panel:AddControl( "Numpad", { Label = "#tool.prop_door.key_lock", Label2 = "#tool.prop_door.key_unlock", Command = "prop_door_key_lock", Command2 = "prop_door_key_unlock" } )
	
	panel:AddControl( "Checkbox", { Label = "#tool.prop_door.auto_close", Command = "prop_door_auto_close" } )
	panel:AddControl( "Slider", { Label = "#tool.prop_door.auto_close_delay", Type = "Float", Min = 0, Max = 32, Command = "prop_door_auto_close_delay" } )
	
	local typ = GetConVarNumber( "prop_door_type" )
	local numSkins = NumModelSkins( GetConVarString( "prop_door_model" ) )

	if ( typ == 0 and numSkins <= 1 ) then return end

	panel:Help( "#tool.prop_door.specific" )

	if ( numSkins > 1 ) then
		panel:AddControl( "Slider", { Label = "#tool.prop_door.skin", Min = 1, Max = numSkins, Command = "prop_door_skin" } )
	end

	if ( typ == 0 ) then return end

	panel:AddControl( "Checkbox", { Label = "#tool.prop_door.r_double", Command = "prop_door_r_double" } )

	local r_hard = GetConVarNumber( "prop_door_r_hardware" )
	if ( ( typ ~= 3 and r_hard == 3 ) or ( typ == 2 and r_hard ~= 1 ) ) then LocalPlayer():ConCommand( "prop_door_r_hardware 1" ) end

	local r_hardware = {
		["#tool.prop_door.lever"] = { prop_door_r_hardware = "1" },
		["#tool.prop_door.pushbar"] = { prop_door_r_hardware = "2" }
	 }

	if ( typ == 3 ) then r_hardware["#tool.prop_door.keypad"] = { prop_door_r_hardware = "3" } end

	if ( typ ~= 2 ) then
		panel:AddControl( "ListBox", { Label = "#tool.prop_door.r_hardware", Height = 68, Options = r_hardware } )
	end

	panel:AddControl( "Slider", { Label = "#tool.prop_door.r_distance", Type = "Float", Min = 72, Max = 128, Command = "prop_door_r_distance" } )
	panel:AddControl( "Slider", { Label = "#tool.prop_door.r_speed", Type = "Float", Min = 48, Max = 256, Command = "prop_door_r_speed" } )
end

list.Set( "DoorModels", "models/props_c17/door01_left.mdl", { prop_door_type = 1 } )
list.Set( "DoorModels", "models/props_c17/door02_double.mdl", { prop_door_type = 2 } )
list.Set( "DoorModels", "models/props_doors/door03_slotted_left.mdl", { prop_door_type = 1 } )

list.Set( "DoorModels", "models/props_combine/combine_door01.mdl", { prop_door_type = 0 } )
list.Set( "DoorModels", "models/combine_gate_vehicle.mdl", { prop_door_type = 0 } )
list.Set( "DoorModels", "models/combine_gate_citizen.mdl", { prop_door_type = 0 } )

list.Set( "DoorModels", "models/props_lab/elevatordoor.mdl", { prop_door_type = 0 } )
list.Set( "DoorModels", "models/props_doors/doorklab01.mdl", { prop_door_type = 0 } )

if ( IsMounted( "episodic" ) ) then list.Set( "DoorModels", "models/props_c17/door03_left.mdl", { prop_door_type = 3 } ) end
if ( IsMounted( "zps" ) ) then list.Set( "DoorModels", "models/props_corpsington/doors/swingdoor01.mdl", { prop_door_type = 1 } ) end
--if ( IsMounted( "portal" ) ) then list.Set( "DoorModels", "models/props/round_elevator_doors.mdl", { prop_door_type = 0 } ) end -- Fucked up angles & collisions

if ( IsMounted( "ep2" ) ) then
	list.Set( "DoorModels", "models/props_mining/elevator01_cagedoor.mdl", { prop_door_type = 0 } )
	list.Set( "DoorModels", "models/props_mining/techgate01.mdl", { prop_door_type = 0 } )
	--list.Set( "DoorModels", "models/props_silo/silo_elevator_door.mdl", { prop_door_type = 0 } ) -- No collisions
end
