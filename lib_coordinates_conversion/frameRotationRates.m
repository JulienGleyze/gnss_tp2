function [Rnav, Rnav_EI,Rnav_NE, dRnav_EI_Lat, dRnav_NE_Lat, dRnav_NE_H, dRnav_NE_Vel] = frameRotationRates(llh,vel)

earthRotationRate		= 7.2921151e-5;

lat = llh(1);
lon = llh(2);
h   = llh(3);

%if strcmp(frame, 'ned')
vn = vel(1);
ve = vel(2);
vd = vel(3);
%end

[Rlat, Rlon, R0lat, R0lon] = local_radius(llh, 'rad');

Rnav_NE	= [(ve/(R0lon+h));...  
				(-(vn/(R0lat+h)));... 
				(-(ve*tan(lat))/(R0lon+h))]  ;

Rnav_EI	= [(earthRotationRate*cos(lat));...  
					0;...   
					(earthRotationRate*(-sin(lat)))] ;

Rnav		= Rnav_NE + Rnav_EI;

dRnav_EI_Lat	= [(-earthRotationRate*sin(lat))...  
								 0 ...
								(-earthRotationRate*(cos(lat)))] ;

dRnav_NE_Lat = [0; ...
								 0 ;...
								 (-ve) / ( (cos(lat)*cos(lat))*(R0lon+h) )];

dRnav_NE_H	= [(-ve) / ((R0lon+h)*(R0lon+h));... 
									(vn) / ( (R0lat+h)*(R0lat+h) );... 
									 (ve*tan(lat)) / ( (R0lon+h)*(R0lon+h) )];

dRnav_NE_Vel	= [ 0  (1/(R0lon+h))  0;... 
								   -1/(R0lat+h)  0  0;... 
									 0  -tan(lat)/(R0lon+h)  0] ;

end