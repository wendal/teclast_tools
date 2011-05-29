print('RK29xx固件解包/打包工具')
print('Wendal作品 http://wendal.net')
print('项目地址: https://github.com/wendal/teclast_tools')
print('意见或反馈: pad@wendal.net')


function readHex(f)
    D1 = string.byte(f:read(1))
    D2 = string.byte(f:read(1))
    D3 = string.byte(f:read(1))
    D4 = string.byte(f:read(1))
    --D = D1 + D2 *256 8 + D3 * 256 * 256 + D4 *256*256*256
    return D1 + D2 *256 + D3 * 256 * 256 + D4 *256*256*256
end

BUFF=8192

function readDate(f,pos,len,dest)
    print(string.format('偏移量(0x%X) 长度(0x%X)',pos,len))
    rom_file:seek('set',pos)
    destF = io.open(dest, 'wb+')
    while len > 0 do
        data = nil
        if len > BUFF then
            data = f:read(BUFF)
            len = len - BUFF
        else
            data = f:read(len)
            len = 0
        end
        if data then
            destF:write(data)
        end
        --print('len=',len, data)
    end
    destF:flush()
    destF:close()
end

--解压
function unpack()
    rom_file=io.open('wendal.img','rb')

    print("读取文件头")
    print("文件头"..rom_file:read(5))

    rom_file:seek('set',25)
    print("读取loader的偏移量")
    L_P = readHex(rom_file)
    print("读取loader的长度")
    L_L = readHex(rom_file)
    
    print("读取update.img的偏移量")
    U_P = readHex(rom_file)
    print("读取update.img的长度")
    U_L = readHex(rom_file)
    
    
    print("输出Loader文件")
    readDate(rom_file,L_P,L_L,'RK29xxLoader(L).bin')
    print("输出updata.img")
    readDate(rom_file,U_P,U_L,'update.img')
    
    print("解压updata.img到Temp文件夹")
    os.execute('AFPTool.exe -unpack update.img Temp\\')
    
    print("解压system.img到system文件夹")
    os.execute('cramfsck_nocrc -x system Temp\\Image\\system.img')
    
    print("开启root权限")
    os.execute('copy /B su system\\bin\\su >nul')
    os.execute('copy /B Superuser.apk system\\app\\ >nul')
    os.execute('chmod -R 0777 system/*')
    os.execute('chmod 6755 system/bin/su')
    os.execute('chmod 6755 system/app/Superuser.apk')
    print('解包工作 -- 全部完成')
end