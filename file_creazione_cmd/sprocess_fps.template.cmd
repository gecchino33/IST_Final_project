# 2D pMOSFET on SOI substrate (Sentaurus Process)
# ------------------------------------------------
# TEMPLATE: the fields between double percent signs are filled in by genera_sprocess.py with the
# values of constraint_iniziali.py. Edit this template or the .py file,
# never the generated sprocess_fps.cmd.

math coord.ucs


# Declare initial grid (half structure)
# x = depth (x=0 is the top of the Si film), y = lateral (y=0 is the channel center)
# ----------------------------------------------------------------------------------

line x location= 0.0           spacing= %%film_spacing%%  tag= SiTop
line x location= %%T_si%%      spacing= %%film_spacing%%  tag= BoxTop
line x location= %%x_box_bot%% spacing= 10.0<nm>          tag= BoxBot
line x location= %%x_bottom%%  spacing= 50.0<nm>          tag= SiBottom

line y location= 0.0           spacing= 5.0<nm>           tag= Mid
line y location= %%y_right%%   spacing= 10.0<nm>          tag= Right


# SOI substrate definition: Si film / buried oxide (BOX) / Si handle wafer
# ------------------------------------------------------------------------

region Silicon xlo= SiTop  xhi= BoxTop   ylo= Mid yhi= Right
region Oxide   xlo= BoxTop xhi= BoxBot   ylo= Mid yhi= Right
region Silicon xlo= BoxBot xhi= SiBottom ylo= Mid yhi= Right


# Initialize the simulation (n-type body for a pMOS)
# --------------------------------------------------

init concentration= %%n_body%%<cm-3> field= Phosphorus !DelayFullD

AdvancedCalibration

struct tdr=n@node@_NMOS_substrate0; #substrate


# Global Mesh settings for automatic meshing in newly generated layers
# --------------------------------------------------------------------

grid set.min.normal.size= %%min_normal%% set.normal.growth.ratio.2d= 1.5
mgoals accuracy= 1e-5


# Gate oxide (deposited, so it does not consume the thin Si film)
# ---------------------------------------------------------------

deposit material= {Oxide} type= isotropic time= 1 rate= {%%t_ox_um%%}


# Poly gate deposition
# --------------------

deposit material= {PolySilicon} type= anisotropic time= 1 rate= {%%gate_high_um%%}


# Poly gate pattern/etch
# ----------------------

mask name= gate_mask left=-1 right= %%Lg_half%%

etch material= {PolySilicon} type= anisotropic time= 1 rate= {%%poly_etch_um%%} mask= gate_mask

struct tdr= n@node@_NMOS1;

etch material= {Oxide}       type= anisotropic time= 1 rate= {%%ox_etch_um%%}

struct tdr= n@node@_NMOS2; # PolyGate


# (poly reoxidation removed: it would consume silicon from the thin film)


# LDD implantation (p- extensions)
# --------------------------------

refinebox Silicon min= {0.0 %%ref_ldd_ymin%%} max= {%%T_si_um%% %%ref_ldd_ymax%%} xrefine= {%%ref_dx%% %%ref_dx%% %%ref_dx%%} yrefine= {%%ref_dy%% %%ref_dy%% %%ref_dy%%} add
grid remesh

implant Boron dose= %%dose_ldd%%<cm-2> energy= %%E_ldd%%<keV> tilt= 0 rotation= 0

struct tdr= n@node@_NMOS4 ; # LDD Implant

diffuse temperature= 1050<C> time= %%t_act_ldd%%<s> ; # Quick activation

struct tdr= n@node@_NMOS5 ; # LDD Diffuse


# (halo implants not included: optional, not required by the specification)


# RTA of LDD implants
# -------------------

diffuse temperature= 1050<C> time= %%t_rta_ldd%%<s>

struct tdr= n@node@_NMOS10 ; # LDD RTA


# Nitride spacer
# --------------

deposit material= {Nitride} type= isotropic time= 1 rate= {%%spacer_um%%}

struct tdr= n@node@_NMOS11 ; # Spacer deposition

etch    material= {Nitride} type= anisotropic time= 1 rate= {%%spacer_etch_um%%} isotropic.overetch= %%spacer_overetch_um%%

struct tdr= n@node@_NMOS12 ; # Spacer etch


# P+ source/drain implantation
# ----------------------------

refinebox Silicon min= {0.0 %%sd_ref_ymin%%} max= {%%T_si_um%% %%y_right_um%%} xrefine= {%%ref_dx%% %%ref_dx%% %%ref_dx%%} yrefine= {%%ref_dy_sd%% %%ref_dy_sd%% %%ref_dy_sd%%} add
grid remesh

implant Boron dose= %%dose_sd%%<cm-2> energy= %%E_sd%%<keV> tilt= 7<degree> rotation= -90<degree>

struct tdr= n@node@_NMOS14 ; # P+ implantation


# Final RTA
# ---------------------------

diffuse temperature= 1050<C> time= %%t_rta_final%%<s>

struct tdr= n@node@_NMOS15 ; # Final RTA


# Contacts
# --------

deposit material= {Aluminum} type= isotropic time= 1 rate= {%%al_um%%}

struct tdr= n@node@_NMOS16 ; # Aluminium deposition

mask name= contacts_mask left= %%contact_left%% right= 1.0<um>
etch material= {Aluminum} type= anisotropic time= 1 rate= {0.25} mask= contacts_mask

struct tdr= n@node@_NMOS17 ; # Aluminium etching 1

mask name= gate_mask2 left=-1 right= %%gate_contact_half%% negative
deposit material= {Aluminum} type= anisotropic time= 1 rate= {%%al_um%%} mask= gate_mask2

struct tdr= n@node@_NMOS18 ; # Gate contact creation


# Reflect
# -------

transform reflect left


# save final structure:
#  - 1D cross sections

struct tdr= n@node@_NMOS20 ; # Final

SetPlxList   {BTotal NetActive}
WritePlx n@node@_NMOS_channel.plx  y=0.0 Silicon

SetPlxList   {PTotal BTotal NetActive}
WritePlx n@node@_NMOS_ldd.plx y=%%y_prof_ldd%% Silicon

SetPlxList   {PTotal BTotal NetActive}
WritePlx n@node@_NMOS_sd.plx y=%%y_prof_sd%% Silicon


# Contacts
# -------

contact bottom name = substrate Silicon

contact name = gate x = %%x_gate_contact%% y = 0.0 Aluminum

contact name = source x = %%x_sd_contact%% y = %%y_contact_neg%% Aluminum

contact name = drain x = %%x_sd_contact%% y = %%y_contact_pos%% Aluminum

struct tdr= n@node@_presimulation

exit