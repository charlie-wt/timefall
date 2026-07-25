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

function tiles(pos)
	return {round(pos.x/8), round(pos.y/8)}
end

function pixels(pos)
	return {pos.x*8, pos.y*8}
end
