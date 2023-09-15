try
    pyrun(['import ballz']);
catch ME
    err_msg = sprintf("dumb error!\n%s\n%s", ME.message);
    disp(err_msg)
end