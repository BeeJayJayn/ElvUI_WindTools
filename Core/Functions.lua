local W, F, E, L, V, P, G = unpack(select(2, ...))
local LSM = E.Libs.LSM
local format, pairs, tonumber, type, unpack, print = format, pairs, tonumber, type, unpack, print
local strlen, strfind, strsub, strbyte, tinsert = strlen, strfind, strsub, strbyte, tinsert
local GetClassColor = GetClassColor

--[[
    从数据库设定字体样式
    @param {object} text FontString 型对象
    @param {table} db 字体样式数据库
]]
function F.SetFontWithDB(text, db)
    if not text or not text.GetFont then
        F.DebugMessage("函数", "[1]找不到处理字体风格的字体")
        return
    end
    if not db or type(db) ~= "table" then
        F.DebugMessage("函数", "[1]找不到字体风格数据库")
        return
    end

    text:FontTemplate(LSM:Fetch("font", db.name), db.size, db.style)
end

--[[
    从数据库设定字体颜色
    @param {object} text FontString 型对象
    @param {table} db 字体颜色数据库
]]
function F.SetFontColorWithDB(text, db)
    if not text or not text.GetFont then
        F.DebugMessage("函数", "[2]找不到处理字体风格的字体")
        return
    end
    if not db or type(db) ~= "table" then
        F.DebugMessage("函数", "[1]找不到字体颜色数据库")
        return
    end

    text:SetTextColor(db.r, db.g, db.b, db.a)
end

--[[
    更换字体描边为轮廓
    @param {object} text FontString 型对象
    @param {string} [font] 字型路径
    @param {number|string} [size] 字体尺寸或是尺寸变化量字符串
]]
function F.SetFontOutline(text, font, size)
    if not text or not text.GetFont then
        F.DebugMessage("函数", "[3]找不到处理字体风格的字体")
        return
    end
    local fontName, fontHeight = text:GetFont()

    if size and type(size) == "string" then
        size = fontHeight + tonumber(size)
    end

    text:FontTemplate(font or fontName, size or fontHeight, "OUTLINE")
    text:SetShadowColor(0, 0, 0, 0)
    text.SetShadowColor = E.noop
end

--[[
    从数据库创建彩色字符串
    @param {string} text 文字
    @param {table} db 字体颜色数据库
]]
function F.CreateColorString(text, db)
    if not text or not type(text) == "string" then
        F.DebugMessage("函数", "[4]找不到处理字体风格的字体")
        return
    end
    if not db or type(db) ~= "table" then
        F.DebugMessage("函数", "[2]找不到字体颜色数据库")
        return
    end

    local hex = db.r and db.g and db.b and E:RGBToHex(db.r, db.g, db.b) or "|cffffffff"

    return hex .. text .. "|r"
end

--[[
    创建职业色字符串
    @param {string} text 文字
    @param {string} englishClass 职业名
]]
function F.CreateClassColorString(text, englishClass)
    if not text or not type(text) == "string" then
        F.DebugMessage("函数", "[5]找不到处理字体风格的字体")
        return
    end
    if not englishClass or type(englishClass) ~= "string" then
        F.DebugMessage("函数", "[3]职业错误")
        return
    end

    local r, g, b = GetClassColor(englishClass)
    local hex = r and g and b and E:RGBToHex(r, g, b) or "|cffffffff"

    return hex .. text .. "|r"
end

--[[
    更换窗体内部字体描边为轮廓
    @param {object} frame 窗体
    @param {string} [font] 字型路径
    @param {number|string} [size] 字体尺寸或是尺寸变化量字符串
]]
function F.SetFrameFontOutline(frame, font, size)
    if not frame or not frame.GetRegions then
        F.DebugMessage("函数", "找不到处理字体风格的窗体")
        return
    end
    for _, region in pairs({frame:GetRegions()}) do
        if region:IsObjectType("FontString") then
            F.SetFontOutline(region, font, size)
        end
    end
end

--[[
    输出 Debug 信息
    @param {table/string} module Ace3 模块或自定义字符串
    @param {string} text 错误讯息
]]
function F.DebugMessage(module, text)
    if not text then
        return
    end

    if not module then
        module = "函数"
        text = "无模块名>" .. text
    end
    if type(module) ~= "string" and module.GetName then
        module = module:GetName()
    end
    local message = format("[WT - %s] %s", module, text)
    print(message)
end

--[[
    延迟去除全部模块函数钩子
    @param {table/string} module Ace3 模块或自定义字符串
]]
function F.DelayUnhookAll(module)
    if type(module) == "string" then
        module = W:GetModule(module)
    end

    if module then
        if module.UnhookAll then
            E:Delay(1, module.UnhookAll, module)
        else
            F.DebugMessage(module, "无 AceHook 库函数！")
        end
    else
        F.DebugMessage(nil, "找不到模块！")
    end
end

--[[
    分割 CJK 字符串
    @param {string} delimiter 分割符
    @param {string} subject 待分割字符串
    @return {table/string} 分割结果
]]
function F.SplitCJKString(delimiter, subject)
    if not subject or subject == "" then
        return {}
    end

    local length = strlen(delimiter)
    local results = {}

    local i = 0
    local j = 0

    while true do
        j = strfind(subject, delimiter, i + length)
        if strlen(subject) == i then
            break
        end

        if j == nil then
            tinsert(results, strsub(subject, i))
            break
        end

        tinsert(results, strsub(subject, i, j - 1))
        i = j + length
    end

    return unpack(results)
end

--[[
    返回当前字符实际占用的字符数
    https://blog.csdn.net/fenrir_sun/article/details/52232723
    @param {string} str 字符串
    @param {number} index 字符下标
    @return {number} 数量
]]
function F.SubStringGetByteCount(str, index)
    local curByte = strbyte(str, index)
    local byteCount = 1
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte >= 192 and curByte <= 223 then
        byteCount = 2
    elseif curByte >= 224 and curByte <= 239 then
        byteCount = 3
    elseif curByte >= 240 and curByte <= 247 then
        byteCount = 4
    end
    return byteCount
end

--[[
    获取中英混合字符串的真实字符下标
    https://blog.csdn.net/fenrir_sun/article/details/52232723
    @param {string} str 字符串
    @param {number} index 下标
    @return {number} 数量
]]
function F.SubStringGetTrueIndex(str, index)
    local curIndex = 0
    local i = 1
    local lastCount = 1
    repeat
        lastCount = F.SubStringGetByteCount(str, i)
        i = i + lastCount
        curIndex = curIndex + 1
    until (curIndex >= index)
    return i - lastCount
end

--[[
    获取中英混合字符串的真实字符数量
    https://blog.csdn.net/fenrir_sun/article/details/52232723
    @param {string} str 字符串
    @return {number} 数量
]]
function F.SubStringGetTotalIndex(str)
    local curIndex = 0
    local i = 1
    local lastCount = 1
    repeat
        lastCount = F.SubStringGetByteCount(str, i)
        i = i + lastCount
        curIndex = curIndex + 1
    until (lastCount == 0)
    return curIndex - 1
end

--[[
    截取中英混合字符串
    https://blog.csdn.net/fenrir_sun/article/details/52232723
    @param {string} str 字符串
    @param {number} startIndex 起始下标
    @param {number/nil} endIndex 终止下标
    @return {string} 截取结果
]]
function F.SubCJKString(str, startIndex, endIndex)
    if startIndex < 0 then
        startIndex = F.SubStringGetTotalIndex(str) + startIndex + 1
    end

    if endIndex ~= nil and endIndex < 0 then
        endIndex = F.SubStringGetTotalIndex(str) + endIndex + 1
    end

    if endIndex == nil then
        return strsub(str, F.SubStringGetTrueIndex(str, startIndex))
    else
        return strsub(str, F.SubStringGetTrueIndex(str, startIndex), F.SubStringGetTrueIndex(str, endIndex + 1) - 1)
    end
end
