--
function table.val_to_str ( v )
   if "string" == type( v ) then
      v = string.gsub( v, "\n", "\\n" )
      if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
         return "'" .. v .. "'"
      end
      return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
   end
   return "table" == type( v ) and table.tostring( v ) or tostring( v )
end

--
function table.key_to_str ( k )
   if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
      return k
   end
   return "[" .. table.val_to_str( k ) .. "]"
end

-- Преобразование таблицы или массива в текстовое представление в соответствии с синтаксисом языка lua
function table.tostring( tbl )
   local result, done = {}, {}
   for k, v in ipairs( tbl ) do
      table.insert( result, table.val_to_str( v ) )
      done[ k ] = true
   end
   for k, v in pairs( tbl ) do
      if not done[ k ] then
         table.insert( result, table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
      end
   end
   return "{" .. table.concat( result, "," ) .. "}"
end

-- Сохранение таблицы или массива в файл
function table.save(tbl,filename)
   local f,err = io.open(filename,"w")
   if not f then
      return nil,err
   end
   f:write(table.tostring(tbl))
   f:close()
   return true
end

-- Чтение таблицы из файла в массива или таблицу
function table.load(filename)
   local f,err = io.open(filename,"r")
   if not f then
      return nil,err
   end
   local tbl = assert(loadstring("return " .. f:read("*a")))
   f:close()
   return tbl()
end

-- Поиск в массиве таблицы с заданной парой ключ-значение
function table.find_table_with(tbl,key,value)
   for k,v in ipairs(tbl) do
      if v[key] == value then return v end
   end   
   return nil
end

function table.shallowcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = orig_value
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end
