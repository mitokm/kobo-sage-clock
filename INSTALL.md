# Cài đặt Sage Clock cho Kobo Sage — hướng dẫn chi tiết

Hướng dẫn này dành cho người cài lần đầu, làm chậm rãi từng bước.
Chỉ cần: một chiếc **Kobo Sage đã cài KOReader**, một máy tính (Windows hay
macOS đều được) và cáp USB-C của máy.

> Nếu Sage của bạn **chưa có KOReader**: tải bản KOReader mới nhất dành cho
> Kobo tại [trang Releases của KOReader](https://github.com/koreader/koreader/releases)
> và cài theo hướng dẫn trong gói đó trước, rồi quay lại đây.

## Bước 0 — Chuẩn bị trên máy đọc sách

1. Trong **Settings của Kobo → Date and time**, kiểm tra giờ và múi giờ cho
   đúng. Đồng hồ lấy giờ hệ thống — giờ hệ thống sai thì đồng hồ sai theo.
2. Sạc pin Sage lên tối thiểu ~30% cho yên tâm trong lúc cài.

## Bước 1 — Tải mã nguồn

1. Ở đầu trang repo này, bấm nút **Code** màu xanh lá → **Download ZIP**.
2. Giải nén file ZIP vừa tải. Bạn sẽ được một thư mục như sau:

   ```
   kobo-sage-clock-main/
   ├─ README.md
   ├─ README.vi.md
   ├─ INSTALL.md          ← file bạn đang đọc
   ├─ CHANGELOG.md
   ├─ LICENSE
   ├─ docs/
   └─ sageclock.koplugin/     ← THƯ MỤC CẦN CHÉP VÀO MÁY
      ├─ _meta.lua
      └─ main.lua
   ```

   Chỉ cần quan tâm thư mục **`sageclock.koplugin`** — đừng chép cả thư mục
   `kobo-sage-clock-main` vào máy.

## Bước 2 — Chép plugin vào Sage

1. Cắm Sage vào máy tính bằng cáp USB-C. Trên màn hình Sage hiện hộp hỏi
   kết nối máy tính — bấm **Connect**.
2. Trên máy tính, mở ổ đĩa **KOBOeReader** vừa xuất hiện.
3. Lần lượt mở các thư mục: **`.adds`** → **`koreader`** → **`plugins`**.
   - Thư mục bắt đầu bằng dấu chấm (`.adds`) là thư mục **ẩn**:
     - **macOS:** trong Finder bấm `Cmd + Shift + .` (dấu chấm) để hiện
       file/thư mục ẩn.
     - **Windows:** thư mục này hiện bình thường trong File Explorer.
   - Nếu bên trong `koreader` chưa có thư mục `plugins` thì **tự tạo mới**
     một thư mục tên đúng `plugins`.
4. Chép **nguyên thư mục `sageclock.koplugin`** (kéo–thả hoặc copy–paste)
   vào trong `plugins`.
5. Kiểm tra lại đường dẫn cuối cùng — phải đúng thế này:

   ```
   KOBOeReader/.adds/koreader/plugins/sageclock.koplugin/main.lua
   KOBOeReader/.adds/koreader/plugins/sageclock.koplugin/_meta.lua
   ```

   Lỗi hay gặp nhất: chép nhầm thành hai lớp thư mục kiểu
   `plugins/sageclock.koplugin/sageclock.koplugin/main.lua` (do giải nén lồng
   nhau). Nếu thấy hai lớp như vậy, dời thư mục con ra ngoài.

## Bước 3 — Khởi động lại KOReader

1. **Eject / ngắt kết nối an toàn** ổ KOBOeReader trên máy tính trước khi rút
   cáp. Rút cáp lúc máy đang ghi dữ liệu có thể làm hỏng file trên máy.
2. Trên Sage, nếu đang ở KOReader thì **thoát hẳn** (menu → biểu tượng nguồn
   → Exit / thoát về giao diện Kobo), rồi mở lại KOReader.
   Nếu đang ở giao diện Kobo thì cứ mở KOReader như thường.
   KOReader chỉ nạp plugin lúc khởi động — không khởi động lại là không thấy
   plugin đâu.

## Bước 4 — Mở đồng hồ lần đầu

1. Trong KOReader: **Menu ☰ → Công cụ (Tools) → Sage Clock — đồng hồ →
   Hiện đồng hồ (chạm để thoát)**.
2. Màn hình hiện đồng hồ pixel toàn màn hình, kèm một câu thành ngữ ở dưới.
3. **Chạm vào màn hình** để thoát về đọc sách.

Xong rồi đấy. Từ lần sau, nếu muốn mở nhanh, vào phần cài đặt cử chỉ
(Gestures) của KOReader và gán hành động **“Sage Clock — hiện đồng hồ”**
cho một cử chỉ bất kỳ.

## Các tùy chọn

Trong **Menu → Công cụ → Sage Clock — đồng hồ**:

| Tùy chọn | Mặc định | Ý nghĩa |
| --- | --- | --- |
| Kiểu dọc: giờ trên, phút dưới | tắt | Bật lên thì giờ hiện thành hai dòng, số to gần gấp đôi |
| Hiện câu thành ngữ dưới đồng hồ | bật | Tắt đi nếu chỉ muốn đồng hồ trơn, không chữ |

Đổi tùy chọn xong phải **mở lại đồng hồ** mới thấy thay đổi.

## Nâng cấp lên bản mới

Khi repo có bản mới: tải ZIP mới, chép thư mục `sageclock.koplugin` đè lên
thư mục cũ trong `.adds/koreader/plugins/`, rồi khởi động lại KOReader.
Cài đặt (kiểu dọc, bật/tắt thành ngữ) được giữ nguyên.

## Gỡ cài đặt

Xóa thư mục `.adds/koreader/plugins/sageclock.koplugin` rồi khởi động lại
KOReader. Plugin không sửa gì vào phần mềm gốc của Kobo nên gỡ là sạch
hoàn toàn.

## Xử lý sự cố

| Hiện tượng | Nguyên nhân thường gặp & cách xử lý |
| --- | --- |
| Không thấy mục **Sage Clock** trong menu Công cụ | Chưa khởi động lại KOReader thật sự (Bước 3), hoặc chép sai đường dẫn / lồng hai lớp thư mục (kiểm tra lại Bước 2, mục 5) |
| Đồng hồ hiện sai giờ | Giờ hệ thống của Kobo sai — chỉnh trong Settings của Kobo → Date and time |
| Giờ hiển thị chậm 1 phút so với điện thoại | Đúng thiết kế: đồng hồ chỉ cập nhật ở mốc phút chẵn (mỗi 2 phút) để tiết kiệm pin |
| Không có dòng thành ngữ | Tùy chọn thành ngữ đang tắt, hoặc đang ở lần mở đồng hồ trước khi bật — mở lại đồng hồ |
| Màn hình hiện đồng hồ xong máy tự ngủ như thường | Bạn đang nhìn màn hình ngủ của Kobo/KOReader chứ không phải Sage Clock — mở KOReader rồi bật đồng hồ theo Bước 4 |
| KOReader báo lỗi / văng khi mở đồng hồ | Lấy file `crash.log` trong thư mục `.adds/koreader` trên máy, mở một Issue trong repo này và đính kèm file đó |
| Pin tụt nhanh khi để đồng hồ | Bình thường: đồng hồ giữ CPU thức liên tục. Để chạy lâu/qua đêm thì cắm sạc USB-C |

## Câu hỏi thường gặp

**Để đồng hồ chạy qua đêm có hại màn hình không?**
E-ink không bị burn-in như OLED/LCD, và plugin tự làm mới toàn phần mỗi 20
phút để xóa bóng ma. Cắm sạc khi để qua đêm là đủ.

**Có dùng được cho Kobo khác (Libra, Clara…) không?**
Về nguyên tắc được — cỡ số tự tính theo kích thước màn hình thật. Nhưng mọi
căn chỉnh và kiểm tra đều làm cho Sage (1440×1920) nên máy khác em chưa dám
khẳng định; ai thử được xin báo kết quả qua Issues.

**Có mất sách, ghi chú, tiến độ đọc không?**
Không. Plugin chỉ là một thư mục thêm vào KOReader, không đụng gì tới thư
viện và dữ liệu đọc của bạn.
