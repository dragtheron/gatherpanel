function Dump(o)
  if type(o) == 'table' then
     local s = '{ '
     for k,v in pairs(o) do
        if type(k) ~= 'number' then k = '"'..k..'"' end
        s = s .. '['..k..'] = ' .. Dump(v) .. ','
     end
     return s .. '} '
  else
     return tostring(o)
  end
end

function Keys(o)
    if type(o) == 'table' then
       local s = '[ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. k ..', '
       end
       return s .. '] '
    end
end

function Deepcopy(orig)
   local orig_type = type(orig)
   local copy
   if orig_type == 'table' then
       copy = {}
       for orig_key, orig_value in next, orig, nil do
           copy[Deepcopy(orig_key)] = Deepcopy(orig_value)
       end
       setmetatable(copy, Deepcopy(getmetatable(orig)))
   else -- number, string, boolean, etc
       copy = orig
   end
   return copy
end

function Shallowcopy(orig)
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
