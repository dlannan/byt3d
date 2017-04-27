------------------------------------------------------------------------------------------------------------
--~ /*
--~  * Created by David Lannan
--~  * User: David Lannan
--~  * Date: 5/22/2012
--~  * Time: 7:04 PM
--~  * 
--~  */
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
-- Poolmanager 
--
-- gPoolMgr	= {}



------------------------------------------------------------------------------------------------------------
--~ 	/// <summary>
--~ 	/// Pool objects are aimed at being generic cache pools of data/assets. This allows a 
--~ 	/// developer to make the best use of their resources. Assets can be marked to be 
--~		/// explicitly added or removed from the cache. 
--~		/// Sorted cache index is a list of cache elements based on time of creation.
--~		/// Using this sorted list a developer can destroy a "time" set of assets (ideal for levels etc)
--~ 	/// </summary>
byt3dPool =
{ 
	cache 		= {},				-- List of named assets 
	sorted		= {},				-- List of cache indexes that are ordered by creation time
	filter 		= ""				-- Filter types that this cache uses
}

------------------------------------------------------------------------------------------------------------
byt3dPool.TEXTURES_NAME             = "Textures"
byt3dPool.SHADERS_NAME              = "Shaders"
byt3dPool.MATERIALS_NAME            = "Materials"
------------------------------------------------------------------------------------------------------------
function byt3dPool:CheckPoolMgr( )
	if gPoolMgr == nil then
		gPoolMgr = {}
	end
end
------------------------------------------------------------------------------------------------------------

function byt3dPool:GetPool( name )
	self:CheckPoolMgr()
	
	local pool = gPoolMgr[name]
	return pool
end

------------------------------------------------------------------------------------------------------------

function byt3dPool:New( name )
	self:CheckPoolMgr()
	
	print("New Pool: ", name)
	local newPool = deepcopy(byt3dPool)
	-- Pool names should be unique - or problems may occur.
	gPoolMgr[name] = newPool
	return newPool
end

------------------------------------------------------------------------------------------------------------

function byt3dPool:CreateResource( obj )
	self:CheckPoolMgr()
	--assert(obj ~= nil, "Resource object is nil.")
	--assert(obj.name ~= nil, "Resource object has no name - must be named.")

	-- lookup the object in the cache
	local cobj = self.cache[obj.name]
	
	-- make a new cache object
	if cobj == nil then
		self.cache[obj.name] = obj
		cobj = self.cache[obj.name]
		cobj.refcount = 1
		
	-- otherwise return the cache object
	else
		cobj.refcount = cobj.refcount + 1
	end
	
	local create_time = os.time()
	
	--print("Name:", obj.name, create_time, self)
	self.sorted[create_time] = obj.name
	cobj.created = create_time
	
	if cobj.Create ~= nil then cobj:Create() end
	return cobj
end

------------------------------------------------------------------------------------------------------------

function byt3dPool:GetResource( name )
	self:CheckPoolMgr()
	
	--assert(self.cache == nil, "Cache is nil. Cannot get resource from Cache.")
	local res = self.cache[name]
	return res
end

------------------------------------------------------------------------------------------------------------

function byt3dPool:DestroyResource( name )
	
	local cobj = self.cache[name]
	if cobj ~= nil then 
		cobj.refcount = cobj.refcount - 1
		if cobj.refcount < 1 then
			if cobj.Destroy ~= nil then cobj:Destroy() end
		end
	end
	self.cache[name] = nil
end

------------------------------------------------------------------------------------------------------------

function byt3dPool:DestroyAllFromTime( t )

	--print("Destroy From Time", t, self)
	for k,v in pairs(self.sorted) do 
	--print("Deleting:", k, v)
		if k > t then
			self:DestroyResource( v )
			self.sorted[k] = nil
		end
	end
end

------------------------------------------------------------------------------------------------------------
-- Destroy all elements in a pool

function byt3dPool:Destroy( )

	for k,v in pairs(self.cache) do 
		v:DestroyResource( k )
		v = nil
	end
end

------------------------------------------------------------------------------------------------------------

return byt3dPool

------------------------------------------------------------------------------------------------------------
