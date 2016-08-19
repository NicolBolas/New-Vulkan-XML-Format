
local write_utils = require "_NewFormatUtils"

local func_attribs = {}
local func_writers = {}

func_attribs["command-alias"] = {"name", "target", "notation", }
func_writers["command-alias"] = function(writer, data)
end

func_attribs.command = {"name",
		"renderpass", "cmdbufferlevel", "queues", "notation",}
function func_writers.command(writer, data)
	writer:PushElement("return-type")
	write_utils.WriteAttribs(writer, {"successcodes", "errorcodes"}, data.return_type)
	write_utils.WriteVarDef(writer, data.return_type)
	writer:PopElement()

	if(data.params) then
		for _, param in ipairs(data.params) do
			writer:PushElement("param")
			write_utils.WriteNamedVariable(writer, param)
			writer:PopElement()
		end
	end
	
	if(data.usages) then
		writer:PushElement("validity")
		for _, usage in ipairs(data.usages) do
			writer:PushElement("usage")
			writer:AddText(usage)
			writer:PopElement()
		end
		writer:PopElement()
	end
	
	if(data.external_sync) then
		writer:PushElement("external-sync")
		for _, sync in ipairs(data.external_sync) do
			writer:PushElement("sync")
			writer:AddText(sync)
			writer:PopElement()
		end
		writer:PopElement()
	end
end

local writers = {}

for name, func in pairs(func_writers) do
	writers[name] = write_utils.NamedElementWriter(name, func, func_attribs[name])
end

return writers
