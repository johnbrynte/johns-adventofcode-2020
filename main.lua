day = 1
problem = 1

if arg[2] then
    day = arg[2]
end

if arg[3] then
    problem = arg[3]
end

require(string.format("%d.%d", day, problem))
