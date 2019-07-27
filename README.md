# meiru
A mini web framework of lua.
The sparrow may be small, fully-equipped

## Features
  * Object-Oriented Design
  * Composition structure with the 'Node' tree
  * All thing is components, just like Unity3D framework.
  * Support Markdown and FastWidget
  * Use 'Meiru' look like express(node.js)
  * It is sample, No has third party Library
  * It can be Debugeb by vscode(lua extension)
  * The purpose of Meiru is used in skynet(High Concurrency Network Framework).

## Example

```
--open developmet mode
os.mode = config.debug and 'dev'

--include Meiru library
local extension = require "meiru.extension"
local meiru     = require "meiru.meiru"

---------------------------------------
-- create the router
---------------------------------------
--router is a Node and can produce Node
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
--create Meiru app Object
---------------------------------------
local app = meiru.create_app()

app.set("views_path", "./assets/view")
app.set("static_path", "./assets/public")

local config = {
    debug = true,
    name = 'meiru', 
    description = 'meiru web framework', 
    keywords = 'meiru skynet lua skynetlua'
}
--setting viewdata, It can be used in ejs
app.data("config", config)

--static web resource
app.use(meiru.static('/public', static_path))

--add routerNode
app.use(router.node())

--start Meiru application
app.run()

```

If want to see the detail.just do that
```
local tree = app.treeprint()
log("treeprint:\n", tree)
```
log result:
```
treeprint:
 ++node_root
++++node_req
++++++node_start
------ComInit
------ComPath
------ComHeader
------ComSession
++++++++node_static:/public
--------ComStatic
++++++++node_routers
--------ComBody
--------ComCSRF
++++++++++node_router:/index
----------ComHandle
++++++node_finish
------ComFinish
++++node_res
----ComRender
----ComResponse
```


---------------------------------------
--simulate request
local req = {
    protocol = 'http',
    method   = "get",
    url      = "/index",
    headers  = {},
    body     = "",
}

--response
local res = {
    response = function(code, bodyfunc, headers)
        log("response", code, headers)
    end,
}

--dispatch request
app.dispatch(req, res)

```

log reust:
```
response 200 {
	content-type = "text/html;charset=utf-8",
	X-Powered-By = "MeiRu",
	date = "Sat, 27 Jul 2019 06:55:51 GMT",
	accept-ranges = "bytes",
	Set-Cookie = "mrsid=s%3Apvagl29xbxw51.14f10d14d745e2a766b17afc811431cd;Path=/;Domain=;Expires=Sun, 26 Jul 2020 06:55:50 GMT",
	server = "MeiRu/1.0.0",
}
```

What it work?Just do that

```
local foot = app.footprint()
log("footprint\n", foot)
```
log result
```
footprint
 ++node_root
++++node_req
++++++node_start
------ComInit
------ComPath
------ComHeader
------ComSession
++++++++node_static:/public
++++++++node_routers
--------ComBody
--------ComCSRF
++++++++++node_router:/index
----------ComHandle
++++node_res
----ComRender
----ComResponse

```

How ejs.lua work?Just do that

```
local chunk = app.chunkprint()
log("chunkprint\n", chunk)
```
log result?
Try yourself and see the result
Use lua5.3 program
```
lua ./example.lua
```


## Purpose
  The purpose of Meiru is developed for skynet(High Concurrency Network Framework).
  See the 'skynetlua/meiru-skynet'



