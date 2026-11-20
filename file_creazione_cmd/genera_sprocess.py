#!/usr/bin/env python3
"""Rigenera sprocess_fps.cmd a partire da constraint_iniziali.py.

Uso:
    python genera_sprocess.py            # genera una volta
    python genera_sprocess.py --watch    # rigenera ad ogni salvataggio di
                                         # constraint_iniziali.py o del template

Il template (sprocess_fps.template.cmd) contiene campi %%nome%% che vengono
sostituiti con i valori calcolati qui sotto. Nessuna dipendenza esterna.
"""
import argparse
import re
import time
from datetime import datetime
from pathlib import Path

HERE = Path(__file__).resolve().parent
PARAMS = HERE.parent / "constraint_iniziali.py"
TEMPLATE = HERE / "sprocess_fps.template.cmd"
OUTPUT = HERE.parent / "sprocess_fps.cmd"   # una cartella sopra quella dello script

REQUIRED = [
    "L_channel", "T_si", "T_BOX", "Spacer", "gate_high", "t_ox",
    "width_mos", "thickness_sub", "n_well_doping", "Al_thickness",
    "dose_sd", "dose_ldd", "E_sd_keV", "E_ldd_keV",
    "t_act_ldd_s", "t_rta_ldd_s", "t_rta_final_s",
]

# Scelte geometriche fisse (modificabili qui)
GATE_CONTACT_MARGIN = 2e-9   # m, il contatto di gate e' piu' stretto del gate
CONTACT_OFFSET = 20e-9       # m, distanza tra bordo spacer e inizio contatto S/D


class GenError(Exception):
    pass


# --- formattazione per Sentaurus -------------------------------------------
def nm(v):   # metri -> "xx<nm>"
    return f"{v * 1e9:.6g}<nm>"


def um(v):   # metri -> numero in micrometri (unita' di default di sprocess)
    return f"{v * 1e6:.6g}"


def sci(v):  # notazione scientifica
    return f"{v:.3e}"


# --- lettura parametri -----------------------------------------------------
def load_params():
    try:
        src = PARAMS.read_text(encoding="utf-8")
        ns = {}
        exec(compile(src, str(PARAMS), "exec"), ns)
    except Exception as e:  # errori di sintassi mentre si modifica il file
        raise GenError(f"{PARAMS.name}: {type(e).__name__}: {e}")
    missing = [k for k in REQUIRED if k not in ns]
    if missing:
        raise GenError(f"{PARAMS.name}: mancano le variabili {missing}")
    return ns


# --- valori per il template ------------------------------------------------
def build_values(p):
    Lg, Tsi, Tbox = p["L_channel"], p["T_si"], p["T_BOX"]
    sp, tox, gh, al = p["Spacer"], p["t_ox"], p["gate_high"], p["Al_thickness"]

    half = Lg / 2                       # mezzo gate (struttura simmetrica)
    y_right = p["width_mos"] / 2        # mezza larghezza del dominio
    x_box_bot = Tsi + Tbox
    x_bottom = x_box_bot + p["thickness_sub"]

    contact_left = half + sp + CONTACT_OFFSET
    y_contact = (contact_left + y_right) / 2
    ref_ldd_ymin = max(0.0, half - 10e-9)
    ref_ldd_ymax = half + sp + 20e-9
    sd_ref_ymin = max(0.0, half + sp - 10e-9)

    v = {
        "film_spacing": nm(Tsi / 10),
        "T_si": nm(Tsi), "T_si_um": um(Tsi),
        "x_box_bot": nm(x_box_bot), "x_bottom": nm(x_bottom),
        "y_right": nm(y_right), "y_right_um": um(y_right),
        "min_normal": nm(tox / 3),
        "t_ox_um": um(tox),
        "gate_high_um": um(gh),
        "Lg_half": nm(half),
        "poly_etch_um": um(gh * 1.1),
        "ox_etch_um": um(tox * 3),
        "ref_ldd_ymin": um(ref_ldd_ymin), "ref_ldd_ymax": um(ref_ldd_ymax),
        "ref_dx": um(Tsi / 20), "ref_dy": um(2e-9), "ref_dy_sd": um(5e-9),
        "sd_ref_ymin": um(sd_ref_ymin),
        "n_body": sci(p["n_well_doping"]),
        "dose_ldd": sci(p["dose_ldd"]), "E_ldd": f"{p['E_ldd_keV']:g}",
        "dose_sd": sci(p["dose_sd"]), "E_sd": f"{p['E_sd_keV']:g}",
        "t_act_ldd": f"{p['t_act_ldd_s']:g}",
        "t_rta_ldd": f"{p['t_rta_ldd_s']:g}",
        "t_rta_final": f"{p['t_rta_final_s']:g}",
        "spacer_um": um(sp),
        "spacer_etch_um": um(sp * 1.4),       # rapporto 0.084/0.06 del tutorial
        "spacer_overetch_um": um(sp / 6),     # rapporto 0.01/0.06 del tutorial
        "al_um": um(al),
        "contact_left": nm(contact_left),
        "gate_contact_half": nm(half - GATE_CONTACT_MARGIN),
        "x_gate_contact": um(-(tox + gh + al / 2)),
        "x_sd_contact": um(-0.9 * al),
        "y_contact_pos": um(y_contact), "y_contact_neg": um(-y_contact),
        "y_prof_ldd": um(half + sp / 2),
        "y_prof_sd": um(y_right - 10e-9),
    }
    return v, y_right - contact_left


def sanity(p, margin_sd):
    """Controlli di coerenza: solo avvisi, non bloccano la generazione."""
    Lg, Tsi, tox = p["L_channel"], p["T_si"], p["t_ox"]
    lam = (11.7 / 3.9 * Tsi * tox) ** 0.5
    print(f"  Lg/T_si = {Lg / Tsi:.1f}  (obiettivo 4-5)")
    print(f"  lambda = {lam * 1e9:.1f} nm, Lg/lambda = {Lg / lam:.1f}  (obiettivo >= 5)")
    if Lg / Tsi < 3:
        print("  ATTENZIONE: film troppo spesso rispetto a Lg")
    if Lg / lam < 5:
        print("  ATTENZIONE: Lg/lambda < 5, controllo elettrostatico debole")
    if margin_sd < 20e-9:
        print("  ATTENZIONE: poco spazio per il contatto S/D, aumenta width_mos")


# --- generazione -----------------------------------------------------------
def generate():
    p = load_params()
    values, margin_sd = build_values(p)
    try:
        template = TEMPLATE.read_text(encoding="utf-8")
    except OSError as e:
        raise GenError(f"template non leggibile: {e}")

    def repl(m):
        key = m.group(1)
        if key not in values:
            raise GenError(f"campo %%{key}%% nel template senza valore in genera_sprocess.py")
        return values[key]

    text = re.sub(r"%%(\w+)%%", repl, template)
    header = (
        f"# GENERATED {datetime.now():%Y-%m-%d %H:%M:%S} by genera_sprocess.py\n"
        f"# from {PARAMS.name} + {TEMPLATE.name} -- DO NOT EDIT BY HAND\n\n"
    )
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(header + text)
    print(f"[{datetime.now():%H:%M:%S}] aggiornato {OUTPUT}")
    sanity(p, margin_sd)


def mtime(path):
    try:
        return path.stat().st_mtime
    except OSError:
        return None


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--watch", action="store_true",
                    help="rigenera automaticamente quando i file sorgente cambiano")
    args = ap.parse_args()

    if not args.watch:
        try:
            generate()
        except GenError as e:
            raise SystemExit(f"ERRORE: {e}")
        return

    print(f"Controllo {PARAMS.name} e {TEMPLATE.name} (Ctrl+C per uscire)")
    last = None
    try:
        while True:
            stamp = (mtime(PARAMS), mtime(TEMPLATE))
            if stamp != last:
                last = stamp
                try:
                    generate()
                except GenError as e:
                    print(f"ERRORE: {e}")
            time.sleep(0.5)
    except KeyboardInterrupt:
        print("\nInterrotto.")


if __name__ == "__main__":
    main()