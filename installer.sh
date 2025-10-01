cat > /tmp/installer.sh <<'EOF'
#!/bin/sh
# installer.sh — pasang dari ZIP, timpa file, chmod sesuai, tanam rc.local, start pingoc
set -eu

# 1. Definisikan URL dan path untuk download ZIP | Menentukan URL dan lokasi file ZIP
ZIP_URL="${ZIP_URL:-https://github.com/Hnatta/pingoc/archive/refs/heads/main.zip}"  # URL sumber ZIP
ZIP_PATH="${ZIP_PATH:-/tmp/pingoc-main.zip}"                                      # Lokasi penyimpanan file ZIP
EXTRACT_DIR_GLOB="${EXTRACT_DIR_GLOB:-/tmp/pingoc-*}"                            # Direktori hasil ekstrak ZIP

# 2. Bersihkan file lama jika ada | Menghapus file ZIP dan direktori ekstrak sebelumnya
rm -f "$ZIP_PATH" 2>/dev/null || true
rm -rf $EXTRACT_DIR_GLOB 2>/dev/null || true

# 3. Hapus file yang sudah ada | Menghapus file lama untuk menghindari konflik
echo "[installer] Menghapus file lama..."
for FILE in \
  /etc/pingoc.env \
  /usr/bin/modem \
  /usr/bin/pingoc \
  /usr/lib/lua/luci/controller/pingoc.lua \
  /usr/lib/lua/luci/controller/yamloc.lua \
  /usr/lib/lua/luci/view/pingoc.htm \
  /usr/lib/lua/luci/view/yamloc.htm \
  /www/cgi-bin/pingoc-log.sh \
  /www/tinyfm/pingoc.html \
  /www/tinyfm/yamloc.html
do
  [ -f "$FILE" ] && rm -f "$FILE" && echo "  - $FILE dihapus"
done

# 4. Unduh ZIP dari URL | Mengunduh file ZIP dari GitHub
echo "[installer] Download: $ZIP_URL"
if command -v curl >/dev/null 2>&1; then
  curl -fL -o "$ZIP_PATH" "$ZIP_URL"
elif command -v wget >/dev/null 2>&1; then
  wget -O "$ZIP_PATH" "$ZIP_URL"
else
  echo "[ERROR] butuh curl atau wget" >&2; exit 1
fi

# 5. Ekstrak ZIP | Mengekstrak file ZIP ke direktori sementara
echo "[installer] Extract: $ZIP_PATH"
if ! command -v unzip >/dev/null 2>&1; then
  opkg update >/dev/null 2>&1 || true
  opkg install unzip >/dev/null 2>&1 || { echo "[ERROR] gagal pasang unzip"; exit 1; }
fi
unzip -q "$ZIP_PATH" -d /tmp
SRC_DIR="$(ls -d $EXTRACT_DIR_GLOB 2>/dev/null | head -n1 || true)"
[ -n "$SRC_DIR" ] || { echo "[ERROR] extract dir not found"; exit 1; }

# 6. Daftar file untuk disalin | Menentukan file yang akan disalin dari direktori ekstrak
FILES="
files/etc/pingoc.env
files/usr/bin/modem
files/usr/bin/pingoc
files/usr/lib/lua/luci/controller/pingoc.lua
files/usr/lib/lua/luci/controller/yamloc.lua
files/usr/lib/lua/luci/view/pingoc.htm
files/usr/lib/lua/luci/view/yamloc.htm
files/www/cgi-bin/pingoc-log.sh
files/www/tinyfm/pingoc.html
files/www/tinyfm/yamloc.html
"

# 7. Salin dan timpa file | Menyalin file ke lokasi tujuan dengan izin khusus
echo "[installer] Copy & overwrite files..."
for REL in $FILES; do
  SRC="$SRC_DIR/$REL"
  DST="/$(printf '%s' "$REL" | sed 's/^files\///')"
  DDIR="$(dirname "$DST")"
  if [ ! -f "$SRC" ]; then echo "[WARN] skip: $SRC"; continue; fi
  mkdir -p "$DDIR"
  cp -f "$SRC" "$DST"

  # Normalisasi file (anti Exec format error) | Membersihkan karakter BOM dan CR
  sed -i '1s/^\xEF\xBB\xBF//' "$DST" 2>/dev/null || true
  sed -i 's/\r$//' "$DST" 2>/dev/null || true
  case "$DST" in
    /usr/bin/pingoc|/usr/bin/modem|/www/cgi-bin/*.sh)
      grep -q '^#!' "$DST" || sed -i '1i #!/bin/sh' "$DST"
      chmod 0755 "$DST" 2>/dev/null || true
      ;;
    /etc/pingoc.env|/usr/lib/lua/luci/controller/pingoc.lua|/usr/lib/lua/luci/controller/yamloc.lua|/usr/lib/lua/luci/view/pingoc.htm|/usr/lib/lua/luci/view/yamloc.htm)
      chmod 0755 "$DST" 2>/dev/null || true
      ;;
    /www/tinyfm/pingoc.html|/www/tinyfm/yamloc.html)
      chmod 0644 "$DST" 2>/dev/null || true
      ;;
  esac
  echo "  + $DST"
done

# 8. Konfigurasi uhttpd untuk CGI | Mengatur LuCI agar mendukung skrip CGI
if command -v uci >/dev/null 2>&1; then
  uci add_list uhttpd.main.interpreter='.sh=/bin/sh' 2>/dev/null || true
  uci set uhttpd.main.cgi_prefix='/cgi-bin'
  uci commit uhttpd
  /etc/init.d/uhttpd restart || true
fi

# 9. Tambahkan ke rc.local | Menambahkan perintah startup ke rc.local
RC=/etc/rc.local
if [ ! -f "$RC" ]; then echo "#!/bin/sh" > "$RC"; echo "exit 0" >> "$RC"; chmod +x "$RC"; fi
sed -i "/^# >>> pingoc boot start/,/^# >>> pingoc boot end/d" "$RC"
awk '
BEGIN{printed=0}
/^exit 0$/ && !printed{
  print "# >>> pingoc boot start"
  print "sleep 182 && /usr/bin/pingoc -r || true"
  print "# >>> pingoc boot end"
  printed=1
}
{print}
END{
  if(!printed){
    print "# >>> pingoc boot start"
    print "sleep 182 && /usr/bin/pingoc -r || true"
    print "# >>> pingoc boot end"
    print "exit 0"
  }
}' "$RC" > /tmp/rc.local.new && mv /tmp/rc.local.new "$RC" && chmod +x "$RC"

# 10. Jalankan perintah awal | Menjalankan pingoc setelah instalasi
echo "[installer] Menjalankan pingoc..."
sleep 2
/usr/bin/pingoc -r || true

# 11. Restart service LuCI | Merestart uhttpd untuk menerapkan perubahan
echo "[installer] Restart service uhttpd..."
/etc/init.d/uhttpd restart || true

# 12. Bersihkan file sementara | Menghapus file ZIP dan direktori ekstrak
echo "[installer] Cleanup"
rm -f "$ZIP_PATH" 2>/dev/null || true
rm -rf $EXTRACT_DIR_GLOB 2>/dev/null || true

echo "[installer] Selesai."
EOF

# Jalankan script dengan satu perintah | Eksekusi script installer
sh /tmp/installer.sh
