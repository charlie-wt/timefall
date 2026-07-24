function round(n)
	if (n % 1 < 0.5) return flr(n)
	return ceil(n)
end

function contains(l,x)
	for i in all(l) do
		if (i == x) return true
	end
	return false
end


