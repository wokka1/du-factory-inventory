for k, v in pairs(unit) do
    if type(v) == "table" and v.getElementClass then
        if v.getElementClass() == "ManualSwitchUnit" then
            v.deactivate()
        end
    end
end
