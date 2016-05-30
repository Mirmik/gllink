paths = {}

local os = require "os"

function paths.split(path)
    local res = {}
    path = path:match('/$') and path or (path .. '/')
    path = path:gsub('/+', '/')
    local res = {}
    if path:match('^/') then table.insert(res, '/'); path = path:sub(2,#path) end
    for sub in path:gmatch('([^/]*/)') do
       table.insert(res, sub)
    end
    local lst = #res
    local strt = res[1] == "/" and 2 or 1;
    for i = strt, lst do
   		 res[i] = res[i]:sub(1, #res[i] - 1)
    end
    return res
end

function paths.unsplit(list)
	str = ""
	local len = #list 
	local strt = 1 
	if list[1] == "/" then strt = 2; str = "/" end 
	for i = strt, len - 1 do
		str = str .. list[i] .. "/"
	end 
	str = str .. list[len]
	return str
end

function paths.lreduce(path)
	local i = 1
	while i <= #path do
	    if path[i] == '.' then
	      	table.remove(path, i)
	    elseif path[i] == '..' then
	        if path[i-1] then
	        	if path[i-1] == '/' then -- root?
	            	table.remove(path, i) -- ignore it (we could also have raised an error)
	        	elseif path[i-1] == '..' then -- could not reduce it before?
	            	i = i + 1
	        	else
	            	table.remove(path, i)
	            	table.remove(path, i-1)
	            	i = i - 1
	    		end
	      	else
	        	i = i + 1
	    	end
	    else
	    	i = i + 1
		end
	end
	return path
end

function paths.reduce(path)
   	local list = paths.lreduce(paths.split(path))
   	return paths.unsplit(list)
end

function paths.concat(...)
   local path = paths.cwd()
   for i=1,select('#', ...) do
      if select(i, ...):match('^/') then
         path = select(i, ...)
      else
         path = path .. '/' .. select(i, ...)
      end
   end
   return paths.reduce(path)
end

function paths.mkdir(name)
   if not os.execute(string.format('mkdir -p %s', name)) then
      error(string.format('unable to create directory <%s>', name))
   end
end

function paths.basename(path)
   if not path:match('^/') then
      path = paths.cwd() .. '/' .. path
   end
   path = paths.reduce(paths.split(path))
   return table.remove(path)
end

function paths.exists(filename)
   local f = io.open(filename)
   if f then
      f:close()
      return true
   end
   return false
end

--[[
function paths.absdir(path)
   if not path:match('^/') then
      path = paths.cwd() .. '/' .. path
   end
   path = paths.reduce(paths.split(path))
   table.remove(path)
   path = paths.reduce(path)
   return table.concat(path)
end

function paths.reldir(path)
   path = paths.reduce(paths.split(path))
   table.remove(path)
   path = paths.reduce(path)
   return table.concat(path)
end
--]]

function paths.absdir(path)
  local lpath = paths.abslist(paths.split(path))
  table.remove(lpath,#lpath)
  return paths.unsplit(lpath) 
end

function paths.reldir(path)
  local lpath = paths.split(path)
  table.remove(lpath,#lpath)
  return paths.unsplit(lpath) 
end

function paths.cwd()
	return os.getenv("PWD")
end

function paths.abslist(list)
	if list[1] == "/" then return list end
	local cwdlist = paths.split(paths.cwd())
	local ii=0
	for i = #cwdlist + 1, #cwdlist + #list + 1 do
    	ii = ii + 1
    	cwdlist[i] = list[ii]
    end
    return cwdlist
end

function paths.relative(root, path)
   local root = paths.abslist(paths.lreduce(paths.split(root)))
   local path = paths.abslist(paths.lreduce(paths.split(path)))

   while root[1] and root[1] == path[1] do
      table.remove(root, 1)
      table.remove(path, 1)
   end

   while root[1] do
      table.remove(root, 1)
      table.insert(path, 1, '../')
   end

   return table.concat(path)
end

function paths.mkdir_list_relative(list,rel)
	for i = 1, #list do
		paths.mkdir(rel .. "/" .. list[i])
	end
end

function os.capture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
  return s
end


function paths.find(templ,root)
	local tbl = string.split(os.capture(string.format('find %s -name "%s"', root, templ),true))
	return tbl
end

function paths.changeexp(str, exp)
  local nstr = str:gsub("%w+$", exp)
  return nstr
end

function paths.list_add_prefix(list, prefix)
  local outlist = {}
  if (prefix == "") or (prefix == nil) then
    return table.shallowcopy(list)
  end
  for i = 1, #list do
    table.insert(outlist, paths.reduce(prefix .. "/" .. list[i]))
  end
  return outlist
end

function paths.list_changeexp(list, exp)
  local outlist = {}
  for i = 1, #list do
    table.insert(outlist, paths.changeexp(list[i],exp))
  end
  return outlist
end

--return paths