print('RK29xx Image Pack/Unpack Tools')
print('Blog http://wendal.net')
print('Project: https://github.com/wendal/teclast_tools')
print('feedback: pad@wendal.net')


function readHex(f)
    local D1 = string.byte(f:read(1))
    local D2 = string.byte(f:read(1))
    local D3 = string.byte(f:read(1))
    local D4 = string.byte(f:read(1))
    --D = D1 + D2 *256 8 + D3 * 256 * 256 + D4 *256*256*256
    return D1 + D2 *256 + D3 * 256 * 256 + D4 *256*256*256
end

dofile('BYTE.lua')

function writeHex(f,num)
    local str = string.format('%08X',num)
    local D1 = tonumber(string.sub(str,7),16)
    local D2 = tonumber(string.sub(str,5,6),16)
    local D3 = tonumber(string.sub(str,3,4),16)
    local D4 = tonumber(string.sub(str,1,2),16)
    --print(str)
    --print(D1,D2,D3,D4)
    f:write(B[D1 + 1])
    f:write(B[D2 + 1])
    f:write(B[D3 + 1])
    f:write(B[D4 + 1])
end

BUFF=8192

function readDate(f,pos,len,dest)
    print(string.format('offset(0x%X) len(0x%X)',pos,len))
    f:seek('set',pos)
    local destF = io.open(dest, 'wb+')
    while len > 0 do
        local data = nil
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

--unpack
function unpackROM()
    print("Pls copy Image file into this folder,and rename to wendal.img \nNotify any errors!")
    os.execute('pause')
    local rom_file=io.open('wendal.img','rb')

    if not rom_file then
        print("wendal.img not found!!")
        return
    end

    print("Reading file header...")
    print("File header: "..rom_file:read(5))

    rom_file:seek('set',25)
    print("Read loader's offset")
    local L_P = readHex(rom_file)
    print("Read loader's len")
    local L_L = readHex(rom_file)
    
    print("Read update.img's offset")
    local U_P = readHex(rom_file)
    print("Read update.img's len")
    local U_L = readHex(rom_file)

    
    print("Output Loader")
    readDate(rom_file,L_P,L_L,'RK29xxLoader(L).bin')
    print("Output updata.img")
    readDate(rom_file,U_P,U_L,'update.img')
    
    print("Unpack updata.img to Temp folder")
    os.execute('AFPTool.exe -unpack update.img Temp\\')
    
    print("Unpack system.img to system folder")
    os.execute('cramfsck -x system Temp/Image/system.img')
    
    print("Enable root permission")
    os.execute('copy /B su system\\bin\\ >nul')
    os.execute('copy /B Superuser.apk system\\app\\ >nul')
    os.execute('chmod -R 0777 system/*')
    os.execute('chmod 6755 system/bin/su')
    os.execute('chmod 6755 system/app/Superuser.apk')

    print('Unpack -- All Done')
    rom_file:close()
end

--´ò°ü
function packROM()
    local SYSTEM_DIR = io.open('system/build.prop','r')
    if SYSTEM_DIR then
        SYSTEM_DIR:close()
        --os.execute('chmod -R 777 system/*')
        print('Packing system folder to system.img,overwrite to Temp\\Image\\system.img')
        os.execute('mkcramfs -q system Temp/Image/system.img')
    end

    print('Packing files in Temp folder to update_new.img')
    os.execute('Afptool -pack ./Temp update_new.img')
    
    print('Get loader\'s and update_new.img\'s file len')
    local L_P = 0x66 -- Loader's offset
    local loader_file = io.open('RK29xxLoader(L).bin','rb+')
    local L_L = loader_file:seek('end')
    loader_file:seek('set',0) -- back to start of file

    U_P = L_P + L_L -- update.img's offset, following loader
    local update_file = io.open('update_new.img','rb+')
    local U_L = update_file:seek('end')
    update_file:seek('set',0) -- back to start of file

    local T_File = io.open('wendal.img', 'rb+') -- open pre-packed image
    local DestF = io.open('wendal_new.img', 'wb+') --open target file
    local data = T_File:read(25)
    DestF:write(data)
    writeHex(DestF,L_P)
    writeHex(DestF,L_L)
    writeHex(DestF,U_P)
    writeHex(DestF,U_L)
    T_File:read(16) -- sjip 16 bytes , data is Unkown!!
    data = T_File:read(102 - 25 - 16)
    DestF:write(data)
    DestF:flush()
    T_File:close()
    print('Start writing loader')
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
    print('Start writing update.img')
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
    print('calculate MD5')
    os.execute('md5sums.exe -u wendal_new.img > md5.txt')
    local M_File = io.open('md5.txt','r')
    local md5 = M_File:read(32)
    M_File:close()
    print('MD5='..md5)
    print('Write MD5 into wendal_new.img')
    DestF = io.open('wendal_new.img', 'ab+') --open target file
    DestF:seek('end')
    DestF:write(md5)
    DestF:flush()
    DestF:close()
    print('Pack completa!! Target file --> wendal_new.img')
end


while true do
    print('Pls input: 1-Unpack 2-Pack 3-Exit')
    local m = io.read('*n')
    if m == 1 then
        unpackROM()
    elseif m == 2 then
        packROM()
    elseif m == 3 then
        os.exit(1)
    end
end