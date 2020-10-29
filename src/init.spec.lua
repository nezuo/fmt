return function()
    local fmt = require(script.Parent)

    it("should return an identical string", function()
        expect(fmt("Hello, world!")).to.equal("Hello, world!")
    end)
end