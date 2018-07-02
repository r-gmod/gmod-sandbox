-- Constraint () attached to two static objects ( and world)!!! 


-- mitterdoo
TOOL.Category	= "Constraints"
TOOL.Name		= "#Weld - Multi"	
TOOL.Command	= nil			
TOOL.ConfigName	= nil			

TOOL.ClientConVar[ "nocollide" ] = 1
TOOL.ClientConVar[ "doeach" ] = 1
TOOL.ClientConVar[ "range" ] = 512

if SERVER then

	TOOL.Selected = {}

else

	language.Add( "Tool.multi_weld.name", "Weld - Multi" )
	language.Add( "Tool.multi_weld.desc", "Weld multiple props together!" )
	language.Add( "Tool.multi_weld.0", "Primary: Select/deselect prop (Hold USE to select all within radius) Secondary: Weld selected props together. Reload: Clear selected." )
	language.Add( "Tool.multi_weld.1", "Welding..." )

end

function TOOL:IsEntSelected( ent )

	for k,v in pairs( self.Selected ) do

		if v.Entity == ent then

			return k

		end

	end
	return false
end

function TOOL:CheckThenAddEntity( ent )

	if IsValid( ent ) and !ent:IsPlayer() and IsValid( ent:GetPhysicsObject() ) and !ent:IsWorld() then

		local index = self:IsEntSelected( ent )
		if index then
			ent:SetColor( self.Selected[ index ].Color )
			table.remove( self.Selected, index )
		else
			table.insert( self.Selected, {
				Entity = ent,
				Color = ent:GetColor()
			} )
			ent:SetColor( Color( 255, 0, 255 ) )
		end

	end

end

function TOOL:LeftClick( tr )

	if self:GetStage() != 0 then return end
	if CLIENT then return true end
	if self:GetOwner():KeyDown( IN_USE ) then
		for k, ent in pairs( ents.FindInSphere( tr.HitPos, math.Clamp( self:GetClientNumber( "range" ), 1, 1024 ) ) ) do
			self:CheckThenAddEntity( ent )
		end
	else
		local ent = tr.Entity
		self:CheckThenAddEntity( ent )
	end
	return true

end
function TOOL:Reload()

	if SERVER then

		self:DeselectAll()

	end

end

function TOOL:RightClick( tr )

	if self:GetStage() != 0 then return end
	if CLIENT then return true end
	if #self.Selected < 2 then return end

	if self:GetClientNumber( "doeach" ) == 0 then // we're only welding to this prop we clicked; make sure it's the first index of the table
		local ent = tr.Entity
		if IsValid( ent ) and !ent:IsPlayer() and IsValid( ent:GetPhysicsObject() ) and !ent:IsWorld() then

			if !self:IsEntSelected( ent ) then
				table.insert( self.Selected, 1, { Entity = ent, Color = ent:GetColor() } )
				ent:SetColor( Color( 0, 255, 0 ) )
			elseif self.Selected[1].Entity != ent then
				for k, v in pairs( self.Selected ) do

					if v.Entity == ent then
						local old = self.Selected[1]
						self.Selected[1] = v
						self.Selected[k] = old
						break
					end

				end
			end

			self:SetStage( 1 )
			self.Index = 1
			self.Welds = {}
			self.Selected2 = table.Copy( self.Selected )
			return true

		else

			return false

		end

	end

	self:SetStage( 1 )
	self.Index = 1
	self.Welds = {}
	self.Selected2 = table.Copy( self.Selected )

end

if SERVER then

	function TOOL:DeselectAll()

		for k, v in pairs( self.Selected ) do

			if !IsValid( v.Entity ) then continue end
			v.Entity:SetColor( v.Color )

		end
		self.Selected = {}
		if self.Selected2 then
			for k, v in pairs( self.Selected2 ) do

				if !IsValid( v.Entity ) then continue end
				v.Entity:SetColor( v.Color )

			end
			self.Selected2 = nil
		end
	end

end

local function drawProp( x, y, main )
	
	surface.SetDrawColor( main and Color( 0,255,0 ) or Color( 255,0,255 ) )
	surface.DrawRect( x - 24, y - 24, 48, 48 )
	
end

function TOOL:DrawToolScreen( w, h )

	// make us look nice
	surface.SetDrawColor( 0, 0, 0 )
	surface.DrawRect( 0, 0, w, h )
	
	draw.DrawText( "Weld Mode", "DermaLarge", w / 2, 16, Color( 255,255,255 ), TEXT_ALIGN_CENTER )
	
	
	local doEach = self:GetClientNumber( "doeach" ) == 1
	
	
	draw.DrawText( doEach and "All to all" or "All to one", "DermaLarge", w / 2, h - 60, Color( 255,255,255 ), TEXT_ALIGN_CENTER )
	if self:GetClientNumber( "nocollide" ) == 1 then
		draw.DrawText( "No-collide enabled", "Trebuchet24", w/2, h - 32, Color( 255,255,255 ), TEXT_ALIGN_CENTER )
	end
	if doEach then
		
		surface.SetDrawColor( 0, 255, 255 )
		surface.DrawLine( w / 4 * 1, h / 3-1, w / 4 * 3, h / 3-1 )
		surface.DrawLine( w / 4 * 1, h / 3, w / 4 * 3, h / 3 )
		surface.DrawLine( w / 4 * 1, h / 3+1, w / 4 * 3, h / 3+1 )

		surface.DrawLine( w / 4 * 1, h / 3, w / 2, h / 3 * 2 )
		surface.DrawLine( w / 4 * 3, h / 3, w / 2, h / 3 * 2 )
		surface.DrawLine( w / 2, h / 3, w / 2, h / 3 * 2 )
		drawProp( w / 4, h / 3 )
		drawProp( w/2, h/3 )
		drawProp( w/4*3, h / 3 )
		drawProp( w / 2, h/3*2 )
		
	else
	
		surface.SetDrawColor( 255, 0, 0 )
		surface.DrawLine( w / 4 * 1, h / 3, w / 2, h / 3 * 2 )
		surface.DrawLine( w / 4 * 3, h / 3, w / 2, h / 3 * 2 )
		surface.DrawLine( w / 2, h / 3, w / 2, h / 3 * 2 )
		drawProp( w / 4, h / 3 )
		drawProp( w/2, h/3 )
		drawProp( w/4*3, h / 3 )
		drawProp( w / 2, h/3*2, true )
	
	end


end

function TOOL:Think() // weld everything per think so we don't lag the server to death

	if CLIENT then return end
	if self:GetStage() != 1 then return end

	local noCollide = self:GetClientNumber( "nocollide" ) == 1
	local doEach = self:GetClientNumber( "doeach" ) == 1

	self.Index = self.Index + 1
	if self.Index > #self.Selected then
		table.remove( self.Selected, 1 )
		if doEach and #self.Selected > 1 then
			self.Index = 2
		else


			self:GetOwner():SendLua( [[notification.AddLegacy( "Finished welding!", NOTIFY_GENERIC, 3 ) surface.PlaySound( "ambient/water/drip"..math.random(1, 4)..".wav" )]])
			undo.Create( "Weld - Multi" )
				for k, v in pairs( self.Welds ) do

					if IsValid( v ) then
						undo.AddEntity( v )
					end

				end
				undo.SetPlayer( self:GetOwner() )
				undo.SetCustomUndoText( "Undone multi-weld" )
			undo.Finish()

			self.Index = nil
			self:DeselectAll()
			self:SetStage( 0 )
			return
		end
	end

	local ent1 = self.Selected[1].Entity
	local ent2 = self.Selected[ self.Index ].Entity
	if !IsValid( ent1 ) or !IsValid( ent2 ) then return end
	local Weld = constraint.Weld( ent1, ent2, 0, 0, 0, noCollide )
	table.insert( self.Welds, Weld )

end

function TOOL.BuildCPanel(panel)

	panel:AddControl( "Header", {
		Text = "Weld - Multi",
		Description = "Select multiple "
})
	panel:AddControl( "CheckBox", {
		Label = "No-collide entities",
		Command = "multi_weld_nocollide"
	})
	panel:AddControl( "CheckBox", {
		Label = "Weld all entities to each other",
		Command = "multi_weld_doeach"
	})
	panel:AddControl( "Slider", {
		Label = "Auto-select range",
		Command = "multi_weld_range",
		Type = "Float",
		Min = 0,
		Max = 1024
	})

end
