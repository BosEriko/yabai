on run argv
    set launcher to item 1 of argv
    set appId to item 2 of argv
    set spaceId to item 3 of argv
    set launchCommand to "/bin/sh " & quoted form of launcher & " install " & quoted form of appId & " " & quoted form of spaceId
    tell application "Terminal"
        do script launchCommand
        activate
    end tell
end run
