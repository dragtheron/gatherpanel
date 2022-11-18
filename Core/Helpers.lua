local _, addon = ...;

function addon:Dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. self:Dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function addon:Enum(tbl)
   local length = #tbl
   for i = 1, length do
       local v = tbl[i]
       tbl[v] = i
   end

   return tbl
end
