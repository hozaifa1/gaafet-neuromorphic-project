;;==============================================================================
;;== GAA FeFET LIF Neuron - Sentaurus Structure Editor (SDE) Script
;;== Device: 2D Double-Gate approximation of GAA Floating Nanosheet FET
;;== Application: Leaky Integrate-and-Fire (LIF) Neuron
;;== Structure: MFIS (Metal/Ferroelectric/Insulator/Semiconductor) per Workflow.md
;;== Syntax: Following Working_Codes_MFMIS coding patterns
;;==============================================================================

;;==============================================================================
;;== Block 1: PARAMETER DEFINITIONS
;;== All dimensions in micrometers (um) - VALUES FROM WORKFLOW.MD
;;==============================================================================

;; --- Device Geometry Parameters (from Workflow.md Section 2.1) ---
(define L_gate      0.100)    ; Gate Length: 100 nm (optimized for Impact Ionization)
(define T_si        0.015)    ; Nanosheet Thickness: 15 nm (floating body)
(define T_ox        0.002)    ; Interfacial Oxide (SiO2): 2 nm
(define T_fe        0.010)    ; Ferroelectric HZO Thickness: 10 nm
(define T_metal     0.005)    ; Gate Metal (TiN) Thickness: 5 nm
(define L_sd        0.050)    ; Source/Drain Extension: ~50 nm

;; --- Doping Concentrations (cm^-3) from Workflow.md Section 3.1 ---
(define N_sub       1e16)     ; Channel: P-type (Boron) 1e16 - low for floating body
(define N_sd        1e20)     ; Source/Drain: N-type (Arsenic) 1e20 - high for ohmic

;; --- Meshing Parameters ---
(define mesh_max_global  0.010)
(define mesh_min_global  0.005)
(define mesh_max_channel 0.005)
(define mesh_min_channel 0.0005)

;;==============================================================================
;;== Block 2: GEOMETRY DEFINITION
;;== Purpose: Create the correct thin-body double-gate MFIS structure.
;;== Stack (per Workflow.md 2.2): Si -> SiO2 -> HZO -> TiN (NO internal metal)
;;==============================================================================

;; --- Set overlap behavior ---
(sdegeo:set-default-boolean "ABA")

;; --- Calculate key coordinates (origin is center of the channel length) ---
(define x_center 0)
(define y_center 0)
(define x_gate_start  (- (/ L_gate 2.0)))
(define x_gate_end    (+ (/ L_gate 2.0)))
(define x_source_end  x_gate_start)
(define x_source_start (- x_source_end L_sd))
(define x_drain_start x_gate_end)
(define x_drain_end   (+ x_drain_start L_sd))

;; --- Create the thin Silicon body as three distinct regions ---
;; This ensures interfaces are created between source, channel, and drain.
(sdegeo:create-rectangle (position x_gate_start  (- (/ T_si 2.0)) 0) (position x_gate_end    (+ (/ T_si 2.0)) 0) "Silicon" "channel")
(sdegeo:create-rectangle (position x_source_start (- (/ T_si 2.0)) 0) (position x_source_end  (+ (/ T_si 2.0)) 0) "Silicon" "source")
(sdegeo:create-rectangle (position x_drain_start (- (/ T_si 2.0)) 0) (position x_drain_end   (+ (/ T_si 2.0)) 0) "Silicon" "drain")

;; --- Create TOP Gate Stack (MFIS per Workflow.md) - ONLY OVER THE CHANNEL ---
;; Stack: SiO2 (T_ox) -> HZO (T_fe) -> TiN (T_metal)
(define y_top_si (+ (/ T_si 2.0)))
(sdegeo:create-rectangle (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_ox) 0) "SiO2" "insulator_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_ox) 0) (position x_gate_end (+ y_top_si T_ox T_fe) 0) "HZO" "ferroelectric_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_ox T_fe) 0) (position x_gate_end (+ y_top_si T_ox T_fe T_metal) 0) "TiN" "gate_metal_top")

;; --- Create BOTTOM Gate Stack (MFIS) - ONLY UNDER THE CHANNEL ---
(define y_bot_si (- (/ T_si 2.0)))
(sdegeo:create-rectangle (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_ox) 0) "SiO2" "insulator_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_ox) 0) (position x_gate_end (- y_bot_si T_ox T_fe) 0) "HZO" "ferroelectric_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_ox T_fe) 0) (position x_gate_end (- y_bot_si T_ox T_fe T_metal) 0) "TiN" "gate_metal_bottom")

;;==============================================================================
;;== Block 3: DOPING DEFINITION
;;==============================================================================
;; --- Define Doping Profiles (The Recipes) ---
(sdedr:define-constant-profile "ChannelDoping" "BoronActiveConcentration" N_sub)
(sdedr:define-constant-profile "SourceDrainDoping" "ArsenicActiveConcentration" N_sd)

;; --- Place Doping Profiles in the distinct Regions ---
(sdedr:define-constant-profile-region "PlaceChannelDoping" "ChannelDoping" "channel")
(sdedr:define-constant-profile-region "PlaceSourceDoping" "SourceDrainDoping" "source")
(sdedr:define-constant-profile-region "PlaceDrainDoping" "SourceDrainDoping" "drain")

;;==============================================================================
;;== Block 4: CONTACT DEFINITION
;;==============================================================================

;; --- Define all Contact Sets ---
(sdegeo:define-contact-set "gate_contact" 4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "source_contact" 4 (color:rgb 0 1 0) "##")
(sdegeo:define-contact-set "drain_contact" 4 (color:rgb 0 0 1) "##")

;; --- Activate and Place each Contact ---
(sdegeo:set-current-contact-set "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_center (+ y_top_si T_ox T_fe T_metal) 0)))) "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_center (- y_bot_si T_ox T_fe T_metal) 0)))) "gate_contact")
(sdegeo:set-current-contact-set "source_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_source_start y_center 0)))) "source_contact")
(sdegeo:set-current-contact-set "drain_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_drain_end y_center 0)))) "drain_contact")

;;==============================================================================
;;== Block 5: MESHING STRATEGY
;;==============================================================================

;; --- Define Refinement Windows that cover ONLY the geometry ---
(sdedr:define-refeval-window "SiliconFinWindow" "Rectangle" (position x_source_start y_bot_si 0) (position x_drain_end y_top_si 0))
(sdedr:define-refeval-window "TopStackWindow" "Rectangle" (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_ox T_fe T_metal) 0))
(sdedr:define-refeval-window "BotStackWindow" "Rectangle" (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_ox T_fe T_metal) 0))

;; --- Define Refinement Rules ---
(sdedr:define-refinement-size "GlobalRefinement" mesh_max_global mesh_max_global mesh_min_global mesh_min_global)
(sdedr:define-refinement-size "ChannelRefinement" mesh_max_channel mesh_max_channel mesh_min_channel mesh_min_channel)

;; --- Place Refinements ---
(sdedr:define-refinement-placement "PlaceGlobalSi" "GlobalRefinement" "SiliconFinWindow")
(sdedr:define-refinement-placement "PlaceGlobalTopStack" "GlobalRefinement" "TopStackWindow")
(sdedr:define-refinement-placement "PlaceGlobalBotStack" "GlobalRefinement" "BotStackWindow")
(sdedr:define-refinement-placement "PlaceChannel" "ChannelRefinement" "SiliconFinWindow")
(sdedr:define-refinement-function "ChannelRefinement" "MaxLenInt" "Silicon" "SiO2" mesh_min_channel 1.4 "DoubleSide")

;;==============================================================================
;;== Block 6: BUILD MESH
;;==============================================================================
(sdeio:save-tdr-bnd (get-body-list) "n@node@_bnd.tdr")
(sde:build-mesh "snmesh" " " "n@node@")
