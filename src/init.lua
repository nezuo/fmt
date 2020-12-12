local Formatter = require(script.Formatter)

local function fmt(template, ...)
    local buffer = Formatter.new()

    buffer:write(template, ...)

    return buffer:asString()
end

local function output(template, ...)
    local buffer = Formatter.new()

    buffer:write(template, ...)

    return buffer:asTuple()
end

-- Wrap the given object in a type that implements the given function as its
-- Debug implementation, and forwards __tostring to the type's underlying
-- tostring implementation.
local function debugify(object, fmtFn)
    return setmetatable({}, {
        __fmtDebug = function(_, ...)
            return fmtFn(object, ...)
        end;
        __tostring = function()
            return tostring(object)
        end;
    })
end

return {
    Formatter = Formatter;
    fmt = fmt;
    output = output;
    debugify = debugify;
}