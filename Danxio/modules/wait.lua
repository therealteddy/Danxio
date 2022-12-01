function wait(t) 
    local t0 = os.clock()
    while os.clock() - t0 <= t do 
        -- Do nothing, but wait! 
    end 
end