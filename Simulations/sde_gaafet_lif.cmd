;;==============================================================================
;;== GAA FeFET LIF Neuron - Sentaurus Structure Editor (SDE) Script
;;== Device: 2D Double-Gate approximation of GAA Floating Nanosheet FET
;;== Application: Leaky Integrate-and-Fire (LIF) Neuron
;;== Structure: MFMIS (Metal/Ferroelectric/Metal/Insulator/Semiconductor)
;;== Based on: Working_Codes_MFMIS syntax with Workflow.md dimensions
;;==============================================================================

;;==============================================================================
;;== Block 1: PARAMETER DEFINITIONS
;;== All dimensions in micrometers (um)
;;==============================================================================

;; --- Device Geometry Parameters (from Workflow.md) ---
(define L_gate      0.100)    ; Gate Length: 100 nm (optimized for Impact Ionization)
(define T_si        0.015)    ; Nanosheet Thickness: 15 nm (floating body)
(define T_in        0.002)    ; Interfacial Oxide (SiO2): 2 nm
(define T_metal_int 0.002)    ; Internal Metal (TiN): 2 nm
(define T_fe        0.010)    ; Ferroelectric HZO Thickness: 10 nm
(define T_metal_gate 0.005)   ; Gate Metal (TiN) Thickness: 5 nm
(define L_sd        0.050)    ; Source/Drain Extension: 50 nm

;; --- Doping Concentrations (cm^-3) from Workflow.md ---
(define N_sub       1e16)     ; Channel: P-type (Boron) - low for floating body
(define N_sd        1e20)     ; Source/Drain: N-type - high for ohmic contacts

;; --- Meshing Parameters ---
(define mesh_max_global  0.010)
(define mesh_min_global  0.005)
(define mesh_max_channel 0.005)
(define mesh_min_channel 0.0005)

;;==============================================================================
;;== Block 2: GEOMETRY DEFINITION
;;== Purpose: Create the correct thin-body double-gate MFMIS structure.
;;== CORRECTION: Create S/D/Channel as distinct regions to match paper.
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

;; --- [FIX] Create the thin Silicon body as three distinct regions ---
;; This ensures interfaces are created between source, channel, and drain.
(sdegeo:create-rectangle (position x_gate_start  (- (/ T_si 2.0)) 0) (position x_gate_end    (+ (/ T_si 2.0)) 0) "Silicon" "channel")
(sdegeo:create-rectangle (position x_source_start (- (/ T_si 2.0)) 0) (position x_source_end  (+ (/ T_si 2.0)) 0) "Silicon" "source")
(sdegeo:create-rectangle (position x_drain_start (- (/ T_si 2.0)) 0) (position x_drain_end   (+ (/ T_si 2.0)) 0) "Silicon" "drain")

;; --- Create TOP Gate Stack (MFMIS) - ONLY OVER THE CHANNEL ---
(define y_top_si (+ (/ T_si 2.0)))
(sdegeo:create-rectangle (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_in) 0) "SiO2" "insulator_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in) 0) (position x_gate_end (+ y_top_si T_in T_metal_int) 0) "TiN" "metal_internal_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in T_metal_int) 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe) 0) "HZO" "ferroelectric_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in T_metal_int T_fe) 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe T_metal_gate) 0) "TiN" "gate_metal_top")

;; --- Create BOTTOM Gate Stack (MFMIS) - ONLY UNDER THE CHANNEL ---
(define y_bot_si (- (/ T_si 2.0)))
(sdegeo:create-rectangle (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_in) 0) "SiO2" "insulator_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in) 0) (position x_gate_end (- y_bot_si T_in T_metal_int) 0) "TiN" "metal_internal_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in T_metal_int) 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe) 0) "HZO" "ferroelectric_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in T_metal_int T_fe) 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe T_metal_gate) 0) "TiN" "gate_metal_bottom")

;;==============================================================================
;;== Block 3: DOPING DEFINITION
;;==============================================================================
;; --- Define Doping Profiles (The Recipes) ---
(sdedr:define-constant-profile "ChannelDoping" "BoronActiveConcentration" N_sub)
(sdedr:define-constant-profile "SourceDrainDoping" "PhosphorusActiveConcentration" N_sd)

;; --- Place Doping Profiles in the distinct Regions ---
(sdedr:define-constant-profile-region "PlaceChannelDoping" "ChannelDoping" "channel")
(sdedr:define-constant-profile-region "PlaceSourceDoping" "SourceDrainDoping" "source")
(sdedr:define-constant-profile-region "PlaceDrainDoping" "SourceDrainDoping" "drain")

;;==============================================================================
;;== Block 4: CONTACT DEFINITION
;;== Substrate contact is now on the bottom of the channel/body.
;;==============================================================================

;; --- Define all Contact Sets ---
(sdegeo:define-contact-set "gate_contact" 4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "source_contact" 4 (color:rgb 0 1 0) "##")
(sdegeo:define-contact-set "drain_contact" 4 (color:rgb 0 0 1) "##")

;; --- Activate and Place each Contact ---
(sdegeo:set-current-contact-set "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_center (+ y_top_si T_in T_metal_int T_fe T_metal_gate) 0)))) "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_center (- y_bot_si T_in T_metal_int T_fe T_metal_gate) 0)))) "gate_contact")
(sdegeo:set-current-contact-set "source_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_source_start y_center 0)))) "source_contact")
(sdegeo:set-current-contact-set "drain_contact")
(sdegeo:set-contact (list (car (find-edge-id (position x_drain_end y_center 0)))) "drain_contact")

;;==============================================================================
;;== Block 5: MESHING STRATEGY
;;== CORRECTION: Use precise refinement windows to avoid visual artifacts.
;;==============================================================================

;; --- Define Refinement Windows that cover ONLY the geometry ---
(sdedr:define-refeval-window "SiliconFinWindow" "Rectangle" (position x_source_start y_bot_si 0) (position x_drain_end y_top_si 0))
(sdedr:define-refeval-window "TopStackWindow" "Rectangle" (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe T_metal_gate) 0))
(sdedr:define-refeval-window "BotStackWindow" "Rectangle" (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe T_metal_gate) 0))

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
