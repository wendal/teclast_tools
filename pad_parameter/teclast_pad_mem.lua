print('台电平板固件 内存分配文件parameter修改器')
print('Wendal作品 http://wendal.net')

DATA_NAME = {
misc='核心方法',
kernel='内核',
boot='启动分区',
recovery='恢复分区',
system='系统分区',
backup='备份分区',
cache='缓存分区',
userdata='用户数据区',
kpanic='T760特有分区',
user='数据区'
}

NAMES = {'misc','kernel','boot','recovery','system','backup','cache','userdata','kpanic'}

P_SIZE=512 -- 区块的大小

function printInfo(nameX)
    print(string.format('%-10s %-10s  %10smb',nameX,DATA_NAME[nameX],t[nameX]))
end

function printUserInfo()
    print(string.format('%-10s %-10s  %10smb','user',DATA_NAME['user'],DATA_SIZE))
end

print('尝试读取parameter文件')
f = io.open('parameter')
if not f then
    print('请先将parameter放入本地文件夹!!!')
    os.exit(1)
end
io.close(f)

print('开始读取parameter文件')
lines = io.lines('parameter')
print('读取完成,开始分析')
x = nil
index = 0
for line in lines do
    index = index + 1
    if line and string.find(line,'mtdparts=.+') then
        x = line
        break
    end
end

if not x then
    print('在parameter找不到需要的数据!!!!')
    os.exit(2)
end

mem_str_pos = string.find(x, 'nand')+5
print('在parameter找到需要的数据了')
mem_data_str = string.sub(x,mem_str_pos)
t = {}
DATA_SIZE=8*1024
INIT_POS = -1
for size,pos,nameX in string.gmatch(mem_data_str, '(0x[%x]+)@(0x[%x]+)[(]([%w]+)[)]') do
    size = tonumber(size) / 1024
    t[nameX] = size
    print(string.format('%-10s %-10s  %10smb',nameX,DATA_NAME[nameX],size))
    DATA_SIZE = DATA_SIZE - size
    if INIT_POS == -1 then
        INIT_POS = tonumber(pos)
    end
end
printUserInfo()


print("\n请依次按提示输入各个分区的大小,单位为mb,如不修改,请直接回车跳过\n")
DATA_SIZE=8*1024
for i,nameX in pairs(NAMES) do
    if not t[nameX] then
        break
    end
    print(string.format('%-10s %-10s  现在的大小:%10smb',nameX,DATA_NAME[nameX],t[nameX]))
    newSize = io.read()
    if newSize and string.len(newSize) > 0 then
        t[nameX] = tonumber(newSize)
    end
    DATA_SIZE = DATA_SIZE - t[nameX]
end
print("以下内容将写入文件:")
data_str = ''
pos = INIT_POS
for i,nameX in pairs(NAMES) do
    if not t[nameX] then
        break
    end
    print(string.format('%-10s %-10s  %10smb',nameX,DATA_NAME[nameX],t[nameX]))
    data_str = data_str .. string.format('0x%08X@0x%08X(%s),',t[nameX] * 1024,pos,nameX)
    pos = pos + t[nameX] * 1024
end
printUserInfo()
data_str = data_str .. string.format('-@0x%08X(%s)',pos,'user')

--开始输出文件
--print(data_str)
lines = io.lines('parameter')
f = io.open('parameter_new','w')
i = 0
pre = nil
for line in lines do
    i = i + 1
    if i == index then
        pre = line
        break
    end
    f.write(f, tostring(line) .. '\n')
end

pos = string.find(pre, 'nand')
pre = string.sub(pre, 1,pos - 1)
--print(pre)
f.write(f, pre .. 'nand:' .. data_str)
io.flush(f)

print("成功写入parameter_new文件")