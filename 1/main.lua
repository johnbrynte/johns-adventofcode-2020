-- Lucka 1 i adventofcode.com
-- https://adventofcode.com/2020/day/1
AnimatedText = require("AnimatedText")
input = love.filesystem.read("input.txt")

if arg[2] and arg[2] == "2" then
    dofile("1/2.lua")
else
    dofile("1/1.lua")
end
