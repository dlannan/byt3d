------------------------------------------------------------------------------------------------------------
local ffi 	= require( "ffi" )

------------------------------------------------------------------------------------------------------------

require("math/Matrix44")
require("math/Maths")

require("framework/byt3dNode")
require("framework/byt3dMesh")

------------------------------------------------------------------------------------------------------------
--/// <summary>
--/// Model type based around the Assimp library. 
--/// Data is managed using the Assimp Scene and Node types.
--/// </summary>
byt3dModel =
{
--	/// <summary>
--	/// The name of the model.
--	/// </summary>
    name		= "",
    fileName	= "",
    filePath	= "",
    
--    /// <summary>
--    /// The top node of the Scene
--    /// </summary>
    node		= byt3dNode:New(),
    
--    /// <summary>
--    /// TODO: Must convert the following into a material object
--    /// </summary>
    modelMat			= 0,

--	  /// If the shader is set then the model uses a single shader for all meshes.
	shader				= nil,

    boundMin			= { 0.0, 0.0, 0.0, 0.0 },
    boundMax			= { 0.0, 0.0, 0.0, 0.0 },
    boundCtr			= { 0.0, 0.0, 0.0, 0.0 }
}

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Constructor.
--    /// </summary>
function byt3dModel:New()

	local newModel = deepcopy(byt3dModel)
    newModel.name		= ""
    newModel.fileName	= ""
    newModel.filePath	= ""

    newModel.node		= byt3dNode:New()
    newModel.boundMax 	=  { -math.huge, -math.huge, -math.huge, 0.0 }
    newModel.boundMin 	=  { math.huge, math.huge, math.huge, 0.0 }
    newModel.boundCtr 	=  { 0.0, 0.0, 0.0, 0.0 }
    return newModel
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build a Model from a file data set only. This is internal model format.
--    /// <param name="dModel">the data model that has been loaded via LoadXml</param>
--    /// </summary>
function byt3dModel:FromFile(dModel)

    -- DumpXml(dModel)
    local newModel = deepcopy(byt3dModel)
    newModel.name		=   dModel.byt3dModel.name
    newModel.fileName	=   dModel.byt3dModel.fileName
    newModel.filePath	=   dModel.byt3dModel.filePath

    newModel.boundMax 	=   dModel.byt3dModel.boundMax
    newModel.boundMin 	=   dModel.byt3dModel.boundMin
    newModel.boundCtr 	=   dModel.byt3dModel.boundCtr

    -- Fill the rest of the data into the new 'proper' model
    -- When indexbuffer, vertbuffer and uvbuffers are reached, load the binaries in.
    newModel.node       = byt3dNode:New()

    newModel:LoadChildNodes(dModel.byt3dModel.node)
    -- Opague is the default
    newModel:SetMeshProperty("priority", byt3dRender.OPAQUE)

    return newModel
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build all the missing parts to the model.
--    /// <param name="newNode">The node proprties are all filled out</param>
--    /// <param name="dnode">the incoming data node</param>
--    /// </summary>
function byt3dModel:LoadChildNodes( dnode )

    self.node:LoadChildNodes(dnode)
end
------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Load in a model and give it a model name.
--    /// </summary>
--    /// <param name="fileobject">Filename of the model to load</param>
--    /// <param name="modelname">Name given to the model</param>
function byt3dModel:Load( fileobject, modelname )

    self.name = modelname
    
--    -- //Filepath to our model
--    self.fileName = Path.Combine(Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location), fileobject);
--    self.filePath = Path.GetDirectoryName(fileName);
--
--    -- //Create a new importer
--    AssimpImporter importer = new AssimpImporter();
--
--    -- //This is how we add a configuration (each config is its own class)
--    -- //NormalSmoothingAngleConfig config = new NormalSmoothingAngleConfig(66.0f);
--    -- //importer.SetConfig(config);
--
--    -- //This is how we add a logging callback 
--    LogStream logstream = new LogStream(delegate(String msg, IntPtr userData)
--    {
--        Console.WriteLine(msg);
--    });
--    importer.AttachLogStream(logstream);
--
--    -- //Import the model - this is considered a single atomic call. All configs are set, all logstreams attached. The model
--    -- //is imported, loaded into managed memory. Then the unmanaged memory is released, and everything is reset.
--    Scene model = importer.ImportFile(fileName, PostProcessPreset.TargetRealTimeQuality);
--
--    -- // Build the mesh list for this scene object
--    self.node = BuildMesh(model);
--    
--    -- //End of example
--    importer.Dispose();
end


------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Add to bounds and recurse children
--    /// </summary>

function byt3dModel:RecursiveBound( nd, Min, Max, Ctr )

    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do
        Min, Max, Ctr = MergeBounds(v.boundMin, v.boundMax, Min, Max, Ctr)
    end

    -- Iterate into the model and build bounds
    for k,v in pairs(nd.children) do
        local tmin, tmax, tctr = self:RecursiveBound(v, Min, Max, Ctr)
        Min, Max, Ctr = MergeBounds(tmin, tmax, Min, Max, Ctr)
    end

    return Min, Max, Ctr
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build the bounding box data for this model
--    /// </summary>
function byt3dModel:BuildBounds()

    -- Iterate into the model and build bounds
    local tmin, tmax, tctr = self:RecursiveBound(self.node, self.boundMin, self.boundMax, self.boundCtr)
    self.boundMin, self.boundMax, self.boundCtr = MergeBounds(tmin, tmax, self.boundMin, self.boundMax, self.boundCtr)
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build sub components
--    /// </summary>
--    /// <param name="model"></param>
--    /// <param name="node"></param>
function byt3dModel:BuildSubMesh( temp, model, nd )

    local n = 0
	local mat = nd.transform
	
    -- // update transform
    local m = Matrix44:New()
    m = m:Matrix44Copy(mat)

    temp.transform = m
    temp.working.m = temp.working:Mult44( temp.transform.m)
    
    -- // build all meshes assigned to this node
    for n=1,nd.MeshCount do 
    
    	local mesh = model.Meshes[nd.MeshIndices[n]]
    	newmesh = byt3dMesh:New()
    	newmesh:Init(self.filePath, mesh, model)
        newmesh:SetShaderFromModel(self.shader)
    	
    	temp:AddBlock(newmesh)
        
        -- // Update bounds - model bounds can be used for general bounds testing
        local opmax = temp.working:Mat44MultVec4( { newmesh.boundMax[1], newmesh.boundMax[2], newmesh.boundMax[3], 1.0 } )
        local opmin = temp.working:Mat44MultVec4( { newmesh.boundMin[1], newmesh.boundMin[2], newmesh.boundMin[3], 1.0 } )

        if (opmax[1] > self.boundMax[1]) then self.boundMax[1] = opmax[1] end
        if (opmax[2] > self.boundMax[2]) then self.boundMax[2] = opmax[2] end
        if (opmax[3] > self.boundMax[3]) then self.boundMax[3] = opmax[3] end
        if (opmin[1] < self.boundMin[1]) then self.boundMin[1] = opmin[1] end
        if (opmin[2] < self.boundMin[2]) then self.boundMin[2] = opmin[2] end
        if (opmin[3] < self.boundMin[3]) then self.boundMin[3] = opmin[3] end
    end

    -- // Build all children
    for n = 1, nd.ChildCount do 
    
 		local child = byt3dNode:New()
        child.parent = temp
        child.working = temp.working
 		table.insert(temp.children, child)
    	self:BuildSubMesh(child, model, nd.Children[n]);
    end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build the vertbuffers 
--    /// </summary>
--    /// <param name="model"></param>
function byt3dModel:BuildMesh( model )

    self.node.working = Matrix44:New()
    self.node.working:Identity()

    self:BuildSubMesh(node, model, model.RootNode)
    boundCtr[1] = (boundMax[1] - boundMin[1]) * 0.5 + boundMin[1]
    boundCtr[2] = (boundMax[2] - boundMin[2]) * 0.5 + boundMin[2]
    boundCtr[3] = (boundMax[3] - boundMin[3]) * 0.5 + boundMin[3]
    return self.node
end

------------------------------------------------------------------------------------------------------------
--	/// <summary>
--	/// Render recursively. 
--	/// </summary>
--	/// <param name="sc">Scene node</param>
--	/// <param name="nd">Sub node</param>
function byt3dModel:RecursiveRender( nd )

    nd.working = nd.working:Mult44(nd.transform, nd.working)
    local tmat = ffi.new("float[16]", nd.working.m )
    
	--print("Model right:", tmat[0], tmat[1], tmat[2], tmat[3])
	--print("Model up:", tmat[4], tmat[5], tmat[6], tmat[7])
	--print("Model view:", tmat[8], tmat[9], tmat[10], tmat[11])
	--print("Model pos:", tmat[12], tmat[13], tmat[14], tmat[15])

    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do

        -- Only do this for meshes!
        if v.blockType == "byt3dMesh" then
            if(v.Render) then
                v.modelMatrix = tmat
                v:Render()
            end
        end
    end

    -- // draw all children
    for k,v in pairs(nd.children) do 
    
        local child = v
        child.working = nd.working
        self:RecursiveRender(child)
    end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Render the current model
--	  ///   byt3dCamera passed in
--    /// </summary>
function byt3dModel:Render( cam )

    self.node.working = Matrix44:New()
    self:RecursiveRender(self.node)
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Set each new childs property and value setting for a mesh
--    /// </summary>
--    /// <param name="nd"> node of the child mesh to set (if its a mesh) </param>
--    /// <param name="property"> property string name to be setting</param>
--    /// <param name="value"> value to set the property to</param>
function byt3dModel:RecursiveSetMeshProperty( nd, property, value )

    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do
        -- Only do this for meshes!
        if v.blockType == "byt3dMesh" then v[property] = value end
    end

    -- // draw all children
    for k,v in pairs(nd.children) do
        self:RecursiveSetMeshProperty(v, property, value)
    end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Set some property of a mesh - this should be used for alpha etc.. now (doh!)
--    /// </summary>
--    /// <param name="priority"></param>
function byt3dModel:SetMeshProperty( property, value )

    self[property] 		= value
    self:RecursiveSetMeshProperty(self.node, property, value)
end


------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Set each new childs sampler texture
--    /// </summary>
--    /// <param name="tex"></param>
--    /// <param name="sampler"></param>
function byt3dModel:RecursiveSetSamplerTex( nd, tex, sampler )

    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do

        -- Only do this for meshes!
        if v.blockType == "byt3dMesh" then

            if v.SetTexture then
                v:SetTexture(tex) -- /// TODO: Fix me to support multi-tex
            end
        end
    end

    -- // draw all children
    for k,v in pairs(nd.children) do
    
        self:RecursiveSetSamplerTex(v, tex, sampler)
    end
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Set the sampler texture for all meshes in this model - not overly useful
--    /// but handy for debug, and testing
--    /// </summary>
--    /// <param name="tex"></param>
--    /// <param name="sampler"></param>
function byt3dModel:SetSamplerTex( tex, sampler )

    self:RecursiveSetSamplerTex(self.node, tex, sampler)
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:RecursiveGetMeshes(nd, meshes)

    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do

        if v.blockType == "byt3dMesh" then
            table.insert(meshes, v)
        end
    end

    -- // draw all children
    for k,v in pairs(nd.children) do

        self:RecursiveGetMeshes(v, meshes)
    end
    return meshes
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GetMeshes()

    local meshes = {}
    meshes = self:RecursiveGetMeshes(self.node, meshes)
    return meshes
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GetBlock( ct, btype )

    -- Get root node...
    local nd = self.node
    local count = 1
    -- // draw all meshes assigned to this node
    for k,v in pairs(nd.blocks) do

        if v.blockType == btype and count == ct then
            return v
        end
        count = count + 1
    end

    return nil
end

------------------------------------------------------------------------------------------------------------
--    /// Some default models so can easily do simple things
--    /// Also this is a reference for math generated geometry 
--    /// 
local gCubeCount	= 0
local gPlaneCount	= 0
local gSphereCount	= 0

function byt3dModel:GenerateCube( sz, d )

    local cube 		= byt3dMesh:New()

    local verts = {}
    local indices = {} 
    local uvs = {}			-- TODO - generate UVS

    local vcount = 1
    local ucount = 1
    local icount = 1
    local index = 1

	-- Start with a cube. Then for number x/y sizes iterate each side of the cube
	-- For each side of the cube cal vert trace back to center of cube, then recalc vert based on radius.
	-- Collect verts in order, making triangles along the way	
	
	local targets = {  
		[1] = function( a, b ) return { a, -sz, b, -1, 0.25, 0.333 }; end,
		[2] = function( a, b ) return { a, b, -sz, 1, 0.0, 0.333 }; end,
		[3] = function( a, b ) return { a, b, sz, -1, 0.25, 0.333 }; end,
		[4] = function( a, b ) return { -sz, b, a, -1, 0.25, 0.333 }; end,
		[5] = function( a, b ) return { sz, b, a, 1, 0.0, 0.333 }; end,
		[6] = function( a, b ) return { a, sz, b, 1, 0.0, 0.333 }; end
	  }
	  
	local startuvs = {
		[1] = { 0.25, 0.666 },		-- Ground
		[2] = { 0.25, 0.333 },		-- Front
		[3] = { 0.75, 0.333 },		-- Back
		[4] = { 0.0, 0.333 },		-- Left
		[5] = { 0.5, 0.333 },		-- Right
		[6] = { 0.25, 0.0 }			-- Sky
		}
	  
	local stepsize = sz * 2 / d
	for key, func in ipairs(targets) do
		
		local uv1 = startuvs[key][1]
		local vstep = 1.0 / d
		
		local amult = 1.0 / ( 2.005 * sz * 4.0 )
		local bmult = 1.0 / ( 2.005 * sz * 3.0 )
		
		for a = -sz, sz-stepsize, stepsize do
		
			local uv2 = startuvs[key][2]
			for b = -sz, sz-stepsize, stepsize do
			
				local v = func(a, b)
				indices[index]  = icount-1 ; index = index + 1
				verts[vcount] = v[1]; vcount = vcount + 1
				verts[vcount] = v[2]; vcount = vcount + 1
				verts[vcount] = v[3]; vcount = vcount + 1
				uvs[ucount] = uv1 + v[5] + v[4] * (a + sz) * amult; ucount = ucount + 1
				uvs[ucount] = uv2 + v[6] - (b + sz) * bmult; ucount = ucount + 1

				local x = func(a+stepsize, b)
				indices[index]  = icount ; index = index + 1
				verts[vcount] = x[1]; vcount = vcount + 1
				verts[vcount] = x[2]; vcount = vcount + 1
				verts[vcount] = x[3]; vcount = vcount + 1
				uvs[ucount] = uv1 + x[5] + x[4] * (a + sz + stepsize) * amult; ucount = ucount + 1
				uvs[ucount] = uv2 + x[6] - (b + sz) * bmult; ucount = ucount + 1

				local w = func(a, b+stepsize)
				indices[index]  = icount+1 ; index = index + 1
				verts[vcount] = w[1]; vcount = vcount + 1
				verts[vcount] = w[2]; vcount = vcount + 1
				verts[vcount] = w[3]; vcount = vcount + 1
				uvs[ucount] = uv1 + w[5] + w[4] * (a + sz) * amult; ucount = ucount + 1
				uvs[ucount] = uv2 + w[6] - (b + sz + stepsize) * bmult; ucount = ucount + 1

				local y = func(a+stepsize,b+stepsize)
				verts[vcount] = y[1]; vcount = vcount + 1
				verts[vcount] = y[2]; vcount = vcount + 1
				verts[vcount] = y[3]; vcount = vcount + 1
				uvs[ucount] = uv1 + y[5] + y[4] * (a + sz + stepsize) * amult; ucount = ucount + 1
				uvs[ucount] = uv2 + y[6] - (b + sz + stepsize) * bmult; ucount = ucount + 1
		
				indices[index]  = icount ; index = index + 1
				indices[index]  = icount+1 ; index = index + 1
		
				-- Build the extra tri from previous verts and one new one.
				indices[index]  = icount+2 ; index = index + 1
				icount = icount + 4
			end
		end
	end

    cube.ibuffers[1] = byt3dIBuffer:New()

    cube.ibuffers[1].vertBuffer 	= ffi.new("float["..(vcount-1).."]", verts)
    cube.ibuffers[1].indexBuffer 	= ffi.new("unsigned short["..(index-1).."]", indices)
    cube.ibuffers[1].texCoordBuffer	= ffi.new("float["..(ucount-1).."]", uvs)

    local name = string.format("Dynamic Mesh Cube(%02d)", gCubeCount)
    gCubeCount = gCubeCount + 1  
    self.node:AddBlock(cube, name, "byt3dMesh")
    
    self.boundMax = { sz, sz, sz, 0.0 }
    self.boundMin = { -sz, -sz, -sz, 0.0 }
    self.boundCtr[1] = (self.boundMax[1] - self.boundMin[1]) * 0.5 + self.boundMin[1]
    self.boundCtr[2] = (self.boundMax[2] - self.boundMin[2]) * 0.5 + self.boundMin[2]
    self.boundCtr[3] = (self.boundMax[3] - self.boundMin[3]) * 0.5 + self.boundMin[3]
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GenerateSphere( sz, d, inverted )

    if inverted == nil then inverted = 1.0 end
    local sphere 	= byt3dMesh:New()

    local verts 	= {}
    local indices 	= {} 
    local uvs 		= {}

    local vcount    = 1
    local ucount    = 1
    local icount    = 1
    local index     = 1

	-- Start with a cube. Then for number x/y sizes iterate each side of the cube
	-- For each side of the cube cal vert trace back to center of cube, then recalc vert based on radius.
	-- Collect verts in order, making triangles along the way
	function spherevec( vec )
		local newvec = { vec[1], vec[2], vec[3], 0.0 }
		local nvec = VecNormalize( newvec )
		return { nvec[1] * sz, nvec[2] * sz, nvec[3] * sz, vec[4], vec[5], vec[6] }
	end
	
	local targets = {  
		[1] = function( a, b ) return spherevec( { a, -sz, b, -1, 0.25, 0.333 } ); end,
		[2] = function( a, b ) return spherevec( { a, b, -sz, 1, 0.0, 0.333 } ); end,
		[3] = function( a, b ) return spherevec( { a, b, sz, -1, 0.25, 0.333 } ); end,
		[4] = function( a, b ) return spherevec( { -sz, b, a, -1, 0.25, 0.333 } ); end,
		[5] = function( a, b ) return spherevec( { sz, b, a, 1, 0.0, 0.333 } ); end,
		[6] = function( a, b ) return spherevec( { a, sz, b, 1, 0.0, 0.333 } ); end
	}
	  
	local startuvs = {
		[1] = { 0.25, 0.666 },		-- Ground
		[2] = { 0.25, 0.333 },		-- Front
		[3] = { 0.75, 0.333 },		-- Back
		[4] = { 0.0, 0.333 },		-- Left
		[5] = { 0.5, 0.333 },		-- Right
		[6] = { 0.25, 0.0 }			-- Sky
	}
	  
	local stepsize = sz * 2 / d
	for key, func in ipairs(targets) do
	
		local uv1 = startuvs[key][1]
		local vstep = 1.0 / d
		
		local amult = 1.0 / ( 2.005 * sz * 4.0 )
		local bmult = 1.0 / ( 2.005 * sz * 3.0 )
		
		for a = -sz, sz-stepsize, stepsize do
		
			local uv2 = startuvs[key][2]
			for b = -sz, sz-stepsize, stepsize do
                local toggle = 1

				local v = func(a, b)
				indices[index]  = icount+v[4] * inverted ; index = index + 1
				verts[vcount]   = v[1]; vcount = vcount + 1
				verts[vcount]   = v[2]; vcount = vcount + 1
				verts[vcount]   = v[3]; vcount = vcount + 1
				uvs[ucount]     = uv1 + v[5] + v[4] * (a + sz) * amult; ucount = ucount + 1
				uvs[ucount]     = uv2 + v[6] - (b + sz) * bmult; ucount = ucount + 1

				local x = func(a+stepsize, b)
				indices[index]  = icount ; index = index + 1
				verts[vcount]   = x[1]; vcount = vcount + 1
				verts[vcount]   = x[2]; vcount = vcount + 1
				verts[vcount]   = x[3]; vcount = vcount + 1
				uvs[ucount]     = uv1 + x[5] + x[4] * (a + sz + stepsize) * amult; ucount = ucount + 1
				uvs[ucount]     = uv2 + x[6] - (b + sz) * bmult; ucount = ucount + 1

				local w = func(a, b+stepsize)
				indices[index]  = icount-v[4] * inverted ; index = index + 1
				verts[vcount]   = w[1]; vcount = vcount + 1
				verts[vcount]   = w[2]; vcount = vcount + 1
				verts[vcount]   = w[3]; vcount = vcount + 1
				uvs[ucount]     = uv1 + w[5] + w[4] * (a + sz) * amult; ucount = ucount + 1
				uvs[ucount]     = uv2 + w[6] - (b + sz + stepsize) * bmult; ucount = ucount + 1

				local y = func(a+stepsize,b+stepsize)
				verts[vcount]   = y[1]; vcount = vcount + 1
				verts[vcount]   = y[2]; vcount = vcount + 1
				verts[vcount]   = y[3]; vcount = vcount + 1
				uvs[ucount]     = uv1 + y[5] + y[4] * (a + sz + stepsize) * amult; ucount = ucount + 1
				uvs[ucount]     = uv2 + y[6] - (b + sz + stepsize) * bmult; ucount = ucount + 1

				indices[index]  = icount+2-(1-v[4] * inverted) ; index = index + 1
				indices[index]  = icount+1-v[4] * inverted ; index = index + 1
		
				-- Build the extra tri from previous verts and one new one.
				indices[index]  = icount+1 ; index = index + 1
				icount = icount + 4
			end
		end
	end

    sphere.ibuffers[1] = byt3dIBuffer:New()

    sphere.ibuffers[1].vertBuffer 		= ffi.new("float["..(vcount-1).."]", verts)
    sphere.ibuffers[1].indexBuffer 		= ffi.new("unsigned short["..(index-1).."]", indices)
    sphere.ibuffers[1].texCoordBuffer 	= ffi.new("float["..(ucount-1).."]", uvs)
    
    local name = string.format("Dynamic Mesh Sphere(%02d)", gSphereCount)
    gSphereCount = gSphereCount + 1;    
    self.node:AddBlock(sphere, name, "byt3dMesh")
    
    self.boundMax = { sz, sz, sz, 0.0 }
    self.boundMin = { -sz, -sz, -sz, 0.0 }
    self.boundCtr[1] = (self.boundMax[1] - self.boundMin[1]) * 0.5 + self.boundMin[1]
    self.boundCtr[2] = (self.boundMax[2] - self.boundMin[2]) * 0.5 + self.boundMin[2]
    self.boundCtr[3] = (self.boundMax[3] - self.boundMin[3]) * 0.5 + self.boundMin[3]
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GeneratePyramid(sz)

    local newmodel 	= byt3dModel:New()
    local pyramid 	= byt3dMesh:New()

    local verts = 
    {   
        -sz, 0.0, -sz,  -sz, 0.0, sz,  sz, 0.0, sz,   sz, 0.0, -sz,
        0.0, sz, 0.0
    }

    local indices = 
    {
        0, 2, 1, 2, 3, 0,      -- // Base
        0, 4, 3,  0, 1, 4,  1, 2, 4, 2, 3, 4,  -- // Front Left Back Right
    }

    pyramid.ibuffers[1] = byt3dIBuffer:New()

    pyramid.ibuffers[1].vertBuffer 		= verts
    pyramid.ibuffers[1].indexBuffer 	= indices

    newmodel.node:AddBlock(pyramid, nil, "byt3dMesh")
    newmodel.boundMax = { sz, sz, sz, 0.0 }
    newmodel.boundMin = { -sz, 0.0, -sz, 0.0 }
    newmodel.boundCtr[1] = (newmodel.boundMax[1] - newmodel.boundMin[1]) * 0.5 + newmodel.boundMin[1]
    newmodel.boundCtr[2] = (newmodel.boundMax[2] - newmodel.boundMin[2]) * 0.5 + newmodel.boundMin[2]
    newmodel.boundCtr[3] = (newmodel.boundMax[3] - newmodel.boundMin[3]) * 0.5 + newmodel.boundMin[3]

    return newmodel
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GeneratePlane( sx, sy, uvMult, offx, offy )

    if offx     == nil then offx = 0 end
    if offy     == nil then offy = 0 end
	if uvMult   == nil then uvMult = 1.0 end
    local plane 	= byt3dMesh:New()

	local indices	= ffi.new("unsigned short[6]", 0, 2, 1, 0, 3, 2 )
	local verts		= ffi.new( "float[12]", -sx + offx, sy + offy, 0.0, sx + offx, sy + offy, 0.0, sx + offx, -sy + offy, 0.0, -sx + offx, -sy + offy, 0.0 )
	local uvs		= ffi.new( "float[8]", 0.0, 0.0, uvMult, 0.0, uvMult, uvMult, 0.0, uvMult )

    plane.ibuffers[1] = byt3dIBuffer:New()
    plane.ibuffers[1].vertBuffer 		= verts
    plane.ibuffers[1].indexBuffer 		= indices
    plane.ibuffers[1].texCoordBuffer 	= uvs

    local name = string.format("Dynamic Mesh Plane(%02d)", gPlaneCount)
    print("New Plane: "..name)
    gPlaneCount = gPlaneCount + 1;
    
    self.node:AddBlock(plane, name, "byt3dMesh")
    self.boundMax = { sx + offx, sy + offy, 0.0, 0.0 }
    self.boundMin = { -sx + offx, -sy + offy, 0.0, 0.0 }
    self.boundCtr[1] = (self.boundMax[1] - self.boundMin[1]) * 0.5 + self.boundMin[1]
    self.boundCtr[2] = (self.boundMax[2] - self.boundMin[2]) * 0.5 + self.boundMin[2]
    self.boundCtr[3] = (self.boundMax[3] - self.boundMin[3]) * 0.5 + self.boundMin[3]
end

------------------------------------------------------------------------------------------------------------

function byt3dModel:GenerateBlock( sx, sy, sz, uvMult )

    if uvMult   == nil then uvMult = 1.0 end
    local plane 	= byt3dMesh:New()

    local indices	= ffi.new("unsigned short[36]", 0, 1, 2,  2, 3, 0,  6, 5, 7,  7, 5, 4,
                                                    4, 0, 7,  0, 3, 7,  5, 6, 1,  1, 6, 2,
                                                    0, 4, 5,  0, 5, 1,  2, 7, 3,  2, 6, 7 )
    local verts		= ffi.new( "float[24]", -sx, sy, -sz,   sx, sy, -sz,    sx, -sy, -sz,   -sx, -sy, -sz,
                                            -sx, sy, sz,    sx, sy, sz,     sx, -sy, sz,    -sx, -sy, sz )
    local uvs		= ffi.new( "float[16]", 0.0, 0.0, uvMult, 0.0, uvMult, uvMult, 0.0, uvMult,
                                            uvMult, uvMult, 0.0, 0.0, 0.0, uvMult, uvMult, 0.0)

    plane.ibuffers[1] = byt3dIBuffer:New()
    plane.ibuffers[1].vertBuffer 		= verts
    plane.ibuffers[1].indexBuffer 		= indices
    plane.ibuffers[1].texCoordBuffer 	= uvs

    local name = string.format("Dynamic Mesh Block(%02d)", gPlaneCount)
    io.write("New Plane: ", name, "\n")
    gPlaneCount = gPlaneCount + 1;

    self.node:AddBlock(plane, name, "byt3dMesh")
    self.boundMax = { sx, sy, sz, 0.0 }
    self.boundMin = { -sx, -sy, -sz, 0.0 }
    self.boundCtr[1] = (self.boundMax[1] - self.boundMin[1]) * 0.5 + self.boundMin[1]
    self.boundCtr[2] = (self.boundMax[2] - self.boundMin[2]) * 0.5 + self.boundMin[2]
    self.boundCtr[3] = (self.boundMax[3] - self.boundMin[3]) * 0.5 + self.boundMin[3]
end

------------------------------------------------------------------------------------------------------------
