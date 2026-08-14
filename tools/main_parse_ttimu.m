% main_parse_ttimu.m —— TurtleIMU .bin 数据解析主脚本
%
% 使用方法：
%   1. 把本脚本、parse_ttimu.m 与你的 .bin 文件放在同一目录
%      （或在 MATLAB 中把该目录加入路径）
%   2. 根据需要修改下面的 file 变量（留空则自动选择目录中最新的 .bin 文件）
%   3. 直接点「运行」：解析数据并绘图
%
% 设置 saveVar = true 后，解析结果会保存到工作区变量 data，常用字段：
%   data.timeSec                相对时间（秒）
%   data.gyro.x / .y / .z       陀螺仪 (°/s)
%   data.acc.x / .y / .z        加速度 (m/s²，含重力)
%   data.mag.x / .y / .z        磁力计 (µT)
%   data.att.pitch / roll / azimuth   姿态角 (°)
%   data.gps.lat / lon / alt / speed   定位与速度
%   data.temp.env               环境温度 (°C)
%   data.flags                  各组数据有效性位掩码
%
% 详细文件格式说明见 parse_ttimu.m 文件头注释。

% ---- 用户设置 ----
file    = '';     % 例如 'TurtleIMU_20260814_211316.bin'；留空则自动选最新 .bin
doPlot  = true;   % true = 解析并绘图；false = 只解析不绘图
saveVar = false;  % true = 把结果保存到工作区变量 data；false = 不保存（默认）

% ---- 自动选择文件 ----
if isempty(file)
    list = dir('*.bin');
    if isempty(list)
        error(['当前目录没有 .bin 文件。' newline ...
               '请把上面的 file 变量改为你的文件路径（含文件名）。']);
    end
    [~, idx] = max([list.datenum]);
    file = list(idx).name;
    fprintf('未指定文件，自动选择最新文件: %s\n', file);
end

% ---- 解析（并绘图）----
if saveVar
    data = parse_ttimu(file, doPlot);
    fprintf('解析完成，结果已保存到工作区变量 data（如 data.gyro、data.att、data.gps）。\n');
else
    parse_ttimu(file, doPlot);
    fprintf('解析完成。如需在工作区保存结果，请把 saveVar 改为 true 后重新运行。\n');
end
