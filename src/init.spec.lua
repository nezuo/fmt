return function()
    local fmt = require(script.Parent)

    it("should throw when format specifier is not closed", function()
        expect(function()
            fmt("{")
        end).to.throw("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
    end)

    it("should throw when close brace has no mathching open brace", function()
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

    it("should throw when there are more arguments than parameters", function()
        expect(function()
            fmt("{}", 1, 2)
        end).to.throw("1 parameter found in template string, but there are 2 arguments.")
    end)

    it("should return an identical string", function()
        expect(fmt("Hello, world!")).to.equal("Hello, world!")
    end)

    it("should replace parameters", function()
        expect(fmt("Hello, {}!", "Micah")).to.equal("Hello, Micah!")
    end)

    it("should format positional parameters", function()
        expect(fmt("{2} {} {1} {}", 1, 2)).to.equal("2 1 1 2")
    end)

    it("should return open brace literal", function()
        expect(fmt("{{")).to.equal("{")
    end)

    it("should return close brace literal", function()
        expect(fmt("}}")).to.equal("}")
    end)

    it("should throw with a negative positional parameter", function()
        expect(function()
            fmt("{-1}", 1)
        end).to.throw("Unsupported format specifier -1")
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
end