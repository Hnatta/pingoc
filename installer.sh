#!/bin/sh

# 1. Script ini akan dijalankan dengan perintah:
# curl -fsSL https://raw.githubusercontent.com/Hnatta/pingoc/main/installer.sh | sh

# 2. Definisikan variabel untuk URL, path ZIP, dan direktori ekstraksi
# Mendefinisikan URL tempat file ZIP diunduh, path sementara untuk menyimpan ZIP, dan pola direktori hasil ekstraksi
ZIP_URL="${ZIP_URL:-https://github.com/Hnatta/pingoc/archive/refs/heads/main.zip}"
ZIP_PATH="${ZIP_PATH:-/tmp/pingoc-main.zip}"
EXTRACT_DIR_GLOB="${EXTRACT_DIR_GLOB:-/tmp/pingoc-*}"

# 3. Menghapus file yang sudah ada di sistem OpenWrt
# Menghapus file konfigurasi dan skrip yang sudah ada untuk memastikan tidak ada konflik
rm -f /etc/pingoc.env
rm -f /usr/bin/modem
rm -f /usr/bin/pingoc
rm -f /usr/lib/lua/luci/controller/pingoc.lua
rm -f /usr/lib/lua/luci/controller/yamloc.lua
rm -f /usr/lib/lua/luci/view/pingoc.htm
rm -f /usr/lib/lua/luci/view/yamloc.htm
rm -f /www/cgi-bin/pingoc-log.sh
rm -f /www/tinyfm/pingoc.html
rm -f /www/tinyfm/yamloc.html

# 4. Unduh dan ekstrak file ZIP dari URL yang ditentukan
# Mengunduh file ZIP dari URL dan mengekstraknya ke direktori sementara
curl -fsSL "$ZIP_URL" -o "$ZIP_PATH"
unzip -o "$ZIP_PATH" -d /tmp

# Menemukan direktori hasil ekstraksi berdasarkan pola
EXTRACT_DIR=$(find /tmp -maxdepth 1 -type d -name "pingoc-*")
if [ -z "$EXTRACT_DIR" ]; then
    echo "Gagal menemukan direktori hasil ekstraksi!"
    exit 1
fi

# Memindahkan file dari hasil ekstraksi ke lokasi tujuan dengan paksa menimpa
# Menyalin file dari direktori ekstraksi ke path yang sesuai di sistem
cp -f "$EXTRACT_DIR/files/etc/pingoc.env" /etc/pingoc.env
cp -f "$EXTRACT_DIR/files/usr/bin/modem" /usr/bin/modem
cp -f "$EXTRACT_DIR/files/usr/bin/pingoc" /usr/bin/pingoc
cp -f "$EXTRACT_DIR/files/usr/lib/lua/luci/controller/pingoc.lua" /usr/lib/lua/luci/controller/pingoc.lua
cp -f "$EXTRACT_DIR/files/usr/lib/lua/luci/controller/yamloc.lua" /usr/lib/lua/luci/controller/yamloc.lua
cp -f "$EXTRACT_DIR/files/usr/lib/lua/luci/view/pingoc.htm" /usr/lib/lua/luci/view/pingoc.htm
cp -f "$EXTRACT_DIR/files/usr/lib/lua/luci/view/yamloc.htm" /usr/lib/lua/luci/view/yamloc.htm
cp -f "$EXTRACT_DIR/files/www/cgi-bin/pingoc-log.sh" /www/cgi-bin/pingoc-log.sh
cp -f "$EXTRACT_DIR/files/www/tinyfm/pingoc.html" /www/tinyfm/pingoc.html
cp -f "$EXTRACT_DIR/files/www/tinyfm/yamloc.html" /www/tinyfm/yamloc.html

# 5. Mengatur izin akses untuk file yang disalin
# Memberikan izin eksekusi (0755) untuk file yang perlu dijalankan dan izin baca (0644) untuk file lainnya
chmod 0755 /etc/pingoc.env
chmod 0755 /usr/bin/modem
chmod 0755 /usr/bin/pingoc
chmod 0755 /www/cgi-bin/pingoc-log.sh
chmod 0644 /usr/lib/lua/luci/controller/pingoc.lua
chmod 0644 /usr/lib/lua/luci/controller/yamloc.lua
chmod 0644 /usr/lib/lua/luci/view/pingoc.htm
chmod 0644 /usr/lib/lua/luci/view/yamloc.htm
chmod 0644 /www/tinyfm/pingoc.html
chmod 0644 /www/tinyfm/yamloc.html

# 6. Menambahkan perintah ke startup lokal
# Menambahkan perintah untuk menjalankan pingoc setelah boot dengan jeda 182 detik
echo "sleep 182 && /usr/bin/pingoc -r" >> /etc/rc.local

# 7. Restart service LuCI (uhttpd) agar perubahan diterapkan
# Merestart service uhttpd untuk memastikan antarmuka web LuCI diperbarui
/etc/init.d/uhttpd restart

# 8. Membersihkan file sementara
# Menghapus file ZIP dan direktori hasil ekstraksi untuk membersihkan sistem
rm -f "$ZIP_PATH"
rm -rf "$EXTRACT_DIR"

echo "Instalasi selesai!"
