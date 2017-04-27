----------------------------------------------------------------
--/**
-- * traverse the directory recursively
-- * @return TRUE if success, otherwise FALSE.
-- */
----------------------------------------------------------------

local apr 	= require("ffi/apr")

----------------------------------------------------------------

local dir	= {  init = 0, debug = false }

----------------------------------------------------------------

function dir:Init()

    assert( apr.apr_initialize() == 0 )
end

----------------------------------------------------------------

function dir:getfilepath(filepath)
    -- Try windows backslash first
    local s,e,fpath = string.find(filepath, "(.+)\\")
    -- Then try unix forward slash
    if fpath == nil then s,e,fpath = string.find(filepath, "(.+)/") end
    return fpath
end

----------------------------------------------------------------

function dir:getfilename(filepath)

    -- Try windows backslash first
    local s,e,fpath = string.find(filepath, "(.+)\\")
    -- Then try unix forward slash
    if fpath == nil then s,e,fpath = string.find(filepath, "(.+)/") end
    -- We have the last slash, so return the remaining.
    if fpath == nil then return nil end -- TODO: Should assert or something I think.
    local fname = string.sub(filepath, e+1)
    return fname
end

----------------------------------------------------------------

function dir:getextension(filepath)

	local s,e = string.find(filepath, "%.")
	local ext = ""
	if s ~= nil then ext = string.sub(filepath, e+1) end
	return ext
end

----------------------------------------------------------------
-- The listfolder is capable of a number of different uses.
--  <params:dirpath> - The path to get the directory list of files/folders
--  <params:res> - The results table to put all the entries in
--  <params:dir_expand> - Whether to iterate into subfolders to collect results - BE CAREFUL!!
--  <params:callback> - this is called for each iteration of a file entry (can return updates for feedback)
--  returns the results list of the entries.
--
-- NOTE: All '.' and '..' paths are added as entries but are not included in expansion (of course).
--       Be sure to filter/remove these directories if they are not needed.

function dir:listfolder(dirpath, res, dir_expand, callback)

	-- folder list results - should always have "." and ".." in the list ?!
	if res == nil then res 	= {} end

	local pool = ffi.new( "apr_pool_t*[1]" )
	assert( apr.apr_pool_create_ex( pool, nil, nil, nil ) == 0 )

	local dirt = ffi.new( "apr_dir_t*[1]" )
	assert( apr.apr_dir_open(dirt, dirpath, pool[0]) == 0 )
	
    if callback then callback() end
    local finfo = ffi.new( "apr_finfo_t" )
	while apr.apr_dir_read(finfo, apr.APR_FINFO_DIRENT, dirt[0]) == 0 do
	   local info = finfo
	   local name = ffi.string( info.name )
	   -- print( name, tonumber( info.size ), info.filetype )
	   local entry = { name = name, path = dirpath, size = info.size, ftype = info.filetype, ctime = info.ctime, mtime = info.mtime }
	   table.insert(res, entry)

       -- Expand into the folder and collect all files
       if dir_expand ~= nil and info.filetype == apr.APR_DIR then
           if name ~= "." and name ~= ".." then
            local folderlist = dirpath.."/"..name
            self:listfolder(folderlist, res, dir_expand)
           end
       end

	   -- Below is used for debugging.
	   ----------------------------------------------------------------------------------------------------
	   if self.debug then
	      local fields = { "pool", "valid", "protection", "filetype", "user", "group", "inode", "device",
			       "nlink", "size", "csize", "atime", "mtime", "ctime", "fname", "name", "filehand" }
	      for k, field in ipairs(fields) do
		 	local v = finfo[0][field]
		 	print( k, field, tostring(v) )
	      end
	   end
	   ----------------------------------------------------------------------------------------------------
	end
	
	return res
end

----------------------------------------------------------------

function dir:Finalize()

    print("Closing directory system.")
    apr.apr_terminate()
end
----------------------------------------------------------------

return dir

----------------------------------------------------------------
