-- TODO: Errors

--< Classes >--
local Formatter = {}
Formatter.__index = Formatter

function Formatter.new()
    local self = setmetatable({}, Formatter)
    
    self.buffer = {}

    return self
end

function Formatter:write(value)
    table.insert(self.buffer, value)
end

function Formatter:formatCloseBrace(charAfterBrace)
    if charAfterBrace ~= "}" then
        error("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.")
    end
end

function Formatter:formatOpenBrace(charAfterBrace)
    local closeBrace = string.find(self.template, "}", self.brace + 1)

    if self.brace - self.index > 0 then
        self:write(string.sub(self.template, self.index, self.brace - 1))
    end

    if closeBrace == nil then
        error("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
    end

    local formatSpecifier = string.sub(self.template, self.brace + 1, closeBrace - 1)
    local positionalParam = charAfterBrace ~= "-" and tonumber(formatSpecifier) or nil

    if positionalParam ~= nil then
        self.biggestPositionalParam = math.max(self.biggestPositionalParam, positionalParam)

        if positionalParam > #self.args then
            local argsPrefix = #self.args == 1 and "is " or "are "
            local argsSuffix = #self.args == 1 and " argument)." or " arguments)."
            error("Invalid positional argument " .. positionalParam .. " (there " .. argsPrefix .. #self.args .. argsSuffix)
        end

        self:write(tostring(self.args[positionalParam]))
    else
        self.currentArg += 1
        self.numOfParams += 1

        local arg = self.args[self.currentArg]

        if formatSpecifier == "" then
            self:write(tostring(arg))
        else
            error("Unsupported format specifier " .. formatSpecifier, 2) -- TODO: Copy rust error.
        end
    end

    self.index = closeBrace + 1
end

function Formatter:writeFmt(template, ...)
    self.args = {...}
    self.biggestPositionalParam = 0
    self.currentArg = 0
    self.index = 1
    self.numOfParams = 0
    self.template = template
    
    while self.index <= #template do
        self.brace = string.find(template, "[%{%}]", self.index)

        if self.brace then
            local braceType = string.sub(template, self.brace, self.brace)
            local charAfterBrace = string.sub(template, self.brace + 1, self.brace + 1)

            -- Format brace literals.
            if charAfterBrace == braceType then
                self:write(braceType)
                self.index = self.brace + 2
    
                continue
            end
    
            if braceType == "{" then
                self:formatOpenBrace(charAfterBrace)
            elseif braceType == "}" then
                self:formatCloseBrace(charAfterBrace)
            end
        else
            self:write(string.sub(template, self.index))

            break
        end
    end

    -- TODO: Cleanup suffix and prefix garbage.

    if self.biggestPositionalParam ~= 0 and self.biggestPositionalParam < #self.args then
        local argsPrefix = #self.args == 1 and "is " or "are "
        local argsSuffix = #self.args == 1 and " argument)." or " arguments)."
        error("Invalid positional argument " .. self.biggestPositionalParam .. " (there " .. argsPrefix .. #self.args .. argsSuffix)
    end

    if self.numOfParams ~= #self.args then
        local paramSuffix = self.numOfParams == 1 and " parameter " or " parameters "
        local argsPrefix = #self.args == 1 and "is " or "are "
        local argsSuffix = #self.args == 1 and " argument." or " arguments."

        error(self.numOfParams .. paramSuffix .. "found in template string, but there " .. argsPrefix .. #self.args .. argsSuffix)
    end
end

function Formatter:finish()
    return table.concat(self.buffer, "")
end

--< Module >--
local function fmt(template, ...)
    local formatter = Formatter.new()
    
    formatter:writeFmt(template, ...)

    return formatter:finish()
end

return fmt