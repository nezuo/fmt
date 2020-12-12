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

local function leadingZeros(buffer, argument, argumentLeadingZeros)
    if type(argument) ~= "number" then
        buffer:writeRaw(tostring(argument))
    else
        argument = tostring(argument)

        buffer:writeRaw(string.rep("0", argumentLeadingZeros - #argument) .. argument)
    end
end

local function width(buffer, argument, argumentWidth)
    argument = tostring(argument)

    buffer:writeRaw(argument .. string.rep(" ", argumentWidth - #argument))
end

local function debugTable(buffer, tbl)
    buffer:writeRaw("{")

    for key, value in pairs(tbl) do
        buffer:write("[{:?}] = {:?}", key, value)

        if next(tbl, key) ~= nil then
            buffer:writeRaw(", ")
        end
    end

    buffer:writeRaw("}")
end

local function debugTableExtended(buffer, tbl)
	-- Special case for empty tables.
	if next(tbl) == nil then
		buffer:writeRaw("{}")
		return
	end

	buffer:writeLineRaw("{")
	buffer:indent()

    for key, value in pairs(tbl) do
        buffer:write("[{:?}] = {:#?}", key, value)

        if next(tbl, key) ~= nil then
            buffer:writeRaw(",")
        end

		buffer:writeLine("")
	end

	buffer:unindent()
	buffer:writeRaw("}")
end

local function debugImpl(buffer, argument, isExtendedForm)
    local argumentType = typeof(argument)

    if argumentType == "string" then
        buffer:writeRaw(string.format("%q", argument))
    elseif argumentType == "table" then
        local argumentMetatable = getmetatable(argument)

        if argumentMetatable ~= nil and argumentMetatable.__fmtDebug ~= nil then
            -- This type implements the metamethod we made up to line up with
            -- Rust's `Debug` trait.

            -- TODO: Handle this weird case with new output...

            argumentMetatable.__fmtDebug(argument, buffer, isExtendedForm)
        else
            buffer:addTable(argument)

            buffer:lock()

            if isExtendedForm then
                debugTableExtended(buffer, argument)
            else
                debugTable(buffer, argument)
            end

            buffer:unlock()
        end
    elseif argumentType == "Instance" then
        buffer:writeRaw(argument:GetFullName())
    else
        buffer:writeRaw(tostring(argument))
    end
end

local function precision(buffer, argument, argumentPrecision)
    if type(argument) ~= "number" then
        buffer:writeRaw(tostring(argument))
    else
        buffer:writeRaw(string.format("%." .. argumentPrecision .. "f", tostring(argument)))
    end
end

local function sign(buffer, argument)
    if type(argument) ~= "number" then
        buffer:writeRaw(tostring(argument))
    else
        buffer:writeRaw(argument >= 0 and "+" .. tostring(argument) or tostring(argument))
    end
end

local function interpolate(buffer, parameter, writer)
    local formatParameterStart = string.find(parameter, ":")
    local leftSide = string.sub(parameter, 1, formatParameterStart and formatParameterStart - 1 or -1)
    local rightSide = formatParameterStart ~= nil and string.sub(parameter, formatParameterStart + 1 or -1) or nil

    local positionalParameter = tonumber(leftSide)
    local isRegularParameter = leftSide == ""

    local argument
    if positionalParameter ~= nil then
        if positionalParameter < 0 or positionalParameter % 1 ~= 0 then
            error("Invalid positional parameter `" .. positionalParameter .. "`.", 4)
        end

        if positionalParameter + 1 > #writer.arguments then
            error("Invalid positional argument " .. positionalParameter .. " (there " .. amountify(#writer.arguments) .. " " .. pluralize(#writer.arguments, "argument") .. "). Note: Positional arguments are zero-based.", 4)
        end
    
        writer.biggestPositionalParameter = math.max(writer.biggestPositionalParameter, positionalParameter + 1)
    
        argument = writer.arguments[positionalParameter + 1]
    elseif isRegularParameter then
        writer.currentArgument += 1

        argument = writer.arguments[writer.currentArgument]
    else
        if not isValidVariable(leftSide) then
            error("Invalid named parameter `" .. leftSide .. "`.", 4)
        end

        if writer.namedParameters == nil or writer.namedParameters[leftSide] == nil then
            error("There is no named argument `" .. leftSide .. "`.", 4)
        end

        writer.hadNamedParameter = true

        argument = writer.namedParameters[leftSide]
    end

    if rightSide ~= nil then
        local number = tonumber(rightSide)
        local firstCharacter = string.sub(rightSide, 1, 1)
        local numberAfterFirstCharacter = tonumber(string.sub(rightSide, 2))

        if rightSide == "?" then
            debugImpl(buffer, argument, false)
        elseif rightSide == "#?" then
            debugImpl(buffer, argument, true)
        elseif rightSide == "+" then
            sign(buffer, argument)
        elseif firstCharacter == "." and numberAfterFirstCharacter ~= nil then
            precision(buffer, argument, numberAfterFirstCharacter)
        elseif firstCharacter == "0" and numberAfterFirstCharacter ~= nil then
            leadingZeros(buffer, argument, numberAfterFirstCharacter)
        elseif number ~= nil and number > 0 then
            width(buffer, argument, number)
        else
            error("Unsupported format parameter `" .. rightSide .. "`.", 4)
        end
    else
        buffer:writeRaw(tostring(argument))
    end
end

local function composeWriter(arguments)
    local lastArgument = arguments[#arguments]

    return {
        arguments = arguments;
        currentArgument = 0;
        biggestPositionalParameter = 0;
        namedParameters = type(lastArgument) == "table" and lastArgument or nil;
        hadNamedParameter = false;
    }
end

local function writeFmt(buffer, template, ...)
    local index = 1
    local writer = composeWriter({...})

    while index <= #template do
        local brace = string.find(template, "[%{%}]", index)

        -- There are no remaining braces in the string, so we can write the
        -- rest of the string to the buffer.
        if brace == nil then
            buffer:writeRaw(string.sub(template, index))
            break
        end

        local braceCharacter = string.sub(template, brace, brace)
        local characterAfterBrace = string.sub(template, brace + 1, brace + 1)

        if characterAfterBrace == braceCharacter then
            -- This brace starts a literal '{', written as '{{'.

            buffer:writeRaw(braceCharacter)
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
                        buffer:writeRaw(string.sub(template, index, brace - 1))
                    end

                    local formatSpecifier = string.sub(template, brace + 1, closeBrace - 1)

                    interpolate(buffer, formatSpecifier, writer)

                    index = closeBrace + 1
                end
            end
        end
    end

    local numberOfArguments = writer.hadNamedParameter and #writer.arguments - 1 or #writer.arguments

    if writer.currentArgument > numberOfArguments  then
        error(writer.currentArgument .. " " .. pluralize(writer.currentArgument, "parameter") .. " found in template string, but there " .. amountify(numberOfArguments) .. " " .. pluralize(numberOfArguments, "argument") .. ".", 3)
    end

    if numberOfArguments > writer.currentArgument and writer.biggestPositionalParameter < numberOfArguments then
        error(writer.currentArgument .. " " .. pluralize(writer.currentArgument, "parameter") .. " found in template string, but there " .. amountify(numberOfArguments) .. " " .. pluralize(numberOfArguments, "argument") .. ".", 3)
    end
end

return writeFmt