#!/usr/bin/lua

BUILDDIR = "build/"
GLINKDIR = "../gllink/mk/"
dofile(GLINKDIR .. "gllink.lua")
--targops = dofile(GLINKDIR .. "/targets.lua")

print(colorizing.yellow("StartGLLINK"))

Variables = 
{
	CXX = "g++",
	CC = "gcc",
	LD = "g++",
	AR = "ar",
	LN = "ln",
	CXXFLAG = "-std=gnu++11",
	CCFLAG = "",
	INCLUDE = "-I../glib/include -I../glib/arch/linux/include",
	DEFINE = "",
	LDFLAG = "",
}

RulePrototypes = 
{
	cxx_rule = "{CXX} #src -c -o #tgt {INCLUDE} {DEFINE} {CXXFLAG} #loc",
	cc_rule = "{CC} #src -c -o #tgt {INCLUDE} {DEFINE} {CCFLAG} #loc",	
	ar_rule = "{AR} rc #tgt #src",
	ld_rule = "{LD} -Wl,--start-group #src -Wl,--end-group -o #tgt {LDFLAG} #loc",
	ln_rule = "{LN} #src #tgt"
}
RULES = mk.compile_rules(RulePrototypes,Variables)

task = 
{
	name = "genos",
	sources = 
	{
		--cxx = {"main.cpp"},
	},

	modules = 
	{
		{name = "arch", impl = "linux64"},
		
		{name = "diag", impl = "impl"},
		{name = "arch_diag", impl = "linux64"},

		{name = "dprint", impl = "diag", strtg = Strtg.always},

		{name = "main", strtg = Strtg.always},
	},

	--locinc = 
	--{
		--{src = "mmm.h", tgt = "sss.h"}
	--},
	
	--loc = "-DGENOS=1",
	--target = "genos"
	assembly = true
}
regmodule(task)

gm_dolist(paths.find("*.gll", ".")); 
gm_dolist(paths.find("*.gll", "../glib")); 

--printmods()
print(colorizing.yellow("MAKE"))

makemodule{name = "genos", bdir = BUILDDIR, strtg = Strtg.always}

print(colorizing.green("SuccessEnd"))

os.execute("cp build/genos genos")



