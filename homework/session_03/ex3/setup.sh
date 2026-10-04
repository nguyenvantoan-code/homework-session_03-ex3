#!/bin/bash
# ==============================================================================
# Script Tự Động Cấu Hình HTTP Basic Authentication Cho Nginx (/admin)
# Bài tập 3 - Session 03
# ==============================================================================

set -e

echo "=== 1. Cài đặt công cụ băm mật khẩu (apache2-utils) ==="
sudo apt update
sudo apt install apache2-utils -y

echo "=== 2. Tạo tệp mật khẩu ẩn /etc/nginx/.htpasswd ==="
# Nhập mật khẩu cho tài khoản admin_user
# Lưu ý: Nếu tệp đã tồn tại, bỏ cờ -c để không ghi đè toàn bộ tệp
echo "Vui lòng nhập mật khẩu cho tài khoản admin_user:"
sudo htpasswd -c /etc/nginx/.htpasswd admin_user

echo "=== 3. Phân quyền bảo mật cho tệp .htpasswd ==="
# Đảm bảo chỉ root và nhóm web server (www-data) có quyền đọc
sudo chown root:www-data /etc/nginx/.htpasswd
sudo chmod 640 /etc/nginx/.htpasswd

echo "=== 4. Tạo thư mục và trang thử nghiệm cho /admin ==="
sudo mkdir -p /var/www/html/admin
echo "<!DOCTYPE html><html><head><title>Admin Area</title></head><body><h1>Trang Quản Trị Nội Bộ - Đã Xác Thực Thành Công!</h1></body></html>" | sudo tee /var/www/html/admin/index.html > /dev/null

echo "=== 5. Cấu hình Nginx Server Block ==="
# Kiểm tra nếu file cấu hình mẫu nginx.conf tồn tại cùng thư mục với script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
if [ -f "$SCRIPT_DIR/nginx.conf" ]; then
    echo "Sao chép cấu hình nginx.conf vào /etc/nginx/sites-available/default..."
    sudo cp "$SCRIPT_DIR/nginx.conf" /etc/nginx/sites-available/default
else
    echo "Thêm location /admin vào tệp cấu hình Nginx hiện tại..."
    # Thêm block location nếu chưa có
    sudo bash -c 'cat << "EOF" > /etc/nginx/conf.d/admin-auth.conf
location /admin {
    auth_basic "Restricted Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    try_files $uri $uri/ =404;
}
EOF'
fi

echo "=== 6. Kiểm tra cú pháp cấu hình Nginx ==="
sudo nginx -t

echo "=== 7. Reload service Nginx ==="
sudo systemctl reload nginx

echo "=============================================================================="
echo " Cấu hình thành công HTTP Basic Authentication!"
echo " Kiểm tra truy cập:"
echo " 1. Không gửi thông tin xác thực (Mong đợi: HTTP 401 Unauthorized):"
echo "    curl -I http://localhost/admin"
echo " 2. Gửi thông tin đăng nhập đúng (Mong đợi: HTTP 200 OK):"
echo "    curl -u admin_user:<MAT_KHAU> http://localhost/admin"
echo "=============================================================================="
