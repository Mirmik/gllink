mk = {}
local os = require("os")
local lfs = require("lfs")

function mk.rule_build(prototype, container)
	local lp
	local s
	local str = prototype
	for p in string.gmatch(prototype,"{%w+}") do
		lp = string.sub(p, 2, #p -1)
		s = container[lp] 
		str = string.gsub(str,p,s)
	end
	return str
end

function mk.compile_rules(prototypes,container)
	local outrules = {}
	for key,rule in pairs(prototypes) do
		outrules[key] = mk.rule_build(rule,container)
	end 
	return outrules
end


function mk.use_rule(rule,src,tgt)
	local instr = rule
	instr = string.tblgsub(instr,{"#src","#tgt"},{src,tgt})
	paths.validate_directory(tgt)
	print(instr)
	if not (os.execute(instr) == 0) then
		print(colorizing.red("Error at rule using operation"))
		os.exit()
	end
end

function mk.use_rule_list(rule,src,tgt)
	assert(#src == #tgt)
	for i = 1, #src do
		mk.use_rule(rule,src[i],tgt[i])
	end
end

function mk.prepare_changed_only_list(srclist, tgtlist)
	local _srcl = {}
	local _tgtl = {}
	for i = 1, #srclist do
		if (not (paths.exists(tgtlist[i]))) or (lfs.attributes(srclist[i],"modification") 
			> lfs.attributes(tgtlist[i],"modification"))
		then
		table.insert(_srcl, srclist[i])
		table.insert(_tgtl, tgtlist[i])
		end
	end
	return _srcl, _tgtl
end

function mk.prepare_srctgt_lists(list, tgtexp, srcprefix, tgtprefix)
	local _tgtlist = paths.list_changeexp(list,tgtexp)
	local srclist = paths.list_add_prefix(list,srcprefix)
	local tgtlist = paths.list_add_prefix(_tgtlist,tgtprefix)
	return srclist, tgtlist
end
