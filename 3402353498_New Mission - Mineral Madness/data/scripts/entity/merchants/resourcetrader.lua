function ResourceDepot.addResource(material, amount)
    --print("adding " .. tostring(amount) .. " of material " .. tostring(material))
    amount = amount or 0
    if amount <= 0 then 
        return 
    end

    stock[material] = stock[material] + amount

    broadcastInvokeClientFunction("setData", material, stock[material])
end