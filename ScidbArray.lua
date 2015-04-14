require ("ScidbConnect")

__ScidbArray = {

	con = ScidbConnect{}

}


-- defines that __Field (see above) is a metatable 
metaTableScidbArray = {__index = __ScidbArray}

-- This function is used to implement all ScidbArrays
function ScidbArray (argv)
    local  f   = argv
    -- all other parameters are accessed via the metatable
    setmetatable (f, metaTableScidbArray)
    return f
end
