clear all; clc
xyz_ecef(1) = 2300;
xyz_ecef(2) = 1220;
xyz_ecef(3) = 6000;

ref_ecef = [0 0 0];
ref_llh = [0 0 0];

[llh] = convert_ecef2llh(xyz_ecef, 'rad')
[xyz_enu] = convert_ecef2enu(xyz_ecef, ref_ecef)
[xyz_ned] = convert_ecef2ned(xyz_ecef, ref_ecef)

xyz_enu = [200 3000 150]
[xyz_ecef] = convert_enu2ecef(xyz_enu, ref_ecef)
[llh] = convert_enu2llh(xyz_enu, ref_llh, 'rad')

llh = [1.5769 0.47333 12];
[xyz_ecef] = convert_llh2ecef(llh, 'rad')
[xyz_enu] = convert_llh2enu(llh, ref_llh, 'rad')
[xyz_ned] = convert_llh2ned(llh, ref_llh, 'rad')

[xyz_ecef] = convert_ned2ecef(xyz_ned, ref_ecef)
[llh] = convert_ned2llh(xyz_ned, ref_llh, 'rad')