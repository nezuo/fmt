local writeFmt = require(script.Parent.writeFmt)

local Formatter = {}
Formatter.__index = Formatter

function Formatter.new()
    local self = setmetatable({}, Formatter)

    self._buffer = {}
    self._startOfLine = true
    self._indentLevel = 0
    self._indentation = ""
    self._isLocked = false
    self._display = ""

    return self
end

function Formatter:asString()
    return self._display
end

function Formatter:asTuple()
    return table.unpack(self._buffer)
end

function Formatter:addTable(tbl)
    table.insert(self._buffer, tbl)
end

function Formatter:lock()
    self._isLocked = true
end

function Formatter:unlock()
    self._isLocked = false
end

function Formatter:addToBuffer(value)
    if self._isLocked == false then
        if type(value) == "string" and type(self._buffer[#self._buffer]) == "string" then
            self._buffer[#self._buffer] ..= value
        else
            table.insert(self._buffer, value)
        end
    end
end

function Formatter:indent()
    self._indentLevel += 1
    self._indentation = string.rep("    ", self._indentLevel)
end

function Formatter:nextLine()
    self:addToBuffer("\n")
    self._display ..= "\n"

    self._startOfLine = true
end

function Formatter:unindent()
    self._indentLevel = math.max(0, self._indentLevel - 1)
    self._indentation = string.rep("    ", self._indentLevel)
end

function Formatter:write(template, ...)
    return writeFmt(self, template, ...)
end

function Formatter:writeLine(template, ...)
    writeFmt(self, template, ...)
    self:nextLine()
end

function Formatter:writeLineRaw(value)
    self:writeRaw(value)
    self:nextLine()
end

function Formatter:writeRaw(value)
    if #value > 0 then
        if self._startOfLine and #self._indentation > 0 then
            self._startOfLine = false

            self:addToBuffer(self._indentation)
            self._display ..= self._indentation
        end

        self._startOfLine = false

        self:addToBuffer(value)
        self._display ..= value
    end
end

return Formatter