;;=====================================================================
;;== GAA FeFET LIF Neuron - Sentaurus Structure Editor (SDE) Script
;;== 
;;== Device: 2D Double-Gate approximation of GAA Floating Nanosheet FET
;;== Application: Leaky Integrate-and-Fire (LIF) Neuron
;;== 
;;== Based on: "Design of energy-efficient LIF neuron using CMOS 
;;==           compatible gate-all-around floating nanosheet FET"
;;=====================================================================

;;=====================================================================
;;== Block 1: PARAMETER DEFINITIONS
;;== All dimensions in micrometers (um)
;;=====================================================================

;; --- Device Geometry Parameters ---
(define L_gate   0.100)    ; Gate Length: 100 nm (optimized for Impact Ionization)
(define T_si     0.015)    ; Nanosheet Thickness: 15 nm (floating body)
(define T_ox     0.002)    ; Interfacial Oxide (SiO2): 2 nm
(define T_fe     0.010)    ; Ferroelectric HZO Thickness: 10 nm
(define L_sd     0.050)    ; Source/Drain Extension: 50 nm
(define T_metal  0.005)    ; Gate Metal (TiN) Thickness: 5 nm

;; --- Doping Concentrations (cm^-3) ---
(define N_channel 1e16)    ; Channel: P-type (Boron) - low for floating body
(define N_sd      1e20)    ; Source/Drain: N-type (Arsenic) - high for ohmic contacts

;; --- Meshing Parameters ---
(define mesh_max_global  0.010)   ; Global max mesh size: 10 nm
(define mesh_min_global  0.005)   ; Global min mesh size: 5 nm
(define mesh_max_channel 0.005)   ; Channel max: 5 nm
(define mesh_min_channel 0.001)   ; Channel min: 1 nm (for II resolution)
(define mesh_fe          0.001)   ; FE layer mesh: 1 nm (polarization gradients)
(define mesh_junction    0.0005)  ; Junction refinement: 0.5 nm (II peak region)

;;=====================================================================
;;== Block 2: GEOMETRY DEFINITION
;;== 2D Double-Gate structure approximating GAA nanosheet
;;=====================================================================

;; --- Set overlap behavior ---
(sdegeo:set-default-boolean "ABA")

;; --- Calculate key coordinates (origin at center of gate) ---
(define x_center 0)
(define y_center 0)
(define x_gate_start  (- (/ L_gate 2.0)))      ; -0.05 um
(define x_gate_end    (+ (/ L_gate 2.0)))      ; +0.05 um
(define x_source_end  x_gate_start)
(define x_source_start (- x_source_end L_sd))  ; -0.10 um
(define x_drain_start x_gate_end)
(define x_drain_end   (+ x_drain_start L_sd))  ; +0.10 um

;; --- Y-coordinates for layer stacking ---
(define y_si_top    (+ (/ T_si 2.0)))          ; +0.0075 um
(define y_si_bot    (- (/ T_si 2.0)))          ; -0.0075 um

;; --- Create Silicon Body as three distinct regions ---
;; Channel region (under gate)
(sdegeo:create-rectangle 
  (position x_gate_start y_si_bot 0) 
  (position x_gate_end y_si_top 0) 
  "Silicon" "channel")

;; Source region
(sdegeo:create-rectangle 
  (position x_source_start y_si_bot 0) 
  (position x_source_end y_si_top 0) 
  "Silicon" "source")

;; Drain region
(sdegeo:create-rectangle 
  (position x_drain_start y_si_bot 0) 
  (position x_drain_end y_si_top 0) 
  "Silicon" "drain")

;;=====================================================================
;;== Block 3: TOP GATE STACK (MFIS - Metal/Ferroelectric/Insulator/Si)
;;== Stack order from Si: SiO2 -> HZO -> TiN
;;=====================================================================

;; --- Top Interfacial Oxide (SiO2) ---
(define y_top_ox_start y_si_top)
(define y_top_ox_end   (+ y_si_top T_ox))
(sdegeo:create-rectangle 
  (position x_gate_start y_top_ox_start 0) 
  (position x_gate_end y_top_ox_end 0) 
  "SiO2" "oxide_top")

;; --- Top Ferroelectric (HZO) ---
(define y_top_fe_start y_top_ox_end)
(define y_top_fe_end   (+ y_top_ox_end T_fe))
(sdegeo:create-rectangle 
  (position x_gate_start y_top_fe_start 0) 
  (position x_gate_end y_top_fe_end 0) 
  "HZO" "ferroelectric_top")

;; --- Top Gate Metal (TiN) ---
(define y_top_metal_start y_top_fe_end)
(define y_top_metal_end   (+ y_top_fe_end T_metal))
(sdegeo:create-rectangle 
  (position x_gate_start y_top_metal_start 0) 
  (position x_gate_end y_top_metal_end 0) 
  "TiN" "gate_metal_top")

;;=====================================================================
;;== Block 4: BOTTOM GATE STACK (Mirror of top stack)
;;=====================================================================

;; --- Bottom Interfacial Oxide (SiO2) ---
(define y_bot_ox_start y_si_bot)
(define y_bot_ox_end   (- y_si_bot T_ox))
(sdegeo:create-rectangle 
  (position x_gate_start y_bot_ox_end 0) 
  (position x_gate_end y_bot_ox_start 0) 
  "SiO2" "oxide_bottom")

;; --- Bottom Ferroelectric (HZO) ---
(define y_bot_fe_start y_bot_ox_end)
(define y_bot_fe_end   (- y_bot_ox_end T_fe))
(sdegeo:create-rectangle 
  (position x_gate_start y_bot_fe_end 0) 
  (position x_gate_end y_bot_fe_start 0) 
  "HZO" "ferroelectric_bottom")

;; --- Bottom Gate Metal (TiN) ---
(define y_bot_metal_start y_bot_fe_end)
(define y_bot_metal_end   (- y_bot_fe_end T_metal))
(sdegeo:create-rectangle 
  (position x_gate_start y_bot_metal_end 0) 
  (position x_gate_end y_bot_metal_start 0) 
  "TiN" "gate_metal_bottom")

;;=====================================================================
;;== Block 5: DOPING DEFINITIONS
;;=====================================================================

;; --- Channel Doping Profile (P-type, low concentration) ---
(sdedr:define-constant-profile "ChannelDoping" 
  "BoronActiveConcentration" N_channel)

;; --- Source/Drain Doping Profile (N-type, high concentration) ---
(sdedr:define-constant-profile "SourceDrainDoping" 
  "ArsenicActiveConcentration" N_sd)

;; --- Place Doping Profiles in Regions ---
(sdedr:define-constant-profile-region "PlaceChannelDoping" 
  "ChannelDoping" "channel")
(sdedr:define-constant-profile-region "PlaceSourceDoping" 
  "SourceDrainDoping" "source")
(sdedr:define-constant-profile-region "PlaceDrainDoping" 
  "SourceDrainDoping" "drain")

;;=====================================================================
;;== Block 6: CONTACT DEFINITIONS
;;== Gate contact connects both top and bottom metal electrodes
;;=====================================================================

;; --- Define Contact Sets ---
(sdegeo:define-contact-set "gate_contact" 4 (color:rgb 1 0 0) "##")
(sdegeo:define-contact-set "source_contact" 4 (color:rgb 0 1 0) "||")
(sdegeo:define-contact-set "drain_contact" 4 (color:rgb 0 0 1) "==")

;; --- Place Gate Contacts (top and bottom, electrically connected) ---
(sdegeo:set-current-contact-set "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id 
  (position x_center y_top_metal_end 0)))) "gate_contact")
(sdegeo:set-contact (list (car (find-edge-id 
  (position x_center y_bot_metal_end 0)))) "gate_contact")

;; --- Place Source Contact (left edge of source region) ---
(sdegeo:set-current-contact-set "source_contact")
(sdegeo:set-contact (list (car (find-edge-id 
  (position x_source_start y_center 0)))) "source_contact")

;; --- Place Drain Contact (right edge of drain region) ---
(sdegeo:set-current-contact-set "drain_contact")
(sdegeo:set-contact (list (car (find-edge-id 
  (position x_drain_end y_center 0)))) "drain_contact")

;;=====================================================================
;;== Block 7: MESHING STRATEGY
;;== Critical: Fine mesh at drain junction for Impact Ionization
;;== and in FE layer for polarization gradient resolution
;;=====================================================================

;; --- Define Refinement Windows ---

;; Full Silicon body (source + channel + drain)
(sdedr:define-refeval-window "SiliconWindow" "Rectangle" 
  (position x_source_start y_si_bot 0) 
  (position x_drain_end y_si_top 0))

;; Channel region only
(sdedr:define-refeval-window "ChannelWindow" "Rectangle" 
  (position x_gate_start y_si_bot 0) 
  (position x_gate_end y_si_top 0))

;; Drain junction (critical for Impact Ionization)
(sdedr:define-refeval-window "DrainJunctionWindow" "Rectangle" 
  (position (- x_drain_start 0.005) y_si_bot 0) 
  (position (+ x_drain_start 0.005) y_si_top 0))

;; Top gate stack
(sdedr:define-refeval-window "TopStackWindow" "Rectangle" 
  (position x_gate_start y_si_top 0) 
  (position x_gate_end y_top_metal_end 0))

;; Bottom gate stack
(sdedr:define-refeval-window "BotStackWindow" "Rectangle" 
  (position x_gate_start y_bot_metal_end 0) 
  (position x_gate_end y_si_bot 0))

;; --- Define Refinement Sizes ---

;; Global refinement
(sdedr:define-refinement-size "GlobalRefinement" 
  mesh_max_global mesh_max_global 
  mesh_min_global mesh_min_global)

;; Channel refinement (finer)
(sdedr:define-refinement-size "ChannelRefinement" 
  mesh_max_channel mesh_max_channel 
  mesh_min_channel mesh_min_channel)

;; Drain junction refinement (finest - for II)
(sdedr:define-refinement-size "JunctionRefinement" 
  mesh_junction mesh_junction 
  mesh_junction mesh_junction)

;; Gate stack refinement (for FE layer)
(sdedr:define-refinement-size "StackRefinement" 
  mesh_fe mesh_fe 
  mesh_fe mesh_fe)

;; --- Place Refinements ---
(sdedr:define-refinement-placement "PlaceGlobalSi" 
  "GlobalRefinement" "SiliconWindow")
(sdedr:define-refinement-placement "PlaceChannel" 
  "ChannelRefinement" "ChannelWindow")
(sdedr:define-refinement-placement "PlaceJunction" 
  "JunctionRefinement" "DrainJunctionWindow")
(sdedr:define-refinement-placement "PlaceTopStack" 
  "StackRefinement" "TopStackWindow")
(sdedr:define-refinement-placement "PlaceBotStack" 
  "StackRefinement" "BotStackWindow")

;; --- Interface Refinement Functions ---
;; Fine mesh at Si/SiO2 interfaces
(sdedr:define-refinement-function "ChannelRefinement" 
  "MaxLenInt" "Silicon" "SiO2" mesh_min_channel 1.4 "DoubleSide")

;; Fine mesh at SiO2/HZO interfaces  
(sdedr:define-refinement-function "StackRefinement" 
  "MaxLenInt" "SiO2" "HZO" mesh_fe 1.4 "DoubleSide")

;;=====================================================================
;;== Block 8: BUILD MESH AND SAVE
;;=====================================================================

;; Save boundary file
(sdeio:save-tdr-bnd (get-body-list) "n@node@_bnd.tdr")

;; Build mesh using snmesh
(sde:build-mesh "snmesh" " " "n@node@")

;;=====================================================================
;;== END OF SDE SCRIPT
;;=====================================================================
