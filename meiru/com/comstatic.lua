local Com = include("com", ...)
local platform = include(".util.platform", ...)

local string = string

local ComStatic = class("ComStatic", Com)

function ComStatic:ctor(static_dir)
	self.file_md5s = {}
	self.max_age = 3600*24*7
	if static_dir then
		if string.byte(static_dir,#static_dir) == string.byte("/") then
	    	static_dir = string.sub(static_dir, 1, #static_dir-1)
	    end
	    self.static_dir = static_dir
	 end
	-- log("self.static_dir =", self.static_dir)
end

function ComStatic:get_file_md5(fullpath)
	return self.file_md5s[fullpath]
end

function ComStatic:set_file_md5(fullpath, md5)
	self.file_md5s[fullpath] = md5
end

function ComStatic:get_static_dir()
	if self.static_dir then
		return self.static_dir
	end
	local static_dir = req.app.get("static_dir")
	assert(static_dir)
	if string.byte(static_dir,#static_dir) == string.byte("/") then
	    static_dir = string.sub(static_dir, 1,  #static_dir-1)
	end
    self.static_dir = static_dir
end

function ComStatic:get_full_path(path)
	if not self.static_dir then
		self:get_static_dir()
	end
	if string.byte(path, 1) == string.byte("/") then
		return self.static_dir .. path
	else
		return self.static_dir .. '/' .. path
	end
end

function ComStatic:match(req, res)
    local headers = req.headers
	local fullpath = self:get_full_path(req.path)
	local modify_date = headers['if-modified-since']
	if type(modify_date) == "string" and #modify_date > 0 then
		local modify_time = os.gmttime(modify_date)
		if modify_time then
			local fmodify_time = platform.file_modify_time(fullpath)
			if fmodify_time == modify_time then
				res.send(304)
				local modify_time = platform.file_modify_time(fullpath)
				res.set_header('Last-Modified', os.gmtdate(modify_time))
				res.set_cache_timeout(self.max_age)
				return true
			end
		end
	end

	local content = io.readfile(fullpath)
	if not content then
		return false
	end
	local file_md5 = self:get_file_md5(fullpath)
	if not file_md5 then
		file_md5 = platform.md5(content)
		self:set_file_md5(fullpath, file_md5)
	end
	
	local etag = headers['if-none-match']
	if type(etag) == "string" and #etag > 0 then
		if etag == file_md5 then
			res.send(304)
			res.set_header('ETag', file_md5)
			res.set_cache_timeout(self.max_age)
			return true
		end
	end

	res.set_type(io.extname(fullpath))
	res.set_header('ETag', file_md5)
	local modify_time = platform.file_modify_time(fullpath)
	res.set_header('Last-Modified', os.gmtdate(modify_time))
	res.set_header('Age', 3600*24)
	res.set_cache_timeout(self.max_age)

	res.send(content)
	return true
end

return ComStatic
