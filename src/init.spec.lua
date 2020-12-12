local Workspace = game:GetService("Workspace")

return function()
    local Fmt = require(script.Parent)

    it("should throw when format specifier is not closed", function()
        expect(function()
            Fmt.fmt("{")
        end).to.throw("Expected a '}' to close format specifier. If you intended to write '{', you can escape it using '{{'.")
    end)

    it("should throw when close brace has no matching open brace", function()
        expect(function()
            Fmt.fmt("}")
        end).to.throw("Unmatched '}'. If you intended to write '}', you can escape it using '}}'.")
    end)

    it("should throw when there is one parameter and no argument", function()
        expect(function()
            Fmt.fmt("{}")
        end).to.throw("1 parameter found in template string, but there are 0 arguments.")
    end)

    it("should throw when there are more parameters than arguments", function()
        expect(function()
            Fmt.fmt("{}, {}", 1)
        end).to.throw("2 parameters found in template string, but there is 1 argument.")
    end)

    it("should throw when there are more arguments than parameter", function()
        expect(function()
            Fmt.fmt("{}", 1, 2)
        end).to.throw("1 parameter found in template string, but there are 2 arguments.")
    end)

    it("should return an identical string", function()
        expect(Fmt.fmt("Hello, world!")).to.equal("Hello, world!")
    end)

    it("should escape", function()
        expect(Fmt.fmt("{{}}")).to.equal("{}")
    end)

    it("should replace parameter", function()
        expect(Fmt.fmt("Hello, {}!", "Micah")).to.equal("Hello, Micah!")
    end)

    it("should format positional parameter", function()
        expect(Fmt.fmt("{1} {} {0} {}", 1, 2)).to.equal("2 1 1 2")
    end)

    it("should format extra positional parameter", function()
        expect(Fmt.fmt("{} {1}", 1, 2)).to.equal("1 2")
    end)

    it("should throw with extra parameter", function()
        expect(function()
            Fmt.fmt("{} {1} {} {}", 1, 2)
        end).to.throw("3 parameters found in template string, but there are 2 arguments.")
    end)

    it("should return open brace literal", function()
        expect(Fmt.fmt("{{")).to.equal("{")
    end)

    it("should return close brace literal", function()
        expect(Fmt.fmt("}}")).to.equal("}")
    end)

    it("should throw with a negative positional parameter", function()
        expect(function()
            Fmt.fmt("{-1}", 1)
        end).to.throw("Invalid positional parameter `-1`.")

        expect(function()
            Fmt.fmt("{1.5}", 1)
        end).to.throw("Invalid positional parameter `1.5`.")
    end)

    it("should throw with an invalid positional parameter", function()
        expect(function()
            Fmt.fmt("{1}", 1)
        end).to.throw("Invalid positional argument 1 (there is 1 argument).")
    end)

    it("should throw when more arguments than positional parameters are provided", function()
        expect(function()
            Fmt.fmt("{2}", 1, 2)
        end).to.throw("Invalid positional argument 2 (there are 2 arguments).")
    end)

    it("should format named parameter", function()
        expect(Fmt.fmt("Hello, {name}!", {
            name = "Micah";
        })).to.equal("Hello, Micah!")
    end)

    it("should format named and regular parameters", function()
        expect(Fmt.fmt("Hello, {name}! How are {} today, {name}?", "you", {
            name = "Micah";
        })).to.equal("Hello, Micah! How are you today, Micah?")
    end)

    it("should format multiple named parameters", function()
        expect(Fmt.fmt("Hello, {name}! How {word} you doing {other}?", {
            word = "are";
            name = "Micah";
            other = "today";
        })).to.equal("Hello, Micah! How are you doing today?")
    end)

    it("should format named, regular, and positional parameters", function()
        expect(Fmt.fmt("Hello, {name}! How {} you {1}, {name}?", "are", "today", {
            name = "Micah";
        })).to.equal("Hello, Micah! How are you today, Micah?")
    end)

    it("should throw with extra parameters", function()
        expect(function()
            Fmt.fmt("Hello, {name}! How {} you {1}, {name}? {} {}", "are", "today", {
                name = "Micah";
            })
        end).to.throw("3 parameters found in template string, but there are 2 arguments.")
    end)

    it("should throw with extra arguments", function()
        expect(function()
            Fmt.fmt("Hello, {name}! How {} you {1}, {name}? {}", "are", "today", "yes", {
                name = "Micah";
            })
        end).to.throw("2 parameters found in template string, but there are 3 arguments.")
    end)

    it("should use debug form", function()
        expect(Fmt.fmt("{}", "\"")).to.equal("\"")
        expect(Fmt.fmt("{:?}", "\"")).to.equal("\"\\\"\"")

        local folder = Instance.new("Folder")
        folder.Parent = Workspace

        expect((Fmt.fmt("{}", folder))).to.equal("Folder")
        expect((Fmt.fmt("{:?}", folder))).to.equal("Workspace.Folder")
    end)

    it("should throw with invalid enhanced parameter", function()
        expect(function()
            Fmt.fmt("{:!}")
        end).to.throw("Unsupported format parameter `!`.")
    end)

    it("should add spaces to fit minimum width", function()
        expect(Fmt.fmt("{:5}", "x")).to.equal("x    ")
    end)

    it("should not add spaces when greater than minimum width", function()
        expect(Fmt.fmt("{:5}", "hello")).to.equal("hello")
    end)

    it("should handle sign", function()
        expect(Fmt.fmt("{positive} {positive:+} {negative:+} {zero:+} {message:+}", {
            positive = 5;
            negative = -5;
            zero = 0;
            message = "hello";
        })).to.equal("5 +5 -5 +0 hello")
    end)

    it("should handle precision", function()
        expect(Fmt.fmt("{0:.5} {1:.3}", 5, 5.0001)).to.equal("5.00000 5.000")
    end)

    it("should handle leading zeros", function()
        expect(Fmt.fmt("{0:05} {1:02} {1:01}", 5, 42)).to.equal("00005 42 42")
    end)

    it("should handle array", function()
        local array = {1, 2, 3}

        expect(string.find(Fmt.fmt("{}", array), "table: 0x")).to.be.ok()
        expect(Fmt.fmt("{:?}", array)).to.equal("{[1] = 1, [2] = 2, [3] = 3}")
        expect(Fmt.fmt("{:#?}", array)).to.equal("{\n    [1] = 1,\n    [2] = 2,\n    [3] = 3\n}")
    end)

    itSKIP("should handle edge case", function()
        local buffer = table.pack(Fmt.fmt("{} {} {}", "hello", 5, "yes"))

        expect(buffer[1]).to.equal("hello 5 yes")
        expect(buffer[2]).never.to.be.ok()
    end)
end