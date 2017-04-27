------------------------------------------------------------------------------------------------------------
--/*
-- * Created by David Lannan
-- * User: David Lannan
-- * Date: 5/23/2012
-- * Time: 2:13 AM
-- * 
-- */
------------------------------------------------------------------------------------------------------------

require("math/Matrix44")
require("scripts/utils/copy")

------------------------------------------------------------------------------------------------------------
-- Namespace...sort of
byt3dNode	= {

--	/// <summary>
--	/// A transform representing this nodes position, rotation and scale.
--	/// </summary>
	transform 	= Matrix44:New(),
    working		= Matrix44:New(),
	
--	/// <summary>
--	/// No point hiding this dictionary, makes direct access to children simple.
--	/// </summary>
	children	= {},
	nodeCount 	= 0,
	
--	/// <summary>
--	/// The parent of this node. If it is not set (== null) then it is a root node.
--	/// </summary>
	parent		= nil,
	
--	/// <summary>
--	/// Blocks are just anything that can be appended to a node to make it "something"
--	/// </summary>
	blocks	= {},
	blockCount 	= 0
}

------------------------------------------------------------------------------------------------------------
--	/// <summary>
--	/// Scene graph node - real simple, parent, child and thats it.
--	/// Similar to an object but an object is tied to a LQ DB.
--	/// </summary>

function byt3dNode:New()

	local newNode = deepcopy(byt3dNode)
	newNode.transform 	= Matrix44:New()
    newNode.working		= Matrix44:New()
    newNode.children 	= {}
    newNode.blocks	 	= {}
    return newNode    
end

------------------------------------------------------------------------------------------------------------
--    /// <summary>
--    /// Build all the missing parts to the model.
--    /// <param name="newNode">The node proprties are all filled out</param>
--    /// <param name="dnode">the incoming data node</param>
--    /// </summary>
function byt3dNode:LoadChildNodes( dnode )

    local newNode = self
    if dnode ~= nil then
        -- Copy the node elements
        newNode.transform   = Matrix44:New()
        newNode.transform.m = dnode.transform.m
        newNode.transform:cleanup()

        newNode.working     = Matrix44:New()
        newNode.working.m   = dnode.working.m
        newNode.working:cleanup()

        newNode.nodeCount   = dnode.nodeCount
        newNode.blockCount  = dnode.blockCount
        newNode.parent      = dnode.parent

        if dnode.blocks ~= nil then
            local dblocks = dnode.blocks
            for k,v in pairs(dblocks) do
                -- Only meshes currently supported - will add shaders and collision later
                if v.blocktype == nil or v.blocktype == "byt3dMesh" then
                    local newChild = byt3dMesh:FromFile(v)
                    newNode:AddBlock(newChild, tostring(k))
                end
            end
        end

        if dnode.children ~= nil then

            local dchilds = dnode.children
            for k,v in pairs(dchilds) do
                local newChild = byt3dNode:New()
                newChild:LoadChildNodes( v )
                newNode:AddChild(newChild, tostring(k))
            end
        end
    end
end

------------------------------------------------------------------------------------------------------------
--
-- Go through children nodes and blocks and update all
--
function byt3dNode:Update( mx, my, buttons )

	for k,v in pairs(self.children) do
		if v.Update then
			v:Update( mx, my, buttons )
		end
	end

	-- Render components last (leaf nodes always rendered before parents!
	for k, v in pairs(self.blocks) do
		if v.Update then
			v:Update(mx, my, buttons)
		end
	end
end

------------------------------------------------------------------------------------------------------------
--
-- Go through children nodes and components and render
--      Meshes are attached components. Nodes.. are generally nothing (although gummy visualisation is useful!)
--		byt3dCamera is passed in so the Shader can set the appropriate matrices when rendering 
function byt3dNode:Render( camera )

	for k,v in pairs(self.children) do
		if v.Render then
			v:Render( camera )
		end
	end

	-- Render components last (leaf nodes always rendered before parents!
	for k, v in pairs(self.blocks) do
		if v.Render then
			v:Render( camera )
		end
	end
end

------------------------------------------------------------------------------------------------------------

function byt3dNode:AddChild( newnode, name )

	if name == nil then name = "Node:"..self.nodeCount end
	self.nodeCount = self.nodeCount + 1
	self.children[name] = newnode
end

------------------------------------------------------------------------------------------------------------

function byt3dNode:AddBlock( newnode, name, btype )

    -- Default block type - this will change, but makes mesh building a little simpler
    local deftype = "byt3dMesh"
    if btype ~= nil then deftype = btype end
	if name == nil then name = "Block:"..self.blockCount end
	self.blockCount = self.blockCount + 1
    newnode.blockType = deftype
	self.blocks[name] = newnode
end

------------------------------------------------------------------------------------------------------------