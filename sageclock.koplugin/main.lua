--[[--
Sage Clock v2 — đồng hồ toàn màn hình cho Kobo Sage (KOReader plugin)

Chỉ hiện GIỜ và PHÚT (HH:MM) bằng CHỮ PIXEL (số vẽ bằng ô vuông 5x7,
tự vẽ trực tiếp, không phụ thuộc font nào của máy).
Cập nhật 2 PHÚT một lần, căn theo mốc phút chẵn (…:00, …:02, …:04…)
để đỡ tốn pin và đỡ hao màn e-ink — đổi lại giờ hiển thị có lúc chậm 1 phút.
Chạm vào màn hình (hoặc vuốt) để thoát.

@module koplugin.SageClock
--]]--

local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local Widget = require("ui/widget/widget")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Screen = Device.screen

----------------------------------------------------------------------
-- Thành ngữ / câu hay về thời gian, hiện dưới đồng hồ.
-- Mỗi nhịp cập nhật (2 phút) tự chuyển sang câu tiếp theo.
----------------------------------------------------------------------

local QUOTES = {
    "Thời gian là vàng bạc.",
    "Việc hôm nay chớ để ngày mai.",
    "Chậm mà chắc.",
    "Có công mài sắt, có ngày nên kim.",
    "Thì giờ thấm thoắt thoi đưa.",
    "Thời gian như bóng câu qua cửa sổ.",
    "Sông có khúc, người có lúc.",
    "Mỗi phút giây là một khởi đầu mới.",
}

local function currentQuote()
    local idx = (math.floor(os.time() / 120) % #QUOTES) + 1
    return QUOTES[idx]
end

----------------------------------------------------------------------
-- Mẫu số pixel 5 cột x 7 hàng ("#" = ô đen)
----------------------------------------------------------------------

local GLYPHS = {
    ["0"] = { ".###.", "#...#", "#..##", "#.#.#", "##..#", "#...#", ".###." },
    ["1"] = { "..#..", ".##..", "..#..", "..#..", "..#..", "..#..", ".###." },
    ["2"] = { ".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####" },
    ["3"] = { "#####", "....#", "..#..", "...#.", "....#", "#...#", ".###." },
    ["4"] = { "...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#." },
    ["5"] = { "#####", "#....", "####.", "....#", "....#", "#...#", ".###." },
    ["6"] = { "..#..", ".#...", "#....", "####.", "#...#", "#...#", ".###." },
    ["7"] = { "#####", "....#", "...#.", "..#..", ".#...", ".#...", ".#..." },
    ["8"] = { ".###.", "#...#", "#...#", ".###.", "#...#", "#...#", ".###." },
    ["9"] = { ".###.", "#...#", "#...#", ".####", "....#", "...#.", ".#..." },
    [":"] = { "..", "..", "##", "..", "..", "##", ".." },
    [" "] = { "...", "...", "...", "...", "...", "...", "..." },
}

local function glyphWidth(ch)
    local g = GLYPHS[ch]
    if not g then return 5 end
    return #g[1]
end

----------------------------------------------------------------------
-- Widget chữ pixel: tự vẽ số bằng các ô vuông
----------------------------------------------------------------------

local PixelText = Widget:extend{
    text = "",
    pixel_w = 40,   -- bề ngang 1 ô pixel
    pixel_h = 40,   -- bề cao 1 ô pixel
}

function PixelText:getSize()
    local cols = 0
    for i = 1, #self.text do
        cols = cols + glyphWidth(self.text:sub(i, i))
        if i < #self.text then cols = cols + 1 end -- 1 cột cách giữa các ký tự
    end
    return Geom:new{
        x = 0, y = 0,
        w = cols * self.pixel_w,
        h = 7 * self.pixel_h,
    }
end

function PixelText:paintTo(bb, x, y)
    local cur_x = x
    for i = 1, #self.text do
        local ch = self.text:sub(i, i)
        local g = GLYPHS[ch] or GLYPHS[" "]
        for row = 1, 7 do
            local line = g[row]
            for col = 1, #line do
                if line:sub(col, col) == "#" then
                    bb:paintRect(
                        cur_x + (col - 1) * self.pixel_w,
                        y + (row - 1) * self.pixel_h,
                        self.pixel_w, self.pixel_h,
                        Blitbuffer.COLOR_BLACK)
                end
            end
        end
        cur_x = cur_x + (glyphWidth(ch) + 1) * self.pixel_w
    end
end

----------------------------------------------------------------------
-- Widget đồng hồ toàn màn hình
----------------------------------------------------------------------

local ClockWidget = InputContainer:extend{
    covers_fullscreen = true,
    stacked = false,
    show_quote = true,
    _last_text = nil,
    _changes = 0,
    _tick_scheduled = false,
}

function ClockWidget:init()
    self.dimen = Geom:new{
        x = 0, y = 0,
        w = Screen:getWidth(),
        h = Screen:getHeight(),
    }
    self.ges_events = {
        TapClose = {
            GestureRange:new{ ges = "tap", range = self.dimen },
        },
        SwipeClose = {
            GestureRange:new{ ges = "swipe", range = self.dimen },
        },
    }
    self.key_events = {
        Close = { { "Back" }, { "Escape" } },
    }
    self:build(os.date("%H:%M"))
    self:scheduleTick()
end

-- Tính cỡ ô pixel: lấp gần kín màn hình theo cả hai chiều
function ClockWidget:pixelSize(stacked, sample)
    local w, h = Screen:getWidth(), Screen:getHeight()
    local cols = 0
    for i = 1, #sample do
        cols = cols + glyphWidth(sample:sub(i, i))
        if i < #sample then cols = cols + 1 end
    end
    local pw = math.floor(w * 0.94 / cols)
    local ph
    if stacked then
        -- 2 dòng: 14 hàng pixel + khoảng cách ~1 hàng;
        -- chừa thêm chỗ cho dòng thành ngữ ở dưới nếu đang bật
        ph = math.floor(h * (self.show_quote and 0.76 or 0.90) / 15)
    else
        -- 1 dòng: cho ô cao tối đa gấp đôi ô ngang cho số trông cao, gọn
        ph = math.min(math.floor(h * 0.55 / 7), pw * 2)
    end
    if ph < 1 then ph = 1 end
    return pw, ph
end

function ClockWidget:build(time_text)
    self._last_text = time_text
    local parts = {}
    if self.stacked then
        local pw, ph = self:pixelSize(true, "00")
        local hh, mm = time_text:match("^(%d%d):(%d%d)$")
        parts[#parts + 1] = PixelText:new{ text = hh or time_text, pixel_w = pw, pixel_h = ph }
        parts[#parts + 1] = VerticalSpan:new{ width = ph }
        parts[#parts + 1] = PixelText:new{ text = mm or "", pixel_w = pw, pixel_h = ph }
    else
        local pw, ph = self:pixelSize(false, "00:00")
        parts[#parts + 1] = PixelText:new{
            text = time_text,
            pixel_w = pw, pixel_h = ph,
        }
    end
    if self.show_quote then
        parts[#parts + 1] = VerticalSpan:new{ width = Screen:scaleBySize(36) }
        parts[#parts + 1] = TextBoxWidget:new{
            text = currentQuote(),
            face = Font:getFace("cfont", Screen:scaleBySize(27)),
            width = math.floor(Screen:getWidth() * 0.86),
            alignment = "center",
        }
    end
    local content = VerticalGroup:new{
        align = "center",
        unpack(parts),
    }
    self[1] = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        margin = 0,
        dimen = self.dimen:copy(),
        CenterContainer:new{
            dimen = self.dimen:copy(),
            content,
        },
    }
end

-- Hẹn giờ tới MỐC 2 PHÚT tiếp theo (phút chẵn) rồi mới vẽ lại.
-- Cộng thêm 1 giây đệm để chắc chắn đồng hồ hệ thống đã sang phút mới.
function ClockWidget:scheduleTick()
    if self._tick_scheduled then return end
    self._tick = function()
        self._tick_scheduled = false
        if self._closed then return end
        local now = os.date("%H:%M")
        if now ~= self._last_text then
            self._changes = self._changes + 1
            self:build(now)
            -- Mỗi 10 lần đổi (20 phút) làm mới toàn phần 1 lần để xóa bóng ma e-ink
            local mode = (self._changes % 10 == 0) and "full" or "ui"
            UIManager:setDirty(self, mode)
        end
        self:scheduleTick()
    end
    local now_s = os.time()
    local delay = 120 - (now_s % 120) + 1
    self._tick_scheduled = true
    UIManager:scheduleIn(delay, self._tick)
end

function ClockWidget:onShow()
    -- Giữ máy thức trong lúc làm đồng hồ (gọi phòng thủ: bản KOReader nào
    -- không có hàm tương ứng thì bỏ qua, không để sập plugin)
    pcall(function() UIManager:preventStandby() end)
    pcall(function() UIManager:stopAutoSuspend() end)
    return true
end

function ClockWidget:onCloseWidget()
    self._closed = true
    if self._tick then
        UIManager:unschedule(self._tick)
        self._tick_scheduled = false
    end
    pcall(function() UIManager:allowStandby() end)
    pcall(function() UIManager:startAutoSuspend() end)
end

function ClockWidget:onTapClose()
    UIManager:close(self)
    return true
end

function ClockWidget:onSwipeClose()
    UIManager:close(self)
    return true
end

function ClockWidget:onClose()
    UIManager:close(self)
    return true
end

----------------------------------------------------------------------
-- Plugin
----------------------------------------------------------------------

local SageClock = WidgetContainer:extend{
    name = "sageclock",
    is_doc_only = false,
}

function SageClock:init()
    if self.ui and self.ui.menu then
        self.ui.menu:registerToMainMenu(self)
    end
    if self.ui and self.ui.dispatcher then
        self:onDispatcherRegisterActions()
    end
end

function SageClock:onDispatcherRegisterActions()
    self.ui.dispatcher:registerAction("sageclock_show", {
        category = "none",
        event = "ShowSageClock",
        title = _("Sage Clock — hiện đồng hồ"),
        general = true,
    })
end

function SageClock:isStacked()
    return G_reader_settings:isTrue("sageclock_stacked")
end

function SageClock:showQuote()
    local v = G_reader_settings:readSetting("sageclock_quote")
    if v == nil then return true end
    return v == true
end

function SageClock:addToMainMenu(menu_items)
    menu_items.sageclock = {
        text = _("Sage Clock — đồng hồ"),
        sorting_hint = "more_tools",
        sub_item_table = {
            {
                text = _("Hiện đồng hồ (chạm để thoát)"),
                callback = function()
                    self:showClock()
                end,
            },
            {
                text = _("Kiểu dọc: giờ trên, phút dưới"),
                checked_func = function()
                    return self:isStacked()
                end,
                callback = function()
                    G_reader_settings:flipNilOrFalse("sageclock_stacked")
                end,
            },
            {
                text = _("Hiện câu thành ngữ dưới đồng hồ"),
                checked_func = function()
                    return self:showQuote()
                end,
                callback = function()
                    G_reader_settings:saveSetting("sageclock_quote", not self:showQuote())
                end,
            },
        },
    }
end

function SageClock:showClock()
    local widget = ClockWidget:new{
        stacked = self:isStacked(),
        show_quote = self:showQuote(),
    }
    UIManager:show(widget, "full")
end

function SageClock:onShowSageClock()
    self:showClock()
    return true
end

return SageClock
