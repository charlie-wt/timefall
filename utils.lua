function round(n)
	if n % 1 < 0.5 then return flr(n) end
	return ceil(n)
end

function contains(l,x)
	for i in all(l) do
		if i == x then return true end
	end
	return false
end

function map_table(tbl, fn)
	local res = {}
	for k,v in pairs(tbl) do
		res[k] = fn(v)
	end
	return res
end

function map_table_or_value(input, fn)
	if type(input) == 'table' then
		local res = {}
		for k,v in pairs(input) do
			res[k] = fn(v)
		end
		return res
	else
		return fn(input)
	end
end

function tiles(pos)
	return map_table_or_value(pos, function(p) return round(p/8) end)
end

function pixels(pos)
	return map_table_or_value(pos, function(p) return p*8 end)
end

function lnpx(text) -- length of text in pixels
	return print(text, 0, 999999)
end

function shallow_copy(orig)
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

function list_str(l)
	local res = "{"
	local sep = ""
	for _,val in pairs(l) do
		res = res..sep..tostr(val)
		sep = ", "
	end
	return res.."}"
end

function table_str(l)
	local res = "{"
	local sep = ""
	for key,val in pairs(l) do
		res = res..sep..tostr(key).."="..tostr(val)
		sep = ", "
	end
	return res.."}"
end
