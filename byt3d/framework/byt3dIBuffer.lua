--
-- Created by IntelliJ IDEA.
-- User: grover
-- Date: 3/03/13
-- Time: 5:29 PM
-- To change this template use File | Settings | File Templates.
--


require("framework/byt3dRender")
local byt3dio = require( "byt3d/scripts/utils/fileio" )

------------------------------------------------------------------------------------------------------------
--/// <summary>
--/// Description of byt3dIBuffer.
--///   The IBuffer object is to allow the system to manage large index buffers
--///   and split them into OGLES2 conformat sized buffers (max 65535 indexes).
--///   Additionally the IBuffer also manages the Rendering of itself, and
--///   the generation from large index buffer pools.
--/// </summary>

byt3dIBuffer =
{
    -- // Mapping mesh id to store buffers and tex ids.
    vertBuffer		= nil,
    normalBuffer	= nil,
    colorBuffer		= nil,
    texCoordBuffer	= nil,
    indexBuffer		= nil
}


------------------------------------------------------------------------------------------------------------
-- /// <summary>
-- ///  On construction copy the table (should be empty I guess? - this may change)
-- /// </summary>

function byt3dIBuffer:New()

    local newbuffer = deepcopy(byt3dIBuffer)

    return newbuffer
end

------------------------------------------------------------------------------------------------------------
-- /// <summary>
-- /// Load in an IBuffer/s from a provided data set (usually from assimplib
-- /// </summary>

function byt3dIBuffer:FromFile(dMesh)

    local buffers = {}
    buffers[1] = byt3dIBuffer:New()

    -- try and get ffitype - if not found.. exit with warning!!!
    if dMesh.indexBuffer then
        local ibuff = dMesh.indexBuffer
        local ffitype = ibuff.xarg.ffitype
        local elementsize = byt3dio:getffsize(ffitype)
        print("IndexBuffer: ", ffitype, elementsize)
        local bdata = ffi.new(ffitype.."["..ibuff.xarg.arraysize.."]")
        byt3dio:readdata(ibuff[1], elementsize * ibuff.xarg.arraysize, bdata)
        buffers[1].indexBuffer = bdata
    end
    if dMesh.vertBuffer then
        local vbuff = dMesh.vertBuffer
        local ffitype = vbuff.xarg.ffitype
        local elementsize = byt3dio:getffsize(ffitype)
        print("VertBuffer: ", ffitype, elementsize)
        local bdata = ffi.new(ffitype.."["..vbuff.xarg.arraysize.."]")
        byt3dio:readdata(vbuff[1], elementsize * vbuff.xarg.arraysize, bdata)
        buffers[1].vertBuffer = bdata
    end
    if dMesh.texCoordBuffer then
        local tbuff = dMesh.texCoordBuffer
        local ffitype = tbuff.xarg.ffitype
        local elementsize = byt3dio:getffsize(ffitype)
        print("TexCoordBuffer: ", ffitype, elementsize)
        local bdata = ffi.new(ffitype.."["..tbuff.xarg.arraysize.."]")
        byt3dio:readdata(tbuff[1], elementsize * tbuff.xarg.arraysize, bdata)
        buffers[1].texCoordBuffer = bdata
    end
end

------------------------------------------------------------------------------------------------------------
-- /// <summary>
-- /// Build an IBuffer/s from a
-- /// </summary>

function byt3dIBuffer:FromMesh(newmesh, mesh)

    local buffers = {}

    -- Must iterate indexes and then create more IBuffers when indexes are too big
    print("NumVerts:", mesh.mNumVertices)
    print("NumFaces:", mesh.mNumFaces)

    -- Puts all the indices into a normal lua table - this is safe, and will be our 'source'
    -- to work from and generate the appropriate IBuffer objects
    local indices = {}
    local icount = 1
    for n=0, mesh.mNumFaces-1 do
        local f = mesh.mFaces[n]
        for m=0, f.mNumIndices-1 do
            local index = f.mIndices[m]
            indices[icount] = index; icount = icount + 1
        end
    end

    -- local temps to allow the generation of the data sets
    local verts = {}
    local vcount = 1
    local uvs = {}
    local ucount = 1

    -- Now work out how many buffers we need
    local ibcount = math.ceil(icount / 60000) -- always a minimum of one!
    print("Number of buffers:", ibcount)

    local icheck = 1
    local tcount = 1
    -- For each index, collect the vertex, uv and colour information
    local icollect = {}
    for i=1, icount-1 do

        local j = math.ceil(math.modf(i, 60000))
        local orig_index = indices[i]

        -- need to modify the index to be "ushort"
        local index = math.floor(math.modf(orig_index,  60000) )
        icollect[j] = index

        local v = mesh.mVertices[index]
        verts[vcount] = v.x; vcount = vcount + 1
        verts[vcount] = v.y; vcount = vcount + 1
        verts[vcount] = v.z; vcount = vcount + 1
        if v.x < newmesh.boundMin[1] then newmesh.boundMin[1] = v.x end
        if v.y < newmesh.boundMin[2] then newmesh.boundMin[2] = v.y end
        if v.z < newmesh.boundMin[3] then newmesh.boundMin[3] = v.z end
        if v.x > newmesh.boundMax[1] then newmesh.boundMax[1] = v.x end
        if v.y > newmesh.boundMax[2] then newmesh.boundMax[2] = v.y end
        if v.z > newmesh.boundMax[3] then newmesh.boundMax[3] = v.z end

        -- If there are no materials, not alot of point trying to map textures.
        --if mat then
            local uv = mesh.mTextureCoords[0][orig_index]
            uvs[ucount] = uv.x;     ucount = ucount + 1
            uvs[ucount] = uv.y;     ucount = ucount + 1
        --end

        -- if at end of buffer then write it out
        if icheck == 60000 then

            local newbuff = byt3dIBuffer:New()
            newbuff.indexBuffer 	= ffi.new("unsigned short["..(icheck).."]", icollect)

            -- Build vert buffer from collected verts
            newbuff.vertBuffer 	    = ffi.new("float["..(vcount-1).."]", verts)
            newbuff.texCoordBuffer	= ffi.new("float["..(ucount-1).."]", uvs)
            buffers[tcount] = newbuff

            tcount = tcount + 1

            icollect    = {}; icheck      = 0
            verts       = {}; vcount      = 1
            uvs         = {}; ucount      = 1
            -- print("Icount:", icount, "Vcount:", vcount)
        end
        icheck = icheck + 1
    end

    -- Create remaining buffer
    local j = math.ceil(math.modf(ibcount / 60000))
    local newbuff = byt3dIBuffer:New()
    newbuff.indexBuffer 	= ffi.new("unsigned short["..(icount-1).."]", icollect)
    -- Build vert buffer from collected verts
    newbuff.vertBuffer 	    = ffi.new("float["..(vcount-1).."]", verts)
    newbuff.texCoordBuffer	= ffi.new("float["..(ucount-1).."]", uvs)
    buffers[tcount] = newbuff

    return buffers
end

------------------------------------------------------------------------------------------------------------
