import planar
for vp in [2.5, 3.0, 3.5]:
    r = planar.run_lif("smk", [vp], WF=4.35, VREAD=0.0, N=1, t_p=300e-9)
    row = r[vp]
    print(f"### Vpgm={vp}: ey/Fc={row['ey_over_fc']:.3f}  id_base={row['id_base']:.3e}  id_p1={row['id_p1']:.3e}", flush=True)
