      subroutine amrt_conversion2apex

!!    ~ ~ ~ Purpose ~ ~ ~
!!    This subroutine converts all the MODFLOW variables, to pass into APEX, into the proper units and APEX variables

      use PARM !APEX
      use GLOBAL,only:LENUNI,ITMUNI,NROW,NCOL,NLAY,HNEW,BOTM, !MODFLOW
     &                DELR,DELC,IBOUND,IUNIT
      use amrt_parm !APEX-MODFLOW
      use GWFUPWMODULE, only: SC2UPW
      use GWFRIVMODULE, only:RIVR,MXRIVR
      use GWFWELMODULE, only:WELL,NWELLS
      use GWFRCHMODULE, only: RECH
      use GWFDRNMODULE
      use GWFBASMODULE, only:VBVL
      use mf_rt_link, only: rt_active,rt_rivmass !MODFLOW-RT3D
      use rt_global, only: CNEW !RT3D
      
      implicit none
      
!     define local variables
      integer found,mf_gridID
      integer mf_lengthUnit,mf_timeUnit,nsubs_cell,dum
      integer IL,IC,IR,i,j,k,h,m,n,w,subID,subareaID,hru_id,
     &        well_row,well_col,cell_row,cell_col,sub_id,
     &        num_layer,ctr
      DOUBLE PRECISION HHNEW,CHRIV,RRBOT,CCRIV
      real grid_rivlen, HRIV, CRIV, RBOT, RATE, gw_tot, discharge,
     &     exchange_rate,riv_head,riv_cond,riv_bot,gw_head,
     &     loading,gw_sw_mm,sw_gw_mm,
     &     basin_area,sub_area,
     &     no3_gw_loading,p_gw_loading,
     &     sub_gw_sw,sub_sw_gw,
     &     sub_gw_sw_no3,sub_sw_gw_no3,
     &     sub_gw_sw_p,sub_sw_gw_p,
     &     thickness,cell_area,
     &     cell_gw_volume,gw_volume,sy,aquifer_gw_m,perc_area
      real wtlocation(NCOL,NROW)
      !rtb drain (DRAIN package --> flow to APEX streams)   
      real drnrate(1)
      integer drn_lay,drn_row,drn_col,subarea_row,subarea_col,
     &        drn_hru,sub_basin
      real    drn_elev,cell_head,drn_cond,drn_flow,sub_drn_sw
      !water balance terms
      real    sum_gwsw,sum_swgw,sum_rech,gw_change,gw_conhead
      !salt terms
      real    so4_gw_loading,ca_gw_loading,mg_gw_loading,na_gw_loading,
     &        k_gw_loading,cl_gw_loading,co3_gw_loading,hco3_gw_loading
            
      
      !MODFLOW length and time units
      mf_lengthUnit = LENUNI + 10
      mf_timeUnit = ITMUNI
      wtlocation = 1 !Set default water table location
      subID = 0
      sub_wt_depth = 0.
      
      !MODFLOW length and time units
      mf_lengthUnit = LENUNI + 10
      mf_timeUnit = ITMUNI
      
      !zero out array for subbasin groundwater discharge
      sub_gw_exchange = 0. 
      sub_drn = 0.
      sub_gwno3_exchange = 0
      sub_gwp_exchange = 0.
      if(allocated(sub_salt_exchange)) sub_salt_exchange = 0.
      sub_gwno3 = 0.
      sub_gwp = 0.

      !output file for MODFLOW River Cells
      if(out_MODFLOW_gwsw.eq.1 .and.
     &   day_total.eq.outapexmf(apexmf_out_ctr)) then
        write(30005,*)
        write(30005,*) 'Day:',day_total
        write(30005,*) 'Daily GW/SW Exchange for each River Cell'
        write(30005,*) 'Layer, Row, Column, Flow Rate'
      endif

      !output file for APEX subareas
      if(out_APEX_gwsw.eq.1 .and.
     &   day_total.eq.outapexmf(apexmf_out_ctr)) then
        write(30006,*)
        write(30006,*) 'Day:',day_total
        write(30006,*) 'Daily GW/SW Exchange for each Subarea'
        write(30006,*) 'Aquifer/Stream       Drain/Stream'
      endif
      
      !out files for gw-sw solute mass loadings to APEX subareas
      if(rt_active.eq.1) then
        write(30007,*)
        write(30007,*) 'Day:',day_total
        write(30007,*) 'Daily GW/SW Mass Loading for each River Cell'
        write(30007,*) 'Layer, Row, Column, Loading'
        write(30011,*)
        write(30011,*) 'Day:',day_total
        write(30011,*) 'Daily GW/SW Mass Loading for each River Cell'
        write(30011,*) 'Layer, Row, Column, Loading'
        if(ISALT>0) then
        write(30015,*)
        write(30015,*) 'Day:',day_total
        write(30015,*) 'Daily GW/SW Mass Loading for each River Cell'
        write(30015,*) 'lay,row,col,so4,ca,mg,na,k,cl,co3,hco3'
        endif
      endif


      !calculate exchange rate (m3) between groundwater and surface water -----------------------------------
      if(IUNIT(4).gt.0) then !only proceed if the River package is active
      do i=1,MXRIVR
        
        IR = RIVR(2,i) !row of MODFLOW river cell
        IC = RIVR(3,i) !column of MODFLOW river cell
        mf_gridID = ((IR-1)*NCOL) + IC !grid ID of MODFLOW river cell
        found = 0

        !loop through the River Cells that are connected to APEX subareas
        do m=1,nrivcells_subs
          
          !only proceed if there is a match
          if(mf_gridID.eq.grid2riv_cellID(m)) then
      
            !reset averaged river properties
            grid_rivlen = 0.
            exchange_rate = 0. !rate of water exchange between the aquifer and the river
        
            !retrieve values for the current River Cell
            IL = RIVR(1,i) !layer
            IR = RIVR(2,i) !row
            IC = RIVR(3,i) !column
            riv_head = RIVR(4,i) !river stage
            riv_cond = RIVR(5,i) !riverbed conductance
            riv_bot = RIVR(6,i) !riverbed elevation
            gw_head = HNEW(IC,IR,IL) !groundwater head in the River Cell
            
            !calculate the rate of loss/gain from/to rivers (L3/T) using Darcy's Law
            !(by comparing groundwater head to riverbed elevation)
            if(gw_head.gt.riv_bot) then !groundwater head greater than riverbed elevation
              exchange_rate = riv_cond * (riv_head - gw_head)
            else
              exchange_rate = riv_cond * (riv_head - riv_bot) !stream water enters aquifer
            endif

            !write out exchange rates
            if(out_MODFLOW_gwsw.eq.1 .and.
     &        day_total.eq.outapexmf(apexmf_out_ctr)) then
              write(30005,*) IL,IR,IC,exchange_rate
            endif
             
            !store for monthly and annual values
            amrt_GWSW_MF_tot_mo(i)=amrt_GWSW_MF_tot_mo(i)+exchange_rate
            amrt_GWSW_MF_tot_yr(i)=amrt_GWSW_MF_tot_yr(i)+exchange_rate
        
            !retrieve groundwater solute mass loading
            if(rt_active.eq.1) then
              no3_gw_loading = rt_rivmass(i,1) !grams of no3-n, from MODFLOW river cell
              no3_gw_loading = no3_gw_loading / 1000. !kg of no3-n
              p_gw_loading = rt_rivmass(i,2) !grams of dissolved P, from MODFLOW river cell
              p_gw_loading = p_gw_loading / 1000. !kg of P
              write(30007,*) IL,IR,IC,no3_gw_loading
              write(30011,*) IL,IR,IC,p_gw_loading
              if(ISALT>0) then
                so4_gw_loading = rt_rivmass(i,3) !grams of so4, from MODFLOW river cell
                ca_gw_loading = rt_rivmass(i,4)
                mg_gw_loading = rt_rivmass(i,5)
                na_gw_loading = rt_rivmass(i,6)
                k_gw_loading = rt_rivmass(i,7)
                cl_gw_loading = rt_rivmass(i,8)
                co3_gw_loading = rt_rivmass(i,9)
                hco3_gw_loading = rt_rivmass(i,10)
                so4_gw_loading = so4_gw_loading / 1000. !kg of so4
                ca_gw_loading = ca_gw_loading / 1000.
                mg_gw_loading = mg_gw_loading / 1000.
                na_gw_loading = na_gw_loading / 1000.
                k_gw_loading = k_gw_loading / 1000.
                cl_gw_loading = cl_gw_loading / 1000.
                co3_gw_loading = co3_gw_loading / 1000.
                hco3_gw_loading = hco3_gw_loading / 1000.
                write(30015,101)IL,IR,IC,so4_gw_loading,ca_gw_loading,
     &					  											 mg_gw_loading,na_gw_loading,
     &                                   k_gw_loading,cl_gw_loading,
     &																	 co3_gw_loading,hco3_gw_loading
              endif
            endif
        
            !The river cell might be in multiple subareas. Split the groundwater discharge and mass loadings
            !to these subareas based on stream length (usually, the cell is only in one subbasin)
            nsubs_cell = riv_nsubs(m)

            !Get total stream segment length within current river cell
            do j=1,nsubs_cell !rtb
              grid_rivlen = grid_rivlen + grid2riv_len(m,j)
            enddo
        
            !loop through the subareas that have spatial areas within the current river cell
            do j=1,nsubs_cell
            
              !calculate volume of groundwater discharge to the subarea
              subID = grid2riv_id(m,j) !subarea ID
              discharge = exchange_rate * (-1) !positive now = aquifer to the stream
              call units(discharge, mf_lengthUnit, 12, 3, 1, LPYR)! convert length unit (LENUNI**3/ITMUNI to m**3/ITMUNI)
              call units(discharge, 4, mf_timeUnit, 1, 1, LPYR)! convert time unit (m**3/ITMUNI to m**3/day)          
              discharge = discharge * (grid2riv_len(m,j)/grid_rivlen) !portion of discharge for the subarea
              sub_gw_exchange(subID) = sub_gw_exchange(subID)+discharge !add to subarea discharge total

              !store for monthly and annual values
              amrt_GWSW_APEX_tot_mo(subID)=amrt_GWSW_APEX_tot_mo(subID)+
     &                                     discharge
              amrt_GWSW_APEX_tot_yr(subID)=amrt_GWSW_APEX_tot_yr(subID)+
     &                                     discharge

              !add river cell solute mass loading to the total groundwater mass loading for the subbasin
              if(rt_active.eq.1) then
                loading = no3_gw_loading * (-1) !positive now signifies loading to the stream
                loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                sub_gwno3_exchange(subID) = sub_gwno3_exchange(subID) + 
     &                                      loading
                loading = p_gw_loading * (-1) !positive now signifies loading to the stream
                loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                sub_gwp_exchange(subID) = sub_gwp_exchange(subID) + 
     &                                    loading
                !rtb salt
                if(ISALT>0) then
                  !so4
                  loading = so4_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,1)=sub_salt_exchange(subID,1)
     &                                         + loading 
     
                   
                  if(sub_salt_exchange(subID,1).lt.-1e7) then
                    dum = 10
                  endif
     
                  !ca
                  loading = ca_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,2)=sub_salt_exchange(subID,2)
     &                                         + loading 
                  !mg
                  loading = mg_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,3)=sub_salt_exchange(subID,3)
     &                                         + loading 
                  !na
                  loading = na_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,4)=sub_salt_exchange(subID,4)
     &                                         + loading 
                  !k
                  loading = k_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,5)=sub_salt_exchange(subID,5)
     &                                         + loading 
                  !cl
                  loading = cl_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,6)=sub_salt_exchange(subID,6)
     &                                         + loading 
                  !co3
                  loading = co3_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,7)=sub_salt_exchange(subID,7)
     &                                         + loading 
							!hco3
                  loading = hco3_gw_loading * (-1) !positive now signifies loading to the stream  
                  loading = loading * (grid2riv_len(m,j)/grid_rivlen)
                  sub_salt_exchange(subID,8)=sub_salt_exchange(subID,8)
     &                                         + loading 
                endif
              endif

            enddo !go to the next subarea
          endif
        enddo !end loop to determine if MODFLOW River cell has a match with a cell that is linked with an APEX subarea
      enddo !go to next MODFLOW River Cell
      endif

      
      !print out gw-sw solute mass loadings by subarea
      if(rt_active.eq.1) then
        write(30008,*) 'Day:',day_total
        write(30012,*) 'Day:',day_total
        if(ISALT>0) then
          write(30016,*) 'Day:',day_total
          write(30016,*)'subarea,so4,ca,mg,na,k,cl,co3,hco3'
        endif
        do i=1,MSA
          write(30008,*) i,sub_gwno3_exchange(i)
          write(30012,*) i,sub_gwp_exchange(i)
          if(ISALT>0) then
            write(30016,102) i,(sub_salt_exchange(i,j),j=1,mion)
          endif
        enddo
	endif

      if(IDA.gt.53) then
        dum = 10
      endif

      !Determine drain water added to each sub-basin (from MODFLOW's drain package) -----------------------------------
      if(IUNIT(3).GT.0 .and. mf_drain_subs.eq.1) then
        
        !loop through the DRAIN cells
        do i=1,NDRAIN

          !get the cell index for the current DRAIN cell
          drn_lay = DRAI(1,i)
          drn_row = DRAI(2,i)
          drn_col = DRAI(3,i)

          !only proceed if the MODFLOW cell is active
          if(IBOUND(drn_col,drn_row,drn_lay).gt.0) then

            drn_elev = DRAI(4,i) !elevation of drain

            !only proceed if groundwater head is above the drain
            cell_head = HNEW(drn_col,drn_row,drn_lay)
            if(cell_head.gt.drn_elev) then
              drn_cond = DRAI(5,i) !conductance between drain and aquifer
              
              !calculate flow rate to the drain (and change units to m3/day)
              drn_flow = drn_cond * (cell_head - drn_elev) !L3/day
              drnrate(1) = drn_flow
              !call units(drnrate, mf_lengthUnit, 12, 3, 1, leapyr)! convert length unit (LENUNI**3/ITMUNI to m**3/ITMUNI)
              !call units(drnrate, 4, mf_timeUnit, 1, 1, leapyr)! convert time unit (m**3/ITMUNI to m**3/day)
              
              call units(drnrate, mf_lengthUnit, 12, 3, 1, LPYR)! convert length unit (LENUNI**3/ITMUNI to m**3/ITMUNI)  !Ali
              call units(drnrate, 4, mf_timeUnit, 1, 1, LPYR)! convert time unit (m**3/ITMUNI to m**3/day)               !Ali

              !find the subarea associated with the DRAIN cell
              subID = drn_subs(drn_row,drn_col)
              if(subID.gt.0) then
                sub_drn(subID) = sub_drn(subID) + drnrate(1)
              endif

            endif
          endif
        enddo !go to the next DRAIN cell

      endif !if DRAIN package is used      
      


      !Write out values for each APEX subarea ---------------------------------------------------------------
      if(out_APEX_gwsw.eq.1 .and.
     &   day_total.eq.outapexmf(apexmf_out_ctr)) then
        do i=1,MSA
          write(30006,*) sub_gw_exchange(i),sub_drn(i)
        enddo
        apexmf_out_ctr = apexmf_out_ctr + 1
      endif   
      

      
      !calculate water balance terms for groundwater: total volume, recharge, boundary flow, gw-->sw, sw-->gw
      
      !groundwater-->surface water; surface water-->groundwater
      sum_gwsw = 0.
      sum_swgw = 0.
      do i=1,MSA
        if(sub_gw_exchange(i).gt.0) then
          sum_gwsw = sum_gwsw + (sub_gw_exchange(i)*(-1))
        else
          sum_swgw = sum_swgw + (sub_gw_exchange(i)*(-1))
        endif
      enddo 
      
      !recharge to the water table
      sum_rech = 0.
      do i=1,nrow
        do j=1,ncol
          sum_rech = sum_rech + RECH(j,i)
        enddo
      enddo
      
      !change in groundwater volume (m3)
      gw_change = (VBVL(3,1) - VBVL(4,1)) * (-1)
    
      !total groundwater added/removed via constant head boundaries (m3)
      gw_conhead = (VBVL(3,2) - VBVL(4,2))    
      
      !calculate total groundwater volume
      gw_volume = 0.
      sub_gw_volume = 0.
      if(IUNIT(1) /= 0) then
        num_layer = mf_NTOP
      else
        num_layer = NLAY
      endif
      ctr = 1
      do i=1,NROW
        do j=1,NCOL
          do k=1,num_layer
            thickness = 0
            if(ibound(j,i,k).ne.0) then
            !Determine saturated thickness of the current layer
            if(HNEW(j,i,k).gt.BOTM(j,i,0)) then !head above the top of layer 1
              thickness = HNEW(j,i,k) - BOTM(j,i,0)
            else
              if(HNEW(j,i,k).lt.BOTM(j,i,k-1) .and. !BOTM(J,I,0) contains the top of layer 1
     &             HNEW(j,i,k).gt.BOTM(j,i,k)) then 
                thickness = HNEW(j,i,k) - BOTM(j,i,k)
              else
                thickness = BOTM(j,i,k-1) - BOTM(j,i,k)
              endif
            endif
            cell_area = DELR(j) * DELC(i)
            if(IUNIT(23).gt.0 .or. IUNIT(1).gt.0) then
              sy = mf_SC2(j,i,k) / cell_area !specific yield from cell storage capacity
            else
              sy = SC2UPW(j,i,k) / cell_area !specific yield from cell storage capacity
            endif
            cell_gw_volume = thickness * cell_area * sy
            gw_volume = gw_volume + cell_gw_volume

            !determine the subarea for the current grid cell (find first intersected subarea for the current cell)
            !loop through the Subareas that contribute area to the MODFLOW grid cell
            do m=1,size(s2g_map(ctr)%subarea_id)
              subareaID = s2g_map(ctr)%subarea_id(m)
              if(subareaID.gt.0) then
              perc_area = (s2g_map(ctr)%subarea_area(m)/cell_area)
              sub_gw_volume(subareaID) = sub_gw_volume(subareaID) + 
     &                                 (cell_gw_volume * perc_area)
              !NO3-N and P mass (kg)
              if(rt_active.eq.1) then
                sub_gwno3(subareaID) = sub_gwno3(subareaID) +
     &             (cell_gw_volume*CNEW(j,i,k,1)/1000.*perc_area) !kg of NO3-N in groundwater
                sub_gwp(subareaID) = sub_gwp(subareaID) +
     &             (cell_gw_volume*CNEW(j,i,k,2)/1000.*perc_area) !kg of P in groundwater
              endif 
              endif
            enddo

            endif
          enddo
          ctr = ctr + 1
        enddo
      enddo

	!write to daily groundwater balance file
      write(29998,100) day_total,gw_volume,gw_change,gw_conhead,
     &                 sum_rech,sum_gwsw,sum_swgw
      
      
      
      
      !Determine water table location (layer) and the thickness of the vadose zone ------------------------------------
      !(this will be used to determine if the water table is in APEX's soil profile, and
      !(thus whether the soil processes are affected by the water table)

      !Loop through MODFLOW variables and pull out information
      do j=1,NROW
        do i=1,NCOL
          do k=1,NLAY
            !Loop through and find which layer the water table is in
            if(HNEW(i,j,k).LT.BOTM(i,j,k-1) .and. !BOTM(J,I,0) contains the top of layer1
     &           HNEW(i,j,k).GT.BOTM(i,j,k)) then 
              wtlocation(i,j) = k
              wt_depth_cell(i,j) = BOTM(i,j,0) - HNEW(i,j,k) !distance between the ground surface and the water table
            endif
          enddo
        enddo
      enddo

      !Convert water table depth from MODFLOW grid cells to APEX subareas
      call amrt_grid2sa2D(wt_depth_cell, sub_wt_depth)   
      call units(sub_wt_depth,mf_lengthUnit,12,1,MSA,LPYR) ! to convert length units (LENUNI to mm)
      call units(sub_wt_depth,mf_timeUnit,4,1,MSA,LPYR)    ! to convert time units (ITMUNI to days)
	
      !increment total simulation day counter
      day_total = day_total + 1
      
      !zero out arrays for next day
      if(allocated(latsalt)) latsalt = 0. !salt ion mass in lateral return flow
      
      
 100  format(i6,20e20.10)
 101	format(i6,i6,i6,100(f12.4))
 102  format(i6,100(f12.4))
      
      return
      end