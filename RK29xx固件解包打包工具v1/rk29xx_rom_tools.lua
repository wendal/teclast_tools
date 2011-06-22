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

dofile('BYTE.lua')

function writeHex(f,num)
    str = string.format('%08X',num)
    D1 = tonumber(string.sub(str,7),16)
    D2 = tonumber(string.sub(str,5,6),16)
    D3 = tonumber(string.sub(str,3,4),16)
    D4 = tonumber(string.sub(str,1,2),16)
    print(str)
    print(D1,D2,D3,D4)
    f:write(B[D1 + 1])
    f:write(B[D2 + 1])
    f:write(B[D3 + 1])
    f:write(B[D4 + 1])
end

BUFF=8192

function readDate(f,pos,len,dest)
    print(string.format('偏移量(0x%X) 长度(0x%X)',pos,len))
    f:seek('set',pos)
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
function unpackROM()
    print("请将固件放到本工具的文件夹,并改名为wendal.img \n请留意任何出错信息")
    os.execute('pause')
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
    os.execute('AFPTool.exe -unpack update.img Temp')
    
    print("解压system.img到system文件夹")
    os.execute('cramfsck -x system Temp/Image/system.img')
    
    print("开启root权限")
    os.execute('copy /B su system/bin/su >nul')
    os.execute('copy /B Superuser.apk system/app/ >nul')
    os.execute('chmod -R 0777 system/*')
    os.execute('chmod 6755 system/bin/su')
    os.execute('chmod 6755 system/app/Superuser.apk')

    print("尝试解开boot.img ...")
    print("创建临时文件")
    BootImg = io.open('Temp/Image/boot.img','rb')
    if BootImg then
        BootImg:seek('end')
        B_Size = BootImg:seek() - 8
        BootImg:seek('set',0)
        readDate(BootImg,8,B_Size,'Temp/Image/boot.gz')
        print("尝试解压boot.gz")
        os.execute('gzip -d -f Temp/Image/boot.gz')
        BootImg:close()
        bFile = io.open('Temp/Image/boot','rb')
        if bFile then
            bFile:close()
            print("哦Yes! gzip解压成功,继续下一步cpio解压")
            os.execute('unpackBoot.bat')
        end
    end

    print('解包工作 -- 全部完成')
    rom_file:close()
end

--打包
function packROM()
    SYSTEM_DIR = io.open('system/build.prop','r')
    if SYSTEM_DIR then
        SYSTEM_DIR:close()
        print('将system重新打包为system.img,覆盖到Temp\\Image\\system.img')
        os.execute('mkcramfs -q system Temp/Image/system.img')
    end

    BOOT_DIR = io.open('boot/init','rb')
    if BOOT_DIR then
        BOOT_DIR:close()
        print('将boot重新打包为boot.img,覆盖到Temp\\Image\\boot.img')
        os.execute('packBoot.bat')
        BOOT_FILE = io.open('Temp/boot.gz','rb')
        if BOOT_FILE then
            print("压缩完成,开始写入boot.img")
            BOOT_FILE:seek('end')
            B_L = BOOT_FILE:seek()
            BOOT_FILE:seek('set',0)
            os.execute('del Temp\\Image\\boot.img')
            BOOT_IMG = io.open('Temp//Image//boot.img','wb+')
            BOOT_IMG:write('KRNL')
            writeHex(BOOT_IMG,B_L)
            data = 0
            while B_L > 0 do
                if B_L > BUFF then
                    data = BOOT_FILE:read(BUFF)
                    B_L = B_L - BUFF
                else
                    data = BOOT_FILE:read(B_L)
                    B_L = 0
                end
                BOOT_IMG:write(data)
            end
            BOOT_IMG:flush()
            BOOT_IMG:close()
            print("成功写入boot.img")
            BOOT_FILE:close()
        end
    end

    print('将Temp中的文件,打包为update_new.img文件')
    os.execute('Afptool -pack ./Temp update_new.img')
    
    print('获取loader和update_new.img的文件大小')
    L_P = 0x66 -- Loader的固定偏移量
    loader_file = io.open('RK29xxLoader(L).bin','rb+')
    L_L = loader_file:seek('end')
    loader_file:seek('set',0) -- 恢复到文件起始位置

    U_P = L_P + L_L -- update.img的偏移量,紧跟着loader
    update_file = io.open('update_new.img','rb+')
    U_L = update_file:seek('end')
    update_file:seek('set',0) -- 恢复到文件起始位置

    T_File = io.open('wendal.img', 'rb+') -- 打开模板文件
    DestF = io.open('wendal_new.img', 'wb+') --开启目标文件
    data = T_File:read(25)
    DestF:write(data)
    writeHex(DestF,L_P)
    writeHex(DestF,L_L)
    writeHex(DestF,U_P)
    writeHex(DestF,U_L)
    T_File:read(16) -- 跳过16字节
    data = T_File:read(102 - 25 - 16)
    DestF:write(data)
    DestF:flush()
    T_File:close()
    print('开始写入loader')
    while L_L > 0 do
        if L_L > BUFF then
            data = loader_file:read(BUFF)
            L_L = L_L - BUFF
        else
            data = loader_file:read(L_L)
            L_L = 0
        end
        DestF:write(data)
    end
    print('开始写入update.img')
    while U_L > 0 do
        if U_L > BUFF then
            data = update_file:read(BUFF)
            U_L = U_L - BUFF
        else
            data = update_file:read(U_L)
            U_L = 0
        end
        DestF:write(data)
    end
    DestF:flush()
    DestF:close()
    print('计算MD5')
    os.execute('md5sums.exe -u wendal_new.img > md5.txt')
    M_File = io.open('md5.txt','r')
    md5 = M_File:read(32)
    print('MD5='..md5)
    print('将MD5写入wendal_new.img')
    DestF = io.open('wendal_new.img', 'ab+') --开启目标文件
    DestF:seek('end')
    DestF:write(md5)
    DestF:flush()
    DestF:close()
    print('打包完成!! 目标文件wendal_new.img')
end


while true do
    print('请输入功能号码: 1-解包 2-打包 3-退出')
    m = io.read('*n')
    if m == 1 then
        unpackROM()
    elseif m == 2 then
        packROM()
    elseif m == 3 then
        os.exit(1)
    end
end