colorizing = {}

function colorizing.block(str)
	return  string.char(27) .. str ..  string.char(27) .. "[0m"
end

function colorizing.red(str)
	return colorizing.block("[31m" .. str)
end