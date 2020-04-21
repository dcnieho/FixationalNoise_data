function [pixpercm,pixperdeg,pix2degScaleFunc] = getPixConvs(scrSz,scrRes,viewDist)

pixpercm                    = mean(scrRes./scrSz);
degpercm                    = 2*(atand(1/(2*viewDist)));
pixperdeg                   = pixpercm/degpercm;
pix2degScaleFunc            = @(x,y) sec(atan(hypot(x,y)/pixpercm/viewDist))^2;  % sec()^2 is amount by which distances on screen increase with eccentricity for constant angle. atan bit is angle from center for position on screen at viewDist
