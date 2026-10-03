      subroutine amrt_allocate()  !Ali

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine allocates array sizes for variables used in the APEX-MODFLOW linkage

      use parm !APEX  
      use GLOBAL, only:NCOL,NROW,NLAY,IBOUND !MODFLOW
      use amrt_parm !APEX-MODFLOW
      use mf_rt_link !RT3D
      use GWFBASMODULE, only:HNOFLO
      use GWFRIVMODULE, only:MXRIVR 
      use rt_global, only:NCOMP
      implicit none
      
      integer i,j,k

!     Allocate the size of the river-to-grid variables
      allocate(grid2riv_id(nrivcells_subs,MSA))
      allocate(grid2riv_len(nrivcells_subs,MSA))
      allocate(riv_nsubs(nrivcells_subs))
      allocate(grid2riv_cellID(nrivcells_subs))
      allocate(sub_gw_exchange(MSA))
      allocate(sub_gwno3_exchange(MSA))
      allocate(sub_gwp_exchange(MSA))
      allocate(sub_drn(MSA))
      allocate(dep_chan(MSA))
      allocate(no3_chan(MSA))
      allocate(p_chan(MSA))
      grid2riv_id = 0.
      grid2riv_len = 0.
      riv_nsubs = 0.
      grid2riv_cellID = 0
      sub_gw_exchange = 0.
      sub_gwno3_exchange = 0.
      sub_gwp_exchange = 0.
      sub_drn = 0.
      dep_chan = 0.
      no3_chan = 0.
      p_chan = 0.
      
      !groundwater storage
      allocate(sub_gw_volume(MSA))
      allocate(sub_gwno3(MSA))
      allocate(sub_gwp(MSA))
      sub_gw_volume = 10000.
      sub_gwno3 = 10000.
      sub_gwp = 10000.

      !vertical distance from ground surface to the water table
      allocate(wt_depth_cell(NCOL,NROW))
      allocate(sub_wt_depth(MSA))
      wt_depth_cell = 0.
      sub_wt_depth = 10.

      !allocate the size of subarea variable arrays
      allocate(etremain(MSA)) !mm
      allocate(sepbtm(MSA)) !mm
      allocate(rchrg(MSA)) !mm
      allocate(rch_volume(MSA)) !m3
      allocate(gw_delaye(MSA))
      allocate(percn(MSA)) !kg/ha
      allocate(percp(MSA)) !kg/ha
      allocate(rchrg_n(MSA)) !kg/ha
      allocate(rchrg_p(MSA)) !kg/ha
      etremain = 0.
      sepbtm = 0.
      rchrg = 0.
      rch_volume = 0.
      gw_delaye = 0.
      percn = 0.
      percp = 0.
      rchrg_n = 0.
      rchrg_p = 0.

      !salt arrays
      if(ISALT>0) then
        salt_species(1) = 'Sulfate'
        salt_species(2) = 'Calcium'
        salt_species(3) = 'Magnesium'
        salt_species(4) = 'Sodium'
        salt_species(5) = 'Potassium'
        salt_species(6) = 'Chloride'
        salt_species(7) = 'Carbonate'
        salt_species(8) = 'Bicarbonate'
        allocate(sub_salt_exchange(MSA,mion)) !kg
        allocate(rchrg_salt(MSA,mion)) !kg/ha
        allocate(rchrg_csalt(MSA,mion)) !g/m3
        allocate(chan_csalt(MSA,mion)) !g/m3
        allocate(wsalt(10,MSA,mion)) !kg/ha
        allocate(soil_csalt(10,MSA,mion)) !g/m3
        allocate(vsalt(MSA,mion)) !kg/ha
        allocate(surfqsalt(MSA,mion)) !kg/ha
        allocate(surfqsalt_sub(MSA,mion)) !kg
        allocate(surfsalt(MSA,mion)) !kg/ha
        allocate(surfsalt_sub(MSA,mion)) !kg
        allocate(irrsalt(MSA,mion)) !kg/ha
        allocate(irrig_csalt(MSA,mion)) !g/m3
        allocate(latsalt(MSA,mion)) !kg/ha
        allocate(latsalt_sub(MSA,mion)) !kg
        allocate(qrfsalt(MSA,mion)) !kg
        allocate(qrfsalt_sub(MSA,mion)) !kg
        allocate(gwsalt(MSA,mion)) !kg/ha
        allocate(gwswsalt_sub(MSA,mion)) !kg
        allocate(swgwsalt_sub(MSA,mion)) !kg
        allocate(pts_sub(MSA,mion)) !kg
        allocate(SMQS(MSA,mion)) !kg total
        allocate(SMQS_total(MSA,mion)) !kg total
        allocate(salt_solid_soil(20,MSA,5))
        allocate(init_salt_fraction(20,MSA,5))
        allocate(init_salt_conc(20,MSA,8))
        allocate(Sul_Conc(2000))
        allocate(Cal_Conc(2000))
        allocate(Mg_Conc(2000))
        allocate(Sod_Conc(2000))
        allocate(Pot_Conc(2000))
        allocate(Cl_Conc(2000))
        allocate(Car_Conc(2000))
        allocate(BiCar_Conc(2000))
        allocate(LAMDA(7))
        allocate(saltdissolve_soil(MSA,mion))
        allocate(salt_soil(MSA))
        sub_salt_exchange = 0.
        rchrg_salt = 0.
        rchrg_csalt = 0.
        chan_csalt = 0.
        wsalt = 0. !kg/ha
        soil_csalt = 0. !g/m3
        vsalt = 0. !kg/ha
        surfqsalt = 0. !kg/ha
        surfqsalt_sub = 0. !kg/ha
        surfsalt = 0. !kg/ha
        surfsalt_sub = 0. !kg/ha
        irrsalt = 0. !kg/ha
        irrig_csalt = 0. !g/m3
        latsalt = 0. !kg/ha
        latsalt_sub = 0. !kg/ha
        qrfsalt = 0. !kg/ha
        qrfsalt_sub = 0. !kg/ha
        gwsalt = 0. !kg/ha
        gwswsalt_sub = 0. !kg/ha
        swgwsalt_sub = 0. !kg/ha
        pts_sub = 0. !kg
        SMQS = 0. !kg total
        SMQS_total= 0. !kg total
        saltdissolve_soil = 0.
      endif
      
      !allocate and populate the month_days array (for stored variable averages) (rtb avg)
      allocate(month_days(12))
      month_days(1) = 31
      month_days(2) = 59
      month_days(3) = 90
      month_days(4) = 120
      month_days(5) = 151
      month_days(6) = 181
      month_days(7) = 212
      month_days(8) = 243
      month_days(9) = 273
      month_days(10) = 304
      month_days(11) = 334
      month_days(12) = 365

      allocate(month_days_leap(12))
      month_days_leap(1) = 31
      month_days_leap(2) = 60
      month_days_leap(3) = 91
      month_days_leap(4) = 121
      month_days_leap(5) = 152
      month_days_leap(6) = 183
      month_days_leap(7) = 213
      month_days_leap(8) = 244
      month_days_leap(9) = 274
      month_days_leap(10) = 305
      month_days_leap(11) = 335
      month_days_leap(12) = 366

      !initialize counters
      day_count_mo = 1
      day_count_yr = 1

      !initialize the month (based on the "idaf" variable: starting Julian day of the APEX simulation)
      do i=1,12
        if(idaf.lt.month_days(i)) then
          amrt_month_counter = i
          goto 10
        endif
      enddo

      !arrays for variable averages
10    allocate(amrt_RECH_tot_mo(ncol,nrow))
      allocate(amrt_RECH_tot_yr(ncol,nrow))
      amrt_RECH_tot_mo = 0.
      amrt_RECH_tot_yr = 0.
     
      allocate(amrt_RECH_APEX_tot_mo(MSA))
      allocate(amrt_RECH_APEX_tot_yr(MSA))
      amrt_RECH_APEX_tot_mo = 0.
      amrt_RECH_APEX_tot_yr = 0.

      allocate(amrt_GWSW_MF_tot_mo(MXRIVR))
      allocate(amrt_GWSW_MF_tot_yr(MXRIVR))
      amrt_GWSW_MF_tot_mo = 0.
      amrt_GWSW_MF_tot_yr = 0.

      allocate(amrt_GWSW_APEX_tot_mo(MSA))
      allocate(amrt_GWSW_APEX_tot_yr(MSA))
      amrt_GWSW_APEX_tot_mo = 0.
      amrt_GWSW_APEX_tot_yr = 0.

      if(rt_active.eq.1) then
        allocate(amrt_csolute_tot_mo(ncol,nrow,nlay,10))
        allocate(amrt_csolute_avg_mo(ncol,nrow,nlay,10))
        allocate(amrt_csolute_tot_yr(ncol,nrow,nlay,10))
        allocate(amrt_csolute_avg_yr(ncol,nrow,nlay,10))
        amrt_csolute_tot_mo = 0.
        amrt_csolute_avg_mo = 0.
        amrt_csolute_tot_yr = 0.
        amrt_csolute_avg_yr = 0.
      endif

      day_total = 1
      
      return
      end
