local ipairs = ipairs
local manager = getScriptManager() -- i prefer this get method to ScriptManager.instance

--[[
adjust_items("Base", {
  AssaultRifle = {
     MinDamage = 0.8,
     MaxDamage = 1.4, 
   },
  PistolCase1 = {
     Capacity = 3,
   },
})
]]

local adjust_items = function(module, items)
    for name, tweaks in ipairs(items) do repeat
        local item = manager:getItem(module .. '.'.. name)
        if not item then break end
        for key, value in ipairs(tweaks) do
            item:DoParam(key .. ' = '.. value)
        end
    until true end
end


--[[
-- call the function editting the bookstore with new values
adjust_distrib(ProceduralDistributions.list.BookstoreBooks, {
    -- replace these spawn rates with new values
    BookCarpentry1 = 5,
    BookCarpentry2 = 4,
    BookCarpentry3 = 3,
},{
    -- multiply these spawn rates
    BookCarpentry4 = 2,
    BookCarpentry5 = 0.5,
})
]]
local adjust_distrib = function(dist_table, replace_table, multiply_table)
    -- check for a junk table, and edit it by recursively calling this function
    if dist_table.junk then
        adjust_distrib(dist_table.junk, replace_table, multiply_table)
    end

    local items = dist_table.items
    if not items then return end
    
    -- only need to check every second position, since thats the item name
    for i=1, #items, 2 do
        if replace_table[items[i]] then 
            -- replace the spawn rate with the new value
            items[i+1] = replace_table[items[i]] 
        end
        if multiply_table[items[i]] then
            items[i+1] = items[i+1] * multiply_table[items[i]]
        end
    end
end

return {
    adjust_items = adjust_items,

}
