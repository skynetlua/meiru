
os.mode = 'dev'

local extension = require "meiru.extension"
local meiru     = require "meiru.meiru"

---------------------------------------
--router
---------------------------------------
local router = meiru.router()

router.get('/index', function(req, res)
    local data = {
        topic = {
            title = "hello ejs.lua"
        },
        topics = {
            {
                title = "topic1"
            },{
                title = "topic2"
            }
        }
    }
    function data.helloworld(...)
        if select("#", ...) > 0 then
            return "come from helloworld function"..table.concat(... , ", ")
        else
            return "come from helloworld function"
        end
    end
	res.render('index', data)
end)

---------------------------------------
--app
---------------------------------------
local app = meiru.create_app()

local views_path  = "./assets/view"
local static_path = "./assets/public"
local resource_url = "/"

app.set("views_path", views_path)
app.set("static_path", static_path)
app.set("resource_url", resource_url)

local config = {
    name = 'meiru', 
    description = 'meiru web framework', 
    keywords = 'meiru skynet lua skynetlua'
}
app.data("config", config)

-- app.set("host", "127.0.0.1")
app.use(meiru.static('/public', static_path))
app.use(router.node())
app.run()

local tree = app.treeprint()
log("treeprint\n", tree)

---------------------------------------
--dispatch
---------------------------------------
local req = {
    protocol = 'http',
    method   = "get",
    url      = "/index",
    headers  = {},
    body     = "",
}

local res = {
    response = function(code, bodyfunc, headers)
        log("response", code, headers)
    end,
}

app.dispatch(req, res)

local memory_info = dump_memory()
log("memory_info\n", memory_info)

local foot = app.footprint()
log("footprint\n", foot)

local chunk = app.chunkprint()
log("chunkprint\n", chunk)


