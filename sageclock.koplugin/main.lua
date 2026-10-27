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
local ffiutil = require("ffi/util")
local InfoMessage = require("ui/widget/infomessage")
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
    "Thì giờ là vàng ngọc.",
    "Mưa dầm thấm lâu.",
    "Kiến tha lâu cũng đầy tổ.",
    "Giờ nào việc nấy.",
    "Thời giờ không chờ một ai.",
    "Một tấc thời gian, một tấc vàng.",
    "Thời gian như nước qua cầu.",
    "Trăng đến rằm trăng tròn.",
    "Đêm dài lắm mộng.",
    "Ngày rộng tháng dài.",
    "Ba mươi chưa phải là Tết.",
    "Thời gian chữa lành mọi vết thương.",
    "Góp gió thành bão.",
    "Tích tiểu thành đại.",
    "Đi một ngày đàng, học một sàng khôn.",
    "Có chí thì nên.",
    "Thất bại là mẹ thành công.",
    "Ngày mai bắt đầu từ hôm nay.",
    "Mỗi ngày là một trang sách mới.",
    "Đêm tháng năm chưa nằm đã sáng.",
    "Ngày tháng mười chưa cười đã tối.",
    "Quá khứ đã qua, tương lai chưa tới.",
    "Đừng để hôm qua chiếm hết hôm nay.",
    "Nước chảy đá mòn.",
    "Trăm hay không bằng tay quen.",
    "Một ngày nên nghĩa, chuyến đò nên quen.",
    "Thời gian trôi, lòng người ở lại.",
    "Sớm một bước, hơn một đời chờ.",
    "Chớ thấy sóng cả mà ngã tay chèo.",
    "Đời người được mấy mươi xuân.",
    "Tuổi trẻ qua đi không trở lại.",
    "Thời gian là thầy thuốc giỏi nhất.",
    "Time is money. — Benjamin Franklin",
    "Lost time is never found again. — Franklin",
    "Time waits for no one.",
    "Better late than never.",
    "A stitch in time saves nine.",
    "Make hay while the sun shines.",
    "Time and tide wait for no man.",
    "Rome wasn't built in a day.",
    "Slow and steady wins the race. — Aesop",
    "The early bird catches the worm.",
    "Don't count the days, make the days count. — Ali",
    "Carpe diem. — Horace",
    "Tempus fugit.",
    "This too shall pass.",
    "Time heals all wounds.",
    "Strike while the iron is hot.",
    "Procrastination is the thief of time. — Young",
    "Your time is limited, so don't waste it. — Jobs",
    "The future depends on what you do today. — Gandhi",
    "Either you run the day or the day runs you. — Rohn",
    "Every moment is a fresh beginning. — Eliot",
    "An inch of time is an inch of gold.",
    "Patience is a virtue.",
    "Good things come to those who wait.",
    "There's no time like the present.",
    "Time is the wisest counselor of all. — Pericles",
    "We must use time as a tool, not as a couch. — JFK",
    "A year from now you may wish you had started today.",
    "No man steps in the same river twice. — Heraclitus",
    "How we spend our days is how we spend our lives. — Dillard",
    "The time is always right to do what is right. — King",
    "Dost thou love life? Then do not squander time. — Franklin",
    "Better three hours too soon than a minute too late.",
    "All in good time.",
    "Patience is bitter, but its fruit is sweet. — Rousseau",
    "Time flies over us, but leaves its shadow behind.",
    "Now is the only moment we really have.",
    "Time enjoyed is never wasted.",
    "One day at a time.",
    "Make each day your masterpiece. — Wooden",    "Công cha như núi Thái Sơn / Nghĩa mẹ như nước trong nguồn chảy ra.",
    "Uống nước nhớ nguồn.",
    "Ăn quả nhớ kẻ trồng cây.",
    "Con có cha như nhà có nóc / Con không cha như nòng nọc đứt đuôi.",
    "Anh em như thể tay chân / Rách lành đùm bọc, dở hay đỡ đần.",
    "Thuận vợ thuận chồng tát bể Đông cũng cạn.",
    "Chim có tổ, người có tông / Như cây có cội, như sông có nguồn.",
    "Một giọt máu đào hơn ao nước lã.",
    "Giấy rách phải giữ lấy lề.",
    "Đói cho sạch, rách cho thơm.",
    "Ngọc kia chuốt mãi cũng tròn / Sắt kia mài mãi cũng còn nên kim.",
    "Không thầy đố mày làm nên.",
    "Học thầy không tày học bạn.",
    "Vạn sự khởi đầu nan.",
    "Lửa thử vàng, gian nan thử sức.",
    "Thua keo này ta bày keo khác.",
    "Có cày có cấy mới thấy có hạt xôi.",
    "Muốn biết phải hỏi, muốn giỏi phải học.",
    "Học ăn, học nói, học gói, học mở.",
    "Dốt đến đâu học lâu cũng biết.",
    "Lời nói chẳng mất tiền mua / Lựa lời mà nói cho vừa lòng nhau.",
    "Lời chào cao hơn mâm cỗ.",
    "Một câu nhịn, chín câu lành.",
    "Cười người chớ vội cười lâu / Cười người hôm trước hôm sau người cười.",
    "Kim vàng ai nỡ uốn câu / Người khôn ai nỡ nói nhau nặng lời.",
    "Chim khôn kêu tiếng rảnh rang / Người khôn nói tiếng dịu dàng dễ nghe.",
    "Đánh kẻ chạy đi, không ai đánh người chạy lại.",
    "Ở hiền gặp lành.",
    "Gieo gió gặt bão.",
    "Tiên trách kỷ, hậu trách nhân.",
    "Bán anh em xa, mua láng giềng gần.",
    "Lá lành đùm lá rách.",
    "Thương người như thể thương thân.",
    "Một con ngựa đau, cả tàu bỏ cỏ.",
    "Bầu ơi thương lấy bí cùng / Tuy rằng khác giống nhưng chung một giàn.",
    "Gần mực thì đen, gần đèn thì rạng.",
    "Chọn bạn mà chơi, chọn nơi mà ở.",
    "Trông mặt mà bắt hình dong.",
    "Tốt gỗ hơn tốt nước sơn.",
    "Cái nết đánh chết cái đẹp.",
    "Thau lẫn với vàng, chì pha với bạc.",
    "Biết người biết mặt, khó biết lòng.",
    "Sông sâu biển thẳm dễ dò / Nào ai lấy thước mà đo lòng người.",
    "Thùng rỗng kêu to.",
    "Đa sầu đa cảm thì đa đoan.",
    "Thời gian là vàng là bạc.",
    "Đời người sống mấy gang tay / Hơi đâu mà giận, hơi đâu mà phiền.",
    "Của bền tại người.",
    "Khéo ăn thì no, khéo co thì ấm.",
    "Ăn bữa nay lo bữa mai.",
    "Buôn tàu bán bè không bằng ăn dè hà tiện.",
    "Miếng ăn là miếng tồi tàn / Mất ăn một miếng lộn gan lên đầu.",
    "Đừng thấy hoa nở mà ngỡ xuân về.",
    "Chưa đỗ ông nghè đã đe hàng tổng.",
    "Vỏ quýt dày có móng tay nhọn.",
    "Mèo nhỏ bắt chuột con.",
    "Tránh vỏ dưa, gặp vỏ dừa.",
    "Thả con săn sắt, bắt con cá rô.",
    "Nuôi ong tay áo, nuôi cáo trong nhà.",
    "Giấu đầu hở đuôi.",
    "Cháy nhà mới ra mặt chuột.",
    "Mất bò mới lo làm chuồng.",
    "Nước đến chân mới nhảy.",
    "Rút dây động rừng.",
    "Sai một ly, đi một dặm.",
    "Một tấc đất, một tấc vàng.",
    "Tay làm hàm nhai, tay quai miệng trễ.",
    "Trâu chậm uống nước đục.",
    "Nhập gia tùy tục.",
    "Áo mặc sao qua khỏi đầu.",
    "Cây ngay không sợ chết đứng.",
    "Tre già măng mọc.",
    "Mật ngọt chết ruồi.",
    "Lòng lang dạ thú.",
    "Ta về ta tắm ao ta / Dù trong dù đục ao nhà vẫn hơn.",
    "Quê hương là chùm khế ngọt.",
    "Chuồn chuồn bay thấp thì mưa / Bay cao thì nắng, bay vừa thì râm.",
    "Đêm tháng năm chưa nằm đã sáng / Ngày tháng mười chưa cười đã tối.",
    "Cơn đằng Đông vừa trông vừa chạy / Cơn đằng Nam vừa làm vừa chơi.",
    "Mau sao thì nắng, vắng sao thì mưa.",
    "Mống dài trời lụt, mống cụt trời mưa.",
    "Nhất nước, nhì phân, tam cần, tứ giống.",
    "Trăng mờ còn tỏ hơn sao / Dẫu rằng núi lở còn cao hơn đồi.",
    "Ruộng sâu trâu nái không bằng con gái đầu lòng.",
    "Nhất thì nhì thục.",
    "Tấc đất tấc vàng.",
    "Khoai đất lạ, mạ đất quen.",
    "Cày sâu cuốc bẫm.",
    "Được mùa cau, đau mùa lúa.",
    "Sớm nhặt gai, chiều quét rác.",
    "Chớp đông nhay nháy, gà gáy thì mưa.",
    "Én bay thấp mưa ngập bờ ao / Én bay cao mưa rào lại tạnh.",
    "Gió heo may, chuồn chuồn bay thì bão.",
    "Đất lành chim đậu.",
    "Muốn đi nhanh hãy đi một mình, muốn đi xa hãy đi cùng nhau. (Ngạn ngữ Châu Phi)",
    "Khi ván cờ kết thúc, cả Vua lẫn Tốt đều phải quay về cùng một chiếc hộp. (Ngạn ngữ Ý)",
    "Ngã bảy lần, đứng dậy tám lần. (Tục ngữ Nhật Bản)",
    "Thời điểm tốt nhất để trồng cây là 20 năm trước. Thời điểm tốt thứ hai là ngay bây giờ. (Ngạn ngữ Trung Quốc)",
    "Chiếc rìu thì mau quên, nhưng cái cây bị chém thì nhớ mãi. (Ngạn ngữ Đức / Châu Phi)",
    "Thành Rome không thể xây xong trong một ngày. (Tục ngữ La Tinh)",
    "Đừng phán xét cuốn sách chỉ qua bìa ngoài của nó. (Tục ngữ Anh)",
    "Gốc rễ của học tập thì cay đắng, nhưng quả ngọt của nó thì lâu dài. (Ngạn ngữ Hy Lạp)",
    "Nỗi buồn chia sẻ là nửa nỗi buồn; niềm vui chia sẻ là nhân đôi niềm vui. (Ngạn ngữ Thụy Điển)",
    "Nếu vấn đề giải quyết được thì sao phải lo? Nếu vấn đề không giải quyết được thì lo có ích gì? (Ngạn ngữ Tây Tạng)",
    "Hãy nói cho tôi biết bạn của anh là ai, tôi sẽ nói cho anh biết anh là người thế nào. (Tục ngữ Tây Ban Nha)",
    "Lặp lại là mẹ đẻ của tri thức. (Tục ngữ Nga)",
    "Nghi ngờ là chiếc chìa khóa mở ra cánh cửa chân lý. (Ngạn ngữ Ba Tư)",
    "Một khu rừng bạt ngàn bắt đầu từ một hạt mầm bé nhỏ. (Ngạn ngữ Ả Rập)",
    "Không có tin tức tức là tin tốt lành. (Tục ngữ Pháp)",
    "Kẻ cười sau cùng là kẻ cười vui nhất. (Tục ngữ Pháp)",
    "Một con chim én không làm nên mùa xuân. (Ngạn ngữ Hy Lạp)",
    "Người không bao giờ mắc sai lầm là người chẳng bao giờ dám làm gì. (Tục ngữ Anh)",
    "Đừng đếm gà con trước khi trứng nở. (Tục ngữ Anh)",
    "Khi gió bão thổi tới, kẻ yếu dựng tường chắn, người thông thái xây cối xay gió. (Ngạn ngữ Hà Lan)",
    "Lời nói tử tế sưởi ấm được ba tháng đông buốt giá. (Ngạn ngữ Nhật Bản)",
    "Hành trình vạn dặm khởi đầu từ một bước chân. (Lão Tử - Ngạn ngữ Trung Hoa)",
    "Đừng bao giờ thử độ sâu của dòng sông bằng cả hai chân. (Ngạn ngữ Châu Phi)",
    "Người khôn ngoan học từ sai lầm của người khác; kẻ khờ chỉ học từ sai lầm của mình. (Tục ngữ La Tinh)",
    "Đôi mắt là cửa sổ của tâm hồn. (Tục ngữ Pháp)",
    "Đừng bỏ hết trứng vào chung một rổ. (Tục ngữ Anh)",
    "Lời nói là bạc, giữ im lặng đúng lúc là vàng. (Ngạn ngữ Thụy Sĩ)",
    "Cho ai một con cá là nuôi họ một ngày; dạy họ cách câu cá là nuôi họ cả đời. (Ngạn ngữ Trung Quốc)",
    "Muốn biết giá trị của đồng tiền, hãy thử đi vay mượn người khác. (Ngạn ngữ Mỹ)",
    "Một bức tranh lột tả hơn vạn lời nói. (Tục ngữ Anh)",
    "Chậm chạp mà kiên định sẽ chiến thắng đường đua. (Tục ngữ Hy Lạp)",
    "Lòng biết ơn là ký ức đẹp đẽ của trái tim. (Ngạn ngữ Pháp)",
    "Khi người trí tuệ chỉ tay lên mặt trăng, kẻ ngu muội chỉ nhìn vào ngón tay. (Ngạn ngữ phương Đông)",
    "Không có ngọn lửa nào bốc lên mà không có khói. (Tục ngữ Anh)",
    "Người chịu đựng giỏi nhất sẽ là người chiến thắng vẻ vang nhất. (Ngạn ngữ Scotland)",
    "Trái tim thanh thản là thần dược dưỡng sinh tốt nhất. (Ngạn ngữ Do Thái)",
    "Tiền tài là người đầy tớ trung thành nhưng là ông chủ tàn bạo. (Ngạn ngữ Pháp)",
    "Đừng đốn hạ bóng cây mát che chở cho bạn ngày nắng. (Ngạn ngữ Ả Rập)",
    "Sóng to gió lớn tạo nên những thủy thủ dũng cảm và tài ba. (Tục ngữ Anh)",
    "Không ai đủ giàu để mua lại ngày hôm qua. (Ngạn ngữ Đức)",
    "Con chim thức dậy sớm sẽ bắt được nhiều sâu. (Tục ngữ Anh)",
    "Hãy đo đạc hai lần trước khi đặt nhát cắt đầu tiên. (Tục ngữ Nga)",
    "Nụ cười là khoảng cách ngắn nhất kết nối hai con người. (Ngạn ngữ Đan Mạch)",
    "Người muốn dời ngọn núi lớn phải bắt đầu bằng những hòn đá nhỏ. (Ngạn ngữ Trung Quốc)",
    "Ánh sáng ngọn nến không hề vơi đi khi nó thắp sáng cho ngọn nến khác. (Ngạn ngữ Đan Mạch)",
    "Kẻ sợ đau khổ thì cả đời luôn sống trong sự giày vò của sợ hãi. (Ngạn ngữ Pháp)",
    "Cuộc đời là tấm gương soi: bạn mỉm cười nó sẽ cười lại với bạn. (Ngạn ngữ Anh)",
    "Chân lý giống như vệt dầu loang, luôn nổi lên trên mặt nước dối trá. (Ngạn ngữ Ả Rập)",
    "Mọi con đường rồi cũng sẽ dẫn tới thành Rome. (Tục ngữ La Tinh)",
    "Kẻ biết điểm dừng và biết đủ chính là người giàu sang nhất. (Ngạn ngữ Hy Lạp)",
    "Đừng ném đá vào nhà người khác nếu nhà bạn lợp bằng kính. (Tục ngữ Anh)",
    "Khi một cánh cửa hy vọng khép lại, cánh cửa cơ hội khác sẽ mở ra. (Tục ngữ Tây Ban Nha)",
    "Bông lúa càng trĩu hạt càng cúi đầu khiêm nhường. (Tục ngữ Nhật Bản)",
    "Con người hiếm khi vấp ngã bởi núi cao, họ ngã vì những viên sỏi nhỏ dưới chân. (Ngạn ngữ Trung Quốc)",
    "Kẻ lười biếng luôn miệng hẹn để ngày mai. (Tục ngữ Nga)",
    "Đừng thiêu rụi cây cầu mà mai này bạn có thể phải bước qua lại. (Tục ngữ Anh)",
    "Thà thắp sáng một que diêm nhỏ còn hơn ngồi than trách bóng tối mịt mù. (Ngạn ngữ phương Đông)",
    "Đuổi theo hai con thỏ cùng lúc sẽ không bắt được con nào. (Tục ngữ Nga)",
    "Mũi tên đã bắn đi và lời nói đã thốt ra vĩnh viễn không thể thu hồi. (Ngạn ngữ Thổ Nhĩ Kỳ)",
    "Bàn tay mang hoa hồng trao tặng người khác sẽ luôn lưu lại hương thơm. (Ngạn ngữ Trung Quốc)",
    "Hãy cẩn thận trước người cả đời chỉ đọc đúng một cuốn sách. (Tục ngữ La Tinh)",
    "Giọt nước chảy đều đặn qua ngày tháng sẽ làm đầy vò nước lớn. (Ngạn ngữ Ấn Độ)",
    "Đừng cố dìm người khác xuống bùn lầy chỉ để bản thân trông cao ráo hơn. (Ngạn ngữ Thụy Điển)",
    "Người đi tìm một người bạn hoàn hảo sẽ cô đơn trọn cả kiếp người. (Ngạn ngữ Thổ Nhĩ Kỳ)",
    "Người thầy tốt mở toang cánh cửa tri thức chứ không kéo giật bạn bước vào. (Ngạn ngữ Trung Quốc)",
    "Mọi thứ lấp lánh ánh kim chưa chắc đã là vàng ròng. (Tục ngữ Anh)",
    "Kẻ kiêu căng đứng trên đỉnh núi thấy ai cũng nhỏ, mà không biết ai nhìn hắn cũng bé xíu. (Ngạn ngữ Ba Tư)",
    "Già đi là quy luật tự nhiên của thời gian; trưởng thành là do bản thân lựa chọn. (Ngạn ngữ Mỹ)",
    "Kẻ dối trá phải rèn luyện cho mình một trí nhớ siêu phàm. (Tục ngữ La Tinh)",
    "Đòn roi tạo vết thương ngoài da mau lành, lời độc địa cứa sâu trong dạ suốt đời. (Ngạn ngữ Ba Tư)",
    "Đừng cắn lấy bàn tay đang mở ra cứu giúp và nuôi dưỡng bạn. (Tục ngữ Anh)",
    "Một nửa sự thật khéo giấu thường là lời nói dối nguy hiểm nhất. (Ngạn ngữ Do Thái)",
    "Ngựa tốt không bao giờ cúi đầu ăn cỏ bẩn sau lưng. (Ngạn ngữ Trung Quốc)",
    "Mái nhà ấm áp chính là nơi trái tim bạn cảm thấy an yên nhất. (Tục ngữ Anh)",
    "Tiền kiếm bằng giọt mồ hôi thì giữ được, tiền từ trên trời rơi xuống thì bốc hơi nhanh. (Ngạn ngữ Ba Lan)",
    "Cây sồi cứng nhắc bị giông bão quật ngã, cây lau sậy uốn mình mềm dẻo thì sống sót. (Ngụ ngôn Aesop)",
    "Ai không biết tôn trọng đồng xu nhỏ sẽ không bao giờ giữ nổi gia tài lớn. (Ngạn ngữ Đức)",
    "Sự trả thù ngọt ngào nhất chính là tự biến mình thành người thành công rực rỡ. (Ngạn ngữ Mỹ)",
    "Bắt chước người khác một cách mù quáng là đánh mất hoàn toàn bản thân. (Ngạn ngữ Nhật Bản)",
    "Kẻ muốn hái hoa hồng thì phải chấp nhận bàn tay bị gai cào xước. (Ngạn ngữ Anh)",
    "Bí mật được tiết lộ cho ba người thì cả thiên hạ đều biết. (Ngạn ngữ Pháp)",
    "Nhìn lên trên thấy mình chưa bằng ai, nhìn xuống dưới thấy khối người chẳng bằng mình. (Ngạn ngữ Đức)",
    "Một ngôi nhà đầy ắp tiếng cười quý hơn một cung điện ngập tràn nước mắt. (Ngạn ngữ Nga)",
    "Đừng đo may mắn của bạn bằng chiếc thước đo của người khác. (Ngạn ngữ Hà Lan)",
    "Kẻ sợ gió mùa đông thì không xứng đáng tận hưởng nắng ấm mùa xuân. (Ngạn ngữ Thụy Điển)",
    "Người giàu nhất thế gian là người bằng lòng với những thứ mình đang có. (Ngạn ngữ Hy Lạp)",
    "Lời khen trước mặt là mồi câu, lời khuyên sau lưng mới là vàng ròng. (Ngạn ngữ Đan Mạch)",
    "Lòng kiên nhẫn khi gặp nghịch cảnh là thước đo chân thực của lòng can đảm. (Ngạn ngữ La Tinh)",
    "Người muốn ăn hạnh nhân thì phải tự đập vỡ lớp vỏ cứng. (Tục ngữ Anh)",
    "Bùn lầy dưới chân không ngăn được hạt sen vươn lên nở hoa ngát hương. (Ngạn ngữ Ấn Độ)",
    "Khi mặt trời lặn xuống, đốm lửa tàn nhỏ bé cũng tự ngỡ mình là vầng dương. (Ngạn ngữ Ba Tư)",
    "Người bi quan phàn nàn vì ngược gió, người lạc quan kiên nhẫn chờ gió đổi hướng, người thực tế điều chỉnh cánh buồm. (Ngạn ngữ Anh)",
    "Kẻ hèn nhát chết cả nghìn lần trước khi trút hơi thở cuối cùng. (William Shakespeare / Ngạn ngữ Anh)",
    "Của cải đến nhanh như thác lũ thì cũng ra đi mau chóng như cát bay. (Ngạn ngữ Ả Rập)",
    "Chiếc giếng không bao giờ cạn vì nó ban phát nguồn nước cho muôn loài. (Ngạn ngữ Thổ Nhĩ Kỳ)",
    "Không có món súp nào ăn nóng hổi như lúc nó vừa sôi trên bếp. (Ngạn ngữ Đức)",
    "Muốn hiểu sâu một người, hãy xem cách họ đối xử với kẻ yếu thế hơn mình. (Ngạn ngữ Anh)",
    "Thước đo của một ngày không phải là số quả bạn hái được, mà là số hạt giống bạn gieo trồng. (Ngạn ngữ Scotland)",
    "Con đại bàng bay lượn trên trời cao không bận tâm tiếng ồn ào của đàn sẻ dưới mặt đất. (Ngạn ngữ Ý)",
    "Cuộc sống như một cuốn sách, kẻ không bước chân ra đi chỉ mới đọc được vỏn vẹn một trang duy nhất. (Thánh Augustine / Ngạn ngữ La Tinh)",

}

local function currentQuote(period_sec)
    local idx = (math.floor(os.time() / (period_sec or 120)) % #QUOTES) + 1
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

-- Ba cỡ hiển thị, chỉnh trong menu của plugin (khóa sageclock_size).
-- w: tỉ lệ bề ngang màn hình dùng cho hàng số; hfrac: tỉ lệ bề cao cho
-- kiểu ngang; stacked_h: {có thành ngữ, không thành ngữ}; quote: cỡ chữ
-- của dòng thành ngữ (trước scaleBySize).
local SIZE_PROFILES = {
    S = { w = 0.68, hfrac = 0.32, stacked_h = { 0.50, 0.62 }, quote = 17 },
    M = { w = 0.80, hfrac = 0.40, stacked_h = { 0.60, 0.74 }, quote = 20 },
    L = { w = 0.94, hfrac = 0.55, stacked_h = { 0.76, 0.90 }, quote = 27 },
}

local ClockWidget = InputContainer:extend{
    covers_fullscreen = true,
    stacked = false,
    show_quote = true,
    size = "M",
    interval_min = 2,
    _last_text = nil,
    _changes = 0,
    _tick_scheduled = false,
}

function ClockWidget:sizeProfile()
    return SIZE_PROFILES[self.size] or SIZE_PROFILES.M
end

-- Chu kỳ nhảy giờ tính bằng giây (khóa sageclock_interval, 1..10 phút).
function ClockWidget:periodSec()
    local m = self.interval_min or 2
    if m < 1 then m = 1 end
    if m > 10 then m = 10 end
    return m * 60
end

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

-- Tính cỡ ô pixel theo hồ sơ cỡ đã chọn (S/M/L), chừa lề thoáng bốn phía.
function ClockWidget:pixelSize(stacked, sample)
    local prof = self:sizeProfile()
    local w, h = Screen:getWidth(), Screen:getHeight()
    local cols = 0
    for i = 1, #sample do
        cols = cols + glyphWidth(sample:sub(i, i))
        if i < #sample then cols = cols + 1 end
    end
    local pw = math.floor(w * prof.w / cols)
    local ph
    if stacked then
        -- 2 dòng: 14 hàng pixel + khoảng cách ~1 hàng;
        -- chừa thêm chỗ cho dòng thành ngữ ở dưới nếu đang bật
        ph = math.floor(h * (self.show_quote and prof.stacked_h[1] or prof.stacked_h[2]) / 15)
    else
        -- 1 dòng: cho ô cao tối đa gấp đôi ô ngang cho số trông cao, gọn
        ph = math.min(math.floor(h * prof.hfrac / 7), pw * 2)
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
        parts[#parts + 1] = VerticalSpan:new{ width = Screen:scaleBySize(30) }
        parts[#parts + 1] = TextBoxWidget:new{
            text = currentQuote(self:periodSec()),
            face = Font:getFace("cfont", Screen:scaleBySize(self:sizeProfile().quote)),
            width = math.floor(Screen:getWidth() * 0.82),
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

-- Hẹn giờ tới MỐC chu kỳ tiếp theo (chu kỳ do người dùng chọn, 1..10
-- phút, căn theo đồng hồ hệ thống) rồi mới vẽ lại.
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
            -- Mỗi 5 lần nhảy làm mới toàn phần 1 lần để xóa bóng ma e-ink
            local mode = (self._changes % 5 == 0) and "full" or "ui"
            UIManager:setDirty(self, mode)
        end
        self:scheduleTick()
    end
    local period = self:periodSec()
    local now_s = os.time()
    local delay = period - (now_s % period) + 1
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

-- Thoát bằng CHẠM 2 LẦN liên tiếp (trong 0,6 giây): chạm 1 lần lỡ tay
-- thì đồng hồ vẫn chạy, không bị thoát oan.
function ClockWidget:onTapClose()
    local ok, s, u = pcall(ffiutil.gettime)
    local now = ok and (s + u / 1000000) or os.time()
    if self._last_tap and (now - self._last_tap) <= 0.6 then
        self._last_tap = nil
        UIManager:close(self)
    else
        self._last_tap = now
    end
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
-- Tự cập nhật (OTA): tải main.lua + _meta.lua mới nhất từ GitHub,
-- không cần cắm máy tính. Cần Wi-Fi đang bật trên máy.
----------------------------------------------------------------------

local SAGECLOCK_VERSION = "2.4.1"
local OTA_BASE = "https://raw.githubusercontent.com/mitokm/kobo-sage-clock/main/sageclock.koplugin/"

local function pluginDir()
    local src = debug.getinfo(1, "S").source or ""
    return src:match("^@(.*/)") or "./"
end

local function httpGet(url)
    local https = require("ssl.https")
    local ltn12 = require("ltn12")
    local chunks = {}
    local res, code = https.request{
        url = url,
        sink = ltn12.sink.table(chunks),
        headers = { ["User-Agent"] = "SageClock-OTA" },
    }
    if res and code == 200 then
        return table.concat(chunks)
    end
    return nil, code
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

function SageClock:getSize()
    local v = G_reader_settings:readSetting("sageclock_size")
    if v == "S" or v == "M" or v == "L" then return v end
    return "M"
end

-- Nhịp nhảy giờ: số phút giữa hai lần cập nhật hiển thị (1..10, mặc định 2).
function SageClock:getInterval()
    local v = tonumber(G_reader_settings:readSetting("sageclock_interval"))
    if v and v >= 1 and v <= 10 then return math.floor(v) end
    return 2
end

function SageClock:checkForUpdate()
    UIManager:show(InfoMessage:new{
        text = _("Đang kiểm tra bản mới…"),
        timeout = 2,
    })
    UIManager:scheduleIn(0.5, function()
        local ok, err = pcall(function()
            local meta = httpGet(OTA_BASE .. "_meta.lua")
            if not meta then error("không tải được thông tin phiên bản") end
            local remote = meta:match('version%s*=%s*"([%d%.]+)"')
            if not remote then error("không đọc được phiên bản mới") end
            if remote == SAGECLOCK_VERSION then
                UIManager:show(InfoMessage:new{
                    text = _("Đã là bản mới nhất (" .. SAGECLOCK_VERSION .. ")."),
                })
                return
            end
            local main = httpGet(OTA_BASE .. "main.lua")
            if not main or #main < 5000 or not main:find("SageClock", 1, true) then
                error("file tải về không hợp lệ")
            end
            local dir = pluginDir()
            local f = io.open(dir .. "main.lua.new", "wb")
            if not f then error("không ghi được file tạm") end
            f:write(main)
            f:close()
            os.rename(dir .. "main.lua", dir .. "main.lua.bak")
            os.rename(dir .. "main.lua.new", dir .. "main.lua")
            local fm = io.open(dir .. "_meta.lua", "wb")
            if fm then fm:write(meta) fm:close() end
            UIManager:show(InfoMessage:new{
                text = _("Đã cập nhật lên bản " .. remote .. ".\nHãy khởi động lại KOReader để dùng bản mới."),
            })
        end)
        if not ok then
            UIManager:show(InfoMessage:new{
                text = _("Không cập nhật được. Kiểm tra Wi-Fi rồi thử lại.\n(" .. tostring(err) .. ")"),
            })
        end
    end)
end

function SageClock:addToMainMenu(menu_items)
    -- Menu con chọn nhịp nhảy giờ 1..10 phút
    local interval_items = {}
    for m = 1, 10 do
        local minutes = m
        interval_items[#interval_items + 1] = {
            text = minutes .. _(" phút"),
            checked_func = function()
                return self:getInterval() == minutes
            end,
            callback = function()
                G_reader_settings:saveSetting("sageclock_interval", minutes)
            end,
        }
    end
    menu_items.sageclock = {
        text = _("Sage Clock — đồng hồ"),
        sorting_hint = "more_tools",
        sub_item_table = {
            {
                text = _("Hiện đồng hồ (chạm 2 lần để thoát)"),
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
            {
                text = _("Cỡ chữ (số + thành ngữ)"),
                sub_item_table = {
                    {
                        text = _("Nhỏ"),
                        checked_func = function()
                            return self:getSize() == "S"
                        end,
                        callback = function()
                            G_reader_settings:saveSetting("sageclock_size", "S")
                        end,
                    },
                    {
                        text = _("Vừa"),
                        checked_func = function()
                            return self:getSize() == "M"
                        end,
                        callback = function()
                            G_reader_settings:saveSetting("sageclock_size", "M")
                        end,
                    },
                    {
                        text = _("Lớn"),
                        checked_func = function()
                            return self:getSize() == "L"
                        end,
                        callback = function()
                            G_reader_settings:saveSetting("sageclock_size", "L")
                        end,
                    },
                },
            },
            {
                text = _("Nhịp nhảy giờ"),
                sub_item_table = interval_items,
            },
            {
                text = _("Cập nhật bản mới (OTA, cần Wi-Fi)"),
                callback = function()
                    self:checkForUpdate()
                end,
            },
            {
                text = _("Phiên bản: " .. SAGECLOCK_VERSION),
                callback = function() end,
            },
        },
    }
end

function SageClock:showClock()
    local widget = ClockWidget:new{
        stacked = self:isStacked(),
        show_quote = self:showQuote(),
        size = self:getSize(),
        interval_min = self:getInterval(),
    }
    UIManager:show(widget, "full")
end

function SageClock:onShowSageClock()
    self:showClock()
    return true
end

return SageClock
