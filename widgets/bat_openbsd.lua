-- {{{ Grab environment
local setmetatable = setmetatable
local tonumber = tonumber
local io = { popen = io.popen }
local math = { floor = math.floor }
local helpers = require("vicious.helpers")
local string = {
    gmatch = string.gmatch,
    match = string.match,
    format = string.format

}
-- }}}
local bat_openbsd = {}

local function worker(format, warg)
    local bat_info = {}

    -- reads battery state
    local f = io.popen("apm -blma")
	local lineno = 0
    for line in f:lines("*line") do
		if lineno == 0 then
			bat_info["battery_state"] = tonumber(line)
		elseif lineno == 1 then
			bat_info["percent_left"] = tonumber(line)
		elseif lineno == 2 then
			bat_info["minutes_left"] = line
		elseif lineno == 3 then
			bat_info["charger_state"] = tonumber(line)
		end
		lineno = lineno + 1
	end
    f:close()

    if bat_info["battery_state"] == 0 then
		-- battery full
        state =  "↯"
    elseif bat_info["charger_state"] == 1 then
		-- battery charging
        state = "+"
    elseif bat_info["charger_state"] == 0 then
		if bat_info["battery_state"] == 1 then
			-- battery discharging
			state = "-"
		elseif bat_info["battery_state"] == 2 then
			-- battery critical
			state = "⌁"
		end
    else
		-- battery absent or unknown
        state = ""
    end

    -- use remaining (charging or discharging) time calculated by acpiconf
    local time = bat_info["minutes_left"]
    if time == "unknown" then
        time = "∞"
    end

    -- calculate wear level from (last full / design) capacity
    local wear = "N/A"

    -- dis-/charging rate as presented by battery
    local rate = "N/A"

    -- returns
    --  * state (high "↯", discharging "-", charging "+", N/A "⌁" }
    --  * remaining_capacity (percent)
    --  * remaining_time, by battery
    --  * wear level (percent)
    --  * present_rate (mW)
    return {state, bat_info["percent_left"], time, wear, rate}
end

return setmetatable(bat_openbsd, { __call = function(_, ...) return worker(...) end })
