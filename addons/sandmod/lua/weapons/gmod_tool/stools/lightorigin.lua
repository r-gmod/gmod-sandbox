
TOOL.Category		= "Poser"
TOOL.Name			= "#tool.lightorigin.name"
if CLIENT then
	language.Add( "Tool.lightorigin.name",	"Lighting Origin" )
	language.Add( "Tool.lightorigin.desc",	"Moves entity's lighting origin to another entity" )
	language.Add( "Tool.lightorigin.0", " Left: Select entity to be changed  Right: Reset lighting origin" )
	language.Add( "Tool.lightorigin.1", " Now select origin entity" )
end
function TOOL:LeftClick( trace )
	
	local ent = trace.Entity
	
	if not ent:IsValid( ) then return end
	if ent:IsPlayer() then return end
	
	if SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) then return false end

	local iNum = self:NumObjects()
	
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, ent, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	if ( CLIENT ) then
	
		if ( iNum > 0 ) then self:ClearObjects() end
		return true
		
	end
	
	if ( iNum > 0 ) then
		
		local Ent1,  Ent2  = self:GetEnt(1),	self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),	self:GetBone(2)

		Ent1:SetSaveValue("m_hLightingOrigin",Ent2)
		
		if Ent1:GetPhysicsObject():IsValid() then
			Ent1:GetPhysicsObject():Wake()
		end
		
		self:ClearObjects()
	
	else
		
		self:SetStage( iNum+1 )
	
	end
		
	return true
	
end

function TOOL:RightClick( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	
	trace.Entity:SetSaveValue("m_hLightingOrigin",NULL)
	return true
	
end


function TOOL.BuildCPanel( CPanel )

	CPanel:AddControl( "Header", { Description	= "#tool.lightorigin.desc" }  )

end
