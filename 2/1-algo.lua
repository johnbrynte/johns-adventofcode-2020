valid = 0

for line in io.lines("input.txt") do
    for min, max, char, password in line:gmatch("(%d+)%-(%d+) (%a): (.*)") do
        min = tonumber(min)
        max = tonumber(max)

        _, count = password:gsub(char, "")
        if count >= min and count <= max then
            valid = valid + 1
        end
    end
end

print("valid", valid)
