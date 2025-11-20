
function [tf] = pasaPorPiPf(points,coefs)
    y1 = fix(polyval(coefs, points(1,1)));
    y2 = fix(polyval(coefs, points(4,1)));
    
    tf = (y1 == points(1,2) && y2 == points(4,2));

end

