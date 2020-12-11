local KEYWORDS = {
    ["and"] = true, ["break"] = true, ["do"] = true, ["else"] = true,
    ["elseif"] = true, ["end"] = true, ["false"] = true, ["for"] = true,
    ["function"] = true, ["if"] = true, ["in"] = true, ["local"] = true,
    ["nil"] = true, ["not"] = true, ["or"] = true, ["repeat"] = true,
    ["return"] = true, ["then"] = true, ["true"] = true, ["until"] = true,
    ["while"] = true
}

local function isValidVariable(variable)
    return variable ~= "" and KEYWORDS[variable] == nil and string.find(variable, "^[_%a]+[_%w]+$") ~= nil
end

local function amountify(amount)
    return amount == 1 and "is " .. amount or "are " .. amount
end

local function pluralize(amount, string)
    return amount == 1 and string or string .. "s"
end

local function interpolatePositionalParameter(writer, positionalParameter)
    if positionalParameter > #writer.arguments then
        error("Invalid positional argument " .. positionalParameter .. " (there " .. amountify(#writer.arguments) .. " " .. pluralize(#writer.arguments, "argument") .. ").", 5)
    end

    writer.biggestPositionalParameter = math.max(writer.biggestPositionalParameter, positionalParameter)

    return tostring(writer.arguments[positionalParameter])
end

local function interpolateNamedParameter(writer, parameter)
    if not isValidVariable(parameter) then
        error("Unsupported format specifier `" .. parameter .. "`.", 5)
    end

    if writer.namedParameters == nil or writer.namedParameters[parameter] == nil then
        error("There is no named argument `" .. parameter .. "`.", 5)
    end

    writer.hadNamedParameter = true

    return tostring(writer.namedParameters[parameter])
end

local function interpolateDisplayParameter(writer)
    writer.currentArgument += 1
    writer.numberOfParameters += 1

    return tostring(writer.arguments[writer.currentArgument])
end

local function interpolateDebugImpl(writer, isExtendedForm)
    writer.currentArgument += 1
    writer.numberOfParameters += 1

    local argument = writer.arguments[writer.currentArgument]
    local argumentType = typeof(argument)

    if argumentType == "string" then
        return string.format("%q", argument)
    elseif argumentType == "table" then
        local argumentMetatable = getmetatable(argument)

        if argumentMetatable ~= nil and argumentMetatable.__fmtDebug ~= nil then
            -- This type implements the metamethod we made up to line up with
            -- Rust's `Debug` trait.

            return argumentMetatable.__fmtDebug(argument, isExtendedForm)
        else
            return argument
        end
    elseif argumentType == "Instance" then
        return argument:GetFullName()
    else
        return tostring(argument)
    end
end

local function interpolate(formatSpecifier, writer)
    local firstCharacter = string.sub(formatSpecifier, 1, 1)
    local positionalParameter = firstCharacter ~= "-" and tonumber(formatSpecifier) or nil

    if positionalParameter ~= nil then
        return interpolatePositionalParameter(writer, positionalParameter)
    elseif firstCharacter == ":" then
        if formatSpecifier == ":" then
            return interpolateDisplayParameter(writer)
        elseif formatSpecifier == ":?" then
            -- This should use the equivalent of Rust's `Debug`, invented for
            -- this library as __fmtDebug.

            return interpolateDebugImpl(writer, false)
        elseif formatSpecifier == ":#?" then
            -- This should use the equivalent of Rust's `Debug` with the
            -- `alternate` (ie expanded) flag set.

            return interpolateDebugImpl(writer, true)
        else
            error("Unsupported format specifier `" .. string.sub(formatSpecifier, 2) .. "`.", 4)
        end
    elseif formatSpecifier ~= "" then
        return interpolateNamedParameter(writer, formatSpecifier)
    elseif formatSpecifier == "" then
        return interpolateDisplayParameter(writer)
    end
end

local function composeWriter(arguments)
    local lastArgument = arguments[#arguments]

    return {
        arguments = arguments;
        currentArgument = 0;
        numberOfParameters = 0;
        biggestPositionalParameter = 0;
        namedParameters = type(lastArgument) == "table" and lastArgument or nil;
        hadNamedParameter = false;
    }
end

local function writeToBuffer(buffer, value)
    table.insert(buffer, value)
end

local function writeFmt(buffer, template, ...)
    local index = 1
    local writer = composeWriter({...})

    while index <= #template do
        local brace = string.find(template, "[%{%}]", index)

        -- There are no remaining braces in the string, so we can write the
        -- rest of the string to the buffer.
        if brace == nil then
            writeToBuffer(buffer, string.sub(template, index))
            break
        end

        local braceCharacter = string.sub(template, brace, brace)
        local characterAfterBrace = string.sub(template, brace + 1, brace + 1)

        if characterAfterBrace == braceCharacter then
            -- This brace starts a literal '{', written as '{{'.

            writeToBuffer(buffer, braceCharacter)
            index = brace + 2
        else
            if braceCharacter == "}" then
                error("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.", 3)
            else
                local closeBrace = string.find(template, "}", index + 1)

                if closeBrace == nil then
                    error("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.", 3)
                else
                    -- If there are any unwritten characters before this
                    -- parameter, write them to the buffer.
                    if brace - index > 0 then
                        writeToBuffer(buffer, string.sub(template, index, brace - 1))
                    end

                    local formatSpecifier = string.sub(template, brace + 1, closeBrace - 1)

                    writeToBuffer(buffer, interpolate(formatSpecifier, writer))

                    index = closeBrace + 1
                end
            end
        end
    end

    local numberOfArguments = writer.hadNamedParameter and #writer.arguments - 1 or #writer.arguments

    if writer.numberOfParameters > numberOfArguments  then
        error(writer.numberOfParameters .. " " .. pluralize(writer.numberOfParameters, "parameter") .. " found in template string, but there " .. amountify(numberOfArguments) .. " " .. pluralize(numberOfArguments, "argument") .. ".", 3)
    end

    if numberOfArguments > writer.numberOfParameters and writer.biggestPositionalParameter < numberOfArguments then
        error(writer.numberOfParameters .. " " .. pluralize(writer.numberOfParameters, "parameter") .. " found in template string, but there " .. amountify(numberOfArguments) .. " " .. pluralize(numberOfArguments, "argument") .. ".", 3)
    end
end

local function fmt(template, ...)
    local buffer = {}

    writeFmt(buffer, template, ...)

    return buffer
end

return fmt