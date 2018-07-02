TOOL.Category	= "Construction"
TOOL.Name		= "#tool.smart_remover.name"
TOOL.Command	= nil
TOOL.ConfigName = nil

TOOL.ClientConVar["radius"] = 512

TOOL.SelectedProps = {}
TOOL.Working = false

if CLIENT then
	language.Add( "tool.smart_remover.name", "Remover - Smart" )
	language.Add( "tool.smart_remover.desc", "Removes Props Easily" )
	language.Add( "tool.smart_remover.0", "Left click (+Use/+Shift) selects/deselects props. Right click smart removes props." )
end

local function RemoveEntity( ent )
	if ent:IsValid() then
		ent:Remove()
	end
end

local function DoRemoveEntity( ent )
	if not IsValid( ent ) or ent:IsPlayer() then return false end

	-- Nothing for the client to do here
	if CLIENT then return true end

	-- Remove all constraints (this stops ropes from hanging around)
	constraint.RemoveAll( ent )
	
	-- Remove it properly in 1 second
	timer.Simple( 1, function() RemoveEntity( ent ) end )
	
	-- Make it non solid
	ent:SetNotSolid( true )
	ent:SetMoveType( MOVETYPE_NONE )
	ent:SetNoDraw( true )
	
	-- Send Effect
	local ed = EffectData()
		ed:SetEntity( ent )
	util.Effect( "entity_remove", ed, true, true )
	
	return true
end

function TOOL:ClearSelectedProps()
	if table.Count(self.SelectedProps) > 0 then
		for k, v in pairs( self.SelectedProps ) do
			if v.ent:IsValid() then
				v.ent:SetColor( v )
			end
		end
		self.SelectedProps = {}
		return true
	end
	return false
end

function TOOL:Finish()
	self.Working = false
	self:ClearSelectedProps()
	self:GetOwner():PrintMessage( HUD_PRINTTALK, "Smart Remover: Finished." )
end

function TOOL:SmartRemove()
	for k, v in pairs( self.SelectedProps ) do
		DoRemoveEntity( v.ent )
	end
	self:Finish()
end

function TOOL:SelectEnt( ent )
	local Prop = {}
	Prop = ent:GetColor()
	Prop.ent = ent
	table.insert( self.SelectedProps, Prop )
	ent:SetColor( Color( 255, 255, 0, 255 ) )
end

function TOOL:DeselectEnt( ent )
	for k, v in pairs( self.SelectedProps ) do
		if v.ent == ent then
			v.ent:SetColor( v )
			table.remove( self.SelectedProps, k )
		end
	end
end

function TOOL:IsSelected( ent )
	if table.Count( self.SelectedProps ) > 0 then
		for k, v in pairs( self.SelectedProps ) do
			if v.ent == ent then
				return true
			end
		end
	end
	return false
end

--Based on a function by Conna
function TOOL:IsPropOwner( ply, ent )
	for k, v in pairs( g_SBoxObjects ) do
		for b, j in pairs( v ) do
			for _, e in pairs( j ) do
				if e == ent then
					if k == ply:UniqueID() then
						return true
					end
				end
			end
		end
	end
	return false
end

function TOOL:LeftClick( tr )
	if not ( tr.Entity and tr.Entity:IsValid() ) then return false end
	if tr.Entity:IsPlayer() or tr.Entity:IsWorld() or self.Working then return false end
	if CLIENT then return true end
	
	local ent = tr.Entity
	local ply = self:GetOwner()
	
	if ply:KeyDown( IN_USE ) then -- Area select function
		local SelectedProps = 0
		local Radius = math.Clamp( self:GetClientNumber( "radius" ), 64, 1024 )
		
		for k, v in pairs( ents.FindInSphere( tr.HitPos, Radius ) ) do
			if v:IsValid() and not self:IsSelected( v ) and self:IsPropOwner( ply, v ) then
				self:SelectEnt( v )
				SelectedProps = SelectedProps + 1
			end
		end
		
		self:GetOwner():PrintMessage( HUD_PRINTTALK, "Smart Remover: " .. SelectedProps .. " props were selected." )
	elseif ply:KeyDown( IN_SPEED ) then -- Select all constrained entities
		local SelectedProps = 0
		local SmartTable = constraint.GetAllConstrainedEntities( ent )
		
		for k, v in pairs( SmartTable ) do
			if v:IsValid() and not self:IsSelected( v ) then
				self:SelectEnt( v )
				SelectedProps = SelectedProps + 1
			end
		end
		
		self:GetOwner():PrintMessage( HUD_PRINTTALK, "Smart Remover: " .. SelectedProps .. " props were selected." )
	elseif self:IsSelected( ent ) then -- Ent is already selected, deselect it
		self:DeselectEnt( ent )
	else -- Select single entity
		self:SelectEnt( ent )
	end
	
	return true
end

function TOOL:RightClick( tr )
	if CLIENT then return true end
	if self.Working then return false end
	
	if table.Count(self.SelectedProps) > 0 then
		self.Working = true
		self:SmartRemove()
		return true
	end
	
	return false
end

function TOOL:Reload( tr )
	if CLIENT then return true end
	if self.Working then return false end
	
	self:ClearSelectedProps()
end

function TOOL.BuildCPanel( panel )
	panel:AddControl("Slider", {
		Label = "Auto Select Radius:",
		Type = "integer",
		Min = "64",
		Max = "1024",
		Command = "smart_remover_radius"
	})
end