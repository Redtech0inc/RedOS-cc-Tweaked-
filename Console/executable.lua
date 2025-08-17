xpcall(function() shell.run("shell") end,function ()
    os.reboot()
end)