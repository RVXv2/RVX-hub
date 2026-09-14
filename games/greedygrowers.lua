--[[
    RVX-hub: Greedy Growers Module (Hardened Obfuscated Edition)
    ⚠️ Protected with Multi-Layer XOR & Bytecode String Construction
--]]

local _k1 = {0xAF, 0x8C, 0xF9, 0x1B, 0x3E, 0x72, 0xD4, 0x05}
local _k2 = {0x5C, 0xA1, 0x28, 0xFE, 0x90, 0x4B, 0x13, 0x6D}

local _rawPayload = {
    -- [Nested Byte Stream Payload]
    "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",
    "sefpvdjYTB5LYLc5zC08O7i/W2zhavNk0Kul8o+dCGwKMv5thWhvQPHrV2fvR9U4+LOwwNjFUR4fMuJ8zHl0fvaVEirhFZRqsefpvdjYTB5LYLc5zC08O7i/",
    "RmuzUtE+wqKs+djFTFcfJfoTzC08O7i/EirhFZRqsefpvdjYTB5LYLc5jn95evOVEirhFZRqsefpvdjYTB5LYLc5zC15dfyVEirhFZRqsefpvdjYTB5LYPJ3",
    "iAcWO7i/EirhFZRqsefpvdjYTFcNYON4nmp5b8v6V27hQdwv/83pvdjYTB5LYLc5zC08O7i/EirhFdgl8qalvZuZH1ZLfbd+iXlfburtV2S1dtU5+e/gl/LY",
    "TB5LYLc5zC08O7i/EirhFZRqsa6vvZuZH1ZLfqo5mGxufP3rYW+kUZo6466q+NiMBFsFSrc5zC08O7i/EirhFZRqsefpvdjYTB5LYPt2j2xwO/XwRG+lGZQ+",
    "9Kus7ZeKGHwKI/xfgi0hO+z6Xm+xWsY+36Ko76yZHlkONL9tjX97fuzMV2+lG9so+6Kq6dTYGF8ZJ/Jtv2h5f7bvQGWsRcBjm+fpvdjYTB5LYLc5zC08O7i/",
    "EirhFZRqsa6vvZWXGlsPYONxiWMWO7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EnmkQec+8LO87tDajIbMoC+rDLWH+yEb0rJa1QzBcX9+fUFxjIbGerc7",
    "zCMyO+z+QG2kQecv9KPn7p2dCGoSMPIw5i08O7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7jrU3mqG8Mr+LPhyb20KW4kEsNGv0hIT9TabV2AfOBjm+fpvdjY",
    "TB5LYLc5zC08O7i/EirhFZRqsefpvdjyTB5LYLc5zC08O7i/EirhFZRqsefpvdjYTB5LYOd6jWFwM/7qXGm1XNskue7DvdjYTB5LYLc5zC08O7i/EirhFZRq",
    "sefpvdjYTB5LYLd/hX95S+rwSmOsXMAzwbWm8IiMREoKMvB8mF55fvyxQniuWMQ+uM3pvdjYTB5LYLc5zC08O7i/EirhFZRqsefpvdjYCVAPaZ05zC08O7i/",
    "EirhFZRqsefpvdjYTB5LYLc5zC08b/nsWSS2VN0+uZGMz7G+NWE8Ad5NxQcWO7i/EirhFZRqsefpvdjYTB5LYLc5zC08O7i/EmOnFcAv/aK58oqMLl8IK9F3",
    "zHl0fvaVEirhFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZRqsee9+JSdHFEZNNV4j2ZadbC2OCrhFZRqsefpvdjYTB5LYLc5zC08O7i/EirhFZQv/6PDvdjY",
    "TB5LYLc5zC08O7i/EirhFZRqsefp+JacZh5LYLc5zC08O7i/EirhFZRqsefp+JSLCTRLYLc5zC08O7i/EirhFZRqsefpvdjYTB4YJeNKmGxobuu3EOp4tVTy",
    "FidxKRhA9d7SxHehTe2lk3gnrOp5mFTyGidxKhhB5d7T7a05zi0yNbjrU3imUMAZ9KKts4udCVo/Oed8xQc8O7i/EirhFZRqsefpvdjYTB5LYPJ3iAc8O7i/",
    "EirhFZRqsefpvdjYCVIYJZ05zC08O7i/EirhFZRqsefpvdjYTE0ONMRtjXlpaLC90rNF1QzrcX5BfUBmjIbxoC6ZDLW9+yA60rNG1QzecX9efUBNjIfjoC6Z",
    "DLWH+yAr0rJV1Q3OcX9ufUFxThdhYLc5zC08O7i/EirhFZRqsaKn+fLYTB5LYLc5zC08O7j6XG7LP5RqsefpvdjYTB5LYON4n2YybPn2RiKNevsazo6Hyb2q",
    "On8naZ05zC08O7i/Em+vUb5qsefp+JacRTRhYLc5zH1ucvbrGiiacsYv9KOwvb+KA0kOMuREzO2lmXgnmep5kFTyBeed/JrYjIfroC+6DLWp+yA90rJb1Qzp",
    "cX5AfUBVjIbJYr4TiWN4EZLtV360R9pq1rWs+JyBK0wEN/Jrnwc="
}

local _bxor = (bit32 and bit32.bxor) or (bit and bit.bxor) or function(a, b)
    local r, p = 0, 1
    while a > 0 or b > 0 do
        local a2, b2 = a % 2, b % 2
        if a2 ~= b2 then r = r + p end
        a, b, p = (a - a2) / 2, (b - b2) / 2, p * 2
    end
    return r
end

local _b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local _b64m = {}
for i = 1, #_b64c do _b64m[_b64c:sub(i, i)] = i - 1 end

local function _d64(data)
    data = data:gsub("[^" .. _b64c .. "=]", "")
    local out, bits, count = {}, 0, 0
    for i = 1, #data do
        local c = data:sub(i, i)
        if c ~= "=" then
            local v = _b64m[c]
            if v then
                bits = (bits * 64) + v
                count = count + 6
                if count >= 8 then
                    count = count - 8
                    table.insert(out, string.char(math.floor(bits / (2 ^ count)) % 256))
                end
            end
        end
    end
    return table.concat(out)
end

local function _dx(str, k)
    local out = {}
    for i = 1, #str do
        local b = str:byte(i)
        local keyByte = k[((i - 1) % #k) + 1]
        table.insert(out, string.char(_bxor(b, keyByte)))
    end
    return table.concat(out)
end

-- Reconstruct Stream
local _concated = table.concat(_rawPayload, "")
local _stage1 = _d64(_concated)
local _stage2 = _dx(_stage1, _k1)
local _finalSource = _dx(_stage2, _k2)

local _executor, _compileErr = loadstring(_finalSource)
if not _executor then
    error("[Security Module] Decompression Fault: " .. tostring(_compileErr))
end

return _executor()
