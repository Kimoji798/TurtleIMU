function data = parse_ttimu(file, doPlot)
%PARSE_TTIMU 解析 TurtleIMU 数据记录 .bin 文件，并可选绘图
%
% 用法：
%   推荐直接运行 main_parse_ttimu.m（主脚本，自动选文件并绘图）；
%   本文件为解析函数，也可单独调用：
%   data = parse_ttimu('TurtleIMU_20260814_123456.bin');   % 只解析
%   data = parse_ttimu('TurtleIMU_20260814_123456.bin', true); % 解析并绘图
%
% 返回 struct data，主要字段：
%   data.t         采样时刻（epoch 毫秒，double 列向量）
%   data.timeSec    相对时间（秒）
%   data.gyro       .x .y .z   (°/s, single)
%   data.acc        .x .y .z   (m/s²，含重力, single)
%   data.mag        .x .y .z   (µT, single；iPhone 无数据时全为 NaN)
%   data.att        .pitch .roll .azimuth   (°, single；azimuth 为 0~360)
%   data.gps        .lat .lon .alt(m) .speed(m/s)
%   data.temp       .env        (°C, single)
%   data.flags      uint32 位掩码：bit1 陀螺仪, bit2 加速度, bit3 磁力计,
%                            bit4 姿态角, bit5 GPS, bit6 温度
%   data.valid      对应字段的有效性 logical 掩码
%   data.demo       是否演示模式
%   data.rateHz     设定采样频率
%
% 文件格式（小端 Little-Endian）：
%   文件头 32 字节：帧头 0x55 0xAA(2B) + version u8 + flags u8 + recordSize u16
%                   + rateHz u16 + reserved u32 + epochBase f64 + startPerf f64 + reserved u32
%   每帧 88 字节：  t f64 | gyro x/y/z f32*3 | acc x/y/z f32*3 | mag x/y/z f32*3
%                   | pitch/roll/azimuth f32*3 | lat f64 | lon f64 | alt f32
%                   | speed f32 | temp f32 | flags u32
%   无有效数据的字段写入 NaN，并以 flags 位标记该组是否有效。

if nargin < 1 || isempty(file)
    error('请传入 .bin 文件路径，例如 parse_ttimu(''xxx.bin'')');
end
if nargin < 2, doPlot = false; end

fid = fopen(file, 'r', 'ieee-le');
if fid < 0, error('无法打开文件: %s', file); end
cleanup = onCleanup(@() fclose(fid));

% ---- 文件头 ----
h0 = fread(fid, 4, 'uint8');
if ~(h0(1) == hex2dec('55') && h0(2) == hex2dec('AA'))
    error('帧头不是 0x55AA（前两字节为 [%d %d]）', h0(1), h0(2));
end
version = h0(3);
hflags  = h0(4);
recSize = fread(fid, 1, 'uint16');
rateHz  = fread(fid, 1, 'uint16');
fread(fid, 1, 'uint32');            % reserved
epochBase = fread(fid, 1, 'float64');
startPerf = fread(fid, 1, 'float64');
fread(fid, 1, 'uint32');            % reserved

% ---- 数据帧 ----
info = dir(file);
frameBytes = info.bytes - 32;
if frameBytes <= 0
    error('文件中没有数据帧');
end
n = floor(frameBytes / recSize);
if mod(frameBytes, recSize) ~= 0
    warning('文件末尾有 %d 字节残缺数据，已忽略', mod(frameBytes, recSize));
end
F = fread(fid, [recSize, n], 'uint8=>uint8');

% ---- 按字节偏移解析（小端）----
data = struct();
data.file     = file;
data.version  = version;
data.demo     = bitand(hflags, 1) > 0;
data.rateHz   = double(rateHz);
data.epochBase = epochBase;
data.startPerf = startPerf;
data.recSize  = double(recSize);
data.n        = n;

data.t       = typecast(reshape(F(1:8, :), [], 1), 'double');   % epoch 毫秒
data.timeSec = (data.t - data.t(1)) / 1000;      % 相对秒
data.flags   = typecast(reshape(F(85:88, :), [], 1), 'uint32');

data.gyro.x = typecast(reshape(F(9:12, :), [], 1), 'single');
data.gyro.y = typecast(reshape(F(13:16, :), [], 1), 'single');
data.gyro.z = typecast(reshape(F(17:20, :), [], 1), 'single');
data.acc.x  = typecast(reshape(F(21:24, :), [], 1), 'single');
data.acc.y  = typecast(reshape(F(25:28, :), [], 1), 'single');
data.acc.z  = typecast(reshape(F(29:32, :), [], 1), 'single');
data.mag.x  = typecast(reshape(F(33:36, :), [], 1), 'single');
data.mag.y  = typecast(reshape(F(37:40, :), [], 1), 'single');
data.mag.z  = typecast(reshape(F(41:44, :), [], 1), 'single');
data.att.pitch   = typecast(reshape(F(45:48, :), [], 1), 'single');
data.att.roll    = typecast(reshape(F(49:52, :), [], 1), 'single');
data.att.azimuth = typecast(reshape(F(53:56, :), [], 1), 'single');
data.gps.lat  = typecast(reshape(F(57:64, :), [], 1), 'double');
data.gps.lon  = typecast(reshape(F(65:72, :), [], 1), 'double');
data.gps.alt  = typecast(reshape(F(73:76, :), [], 1), 'single');
data.gps.speed = typecast(reshape(F(77:80, :), [], 1), 'single');
data.temp.env = typecast(reshape(F(81:84, :), [], 1), 'single');

% ---- 有效性掩码（对应 flags 位）----
ok.gyro = bitand(data.flags, 1)  > 0;
ok.acc  = bitand(data.flags, 2)  > 0;
ok.mag  = bitand(data.flags, 4)  > 0;
ok.att  = bitand(data.flags, 8)  > 0;
ok.gps  = bitand(data.flags, 16) > 0;
ok.temp = bitand(data.flags, 32) > 0;
data.valid = ok;

% ---- 命令行摘要 ----
dur = double(data.t(end) - data.t(1)) / 1000;
fprintf('\n==== TurtleIMU 数据文件 ====\n');
fprintf('文件: %s\n', data.file);
fprintf('帧数: %d   时长: %.2f s   设定频率: %d Hz   实际: %.2f Hz\n', ...
    n, dur, data.rateHz, (n - 1) / max(dur, eps));
fprintf('有效帧占比: 陀螺仪 %.1f%%  加速度 %.1f%%  磁力计 %.1f%%  姿态 %.1f%%  GPS %.1f%%  温度 %.1f%%\n', ...
    100 * nnz(ok.gyro) / n, 100 * nnz(ok.acc) / n, 100 * nnz(ok.mag) / n, ...
    100 * nnz(ok.att) / n, 100 * nnz(ok.gps) / n, 100 * nnz(ok.temp) / n);
fprintf('数据有无: 陀螺仪 %s  加速度 %s  磁力计 %s  姿态角 %s  GPS %s  温度 %s\n', ...
    tf(any(ok.gyro)), tf(any(ok.acc)), tf(any(ok.mag)), ...
    tf(any(ok.att)), tf(any(ok.gps)), tf(any(ok.temp)));
if data.demo, fprintf('注意: 该文件为演示模式（模拟数据）。\n'); end
fprintf('================================\n\n');

if ~doPlot, return; end

% ---- 绘图 ----
t = data.timeSec;
figure('Name', sprintf('TurtleIMU 回放: %s', data.file), 'Color', 'w', ...
    'NumberTitle', 'off');

% 1) 陀螺仪
subplot(4, 2, 1); hold on; grid on; box on;
if any(ok.gyro)
    plot(t, data.gyro.x, 'r', t, data.gyro.y, 'g', t, data.gyro.z, 'b');
    legend('X', 'Y', 'Z', 'Location', 'best');
end
title('陀螺仪'); ylabel('°/s'); xlabel('t (s)');

% 2) 加速度计（含重力）
subplot(4, 2, 2); hold on; grid on; box on;
if any(ok.acc)
    plot(t, data.acc.x, 'r', t, data.acc.y, 'g', t, data.acc.z, 'b');
    legend('X', 'Y', 'Z', 'Location', 'best');
end
title('加速度计'); ylabel('m/s²'); xlabel('t (s)');

% 3) 磁力计
subplot(4, 2, 3); hold on; grid on; box on;
if any(ok.mag)
    plot(t, data.mag.x, 'r', t, data.mag.y, 'g', t, data.mag.z, 'b');
    legend('X', 'Y', 'Z', 'Location', 'best');
else
    text(0.5, 0.5, '无磁力计数据（如 iPhone）', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center');
end
title('磁力计'); ylabel('µT'); xlabel('t (s)');

% 4) 姿态角
subplot(4, 2, 4); hold on; grid on; box on;
if any(ok.att)
    plot(t, data.att.pitch, 'r', t, data.att.roll, 'g', t, data.att.azimuth, 'b');
    legend('俯仰', '横滚', '方位', 'Location', 'best');
end
title('姿态角'); ylabel('°'); xlabel('t (s)');

% 5) 经纬轨迹
subplot(4, 2, 5); hold on; grid on; box on;
if any(ok.gps)
    plot(data.gps.lon(ok.gps), data.gps.lat(ok.gps), '.-');
    axis equal;
else
    text(0.5, 0.5, '无定位数据', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center');
end
title('GPS 轨迹'); xlabel('经度 °'); ylabel('纬度 °');

% 6) 高度
subplot(4, 2, 6); hold on; grid on; box on;
if any(ok.gps)
    plot(t, data.gps.alt, '-');
else
    text(0.5, 0.5, '无定位数据', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center');
end
title('高度'); ylabel('高度 m'); xlabel('t (s)');

% 7) 速度
subplot(4, 2, 7); hold on; grid on; box on;
if any(ok.gps)
    plot(t, data.gps.speed, '-');
else
    text(0.5, 0.5, '无定位数据', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center');
end
title('速度'); ylabel('速度 m/s'); xlabel('t (s)');

% 8) 环境温度
subplot(4, 2, 8); hold on; grid on; box on;
if any(ok.temp)
    plot(t, data.temp.env, '.-');
else
    text(0.5, 0.5, '无温度数据', 'Units', 'normalized', ...
        'HorizontalAlignment', 'center');
end
title('环境温度'); ylabel('°C'); xlabel('t (s)');


    function s = tf(v)
        if v, s = '有'; else, s = '无'; end
    end
end