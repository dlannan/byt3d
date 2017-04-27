------------------------------------------------------------------------------------------------------------
-- Asset Import Library Utility functions
--
-- Decription: Converts into internal vbos and fbos 
-- 				Loads Textures and materials
--				Loads meshes into verts buffer

------------------------------------------------------------------------------------------------------------

local assimp = require("ffi/assimp")

------------------------------------------------------------------------------------------------------------
-- Supported import data types
--        Collada ( *.dae;*.xml )
--        Blender ( *.blend ) 3
--        Biovision BVH ( *.bvh )
--        3D Studio Max 3DS ( *.3ds )
--        3D Studio Max ASE ( *.ase )
--        Wavefront Object ( *.obj )
--        Stanford Polygon Library ( *.ply )
--        AutoCAD DXF ( *.dxf )
--        IFC-STEP, Industry Foundation Classes ( *.ifc )
--        Neutral File Format ( *.nff )
--        Sense8 WorldToolkit ( *.nff )
--        Valve Model ( *.smd,*.vta ) 3
--        Quake I ( *.mdl )
--        Quake II ( *.md2 )
--        Quake III ( *.md3 )
--        Quake 3 BSP ( *.pk3 ) 1
--        RtCW ( *.mdc )
--        Doom 3 ( *.md5mesh;*.md5anim;*.md5camera )
--        DirectX X ( *.x ).
--        Quick3D ( *.q3o;q3s ).
--        Raw Triangles ( .raw ).
--        AC3D ( *.ac ).
--        Stereolithography ( *.stl ).
--        Autodesk DXF ( *.dxf ).
--        Irrlicht Mesh ( *.irrmesh;*.xml ).
--        Irrlicht Scene ( *.irr;*.xml ).
--        Object File Format ( *.off ).
--        Terragen Terrain ( *.ter )
--        3D GameStudio Model ( *.mdl )
--        3D GameStudio Terrain ( *.hmp )
--        Ogre (*.mesh.xml, *.skeleton.xml, *.material)3
--        Milkshape 3D ( *.ms3d )
--        LightWave Model ( *.lwo )
--        LightWave Scene ( *.lws )
--        Modo Model ( *.lxo )
--        CharacterStudio Motion ( *.csm )
--        Stanford Ply ( *.ply )
--        TrueSpace ( *.cob, *.scn )2
--        XGL ( *.xgl, *.zgl )

------------------------------------------------------------------------------------------------------------
-- Make meshes on a Node. This is used to populate node information
--
--
function ModelAddMeshes( scene, node, dnode )

    for k=1, dnode.mNumMeshes do

        local mesh = scene.mMeshes[dnode.mMeshes[k-1]]

        -- Get the material index, and build some material info
        local matid = mesh.mMaterialIndex
        local mat = scene.mMaterials[matid]

        local bmesh = byt3dMesh:FromMesh(mesh)
        node:AddBlock(bmesh, ffi.string(dnode.mName.data).."_mesh_"..tostring(k))
    end
end

------------------------------------------------------------------------------------------------------------
-- Make childnodes on a Node. This is used to populate node information
--
--
function ModelAddNodes( scene, node, dnode, accT )

    -- Set rootnode transform
    -- TODO: This is a little weird, have to flip the Y because it doesnt match.
    --       Will need to check other Axes as well.

    local m = dnode.mTransformation
    node.transform.m = {
        m.a1, m.b1, m.c1, m.d1,
        m.a2, m.b2, m.c2, m.d2,
        m.a3, m.b3, m.c3, m.d3,
        m.a4, m.b4, m.c4, m.d4
    }

    ModelAddMeshes(scene, node, dnode)

    local tform = ffi.new("aiMatrix4x4", { m.a1, m.a2, m.a3, m.a4, m.b1, m.b2, m.b3, m.b4, m.c1, m.c2, m.c3, m.c4, m.d1, m.d2, m.d3, m.d4 } )
    assimp.aiMultiplyMatrix4(tform, accT)
    local ccount = dnode.mNumChildren

    for i=1, ccount do
        local nnode = byt3dNode:New()
        local cnode = dnode.mChildren[i-1]
        node:AddChild( nnode, ffi.string(cnode.mName.data) )
        ModelAddNodes( scene, nnode, cnode, tform )
    end
end

------------------------------------------------------------------------------------------------------------
-- Very basic model loader. 
-- TODO: Needs to be expanded to include pools and model management facitilies.
--       Also need auto texture loading and so on.

-- The loader also writes out our own internal format. This is so we dont need
-- the loader at runtime and release builds only use the internal format.
function LoadModel(filemodel)

    -- Try internal format first - this will be the only available method in release mode
    --local tModel = LoadXml(filemodel..".xml")
    --if tModel ~= nil then return byt3dModel:FromFile(tModel) end

	-- This is what everything will be used for converting to
	local newModel = byt3dModel:New()

	-- Test load some models
	local scene = assimp.aiImportFile(filemodel, assimp.aiProcess_Triangulate )
	local rnode = scene.mRootNode

	print("Scene:", scene,  "  Name:", ffi.string(rnode.mName.data))
    -- Write out all the materials - use references for rendering and texture gen
    local mcount = scene.mNumMaterials
    for i=1, mcount do
        local newmat = scene.mMaterials[i-1]
        -- Push this material into the current level material pool
    end

	print("NumMeshes:", scene.mNumMeshes)
    local rtform = ffi.new( "aiMatrix4x4", {1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1})
    ModelAddNodes( scene, newModel.node, rnode, rtform )

    SaveXml(filemodel..".xml", newModel, "byt3dModel")
	return newModel
end

------------------------------------------------------------------------------------------------------------
-- Returns a byt3dModel ready to render with the AssImpLib data

function MakeModel()

end

------------------------------------------------------------------------------------------------------------
