
TOOL.Category		= "Construction"
TOOL.Name			= "#Unbreakable"
TOOL.Command		= nil
TOOL.ConfigName		= nil


TOOL.ClientConVar[ "toggle" ] 	= "1"
if ( CLIENT ) then

	language.Add( "Tool_unbreakable_name", "Unbreakable" )
	language.Add( "Tool_unbreakable_desc", "Makes NPCs and props immune to damage" )
	language.Add( "Tool_unbreakable_0", "Left click on an NPC or a prop to make it unbreakable" )

end


/*------------------------------------------------------------

	Duplicate Immunity to duplicate

------------------------------------------------------------*/
local function ToggleUnbreakable( Player, Entity, Data )

	if ( !Entity ) then return false end

	if ( SERVER ) then

		if ( Data.Unbreakable ~= nil ) then

			Entity.m_bIsUnbreakable = Data.Unbreakable

		end

		duplicator.StoreEntityModifier( Entity, "unbreakable", { Unbreakable = Data.Unbreakable } )

	end

end

duplicator.RegisterEntityModifier( "unbreakable", ToggleUnbreakable )


/*---------------------------------------------------------
   Name:	LeftClick
   Desc:	Make a single entity unbreakable
---------------------------------------------------------*/
function TOOL:LeftClick( trace )

	if (!trace.Entity) then return false end
	if (!trace.Entity:IsValid()) then return false end
	if (trace.Entity:IsPlayer()) then return false end

	// Nothing for the client to do here
	if ( CLIENT ) then return true end

	// Get client's CVars
	local unbreakable = util.tobool( self:GetClientNumber( "toggle" ) )

	// Set the properties

	ToggleUnbreakable( self:GetOwner(), trace.Entity, { Unbreakable = unbreakable } )

	DoPropSpawnedEffect( trace.Entity )

	return true

end

/*---------------------------------------------------------
   Name:	RightClick
   Desc:	Make an entity and everything constrained unbreakable
---------------------------------------------------------*/
function TOOL:RightClick( trace )

	if (!trace.Entity) then return false end
	if (!trace.Entity:IsValid()) then return false end
	if (trace.Entity:IsPlayer()) then return false end

	// Client can bail out now.
	if ( CLIENT ) then return true end

	local ConstrainedEntities = constraint.GetAllConstrainedEntities( trace.Entity )

	// Get client's CVars
	local unbreakable = util.tobool( self:GetClientNumber( "toggle" ) )

	// Loop through all the entities in the system
	for _, Entity in pairs( ConstrainedEntities ) do

		// Set the properties

		ToggleUnbreakable( self:GetOwner(), Entity, { Unbreakable = unbreakable } )

		DoPropSpawnedEffect( Entity )

	end

	return true
end

if ( SERVER ) then


/*------------------------------------------------------------

	This simply gets the Unbreakable variable from the  entity.

	We also scale dmginfo on the entity to remove
	the damage inflicted so nothing breaks

------------------------------------------------------------*/
local function AddUnbreakableBoolean( ent, inflictor, attacker, amount, dmginfo )
	if not dmginfo then
		dmginfo=inflictor
		inflictor=dmginfo:GetInflictor()
		attacker=dmginfo:GetAttacker()
		amount=dmginfo:GetDamage()
	end
	
	if ( !ent or !ent:IsValid() or ent:IsPlayer() ) then return end

	if ( ent.m_bIsUnbreakable and ent.in_rpland ~= true) then

		dmginfo:ScaleDamage( 0.0 )
	end

end

hook.Add( "EntityTakeDamage", "AddUnbreakableBoolean", AddUnbreakableBoolean )


return end