------------------------------------------------------------------------------------------------------------
--/*
-- * Created by David Lannan
-- * User: David Lannan
-- * Date: 5/31/2012
-- * Time: 10:10 PM
-- * 
-- */
------------------------------------------------------------------------------------------------------------

require("framework/byt3dRender")
require("framework/byt3dIBuffer")
local byt3dio = require( "byt3d/scripts/utils/fileio" )

------------------------------------------------------------------------------------------------------------
--/// <summary>
--/// Description of byt3dMesh.
--/// </summary>

byt3dMesh = 
{		
--    /// <summary>
--    /// Program position 
--    /// </summary>
	shader			= nil,    

    -- This is an array of byt3dIBuffer Objects
    ibuffers         = {},

    boundMin		= { math.huge, math.huge, math.huge, 0.0 },
    boundMax		= { -math.huge, -math.huge, -math.huge, 0.0 },

    -- // TODO: Need to get this out of here! Need proper materials!!
	tex0 			= nil,
	tex1			= nil,
	
	-- // Render Priority... 
	priority		= 1024		
}

------------------------------------------------------------------------------------------------------------
-- /// <summary>
-- ///  On construction set bounds to rediculous size, so min/max can be calculated.
-- /// </summary>

function byt3dMesh:New()

	local newmesh = deepcopy(byt3dMesh)
    newmesh.boundMax  	= { -math.huge, -math.huge, -math.huge }
    newmesh.boundMin 	= { math.huge, math.huge, math.huge }
    newmesh.priority 	= 1024
    
    return newmesh
end
------------------------------------------------------------------------------------------------------------

function byt3dMesh:FromFile(dMesh)

    local newmesh = deepcopy(byt3dMesh)
    newmesh.boundMax  	= dMesh.boundmax
    newmesh.boundMin 	= dMesh.boundmin
    newmesh.priority 	= dMesh.priority

    newmesh.ibuffers = byt3dIBuffer:FromFile(dMesh)
    return newmesh
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:FromMesh(dMesh)

    local newmesh = deepcopy(byt3dMesh)
    newmesh.boundMax  	= { -math.huge, -math.huge, -math.huge }
    newmesh.boundMin 	= { math.huge, math.huge, math.huge }
    newmesh.priority 	= 1024

    newmesh.ibuffers = byt3dIBuffer:FromMesh(newmesh, dMesh)
    return newmesh
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:SetShaderFromModel( model )

	self.shader = model.shader
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:SetShader( shader )
	
	self.shader = shader
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:SetPriority( priority )
	
	self.priority = priority
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:SetupTexture( filePath, scene, mat )

	self.tex0 = byt3dTexture:New(filePath, scene, mat)
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:SetTexture( tex )
	self.tex0 = tex
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:Init( filePath, m, sc )

	-- // Texture setup
	local mat = sc.Materials[m.MaterialIndex]
    if(mat ~= nil) then self:SetupTexture(filePath, sc, mat) end
    self:InitBuffers(m)
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:RenderTextureRect( x, y, w, h )

	byt3dRender:RenderTexRect(self, x, y, w, h)
end

------------------------------------------------------------------------------------------------------------

function byt3dMesh:Render()
    -- // Shader changed - just in case we do
    byt3dRender:RenderMesh( self )
end

------------------------------------------------------------------------------------------------------------