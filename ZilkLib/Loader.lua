

local DEFAULT_REPO = 'https://raw.githubusercontent.com/XIMMYzwsss/ZilkLib/main/ZilkLib/'
local LOCAL_ROOTS = {
	'C:/Users/iphon/Desktop/ROBLOX SHIT/ZilkLib/',
	'C:\\Users\\iphon\\Desktop\\ROBLOX SHIT\\ZilkLib\\',
	'ZilkLib/',
	'',
}

local function normalizeRel(path)
	return (path:gsub('^ZilkLib/', ''))
end

local function loadZilkModule(path, repo)
	repo = repo or DEFAULT_REPO
	if repo:sub(-1) ~= '/' then
		repo = repo .. '/'
	end

	local rel = normalizeRel(path)
	local body

	if typeof(readfile) == 'function' and typeof(isfile) == 'function' then
		local candidates = {}
		for _, root in ipairs(LOCAL_ROOTS) do
			table.insert(candidates, root .. rel)
			table.insert(candidates, root .. path)
		end
		table.insert(candidates, path)
		table.insert(candidates, 'ZilkLib/' .. rel)
		table.insert(candidates, rel)
		for _, candidate in ipairs(candidates) do
			local ok, exists = pcall(isfile, candidate)
			if ok and exists then
				local okRead, data = pcall(readfile, candidate)
				if okRead and type(data) == 'string' and #data > 50 then
					body = data
					break
				end
			end
		end
	end

	if not body then
		local url = repo .. rel
		body = game:HttpGet(url)
		if type(body) ~= 'string' or #body < 50 then
			error('[ZilkLib] Failed to fetch: ' .. url)
		end
	end

	local chunkName = '@ZilkLib/' .. rel
	local fn, err = loadstring(body, chunkName)
	if not fn then
		error('[ZilkLib] Failed to compile ' .. rel .. ': ' .. tostring(err))
	end

	local ok, result = pcall(fn)
	if not ok then
		error('[ZilkLib] Failed to run ' .. rel .. ': ' .. tostring(result))
	end

	return result
end

local Loader = {
	Repo = DEFAULT_REPO,
	loadZilkModule = loadZilkModule,
}

function Loader.Load(repo)
	repo = repo or DEFAULT_REPO
	return
		loadZilkModule('Library.lua', repo),
		loadZilkModule('addons/ThemeManager.lua', repo),
		loadZilkModule('addons/SaveManager.lua', repo),
		loadZilkModule('addons/BuiltInTabs.lua', repo)
end

return Loader
