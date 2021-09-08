function DisplayModel(InputFileName, ...
    ShapeType,dAmp,xLoc,yLoc,xPixels,yPixels,nEigen)
% 显示Opensees模型 
% 将所有.tcl文件复制到DisplayFiles中
% 键入任意字符结束窗口
%
% 输入(默认可以输入[]):
% InputFileName - 要显示的.tcl文件名 'main.tcl'
% ShapeType - 'ModeShape', 'NodeNumbers' , 'DeformedShape'
% dAmp - 放大系数
% xLoc,yLoc - 窗口左下角位置(pixel)
% xPixels,yPixels - 窗口宽度
% nEigen - 模态

if nargin==1
    ShapeType = 'ModeShape';
    dAmp = 5;
    xLoc = 10;
    yLoc = 10;
    xPixels = 512;
    yPixels = 384;
    nEigen = 1;
elseif nargin==8
    if isempty(ShapeType)
        ShapeType = 'ModeShape';
    end
    if isempty(dAmp)
        dAmp = 5;
    end
    if isempty(xLoc)
        xLoc = 10;
    end
    if isempty(yLoc)
        yLoc = 10;
    end
    if isempty(xPixels)
        xPixels = 512;
    end
    if isempty(yPixels)
        yPixels = 384;
    end
    if isempty(nEigen)
        nEigen = 1;
    end
else
    warning('输入参数有误！');
    return;
end

MainFileName = 'TempFile.tcl';
fileID = fopen(MainFileName,'w','n','UTF-8');

% 定义参数
fprintf(fileID, '# Created by Matlab script\r\n');
fprintf(fileID, 'set ShapeType "%s";\r\n', ShapeType);
fprintf(fileID, 'set dAmp %f;\r\n', dAmp);
fprintf(fileID, 'set xLoc %i;\r\n', int32(xLoc));
fprintf(fileID, 'set yLoc %i;\r\n', int32(yLoc));
fprintf(fileID, 'set xPixels %i;\r\n', int32(xPixels));
fprintf(fileID, 'set yPixels %i;\r\n', int32(yPixels));
fprintf(fileID, 'set nEigen %i;\r\n', int32(nEigen));

% 引用.tcl文件
fprintf(fileID, 'source DisplayPlane.tcl;\r\n');
fprintf(fileID, 'source DisplayModel2D.tcl;\r\n');
fprintf(fileID, 'cd "./DisplayFiles";\r\n');
fprintf(fileID, 'source "%s";\r\n',InputFileName);
fprintf(fileID, 'cd "../";\r\n');
fprintf(fileID, 'DisplayModel2D $ShapeType $dAmp $xLoc $yLoc $xPixels $yPixels $nEigen;\r\n');
fprintf(fileID, 'gets stdin;\r\n'); 
fclose(fileID);

system(['OpenSees ',MainFileName,' &']);
delete(MainFileName);


end