# DEFINIZIONE DEI PARAMETRI INIZIALI DELLA SIMULAZIONE
L_channel = 40e-9 # m
ratio_I_onoff = 5e4
T_si = L_channel / 4 # improve the electrostability control
T_BOX = 50e-9 # m
Spacer = 10e-9 # m materiale Si3N4
gate_high = 50e-9 # m
t_ox = 1.5e-9 # m
c_ox = 3.9 * 8.854e-12 / t_ox # F/m^2
width_mos = 200e-9 # m
thickness_sub = 400e-9 # m


#DROGAGGI
n_well_doping = 1e15 # m^-3
p+_doping = 1e20 # m^-3
p-_doping = 5e18 # m^-3

#PARAMETRI INIZIALI PER SENTAURUS PROCESS
