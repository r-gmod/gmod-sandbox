CreateConVar( "rg_nolimits_admin", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_LUA_SERVER }, "Whether sandbox limits are ignored for admins" )

FindMetaTable( "Player" ).CheckLimit = function( self, str )

	-- No limits in single player
	if ( game.SinglePlayer() ) then return true end

	if ( self:IsSuperAdmin() or GetConVar( "rg_nolimits_admin" ):GetBool() and self:IsAdmin() ) then return true end

	local c = cvars.Number( "sbox_max" .. str, 0 )

	if ( c < 0 ) then return true end
	if ( self:GetCount( str ) > c - 1 ) then
		if ( SERVER ) then self:LimitHit( str ) end
		return false
	end

	return true

end