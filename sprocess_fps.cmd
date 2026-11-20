# GENERATED 2026-11-20 11:48:04 by genera_sprocess.py
# from constraint_iniziali.py + sprocess_fps.template.cmd -- DO NOT EDIT BY HAND

# 2D pMOSFET on SOI substrate (Sentaurus Process)
# ------------------------------------------------
# TEMPLATE: the fields between double percent signs are filled in by genera_sprocess.py with the
# values of constraint_iniziali.py. Edit this template or the .py file,
# never the generated sprocess_fps.cmd.

math coord.ucs


# Declare initial grid (half structure)
# x = depth (x=0 is the top of the Si film), y = lateral (y=0 is the channel center)
# ----------------------------------------------------------------------------------

line x location= 0.0           spacing= 1<nm>  tag= SiTop
line x location= 10<nm>      spacing= 1<nm>  tag= BoxTop
line x location= 60<nm> spacing= 10.0<nm>          tag= BoxBot
line x location= 460<nm>  spacing= 50.0<nm>          tag= SiBottom

line y location= 0.0           spacing= 5.0<nm>           tag= Mid
line y location= 100<nm>   spacing= 10.0<nm>          tag= Right


# SOI substrate definition: Si film / buried oxide (BOX) / Si handle wafer
# ------------------------------------------------------------------------

region Silicon xlo= SiTop  xhi= BoxTop   ylo= Mid yhi= Right
region Oxide   xlo= BoxTop xhi= BoxBot   ylo= Mid yhi= Right
region Silicon xlo= BoxBot xhi= SiBottom ylo= Mid yhi= Right


# Initialize the simulation (n-type body for a pMOS)
# --------------------------------------------------

init concentration= 1.000e+15<cm-3> field= Phosphorus !DelayFullD

AdvancedCalibration

struct tdr=n@node@_NMOS_substrate0; #substrate


# Global Mesh settings for automatic meshing in newly generated layers
# --------------------------------------------------------------------

grid set.min.normal.size= 0.5<nm> set.normal.growth.ratio.2d= 1.5
mgoals accuracy= 1e-5


# Gate oxide (deposited, so it does not consume the thin Si film)
# ---------------------------------------------------------------

deposit material= {Oxide} type= isotropic time= 1 rate= {0.0015}


# Poly gate deposition
# --------------------

deposit material= {PolySilicon} type= anisotropic time= 1 rate= {0.05}


# Poly gate pattern/etch
# ----------------------

mask name= gate_mask left=-1 right= 20<nm>

etch material= {PolySilicon} type= anisotropic time= 1 rate= {0.055} mask= gate_mask

struct tdr= n@node@_NMOS1;

etch material= {Oxide}       type= anisotropic time= 1 rate= {0.0045}

struct tdr= n@node@_NMOS2; # PolyGate


# (poly reoxidation removed: it would consume silicon from the thin film)


# LDD implantation (p- extensions)
# --------------------------------

refinebox Silicon min= {0.0 0.01} max= {0.01 0.05} xrefine= {0.0005 0.0005 0.0005} yrefine= {0.002 0.002 0.002} add
grid remesh

implant Boron dose= 5.000e+12<cm-2> energy= 0.5<keV> tilt= 0 rotation= 0

struct tdr= n@node@_NMOS4 ; # LDD Implant

diffuse temperature= 1050<C> time= 0.1<s> ; # Quick activation

struct tdr= n@node@_NMOS5 ; # LDD Diffuse


# (halo implants not included: optional, not required by the specification)


# RTA of LDD implants
# -------------------

diffuse temperature= 1050<C> time= 5<s>

struct tdr= n@node@_NMOS10 ; # LDD RTA


# Nitride spacer
# --------------

deposit material= {Nitride} type= isotropic time= 1 rate= {0.01}

struct tdr= n@node@_NMOS11 ; # Spacer deposition

etch    material= {Nitride} type= anisotropic time= 1 rate= {0.014} isotropic.overetch= 0.00166667

struct tdr= n@node@_NMOS12 ; # Spacer etch


# P+ source/drain implantation
# ----------------------------

refinebox Silicon min= {0.0 0.02} max= {0.01 0.1} xrefine= {0.0005 0.0005 0.0005} yrefine= {0.005 0.005 0.005} add
grid remesh

implant Boron dose= 1.000e+14<cm-2> energy= 1<keV> tilt= 7<degree> rotation= -90<degree>

struct tdr= n@node@_NMOS14 ; # P+ implantation


# Final RTA
# ---------------------------

diffuse temperature= 1050<C> time= 10<s>

struct tdr= n@node@_NMOS15 ; # Final RTA


# Contacts
# --------

deposit material= {Aluminum} type= isotropic time= 1 rate= {0.03}

struct tdr= n@node@_NMOS16 ; # Aluminium deposition

mask name= contacts_mask left= 50<nm> right= 1.0<um>
etch material= {Aluminum} type= anisotropic time= 1 rate= {0.25} mask= contacts_mask

struct tdr= n@node@_NMOS17 ; # Aluminium etching 1

mask name= gate_mask2 left=-1 right= 18<nm> negative
deposit material= {Aluminum} type= anisotropic time= 1 rate= {0.03} mask= gate_mask2

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
WritePlx n@node@_NMOS_ldd.plx y=0.025 Silicon

SetPlxList   {PTotal BTotal NetActive}
WritePlx n@node@_NMOS_sd.plx y=0.09 Silicon


# Contacts
# -------

contact bottom name = substrate Silicon

contact name = gate x = -0.0665 y = 0.0 Aluminum

contact name = source x = -0.027 y = -0.075 Aluminum

contact name = drain x = -0.027 y = 0.075 Aluminum

struct tdr= n@node@_presimulation

exit