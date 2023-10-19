pythonPath = char(pyenv().Executable);
disp(pythonPath)
if ispc
% on windows we want to use python.exe not pythonw
    [fp, ~, ~] = fileparts(pythonPath);
    pip_cmd = [fp, '\', 'python.exe -m pip install'];
else
    pip_cmd = [pythonPath, ' -m pip install'];
end
% install pylsl
res = system([pip_cmd, ' scipy']);
if res == 1
    disp('Issue installing scipy!')
else
    disp('Successfully installed Scipy!')
end
res = system([pip_cmd, ' pylsl']);
if res == 1
    disp('Issue installing pylsl!')
else
    disp('Successfully installed pylsl!')
end
res = system([pip_cmd, ' numpy']);
if res == 1
    disp('Issue installing numpy!')
else
    disp('Successfully installed numpy!')
end
