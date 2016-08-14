
local writers = {}

function writers.vendorid(writer, data)
	writer:PushElement("vendorid")
	writer:AddAttribute{
		name = data.name,
		id = data.id,
		notation = data.notation,
	}
	writer:PopElement()
end

return writers
