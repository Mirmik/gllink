
function string.split(inputstr, sep)
   if sep == nil then
      sep = "%s"
   end
   local t={} ; i=1
   for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
      t[i] = str
      i = i + 1
   end
   return t
end

function  string.tblgsub(str,ptbl,ntbl)
	assert( #ptbl == #ntbl )
	local lstr = str
	for i = 1, #ptbl do
		lstr = string.gsub(lstr, ptbl[i], ntbl[i])
	end
	return lstr
end

function string.concat_from_list(list,div)
   local str = ""
   for i = 1, #list - 1 do
      str = str .. list[i] .. div
   end
   str = str .. list[#list]
   return str
end