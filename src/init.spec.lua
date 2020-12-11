local Workspace = game:GetService("Workspace")

return function()
    local fmt = require(script.Parent)

    local function bufferToString(buffer)
        return table.concat(buffer, "")
    end

    it("should throw when format specifier is not closed", function()
        expect(function()
            fmt("{")
        end).to.throw("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
    end)

    it("should throw when close brace has no matching open brace", function()
        expect(function()
            fmt("}")
        end).to.throw("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.")
    end)

    it("should throw when there is one parameter and no argument", function()
        expect(function()
            fmt("{}")
        end).to.throw("1 parameter found in template string, but there are 0 arguments.")
    end)

    it("should throw when there are more parameters than arguments", function()
        expect(function()
            fmt("{}, {}", 1)
        end).to.throw("2 parameters found in template string, but there is 1 argument.")
    end)

    it("should throw when there are more arguments than parameter", function()
        expect(function()
            fmt("{}", 1, 2)
        end).to.throw("1 parameter found in template string, but there are 2 arguments.")
    end)

    it("should return an identical string", function()
        expect(bufferToString(fmt("Hello, world!"))).to.equal("Hello, world!")
    end)

    it("should replace parameter", function()
        expect(bufferToString(fmt("Hello, {}!", "Micah"))).to.equal("Hello, Micah!")
    end)

    it("should format positional parameter", function()
        expect(bufferToString(fmt("{2} {} {1} {}", 1, 2))).to.equal("2 1 1 2")
    end)

    it("should format extra positional parameter", function()
        expect(bufferToString(fmt("{} {2}", 1, 2))).to.equal("1 2")
    end)

    it("should throw with extra parameter", function()
        expect(function()
            fmt("{} {2} {} {}", 1, 2)
        end).to.throw("3 parameters found in template string, but there are 2 arguments.")
    end)

    it("should return open brace literal", function()
        expect(bufferToString(fmt("{{"))).to.equal("{")
    end)

    it("should return close brace literal", function()
        expect(bufferToString(fmt("}}"))).to.equal("}")
    end)

    it("should throw with a negative positional parameter", function()
        expect(function()
            fmt("{-1}", 1)
        end).to.throw("Unsupported format specifier `-1`")
    end)

    it("should throw with an invalid positional parameter", function()
        expect(function()
            fmt("{2}", 1)
        end).to.throw("Invalid positional argument 2 (there is 1 argument).")
    end)

    it("should throw when more arguments than positional parameters are provided", function()
        expect(function()
            fmt("{3}", 1, 2)
        end).to.throw("Invalid positional argument 3 (there are 2 arguments).")
    end)

    it("should format named parameter", function()
        expect(bufferToString(fmt("Hello, {name}!", {
            name = "Micah";
        }))).to.equal("Hello, Micah!")
    end)

    it("should format named and regular parameters", function()
        expect(bufferToString(fmt("Hello, {name}! How are {} today, {name}?", "you", {
            name = "Micah";
        }))).to.equal("Hello, Micah! How are you today, Micah?")
    end)

    it("should format multiple named parameters", function()
        expect(bufferToString(fmt("Hello, {name}! How {word} you doing {other}?", {
            word = "are";
            name = "Micah";
            other = "today";
        }))).to.equal("Hello, Micah! How are you doing today?")
    end)

    it("should format named, regular, and positional parameters", function()
        expect(bufferToString(fmt("Hello, {name}! How {} you {2}, {name}?", "are", "today", {
            name = "Micah";
        }))).to.equal("Hello, Micah! How are you today, Micah?")
    end)

    it("should throw with extra parameters", function()
        expect(function()
            fmt("Hello, {name}! How {} you {2}, {name}? {} {}", "are", "today", {
                name = "Micah";
            })
        end).to.throw("3 parameters found in template string, but there are 2 arguments.")
    end)

    it("should throw with extra arguments", function()
        expect(function()
            fmt("Hello, {name}! How {} you {2}, {name}? {}", "are", "today", "yes", {
                name = "Micah";
            })
        end).to.throw("2 parameters found in template string, but there are 3 arguments.")
    end)

    it("should use debug form", function()
        expect(bufferToString(fmt("{}", "\""))).to.equal("\"")
        expect(bufferToString(fmt("{:?}", "\""))).to.equal("\"\\\"\"")

        local folder = Instance.new("Folder")
        folder.Parent = Workspace

        expect(fmt("{}", folder)[1]).to.equal("Folder")
        expect(fmt("{:?}", folder)[1]).to.equal("Workspace.Folder")
    end)

    it("should throw with invalid enhanced parameter", function()
        expect(function()
            fmt("{:!}")
        end).to.throw("Unsupported format specifier `!`.")
    end)
end