colorizing = {}

function colorizing.block(str)
	return  string.char(27) .. str ..  string.char(27) .. "[0m"
end

function colorizing.red(str)
	return colorizing.block("[31;1m" .. str)
end

function colorizing.green(str)
	return colorizing.block("[32;1m" .. str)
end

function colorizing.yellow(str)
	return colorizing.block("[33;1m" .. str)
end
