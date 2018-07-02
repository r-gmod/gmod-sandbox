
TOOL.Category = "Construction"
TOOL.Name = "#tool.prop_thumper"

TOOL.ClientConVar["model"] = "models/props_combine/CombineThumper002.mdl"
TOOL.ClientConVar["dustscale"] = "128"
TOOL.ClientConVar["activate"] = "38"
TOOL.ClientConVar["deactivate"] = "39"

cleanup.Register( "prop_thumpers" )

if ( CLIENT ) then
	language.Add( "tool.prop_thumper", "HL2 Thumpers" )
	language.Add( "tool.prop_thumper.name", "Thumper Tool" )
	language.Add( "tool.prop_thumper.desc", "Spawn thumpers" )
	language.Add( "tool.prop_thumper.0", "Click somewhere to spawn a Thumper" )

	language.Add( "tool.prop_thumper.model", "Thumper Model" )
	language.Add( "tool.prop_thumper.dustscale", "Thumper Dust Size" )
	language.Add( "tool.prop_thumper.dustscale.help", "The scale of dust produced when thumper hits ground." )
	language.Add( "tool.prop_thumper.activate", "Activate Thumper" )
	language.Add( "tool.prop_thumper.deactivate", "Deactivate Thumper" )
	
	language.Add( "Cleanup_prop_thumpers", "Thumpers" )
	language.Add( "Cleaned_prop_thumpers", "Cleaned up all Thumpers" )
	language.Add( "SBoxLimit_prop_thumpers", "You've hit the Thumper limit!" )
	language.Add( "Undone_prop_thumper", "Thumper undone" )

	language.Add( "prop_thumper", "Thumper" )
end

if ( SERVER ) then
	CreateConVar( "sbox_maxprop_thumpers", 3 )
	
	numpad.Register( "prop_thumper_on", function( ply, prop_thumper )
		if ( !IsValid( prop_thumper ) ) then return false end
		prop_thumper:Fire( "Enable" )
	end )

	numpad.Register( "prop_thumper_off", function( ply, prop_thumper )
		if ( !IsValid( prop_thumper ) ) then return false end
		prop_thumper:Fire( "Disable" )
	end )
	
	function MakeThumper( ply, model, pos, ang, keyOn, keyOff, dustscale )
		if ( IsValid( ply ) and !ply:CheckLimit( "prop_thumpers" ) ) then return nil end
	
		local prop_thumper = ents.Create( "prop_thumper" )
		if ( !IsValid( prop_thumper ) ) then return false end

		prop_thumper:SetPos( pos )
		prop_thumper:SetAngles( ang )
		
		keyOn = keyOn or -1
		keyOff = keyOff or -1
		dustscale = tonumber( dustscale ) or 128

		if ( model == "models/props_combine/combinethumper001a.mdl" ) then
			local vec1 = Vector( -64, 72, 256 )
			vec1:Rotate( ang )
			local Lpos = pos + vec1
			
			local ladder = ents.Create("func_useableladder")
			ladder:SetPos( Lpos )
			ladder:SetAngles( ang )
			ladder:SetKeyValue( "targetname", "rb655_ThumperLadder_" .. prop_thumper:EntIndex() )
			ladder:SetKeyValue( "point0", Lpos.x .. " " .. Lpos.y .. " " .. Lpos.z )
			ladder:SetKeyValue( "point1", Lpos.x .. " " .. Lpos.y .. " " .. (Lpos.z - 252) )
			ladder:Spawn()

			prop_thumper:DeleteOnRemove(ladder)
			ladder:DeleteOnRemove(prop_thumper)
		end

		prop_thumper:SetKeyValue( "dustscale", math.Clamp( dustscale, 64, 1024 ) )
		prop_thumper:SetModel( model )
		prop_thumper:Spawn()
		prop_thumper:Activate()

		prop_thumper.NumpadOn = numpad.OnDown( ply, keyOn, "prop_thumper_on", prop_thumper )
		prop_thumper.NumpadOff = numpad.OnDown( ply, keyOff, "prop_thumper_off", prop_thumper )

		table.Merge( prop_thumper:GetTable(), {
			ply = ply,
			keyOn = keyOn,
			keyOff = keyOff,
			dustscale = dustscale
		} )
		
		if ( IsValid( ply ) ) then
			ply:AddCount( "prop_thumpers", prop_thumper )
			ply:AddCleanup( "prop_thumpers", prop_thumper )
		end

		DoPropSpawnedEffect( prop_thumper )

		return prop_thumper
	end
	
	duplicator.RegisterEntityClass( "prop_thumper", MakeThumper, "model", "pos", "ang", "keyOn", "keyOff", "dustscale" )
end

function TOOL:LeftClick( trace )
	if ( trace.HitSky or !trace.HitPos or trace.HitNormal.z < 0.98 ) then return false end
	if ( IsValid( trace.Entity ) and ( trace.Entity:GetClass() == "prop_thumper" or trace.Entity:IsPlayer() or trace.Entity:IsNPC() ) ) then return false end
	if ( CLIENT ) then return true end

	local ply = self:GetOwner()
	
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch - 270
	
	if ( trace.HitNormal.z > 0.99 ) then ang.y = ply:GetAngles().y + 90 end

	local prop_thumper = MakeThumper( ply, self:GetClientInfo( "model" ),
		trace.HitPos, ang,
		self:GetClientNumber( "activate" ),
		self:GetClientNumber( "deactivate" ),
		self:GetClientNumber( "dustscale" ),
		self:GetClientNumber( "distance" )
	)
	
	undo.Create( "prop_thumper" )
		undo.AddEntity( prop_thumper )
		undo.SetPlayer( ply )
	undo.Finish()

	return true
end

function TOOL:UpdateGhostEntity( ent, ply )
	if ( !IsValid( ent ) ) then return end
	
	local trace = ply:GetEyeTrace()

	if ( !trace.Hit or trace.HitNormal.z < 0.98 or trace.Entity and ( trace.Entity:GetClass() == "prop_thumper" or trace.Entity:IsPlayer() or trace.Entity:IsNPC() ) ) then
		ent:SetNoDraw( true )
		return
	end
	
	local ang = trace.HitNormal:Angle()
	ang.pitch = ang.pitch - 270
	
	if ( trace.HitNormal.z > 0.99 ) then ang.y = ply:GetAngles().y + 90 end
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	
	ent:SetAngles( ang )
	ent:SetNoDraw( false )
end

function TOOL:Think()
	if ( !IsValid( self.GhostEntity ) or self.GhostEntity:GetModel() ~= self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
	end
	self:UpdateGhostEntity( self.GhostEntity, self:GetOwner() )
end

local ConVarsDefault = {}
for k, v in pairs( TOOL.ClientConVar ) do  ConVarsDefault["prop_thumper_" .. k] = v end

function TOOL.BuildCPanel( panel )
	presets.Add( "prop_thumper", "Default", ConVarsDefault )
	local Presets = vgui.Create( "ControlPresets", panel )
	Presets:SetPreset( "prop_thumper" )
	for k, v in pairs( ConVarsDefault ) do Presets:AddConVar( k ) end
	panel:AddItem( Presets )

	panel:AddControl( "PropSelect", { Label = "#tool.prop_thumper.model", Height = 1, ConVar = "prop_thumper_model", Models = list.Get( "ThumperModels" ) } )
	panel:AddControl( "Numpad", { Label = "#tool.prop_thumper.activate", Label2 = "#tool.prop_thumper.deactivate", Command = "prop_thumper_activate", Command2 = "prop_thumper_deactivate" } )
	panel:AddControl( "Slider", { Label = "#tool.prop_thumper.dustscale", Min = 64, Max = 1024, Command = "prop_thumper_dustscale", Help = true } )
end

list.Set( "ThumperModels", "models/props_combine/CombineThumper001a.mdl", {} )
list.Set( "ThumperModels", "models/props_combine/CombineThumper002.mdl", {} )
