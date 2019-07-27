local ok, skynet = pcall(require, "skynet")
skynet = ok and skynet

local _mysqlcached

if skynet then
	skynet.fork(function()
		_mysqlcached = skynet.uniqueservice("meiru/mysqlcached")
	end)
end

local command = {}
if skynet then
setmetatable(command, {__index = function(t,cmd)
    local f = function(...)
    	return skynet.call(_mysqlcached, "lua", cmd, ...)
    end
    t[cmd] = f
    return f
end})
end

-------------------------------------
--Queue
-------------------------------------
local Queue = class("Queue")

function Queue:ctor()
    self.head_idx    = 1
    self.empty_idx   = 1
    self.cache_queue = {}
    self.cache_map   = {}
    self.max_cache   = 1000
end
function Queue:get(key)
    return self.cache_map[key]
end
function Queue:set(key, data)
    self.cache_map[key] = data
    local empty_idx = self.empty_idx
    self.cache_queue[empty_idx] = key
    if empty_idx-self.head_idx >= self.max_cache then
        local head_idx = self.head_idx
        local tmp_key
        while empty_idx-head_idx >= self.max_cache do
            tmp_key = self.cache_queue[head_idx]
            if tmp_key then
                self.cache_queue[head_idx] = nil
                self.cache_map[tmp_key] = nil
            end
            head_idx = head_idx+1
        end
        self.head_idx = head_idx
    end
    empty_idx = empty_idx+1
    self.empty_idx = empty_idx
end
function Queue:remove(key)
    self.cache_map[key] = nil
end
function Queue:removes(keys)
	for _,key in ipairs(keys) do
    	self.cache_map[key] = nil
	end
end

-------------------------------------
-------------------------------------
local _queues = {}

local function get_data(tblName, id)
	local queue = _queues[tblName]
	if not queue then
		queue = Queue.new()
		_queues[tblName] = queue
	end
	return queue:get(id)
end

local function set_data(tblName, id, data)
	local queue = _queues[tblName]
	if not queue then
		queue = Queue.new()
		_queues[tblName] = queue
	end
	queue:set(id, data)
end

local function remove_data(tblName, id)
	local queue = _queues[tblName]
	if not queue then
		queue = Queue.new()
		_queues[tblName] = queue
	end
	return queue:remove(id)
end

local function remove_datas(tblName, ids)
	local queue = _queues[tblName]
	if not queue then
		queue = Queue.new()
		_queues[tblName] = queue
	end
	return queue:removes(ids)
end

local function clone(data)
	if type(data) ~= "table" then
		return data
	end
	local copy = {}
	for k,v in pairs(data) do
		copy[k] = v
	end
	return copy
end

--------------------------------------
--------------------------------------
function command.get(tblName, id)
	local data = get_data(tblName, id)
	if data then
		return clone(data)
	end
	if ok then
		local data = skynet.call(_mysqlcached, "lua", "get", tblName, id)
		set_data(tblName, id, data)
		return clone(data)
	end
end

function command.gets(tblName, ids)
	local datas = {}
	local req_ids = {}
	local data
	for i,id in ipairs(ids) do
		data = get_data(tblName, id)
		if data then
			table.insert(datas, clone(data))
		else
			table.insert(req_ids, id)
		end
	end
	if #req_ids == 0 then
		return datas
	end
	if skynet then
		local ndatas = skynet.call(_mysqlcached, "lua", "gets", tblName, req_ids)
		for _,data in ipairs(ndatas) do
			assert(data.id)
			table.insert(datas, clone(data))
			set_data(tblName, data.id, data)
		end
		return datas
	end
end

function command.update(tblName, id, data)
	-- remove_data(tblName, id)
	local save_data = get_data(tblName, id)
	if save_data then
		for k,v in pairs(data) do
			save_data[k] = v
		end
	end
	if skynet then
		return skynet.call(_mysqlcached, "lua", "update", tblName, id, data)
	end
end

function command.updates(tblName, ids, data)
	-- remove_datas(tblName, ids)
	for _,id in ipairs(ids) do
		local save_data = get_data(tblName, id)
		if save_data then
			for k,v in pairs(data) do
				save_data[k] = v
			end
		end
	end
	if skynet then
		return skynet.call(_mysqlcached, "lua", "updates", tblName, ids, data)
	end
end

function command.clear(tblName)
	_queues[tblName] = nil
end

function command.remove(tblName, id, ...)
	remove_data(tblName, id)
	if skynet then
		return skynet.call(_mysqlcached, "lua", "remove", tblName, id, ...)
	end
end

function command.removes(tblName, ids, ...)
	remove_datas(tblName, ids)
	if skynet then
		return skynet.call(_mysqlcached, "lua", "removes", tblName, ids, ...)
	end
end

function command.delete(tblName, id, ...)
	remove_data(tblName, id)
	if skynet then
		return skynet.call(_mysqlcached, "lua", "delete", tblName, id, ...)
	end
end

function command.deletes(tblName, ids, ...)
	remove_datas(tblName, ids)
	if skynet then
		return skynet.call(_mysqlcached, "lua", "deletes", tblName, ids, ...)
	end
end


return command 

