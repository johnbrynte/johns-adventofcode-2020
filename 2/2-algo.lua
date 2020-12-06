valid = 0

for line in io.lines("input.txt") do
    for min, max, char, password in line:gmatch("(%d+)%-(%d+) (%a): (.*)") do
        min = tonumber(min)
        max = tonumber(max)

        valid1 = password:sub(min, min) == char
        valid2 = password:sub(max, max) == char

        if valid1 and not valid2 or not valid1 and valid2 then
            valid = valid + 1
        end
    end
end

print("valid", valid)
