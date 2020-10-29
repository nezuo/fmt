--< Module >--
local function writeToBuffer(buffer, value)
    buffer ..= value
end

local function fmt(template, ...)
    local buffer = {}
    local currentArg = 0
    local index = 1
    
    while index <= #template do
        local openBrace = string.find(template, "{", index)

        if openBrace == nil then
            writeToBuffer(buffer, string.sub(template, index))
            break
        else
            local charAfterBrace = string.sub(template, openBrace + 1, openBrace + 1)

            if charAfterBrace == "{" then
                writeToBuffer(buffer, string.sub(template, index, openBrace))
                index = openBrace + 2
            else
                if openBrace - index > 0 then
                    writeToBuffer(buffer, string.sub(template, index, openBrace - 1))
                end

                local closeBrace = string.find(template, "}", openBrace + 1)
                assert(closeBrace ~= nil, "Unclosed formatting specifier. Use '{{' to write an open brace.") -- TODO: Copy rust error.

                local formatSpecifier = string.sub(template, openBrace + 1, closeBrace - 1)
                currentArg += 1
                local arg = select(currentArg, ...)

                if formatSpecifier == "" then
                    writeToBuffer(buffer, tostring(arg))
                elseif formatSpecifier == ":?" then
                    -- Debug
                elseif formatSpecifier == ":#?" then
                    -- Debug, expanded
                else
                    error("Unsupported format specifier " .. formatSpecifier, 2) -- TODO: Copy rust error.
                end

                index = closeBrace + 1
            end
        end
    end

    return table.concat(buffer, "")
end

return fmt