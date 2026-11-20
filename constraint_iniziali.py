# DEFINIZIONE DEI PARAMETRI INIZIALI DELLA SIMULAZIONE
# Questo file e' la UNICA fonte dei parametri: genera_sprocess.py lo legge e
# rigenera sprocess_fps.cmd. Unita': lunghezze in m, drogaggi in cm^-3
# (come in Sentaurus), dosi in cm^-2.

L_channel = 40e-9          # m
ratio_I_onoff = 5e4
T_si = L_channel / 4       # m, improve the electrostatic control
T_BOX = 50e-9              # m
Spacer = 10e-9             # m, materiale Si3N4
gate_high = 50e-9          # m
t_ox = 1.5e-9              # m
c_ox = 3.9 * 8.854e-12 / t_ox  # F/m^2
width_mos = 200e-9         # m
thickness_sub = 400e-9     # m


# DROGAGGI [cm^-3]
n_well_doping = 1e15       # corpo/canale di tipo n (pMOS)
p_plus_doping = 1e20       # source/drain
p_minus_doping = 5e18      # LDD / extension


# PARAMETRI INIZIALI PER SENTAURUS PROCESS
Al_thickness = 30e-9       # m, contatti in alluminio

# Dose [cm^-2] = concentrazione media voluta [cm^-3] x spessore del film [cm].
# E' una prima stima: va verificata sul profilo (file .plx) dopo l'annealing.
dose_sd = p_plus_doping * T_si * 100
dose_ldd = p_minus_doping * T_si * 100

# Energie dell'impianto di Boro [keV]: valori iniziali da tarare (Rp ~ T_si/3 - T_si/2).
E_sd_keV = 1.0
E_ldd_keV = 0.5

# Tempi di annealing [s] (1050 C). Sono ancora quelli del tutorial 0.18 um:
# con Lg = 40 nm e film da 10 nm probabilmente vanno ridotti.
t_act_ldd_s = 0.1
t_rta_ldd_s = 5.0
t_rta_final_s = 10.0