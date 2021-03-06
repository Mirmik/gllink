CURDIR = paths.cwd()
STARTDIR = paths.cwd()
STARTPATH = "gllink.lua"
CURFILE = "gllink.lua"
MODS = {}
METAMODS = {}
deep = 0

Strtg = {standart = 0, always = 1, static = 2}
function Strtg.validate(strtg)
	if strtg == Strtg.standart or
	strtg == Strtg.always or
	strtg == Strtg.static then
	return true else return nil end
end

function printmods()
	for k,v in pairs(MODS) do
		print(k)
	end
end

function gm_dofile(fpath)
	CURDIR = paths.absdir(fpath)
	CURFILE = fpath
	dofile(fpath)
	CURFILE = STARTPATH
	CURDIR = STARTDIR
end

function gm_dolist(list)
	for i = 1, #list do
		gm_dofile(list[i])
	end
end

function regmodule(mod)
	assert(mod.name)
	mod.filepath = CURFILE
	mod.dirpath = CURDIR
	MODS[mod.name] = mod
	print("regmodule " .. mod.name)
end

function regmetamodule(mod)
	assert(mod.name)
	mod.filepath = CURFILE
	mod.dirpath = CURDIR
	METAMODS[mod.name] = mod
end

function makesource_list(args)
	local sl,tl,psl,ptl
	sl,tl = mk.prepare_srctgt_lists(args.srcs, "o", args.srcpref, args.bdir) 

	if args.strtg == Strtg.standart then
		psl, ptl = mk.prepare_changed_only_list(sl,tl)
		mk.use_rule_list(args.rule,psl,ptl,args.loc)
		return tl
	end

	if args.strtg == Strtg.always then
		mk.use_rule_list(args.rule,sl,tl,args.loc)
		return tl
	end

	--if args.strtg == Strtg.static then
		--mk.use_rule_list(args.rule,sl,tl)
	--	return tl
	--end

	error("unresolved strategy")
end

function modoutassembl(args)
	assert(args.strtg)

	if args.strtg == Strtg.standart then
		if mk.sl_is_need_to_compile(args.objs,args.tgt) then
			mk.use_rule(args.rule,string.lconcat(args.objs, " "),args.tgt,args.loc)
		end
		return
	end

	if args.strtg == Strtg.always then
		mk.use_rule(args.rule,string.lconcat(args.objs, " "),args.tgt,args.loc)
		return
	end
	
	error("unresolved strategy")	
end


function makesources(args)
	if args.bdir == nil then args.bdir = BUILDDIR end
	if args.rules == nil then args.rules = RULES end
	if args.strtg == nil then args.strtg = Strtg.standart end
	--print("makesources")
	--print("bdir: ", args.bdir)
	assert(args.rules)
	assert(args.bdir)
	assert(args.src)		
	assert(args.strtg)

	params = 
	{
		loc = nil,
		srcpref = args.srcpref,
		bdir = args.bdir,
		strtg = args.strtg,
	}

	local cxxtl, cctl, stl

	if args.src.cxx then
		params.loc = args.loc_cxx
		params.srcs = args.src.cxx
		params.rule = args.rules.cxx_rule
		cxxtl = makesource_list(params)
	end
	
	if args.src.cc then
		params.loc = args.loc_cc
		params.srcs = args.src.cc
		params.rule = args.rules.cc_rule
		cctl = makesource_list(params)
	end
	
	if args.src.s then
		params.loc = ""
		params.srcs = args.src.s
		params.rule = args.rules.s_rule
		stl = makesource_list(params)
	end
	
	local ret = table.uconcat(cxxtl,cctl,stl)
	return ret
end

function makemodule(args)
	local mod
	if args.bdir == nil then args.bdir = BUILDDIR end
	if args.rules == nil then args.rules = RULES end
	if args.strtg == nil then args.strtg = Strtg.standart end
	assert(args.rules)
	assert(args.strtg)
	assert(args.bdir)
	assert(args.name)
	assert(Strtg.validate(args.strtg))
	mod = MODS[args.name]
	assert(mod)
	return makemod(mod,args)
end

function makemetamodule(args)
	local mod
	if args.bdir == nil then args.bdir = BUILDDIR end
	if args.rules == nil then args.rules = RULES end
	if args.strtg == nil then args.strtg = Strtg.standart end
	assert(args.rules)
	assert(args.strtg)
	assert(args.bdir)
	assert(args.name)
	assert(Strtg.validate(args.strtg))
	metamod = METAMODS[args.name]
	if args.impl == nil then 
		assert(metamod.standart)
		args.impl = metamod.standart
	end
	mod = MODS[metamod.name.."."..args.impl]
	assert(mod)
	return makemod(mod,args)
end

function modtarget(mod,args,target)
	if mod.assembly == true then
		return args.bdir .. "/" .. target
	else
		return args.bdir .. "/" .. target .. ".a"
	end
end

function makemod(mod,args)
	local objs = {}
	local abjs = {}
	local tgt = nil
	local mret
	local target
	local lloc_cc, lloc_cxx
	if mod.target == nil then target = mod.name
	else target = mod.target end
	if mod.loc == nil then mod.loc = "" end
	if mod.loc_cc == nil then mod.loc_cc = "" end
	if mod.loc_cxx == nil then mod.loc_cxx = "" end
	if args.loc == nil then args.loc = "" end
	print(colorizing.yellow("["..deep.."] -> " .. mod.name)); deep = deep + 1;
	--print("dir:\t" .. mod.dirpath)
	--print("file:\t" .. mod.filepath)
	--print("target:\t" .. target)
	--print(args.loc)

	if args.strtg == Strtg.static then
		if paths.exists(modtarget(mod,args,target)) 
			then return  {modtarget(mod,args,target)} end
	end

	lloc_cc = mod.loc .. " " .. mod.loc_cc .. " " .. args.loc
	lloc_cxx = mod.loc .. " " .. mod.loc_cxx .. " " .. args.loc

	local s, t

	if mod.locinc then
		for i = 1, #mod.locinc do
			s = mod.dirpath .. "/" .. mod.locinc[i].src
			t = args.bdir .. "/" .. mod.locinc[i].tgt
			if not paths.exists(t) then
				mk.use_rule(args.rules.ln_rule,s,t)
			end
		end
		lloc_cc = lloc_cc .. " -I" .. args.bdir
		lloc_cxx = lloc_cxx .. " -I" .. args.bdir		
	end

	params = 
	{
		loc_cc = lloc_cc,
		loc_cxx = lloc_cxx,
		srcpref = mod.dirpath, 
		bdir = args.bdir, 
		rules = args.rules,
		strtg = args.strtg
	}

	if mod.sources then 
		params.src = mod.sources			
		table.insert_list(objs, makesources(params)) 
	end

	if mod.modules then
	for i = 1, #mod.modules do
		modlit = mod.modules[i]
		assert(modlit.name)
		--assert(MODS[modlit.name])
		modparams = table.shallowcopy(args)
		modparams.name = modlit.name
		if modlit.loc_cc == nil then modlit.loc_cc = "" end
		if modlit.loc_cxx == nil then modlit.loc_cxx = "" end
		modparams.loc_cc = lloc_cc .. " " .. modlit.loc_cc
		modparams.loc_cxx = lloc_cxx .. " " .. modlit.loc_cxx
		modparams.bdir = paths.reduce(args.bdir .. "/" .. modlit.name)
		if modlit.strtg then modparams.strtg = modlit.strtg end
		
		if MODS[modlit.name] then
			mret = makemodule(modparams)
		elseif METAMODS[modlit.name] then
			modparams.impl = modlit.impl
			mret = makemetamodule(modparams)
		else
			error(colorizing.red("wrong module name"))
		end
		table.insert_list(objs, mret)
	end end

	local out
	out = objs
	if (not(#objs == 0)) and (mod.assembly == true) then 
		assert(args.strtg)
		tgt = paths.reduce(args.bdir .. "/" .. target)
		modoutassembl
		{
			rule = args.rules.ld_rule, 
			objs = objs, 
			tgt = tgt, 
			strtg = args.strtg,
			loc_cc = lloc_cc,
			loc_cxx = lloc_cxx
		}
		out = {tgt}
	end

	--print("output: "..table.tostring(out))
	print(colorizing.yellow("["..(deep-1).."] " .. "<- "  .. mod.name))
	deep = deep - 1

	return out
end