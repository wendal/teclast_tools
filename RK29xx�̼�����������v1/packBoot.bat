cd boot
..\find . -depth -print > boot_files
..\cpio -ov > ../Temp/boot < boot_files
cd ..
gzip Temp/boot