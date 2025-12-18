;;==================================================================
;;== Block 1: INITIALIZATION & PARAMETERS
;;== Purpose: Clear database and define all physical and meshing parameters.
;;==================================================================
(sde:clear)

;; --- Device Geometric Parameters (all units in micrometers, µm) ---
(define L_gate    1.0)      ; Gate Length (L)
(define W_device  1.0)      ; Device Width (W) - Assumed for 2D cross-section
(define T_si      0.005)    ; Silicon Channel Thickness (tsi)
(define T_in      0.002)    ; Insulator Thickness (tin)
(define T_fe      0.055)    ; Ferroelectric Layer Thickness (tFE)
(define T_metal_int 0.005)  ; Internal Metal Gate Thickness (Assumed 5nm)
(define T_metal_gate 0.01)  ; External Gate Metal Thickness (Assumed 10nm)
(define L_sd      0.5)      ; Length of Source/Drain regions (Assumed)

;; --- Doping Parameters (atoms/cm^3) ---
(define N_sub     1e10)     ; * CORRECTION: Lowered to simulate intrinsic Si (was 1e15)
(define N_sd      1e20)     ; Source/Drain Doping (n-type, for N+)

;; --- Mesh Parameters (µm) ---
;; Global (coarse) mesh settings
(define mesh_max_global 0.05)
(define mesh_min_global 0.02)

;; Local (fine) mesh settings for the channel and interfaces
(define mesh_max_channel 0.002)
(define mesh_min_channel 0.0005)

;;==================================================================
;;== Block 2: GEOMETRY DEFINITION
;;== Purpose: Create the correct thin-body double-gate MFMIS structure.
;;== CORRECTION: Create S/D/Channel as distinct regions to match paper.
;;==================================================================

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
(sdegeo:create-rectangle (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_in) 0) "HfO2" "insulator_top") ; * CORRECTION: Changed from SiO2 to HfO2 for high-k
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in) 0) (position x_gate_end (+ y_top_si T_in T_metal_int) 0) "TiN" "metal_internal_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in T_metal_int) 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe) 0) "HZO" "ferroelectric_top")
(sdegeo:create-rectangle (position x_gate_start (+ y_top_si T_in T_metal_int T_fe) 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe T_metal_gate) 0) "TiN" "gate_metal_top")

;; --- Create BOTTOM Gate Stack (MFMIS) - ONLY UNDER THE CHANNEL ---
(define y_bot_si (- (/ T_si 2.0)))
(sdegeo:create-rectangle (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_in) 0) "HfO2" "insulator_bottom") ; * CORRECTION: Changed from SiO2 to HfO2 for high-k
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in) 0) (position x_gate_end (- y_bot_si T_in T_metal_int) 0) "TiN" "metal_internal_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in T_metal_int) 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe) 0) "HZO" "ferroelectric_bottom")
(sdegeo:create-rectangle (position x_gate_start (- y_bot_si T_in T_metal_int T_fe) 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe T_metal_gate) 0) "TiN" "gate_metal_bottom")

;;==================================================================
;;== Block 3: DOPING DEFINITION
;;==================================================================
;; --- Define Doping Profiles (The Recipes) ---
(sdedr:define-constant-profile "ChannelDoping" "BoronActiveConcentration" N_sub)
(sdedr:define-constant-profile "SourceDrainDoping" "PhosphorusActiveConcentration" N_sd)

;; --- Place Doping Profiles in the distinct Regions ---
(sdedr:define-constant-profile-region "PlaceChannelDoping" "ChannelDoping" "channel")
(sdedr:define-constant-profile-region "PlaceSourceDoping" "SourceDrainDoping" "source")
(sdedr:define-constant-profile-region "PlaceDrainDoping" "SourceDrainDoping" "drain")

;;==================================================================
;;== Block 4: CONTACT DEFINITION
;;== Substrate contact is now on the bottom of the channel/body.
;;==================================================================

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

;;==================================================================
;;== Block 5: MESHING STRATEGY
;;== CORRECTION: Use precise refinement windows to avoid visual artifacts.
;;==================================================================

;; --- Define Refinement Windows that cover ONLY the geometry ---
(sdedr:define-refeval-window "SiliconFinWindow" "Rectangle" (position x_source_start y_bot_si 0) (position x_drain_end y_top_si 0)) ; * CORRECTION: y_si_bot/top to y_bot_si/y_top_si
(sdedr:define-refeval-window "TopStackWindow" "Rectangle" (position x_gate_start y_top_si 0) (position x_gate_end (+ y_top_si T_in T_metal_int T_fe T_metal_gate) 0)) ; * CORRECTION: y_gate_metal_top_surface to explicit
(sdedr:define-refeval-window "BotStackWindow" "Rectangle" (position x_gate_start y_bot_si 0) (position x_gate_end (- y_bot_si T_in T_metal_int T_fe T_metal_gate) 0)) ; * CORRECTION: y_gate_metal_bot_surface to explicit

;; --- Define Refinement Rules ---
(sdedr:define-refinement-size "GlobalRefinement" mesh_max_global mesh_max_global mesh_min_global mesh_min_global)
(sdedr:define-refinement-size "ChannelRefinement" mesh_max_channel mesh_max_channel mesh_min_channel mesh_min_channel)

;; --- Place Refinements ---
(sdedr:define-refinement-placement "PlaceGlobalSi" "GlobalRefinement" "SiliconFinWindow")
(sdedr:define-refinement-placement "PlaceGlobalTopStack" "GlobalRefinement" "TopStackWindow")
(sdedr:define-refinement-placement "PlaceGlobalBotStack" "GlobalRefinement" "BotStackWindow")
(sdedr:define-refinement-placement "PlaceChannel" "ChannelRefinement" "SiliconFinWindow") ; Fine mesh in all Si
(sdedr:define-refinement-function "ChannelRefinement" "MaxLenInt" "Silicon" "HfO2" mesh_min_channel 1.4 "DoubleSide") ; * CORRECTION: SiO2 to HfO2

;;==================================================================
;;== Block 6: BUILD MESH
;;==================================================================
(sdeio:save-tdr-bnd (get-body-list) "n@node@_bnd.tdr")
(sde:build-mesh "snmesh" " " "n@node@")
