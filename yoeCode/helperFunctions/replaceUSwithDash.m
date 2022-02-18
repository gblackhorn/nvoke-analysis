function newString = replaceUSwithDash(oldString)
    %underscores are annoying in matlab plotting, replacing with dash
    
    USloc = strfind(oldString, '_');
    if (USloc)
        oldString(USloc) = '-';
    end
    
    newString = oldString;