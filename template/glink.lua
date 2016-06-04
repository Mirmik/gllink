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
	CXXFLAG = "",
	CCFLAG = "",
	INCLUDE = "",
	DEFINE = "",
	LDFLAG = "",
}

RulePrototypes = 
{
	cxx_rule = "{CXX} #src -c -o #tgt {INCLUDE} {DEFINE} {CXXFLAG} #loc",
	cc_rule = "{CC} #src -c -o #tgt {INCLUDE} {DEFINE} {CCFLAG} #loc",	
	ar_rule = "{AR} rc #tgt #src",
	ld_rule = "{LD} #src -o #tgt {LDFLAG} #loc",
	ln_rule = "{LN} #src #tgt"
}
RULES = mk.compile_rules(RulePrototypes,Variables)

task = 
{
	name = "genos",
	sources = 
	{
		cxx = {"main.cpp"},
	},

	modules = 
	{
		{name = "factorial", loc = "-DFFF=3"},
	},

	locinc = 
	{
		{src = "mmm.h", tgt = "sss.h"}
	},
	
	loc = "-DGENOS=1",
	--target = "genos"
	assembly = true
}
regmodule(task)

gm_dofile("main.gll")
gm_dofile("factorial/fact.gll")

--printmods()
print(colorizing.yellow("MAKE"))

makemodule{name = "genos", bdir = BUILDDIR, strtg = Strtg.always}

print(colorizing.green("SuccessEnd"))

os.execute("cp build/genos genos")



