#!/bin/sh

# Fungsi untuk menampilkan animasi persentase
show_progress() {
    local percent=0
    local steps=10
    local delay=0.5  # Jeda dalam detik untuk setiap langkah

    echo -n "Proses instalasi: ["
    while [ $percent -lt 100 ]; do
        percent=$((percent + steps))
        if [ $percent -gt 100 ]; then
            percent=100
        fi
        echo -n "===="
        sleep $delay
    done
    echo "] 100% Selesai!"
}

# 1. Script ini akan dijalankan dengan perintah:
# curl -fsSL https://raw.githubusercontent.com/Hnatta/pingoc/main/installer.sh | sh

# 2. Definisikan variabel untuk URL, path ZIP, dan direktori ekstraksi
ZIP_URL="${ZIP_URL:-https://github.com/Hnatta/pingoc/archive/refs/heads/main.zip}"
ZIP_PATH="${ZIP_PATH:-/tmp/pingoc-main.zip}"
EXTRACT_DIR_GLOB="${EXTRACT_DIR_GLOB:-/tmp/pingoc-*}"

# 3. Menghapus file yang sudah ada di sistem OpenWrt
echo "Menghapus file lama..."
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
echo "Mengunduh file ZIP..."
curl -fsSL "$ZIP_URL" -o "$ZIP_PATH"
echo "Mengekstrak file..."
unzip -o "$ZIP_PATH" -d /tmp

# Menemukan direktori hasil ekstraksi berdasarkan pola
EXTRACT_DIR=$(find /tmp -maxdepth 1 -type d -name "pingoc-*")
if [ -z "$EXTRACT_DIR" ]; then
    echo "Gagal menemukan direktori hasil ekstraksi!"
    exit 1
fi

# Memindahkan file dari hasil ekstraksi ke lokasi tujuan
echo "Menyalin file ke direktori sistem..."
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
echo "Mengatur izin akses..."
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
echo "Menambahkan perintah startup..."
echo "sleep 182 && /usr/bin/pingoc -r" >> /etc/rc.local

# 7. Restart service LuCI (uhttpd)
echo "Merestart service LuCI..."
/etc/init.d/uhttpd restart

# 8. Membersihkan file sementara
echo "Membersihkan file sementara..."
rm -f "$ZIP_PATH"
rm -rf "$EXTRACT_DIR"

# Menampilkan animasi persentase
show_progress

echo "Instalasi selesai!"
