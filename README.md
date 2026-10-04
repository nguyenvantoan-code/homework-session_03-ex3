# Bài 3: Bảo Mật Tài Nguyên Bằng HTTP Basic Authentication

> **Nộp bài tập Session 03 - Bài 03**  
> **Đường dẫn GitHub:** `homework/session_03/ex3/`

---

## 🎯 1. Mục Tiêu
- Cài đặt và sử dụng công cụ băm mật khẩu `htpasswd` thuộc gói `apache2-utils`.
- Tạo tệp chứa tài khoản và mật khẩu được băm an toàn tại `/etc/nginx/.htpasswd`.
- Cấu hình Nginx yêu cầu xác thực HTTP Basic Authentication đối với thư mục/đường dẫn nhạy cảm `/admin`.
- Kiểm tra tính đúng đắn của cơ chế xác thực thông qua công cụ dòng lệnh `curl`.

---

## 🔒 2. Bối Cảnh & Ràng Buộc Bảo Mật

### Bối cảnh
Trang web có một thư mục quản trị nội bộ `/admin` chứa thông tin nhạy cảm. Cần thiết lập lớp xác thực mật khẩu trực tiếp trên trình duyệt bằng cơ chế HTTP Basic Authentication để ngăn chặn các truy cập trái phép.

### Ràng buộc bảo mật quan trọng
- **Vị trí lưu trữ tệp mật khẩu:** Tệp ẩn `.htpasswd` **bắt buộc** lưu trữ tại `/etc/nginx/.htpasswd` (nằm ngoài thư mục mã nguồn tĩnh `/var/www/`).
- **Lý do an toàn:** Nếu đặt `.htpasswd` trong `/var/www/html/`, hacker hoặc người dùng bên ngoài có thể gửi request HTTP trực tiếp tới `http://<IP>/..htpasswd` hoặc do cấu hình sai khiến file này bị rò rỉ công khai. Đặt file tại `/etc/nginx/` đảm bảo mã nguồn tĩnh không bao giờ đọc/phục vụ trực tiếp tệp mật khẩu này.
- **Tên tài khoản quản trị:** `admin_user`.

---

## 📂 3. Cấu Trúc Thư Mục Bài Nộp

```text
homework/session_03/ex3/
├── nginx.conf       # File cấu hình Nginx Server Block (chứa location /admin)
├── .htpasswd        # File mật khẩu ẩn mẫu chứa tài khoản admin_user
├── setup.sh         # Script tự động hóa cài đặt & cấu hình trên Ubuntu/Debian
└── README.md        # Hướng dẫn chi tiết & kết quả kiểm tra
```

---

## 🚀 4. Hướng Dẫn Thực Hiện Chi Tiết

### Bước 1: Cài đặt công cụ băm mật khẩu `apache2-utils`
Tiện ích `htpasswd` được tích hợp sẵn trong gói `apache2-utils`. Chạy lệnh sau trên Server/Droplet:
```bash
sudo apt update
sudo apt install apache2-utils -y
```

### Bước 2: Tạo tệp mật khẩu ẩn `/etc/nginx/.htpasswd`
Tạo tài khoản quản trị `admin_user` và băm mật khẩu lưu vào tệp ẩn tại `/etc/nginx/`:
```bash
sudo htpasswd -c /etc/nginx/.htpasswd admin_user
```
*Lưu ý:* Cờ `-c` (Create) được dùng để tạo mới tệp. Hệ thống sẽ yêu cầu bạn nhập và xác nhận mật khẩu cho `admin_user`.

#### Phân quyền bảo mật cho tệp mật khẩu:
```bash
sudo chown root:www-data /etc/nginx/.htpasswd
sudo chmod 640 /etc/nginx/.htpasswd
```

### Bước 3: Cấu hình Server Block Nginx
Mở tệp cấu hình Server Block (thường là `/etc/nginx/sites-available/default` hoặc tệp cấu hình trang web của bạn):
```bash
sudo nano /etc/nginx/sites-available/default
```

Thêm khối `location /admin` vào trong khối `server { ... }`:

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Cấu hình bảo mật HTTP Basic Authentication cho /admin
    location /admin {
        auth_basic "Restricted Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
        try_files $uri $uri/ =404;
    }
}
```

#### Giải thích các chỉ thị:
- `auth_basic "Restricted Admin Area";`: Bật xác thực Basic Auth và hiển thị thông điệp chào mừng/thông báo khu vực giới hạn trên pop-up trình duyệt.
- `auth_basic_user_file /etc/nginx/.htpasswd;`: Đường dẫn tuyệt đối tới tệp chứa danh sách tài khoản và mật khẩu đã băm.
- `try_files $uri $uri/ =404;`: Phục vụ tệp/thư mục tương ứng nếu tồn tại, nếu không sẽ trả về lỗi 404 Not Found.

### Bước 4: Kiểm tra cú pháp và Tải lại cấu hình Nginx
Trước khi áp dụng cấu hình mới, luôn kiểm tra cú pháp để tránh làm gián đoạn dịch vụ:
```bash
sudo nginx -t
```
Nếu màn hình hiển thị `syntax is ok` và `test is successful`, tiến hành tải lại cấu hình:
```bash
sudo systemctl reload nginx
```

---

## 🧪 5. Kiểm Tra Kết Quả (Verification)

Tạo thư mục thử nghiệm `/var/www/html/admin` và file `index.html`:
```bash
sudo mkdir -p /var/www/html/admin
echo "<h1>Admin Dashboard</h1>" | sudo tee /var/www/html/admin/index.html
```

### Lệnh 1: Gửi request thông thường (Không có thông tin đăng nhập)
```bash
curl -I http://<IP_ADDRESS_DROPLET>/admin
```
**Kết quả mong đợi:**
- Trả về mã trạng thái **HTTP 401 Unauthorized**.
- Có chứa tiêu đề `WWW-Authenticate: Basic realm="Restricted Admin Area"`.

```http
HTTP/1.1 401 Unauthorized
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 04 Oct 2026 15:20:00 GMT
Content-Type: text/html
Content-Length: 188
Connection: keep-alive
WWW-Authenticate: Basic realm="Restricted Admin Area"
```

---

### Lệnh 2: Gửi request kèm thông tin tài khoản hợp lệ
```bash
curl -u admin_user:<PASSWORD> http://<IP_ADDRESS_DROPLET>/admin
```
*(Thay `<PASSWORD>` bằng mật khẩu thực tế bạn đã thiết lập khi chạy htpasswd)*

**Kết quả mong đợi:**
- Trả về mã trạng thái **HTTP 200 OK** (hoặc **404 Not Found** nếu chưa tạo file `index.html` trong thư mục `/admin`).
- **tuyệt đối không được trả về 401 Unauthorized**.

```http
HTTP/1.1 200 OK
Server: nginx/1.18.0 (Ubuntu)
Date: Sun, 04 Oct 2026 15:21:00 GMT
Content-Type: text/html
Content-Length: 28
Last-Modified: Sun, 04 Oct 2026 15:20:00 GMT
Connection: keep-alive
ETag: "..."
Accept-Ranges: bytes

<h1>Admin Dashboard</h1>
```

---

## 🛠️ 6. Chạy Tự Động Bằng Script (Tùy Chọn)

Bạn có thể chạy script `setup.sh` được đính kèm để tự động hóa toàn bộ quá trình:
```bash
chmod +x setup.sh
./setup.sh
```

---

## 📌 7. Tổng Kết Kiến Thức
1. **HTTP Basic Auth** truyền thông tin tài khoản qua header `Authorization: Basic <base64>`, do đó nên kết hợp với **HTTPS (TLS/SSL)** trong môi trường thực tế để tránh bị bắt gói tin chứa chuỗi Base64.
2. Đặt tệp `.htpasswd` tại `/etc/nginx/` là nguyên tắc an toàn quan trọng hàng đầu để bảo vệ file mật khẩu khỏi nguy cơ rò rỉ qua Web Server.
