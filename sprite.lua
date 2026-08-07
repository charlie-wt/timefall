sprite = {}

function sprite.cycling(set, period, t)
	local progress = (t % period) / period
	local index = flr(progress * #set) + 1
	return set[index]
end
