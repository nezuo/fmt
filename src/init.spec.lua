return function()
    local fmt = require(script.Parent)

    it("should throw when format specifier is not closed", function()
        expect(function()
            fmt("{")
        end).to.throw("Invalid format string: Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
    end)

    it("should throw when close brace has no mathching open brace", function()
        expect(function()
            fmt("}")
        end).to.throw() -- TODO: Add error
    end)

    it("should return an identical string", function()
        expect(fmt("Hello, world!")).to.equal("Hello, world!")
    end)

    it("should replace parameters", function()
        expect(fmt("Hello, {}!", "Micah")).to.equal("Hello, Micah!")
    end)

    it("should return open brace literal", function()
        expect(fmt("{{")).to.equal("{")
    end)

    it("should return close brace literal", function()
        expect(fmt("}}")).to.equal("}")
    end)
end