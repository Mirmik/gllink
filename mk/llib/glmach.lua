--glmach
glmach = {
	modules = {},
	lastfile = nil,
	impltable = {},
}


modfields = {
{field = "cc_source", tp = "strarray", default = {}}, 
{field = "cpp_source", tp = "strarray", default = {}}, 
{field = "s_source", tp = "strarray", default = {}},
{field = "meta", tp = "string", default = nil},
{field = "opts", tp = "strarray", default = {}},
{field = "name", tp = "string", default = nil},
--{field = "compile", tp = "string", default = "check", variant = {"always", "check", "static"}},
}

function imodfields()
	local i = 0
	return function() 
		i = i + 1; 
		local tbl = modfields[i];
		if not tbl then return nil end
		return tbl.field, tbl.tp, tbl.default, tbl.variant end
end

function valtype(val, tp)
	if val == nil then return nil end
	if tp == "string" then
		if type(val) == "string" then return 0 
		else return nil end
	end
	if tp == "strarray" then
		if type(val) == "table" then
			for k,v in ipairs(val) do
				if not type(v) == "string" then return nil end
			end  
			return 0
		else return nil end
	end
	error("wrong tp")
end

function valvars(val, vars)
	for v in ipairs(vars) do
		if v == val then return v end
	end
	return nil
end

function glmach.error(str)
	error("GlMach: " .. glmach.lastfile .. "." .. str)
end

function glmach.dofile(fname)
	print("GlMach: execute file " .. fname)
	glmach.lastfile = fname
	dofile(fname)
end

function glmach.dolist(list)
	for i = 1, #list do
		glmach.dofile(list[i])
	end
end

function glmach.validate_mod(mod)
	if mod.name == nil then glmach.error("module without name") end
	for f, t, d, vars in imodfields(mod) do
		if mod[f] == nil then 
			mod[f] = d 
		else
			if not valtype(mod[f],t) then glmach.error("wrong data type in field " .. f) end
		end
		if vars then 
			if valvars(mod[f],vars) then  glmach.error("wrong data in field " .. f) end
		end
	end
end

function glmach.reg_module(arg)
	glmach.validate_mod(arg)
	arg.fname = glmach.lastfile
	arg.reldir = paths.reldir(glmach.lastfile)
	--if arg.name == nil then glmach.error("name is nil") end
	print("reg_module: " .. arg.name)
	glmach.modules[arg.name] = arg
	if not (arg.meta == nil) then
		if glmach.impltable[arg.meta] == nil then glmach.impltable[arg.meta] = {} end
		glmach.impltable[arg.meta][arg.name] = arg
	end
end

function reg_module(arg)
	glmach.reg_module(arg)
end

function glmach.mod_print(name)
	mod = glmach.modules[name]
	if mod == nil then error("wrong module name") end
	str_name = mod.name
	if mod.meta then str_name = str_name .. " -> " .. mod.meta end 
	print("Module: " .. str_name)
	print("\tcpp_source: " .. table.tostring(mod.cpp_source))
	print("\tcc_source: " .. table.tostring(mod.cc_source))
	print("\ts_source: " .. table.tostring(mod.s_source))
	print("\tfname: " .. mod.fname)
end

function glmach.print_modnames()
	local names = {}
	for k,v in pairs(glmach.modules) do
		table.insert(names, k)
	end
	print(table.tostring(names))
end

function glmach.print_implementations(name)
	local names = {}
	for k,v in pairs(glmach.impltable[name]) do
		table.insert(names, k)
	end
	print(table.tostring(names))
end

function glmach.atarget(mod)
	return paths.reduce(BUILDDIR .. "/" .. mod.name .. "/" .. mod.name .. ".a")
end

function glmach.build_module(mod,rules)
	print("make_module: " .. mod.name)
	local MODDIR = BUILDDIR .. "/" .. mod.name .. "/"
	local cxxsl, cxxtl, ccsl, cctl, ssl, stl
	cxxsl,cxxtl = mk.prepare_srctgt_lists(mod.cxx_source, "o", mod.reldir, MODDIR)
	mk.use_rule_list(rules.cxx_rule, cxxsl, cxxtl)
	ccsl,cctl = mk.prepare_srctgt_lists(mod.cc_source, "o", mod.reldir, MODDIR)
	mk.use_rule_list(rules.cc_rule, ccsl, cctl)
	ssl,stl = mk.prepare_srctgt_lists(mod.s_source, "o", mod.reldir, MODDIR)
	mk.use_rule_list(rules.s_rule, ssl, stl)

	otgt = string.lconcat(cxxtl," ") .. " " 
	.. string.lconcat(cctl," ") .. " " 
	.. string.lconcat(stl," ") 
	
	atgt = glmach.atarget(mod)

	mk.use_rule(rules.ar_rule, otgt, atgt)
end

function glmach.make_module(mod,rules,strtg)
	if strtg == "always" then glmach.build_module(mod,rules)
	elseif (strtg == "standart") or (strtg == nil) then
		print("TODO")
		os.exit()
	elseif strtg == "static" then 
		if not paths.exists(glmach.atarget(mod)) then build_module(mod) end
	else glmach.error("make, strtg wrong value") end
end

--function glmach.assembly(list)
--	local atargets = {}
--	for i=1, #list do
--		assert(not((list.mod == nil) && (list.pack == nil)))
		--atgt = glmach.atarget(list[i]) 
--		if not (list.mod == nil) then 

--		end	
--		if not (list.mod == nil) then 

--		end	
--	end
--end

