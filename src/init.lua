--< Module >--
-- TODO: Positional arguments.
-- TODO: Error when given the wrong number of arguments.

local function fmt(template, ...)
    local buffer = ""
    local currentArg = 0
    local index = 1

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
                    error("Invalid format string: Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
                end

                local formatSpecifier = string.sub(template, openBrace + 1, closeBrace - 1)
                currentArg += 1
                local arg = select(currentArg, ...)

                if formatSpecifier == "" then
                    buffer ..= tostring(arg)
                else
                    error("Unsupported format specifier " .. formatSpecifier, 2) -- TODO: Copy rust error.
                end

                index = closeBrace + 1
            end
        elseif closeBrace ~= nil then
            local charAfterBrace = string.sub(template, closeBrace + 1, closeBrace + 1)

            if charAfterBrace == "}" then
                buffer ..= "}"
                index = closeBrace + 2
            else
                error("Invalid format string: Unmatched '}'. If you intended to write '}', you can escape it using '}}'.")
            end
        else
            buffer ..= string.sub(template, index)

            break
        end
    end

    return buffer
end

return fmt