local PQueue = include(".lib.pqueue", ...)
local ok, skynet = pcall(require, "skynet")
skynet = ok and skynet

local _cached
if skynet then
	skynet.fork(function()
		_cached = skynet.uniqueservice("meiru/cached")
	end)
end

local _queue = PQueue.new(function(a, b)
	return b.deadline - a.deadline
end)

local kMCacheInterval = 3600

local _caches = {}
local function get_data(key)
	local cache = _caches[key]
	if cache then
		if os.time() <= cache.deadline then
			return cache.data
		end
		_caches[key] = nil
		_queue:remove(cache)
	end
end

local function set_data(key, data, timeout)
	if timeout == 0 or timeout > kMCacheInterval then
		timeout = kMCacheInterval
	end
	local cache = {
		data = data,
		deadline = os.time()+timeout
	}
	_caches[key] = cache
	local tmp = _queue:peek()
	while tmp do
		if os.time()>tmp.deadline then
			_queue:poll()
		else
			break
		end
		tmp = _queue:peek()
	end
	_queue:offer(cache)
end


local cached = {}

function cached.set(key, data, timeout)
	set_data(key, data, timeout or 0)
	if ok then
		data = skynet.packstring(data)
		return skynet.call(_cached, "lua", "set", key, data, timeout)
	end
end

function cached.get(key)
	if not key then
        return
    end
	local data = get_data(key)
	if data then
		return data
	end
	if skynet then
		local data, deadline = skynet.call(_cached, "lua", "get", key)
		if data then
			data = skynet.unpack(data)
			set_data(key, data, deadline-os.time())
		end
		return data
	end
end

return cached 
