for k, v in pairs(unit) do
    if type(v) == "table" and v.getClass then
        if v.getClass() == "ManualSwitchUnit" then
            v.deactivate()
        end
    end
end
