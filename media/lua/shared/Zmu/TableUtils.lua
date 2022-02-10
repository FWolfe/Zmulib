
local table = table
local contains = function(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false 
end

return {
    contains = contains
}
