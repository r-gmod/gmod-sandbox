--[[
	waterizer stool - waterizer.lua
		by Meoo~we
]]--
TOOL.Category		= "Construction"
TOOL.Name			= "#Waterizer"
TOOL.Command		= nil
TOOL.ConfigName		= ""

-- Damping, Default: 15%
TOOL.ClientConVar[ "damping" ] = "15"
-- Density, Default: 70%
TOOL.ClientConVar[ "density" ] = "70"
-- Buoyancy, Default: 500
TOOL.ClientConVar[ "buoyancy" ] = "500"

-- Enable collisions:

cleanup.Register( "waterizer" )

if CLIENT then
    -- Client only
    language.Add( "Tool.waterizer.name", "Waterizer" )
    language.Add( "Tool.waterizer.desc", "Transform props in (fake) water!" )
    language.Add( "Tool.waterizer.0", "Click to transform or update a prop." )

    language.Add( "Undone_waterizer", "Undone Waterizer" )

    language.Add( "Cleanup_waterizer", "Cleanup Waterized props" )
    language.Add( "Cleaned_waterizer", "Cleaned up Waterized props" )
else
    -- Server only

    -- "Toggle collision" command
    concommand.Add( "waterizer_toggle_collision", function( ply, cmd, args )
        ply.w_EnableCollisions = util.tobool( args[1] )
        for _, ent in ipairs( ents.FindByClass("prop_waterized") ) do
            if ent:GetPlayer() == ply then
                ent:SetNotSolid(ply.w_EnableCollisions)
            end
        end
    end )
end

function TOOL:LeftClick( trace )
    if not trace.Entity then return false end
    if not trace.Entity:IsValid() then return false end
    if CLIENT then
        if trace.Entity:GetClass() == "prop_waterized"
        or trace.Entity:GetClass() == "prop_physics" then return true end
        return false
    end

    local damping = math.Clamp( self:GetClientNumber( "damping", 15 ), 1, 99)
    local density = math.Clamp( self:GetClientNumber( "density", 70 ), 1, 99)
    local buoyancy = math.Clamp( self:GetClientNumber( "buoyancy", 500 ), 0, 1000)

    local ply = self:GetOwner()
    local ent = trace.Entity

    if trace.Entity:GetClass() == "prop_waterized" then

        -- Update prop infos
        ent:SetDamping( damping )
        ent.damping = damping
        ent:SetDensity( density )
        ent.density = density
        ent:SetBuoyancy( buoyancy )
        ent.buoyancy = buoyancy

        return true
    elseif trace.Entity:GetClass() ~= "prop_physics" then
        -- Invalid prop
        return false
    end
    -- Make a new waterized prop
    if not self:GetSWEP():CheckLimit( "waterizer" ) then return false end

    -- Take everything we need
    local Data = {
        Pos = ent:GetPos(),
        Angle = ent:GetAngles(),
        Model = ent:GetModel(),
        Frozen = true,
    }

    -- Old entity is now obsolete
    ent:Remove()

    -- New entity
    local new = MakeWaterizedProp( ply, damping, density, buoyancy, Data )

    -- Undo & Cleanup
    undo.Create( "waterizer" )
    undo.AddEntity( new )
    undo.SetPlayer( ply )
    undo.Finish()
    ply:AddCleanup( "waterizer", new )

    return true
end

-- Do the same thing
function TOOL:RightClick( trace )
	return self:LeftClick( trace )
end

-- Tool panel
function TOOL.BuildCPanel( CPanel )
    CPanel:AddControl( "Header", { Text = "#Tool_waterizer_name", Description	= "#Tool_waterizer_desc" }  )

    CPanel:AddControl( "Slider", { Label = "Damping (15%)",
                    Type = "Integer",
                    Min = 1,
                    Max	= 99,
                    Command = "waterizer_damping",
                    Description = "Damping of the water"} )

    CPanel:AddControl( "Slider", { Label = "Density (70%)",
                    Type = "Integer",
                    Min = 1,
                    Max	= 99,
                    Command = "waterizer_density",
                    Description = "Density of the water"} )

    CPanel:AddControl( "Slider", { Label = "Props buoyancy (500)",
                    Type = "Integer",
                    Min = 0,
                    Max	= 1000,
                    Command = "waterizer_buoyancy",
                    Description = "Force applied to props in the water"} )

    CPanel:AddControl( "Label", { Text = "This option also affect existing props:" } )

    CPanel:AddControl( "CheckBox", { Label = "Disable collisions",
                    Command = "waterizer_toggle_collision",
                    Description = "Disable toolgun / physgun"} )
end

function MakeWaterizedProp( ply, damping, density, buoyancy, Data )
    -- Generic stufff
    local ent = ents.Create( "prop_waterized" )
    if not ent:IsValid() then return end
    duplicator.DoGeneric( ent, Data )
    ent:SetPlayer( ply )
    ent:Spawn()
    duplicator.DoGenericPhysics( ent, ply, Data )

    -- Custom data
    ent:SetDamping( damping )
    ent.damping = damping
    ent:SetDensity( density )
    ent.density = density
    ent:SetBuoyancy( buoyancy )
    ent.buoyancy = buoyancy

    ply:AddCount( "waterizer", ent )
    return ent
end

duplicator.RegisterEntityClass( "prop_waterized", MakeWaterizedProp, "damping", "density", "buoyancy", "Data" )
