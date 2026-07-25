function init_sand()
	local res = {}

	local row = {}
	for i=1,16 do
		add(row, false)
	end

	for i=1,16 do
		add(res, shallow_copy(row))
	end

	return res
end

sand = init_sand()

function fall()
	-- TODO #finish
end
