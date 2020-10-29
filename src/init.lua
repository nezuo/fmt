--< Module >--
-- TODO: Errors
-- TODO: Visitor pattern?
local function fmt(template, ...)
    local buffer = ""
    local numOfParams = 0
    local currentArg = 0
    local index = 1
    local maxPositionalParam = 0
    local args = {...}

    while index <= #template do
        local openBrace = string.find(template, "{", index)
        local closeBrace = string.find(template, "}", index)

        local isOpenBraceFirst = true
        if openBrace ~= nil and closeBrace ~= nil and closeBrace < openBrace then
            isOpenBraceFirst = false
        end

        if openBrace ~= nil and isOpenBraceFirst then
            local charAfterBrace = string.sub(template, openBrace + 1, openBrace + 1)

            if charAfterBrace == "{" then
                buffer ..= "{"
                index = openBrace + 2
            else
                if openBrace - index > 0 then
                    buffer ..= string.sub(template, index, openBrace - 1)
                end

                if closeBrace == nil then
                    error("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
                end

                local formatSpecifier = string.sub(template, openBrace + 1, closeBrace - 1)
                local positionalParam = charAfterBrace ~= "-" and tonumber(formatSpecifier) or nil

                if positionalParam ~= nil then
                    maxPositionalParam = math.max(maxPositionalParam, positionalParam)

                    if positionalParam > #args then
                        local argsPrefix = #args == 1 and "is " or "are "
                        local argsSuffix = #args == 1 and " argument)." or " arguments)."
                        error("Invalid positional argument " .. positionalParam .. " (there " .. argsPrefix .. #args .. argsSuffix)
                    end

                    buffer ..= tostring(args[positionalParam])
                else
                    currentArg += 1
                    numOfParams += 1

                    local arg = args[currentArg]

                    if formatSpecifier == "" then
                        buffer ..= tostring(arg)
                    else
                        error("Unsupported format specifier " .. formatSpecifier, 2) -- TODO: Copy rust error.
                    end
                end

                index = closeBrace + 1
            end
        elseif closeBrace ~= nil then
            local charAfterBrace = string.sub(template, closeBrace + 1, closeBrace + 1)

            if charAfterBrace == "}" then
                buffer ..= "}"
                index = closeBrace + 2
            else
                error("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.")
            end
        else
            buffer ..= string.sub(template, index)

            break
        end
    end

    if maxPositionalParam ~= 0 and maxPositionalParam < #args then
        local argsPrefix = #args == 1 and "is " or "are "
        local argsSuffix = #args == 1 and " argument)." or " arguments)."
        error("Invalid positional argument " .. maxPositionalParam .. " (there " .. argsPrefix .. #args .. argsSuffix)
    end

    if numOfParams ~= #args then
        local paramSuffix = numOfParams == 1 and " parameter " or " parameters "
        local argsPrefix = #args == 1 and "is " or "are "
        local argsSuffix = #args == 1 and " argument." or " arguments."

        error(numOfParams .. paramSuffix .. "found in template string, but there " .. argsPrefix .. #args .. argsSuffix)
    end

    return buffer
end

return fmt