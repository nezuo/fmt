local Formatter = require(script.Formatter)

local function format(template, ...)
    local formatter = Formatter.new()

    formatter:write(template, ...)

    return formatter:asString()
end

local function output(template, ...)
    local formatter = Formatter.new()

    formatter:write(template, ...)

    return formatter:asTuple()
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
    format = format;
    output = output;
    debugify = debugify;
}