local Com    = include("com", ...)
local Render = include(".util.render", ...)

local views_path

local function get_res(path)
    local fullpath = views_path.."/"..path..".html"
    local file = io.open(fullpath, "r")
    if not file then
        fullpath =  views_path.."/"..path..".lua"
        file = io.open(fullpath, "r")
        if not file then
            print("[ERROR]fullpath:", fullpath, debug.traceback())
            assert(false)
            return
        end
    end
    local content = file:read("*a")
    file:close()
    return content
end

-----------------------------------------------
--ComRender
----------------------------------------------
local ComRender = class("ComRender", Com)

function ComRender:ctor()
end

function ComRender:match(req, res)
	if res.render_params then
		views_path = req.app.get("views_path")
        local render
        if os.mode == 'dev' then
            render = Render(get_res, req.app.get_viewdatas(), 2)
        else
            render = Render(get_res, req.app.get_viewdatas())
        end
		local csrf = res.res_csrf
		local data = res.render_params.data or {}
		data.csrf = csrf
		local body, chunks = render(res.render_params.view, data)
        req.app.__chunks = chunks
		local layout = res.get_layout()
		if layout then
			data.body = body
    		res.body = render(layout, data)
    	else
    		res.body = body
    	end
	end
end


return ComRender
