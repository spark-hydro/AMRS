      subroutine amrt_read_link

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    This subroutine reads in flags and variables for APEX-MODFLOW linkage

      !import variables
      use PARM, only: ISALT
      use GLOBAL, only: mf_interval,mf_ran !MODFLOW
      use mf_rt_link, only: rt_active !MODFLOW-RT3D Linkage
      use amrt_parm !APEX-MODFLOW
      implicit none
      
      integer n

      !read in information for linking APEX and MODFLOW
      open(6001,file="MODFLOW/apexmf_link.txt")
      read(6001,*) mf_drain_subs
      read(6001,*) rt_active
      read(6001,*) mf_obs_flag
      mf_ran = .false.
      mf_interval = 1 !this is set to 1 day

      !open up file that will contain daily groundwater balance output
      open(29998,file='MODFLOW/amf_MODFLOW_gwbalance')
      write(29998,*) 'Daily Groundwater Balance (m3)'
      write(29998,*) 'Note: Groundwater Volume values are approximate'
      write(29998,*)
      write(29998,1020)
      
      !Optional output files (for APEX-MODFLOW information)
        
      !APEX Deep Percolation (from APEX subareas)
      read(6001,*)
      read(6001,*) out_APEX_recharge 
      if(out_APEX_recharge.eq.1) then
        open(30001,file='MODFLOW/amf_apex_recharge.out')
        write(30001,*) 'APEX deep percolation (mm) (for each Subarea)'
      endif

      !MODFLOW Recharge (by MODFLOW cell)
      read(6001,*) out_MF_recharge 
      if(out_MF_recharge.eq.1) then
        open(30002,file='MODFLOW/amf_MF_recharge.out')
        write(30002,*) 'MODFLOW Recharge (L3/T) (for each cell)'
        write(30002,*) '--Calculated from APEX SA deep percolation--'
      endif

      !APEX Channel Depth (by APEX subarea)
      read(6001,*) out_APEX_channel 
      if(out_APEX_channel.eq.1) then
        open(30003,file='MODFLOW/amf_apex_channel.out')
        write(30003,*) 'APEX channel depth (m) (for each subbasin)'
      endif

      !MODFLOW River Stage (by MODFLOW River Cell)
      read(6001,*) out_MF_channel
      if(out_MF_channel.eq.1) then
        open(30004,file='MODFLOW/amf_MF_riverstage.out')
        write(30004,*) 'MODFLOW River Stage (L) (for each River Cell)'
        write(30004,*) '--Calculated from APEX Channel Depth--'
      endif

      !GW/SW exchange (by MODFLOW River cell)
      read(6001,*) out_MODFLOW_gwsw 
      if(out_MODFLOW_gwsw.eq.1) then
        open(30005,file='MODFLOW/amf_MF_gwsw.out')
        write(30005,*) 'Groundwater/Surface Water exchange (L3/T)'
        write(30005,*) 'for each MODFLOW River Cell'
        write(30005,*) 'Positive: River water seeps to the aquifer'
      write(30005,*) 'Negative: Groundwater flows from aquifer to river'
      endif

      !GW/SW exchange (by APEX subareas)
      read(6001,*) out_APEX_gwsw 
      if(out_APEX_gwsw.eq.1) then
        open(30006,file='MODFLOW/amf_apex_gwsw.out')
        write(30006,*) 'Groundwater/Surface Water exchange (m3/day)'
        write(30006,*) 'for each APEX subarea'
        write(30006,*) '--Calculated from MODFLOW River Package--'
      write(30006,*) 'Positive: Volume entering stream from the aquifer'
      write(30006,*) 'Negative: Volume seeps from stream to the aquifer'
      endif

      !read flag for printing out monthly and annual average output
      read(6001,*) apexmf_out_avg

      !output if RT3D is active
      if(rt_active.eq.1) then
      
      !GW/SW NO3 exchange (by MODFLOW River Cell) --------------------------------------- NITRATE
      open(30007,file='MODFLOW/amf_RT_rivno3.out')
      write(30007,*) 'Groundwater/Surface Water NO3 exchange (kg/day)'
      write(30007,*) 'for each MODFLOW River Cell'
      write(30007,*) 'Positive: Mass seeps to the aquifer'
      write(30007,*) 'Negative: Mass from aquifer to river'

      !GW/SW NO3 exchange (by APEX subbasin)
      open(30008,file='MODFLOW/amf_apex_rivno3.out')
      write(30008,*) 'Groundwater/Surface Water NO3 exchange (kg/day)'
      write(30008,*) 'for each APEX subarea'
      write(30008,*) '--Calculated from MODFLOW River Package--'
      write(30008,*) 'Positive: Mass entering stream from the aquifer'
      write(30008,*) 'Negative: Mass seeps from stream to the aquifer'
      
      !NO3 percolation concentration to MODFLOW grid
      open(30009,file='MODFLOW/amf_RT3D_percno3.out')
      write(30009,*) 'RT3D NO3 Perc. Conc. (mg/L) for each cell'
      write(30009,*) '--Calculated from APEX subarea deep percolation--'

      !NO3 percolation mass from each APEX subarea
      open(30010,file='MODFLOW/amf_apex_percno3.out')
      write(30010,*) 'APEX NO3 Perc. Mass (kg/ha)'
      write(30010,*) 'Subarea, Area(ha), Perc(kg/ha)'

      !GW/SW P exchange (by MODFLOW River Cell) ----------------------------------------- PHOSPHORUS
      open(30011,file='MODFLOW/amf_RT_rivP.out')
      write(30011,*) 'Groundwater/Surface Water P exchange (kg/day)'
      write(30011,*) 'for each MODFLOW River Cell'
      write(30011,*) 'Positive: Mass seeps to the aquifer'
      write(30011,*) 'Negative: Mass from aquifer to river'

      !GW/SW P exchange (by APEX subarea)
      open(30012,file='MODFLOW/amf_apex_rivP.out')
      write(30012,*) 'Groundwater/Surface Water P exchange (kg/day)'
      write(30012,*) 'for each APEX subarea'
      write(30012,*) '--Calculated from MODFLOW River Package--'
      write(30012,*) 'Positive: Mass entering stream from the aquifer'
      write(30012,*) 'Negative: Mass seeps from stream to the aquifer'
      
      !P percolation concentration to MODFLOW grid
      open(30013,file='MODFLOW/amf_RT_percP.out')
      write(30013,*) 'RT3D P Perc. Conc. (mg/L) for each cell'
      write(30013,*) '--Calculated from APEX subarea deep percolation--'

      !P percolation concentration from each APEX subarea
      open(30014,file='MODFLOW/amf_apex_percP.out')
      write(30014,*) 'APEX P Perc. Mass (kg/ha)'
      write(30014,*) 'Subarea, Area(ha), Perc(kg/ha)'
      
      
      !GW/SW NO3 exchange (by MODFLOW River Cell) --------------------------------------- SALT ION
      if(ISALT>0) then
      open(30015,file='MODFLOW/amf_RT_rivSalt.out')
      write(30015,*) 'Groundwater/Surface Water Salt exchange (kg/day)'
      write(30015,*) 'for each MODFLOW River Cell'
      write(30015,*) 'Positive: Mass seeps to the aquifer'
      write(30015,*) 'Negative: Mass from aquifer to river'

      !GW/SW Salt ion exchange (by APEX subarea)
      open(30016,file='MODFLOW/amf_apex_rivSalt.out')
      write(30016,*) 'Groundwater/Surface Water Salt exchange (kg/day)'
      write(30016,*) 'for each APEX subarea'
      write(30016,*) '--Calculated from MODFLOW River Package--'
      write(30016,*) 'Positive: Mass entering stream from the aquifer'
      write(30016,*) 'Negative: Mass seeps from stream to the aquifer'
      
      !Salt ion percolation concentration to MODFLOW grid
      open(30017,file='MODFLOW/amf_RT_percSalt.out')
      write(30017,*) 'RT3D Salt Perc. Conc. (mg/L) for each cell'
      write(30017,*) '--Calculated from APEX subarea deep percolation--'

      !Salt ion percolation concentration from each APEX subarea
      open(30018,file='MODFLOW/amf_apex_percSalt.out')
      write(30018,*) 'APEX Salt ion Perc. Mass (kg/ha)'
      write(30018,*) 'Subarea, Area(ha), Perc(kg/ha)'
      
      endif
      endif

      !Read output control for APEX-MODFLOW variables
      read(6001,*)
      read(6001,*) n_outapexmf
      allocate(outapexmf(n_outapexmf+1))
      do n=1,n_outapexmf
        read(6001,*) outapexmf(n)
      enddo
      apexmf_out_ctr = 1

      !open files for variable average output (rtb avg)
      if(apexmf_out_avg /= 0) then
        
        !recharge (to modflow)
        open(30020,file='MODFLOW/amf_MF_recharge_monthly.out')
        write(30020,*) 'Monthly Total Recharge Values for MODFLOW (m3)'
        write(30020,*)

        open(30021,file='MODFLOW/amf_MF_recharge_yearly.out')
        write(30021,*) 'Yearly Total Recharge Values for MODFLOW (m3)'
        write(30021,*)

        !recharge (from APEX)
        open(30024,file='MODFLOW/amf_apex_recharge_monthly.out')
        write(30024,*) 'Monthly Total Recharge Values from apex (mm)'
        write(30024,*)

        open(30025,file='MODFLOW/amf_apex_recharge_yearly.out')
        write(30025,*) 'Yearly Total Recharge Values from apex (mm)'
        write(30025,*)

        !gw/sw exchange (modflow)
        open(30026,file='MODFLOW/amf_MF_gwsw_monthly.out')
        write(30026,*) 'Monthly Total GW/SW Rates for River Cells (m3)'
        write(30026,*) 'Negative values: GW --> SW'
        write(30026,*) 'Positive values: SW --> GW'
        write(30026,*)

        open(30027,file='MODFLOW/amf_MF_gwsw_yearly.out')
        write(30027,*) 'Annual Total GW/SW Rates for River Cells (m3)'
        write(30027,*) 'Negative values: GW --> SW'
        write(30027,*) 'Positive values: SW --> GW'
        write(30027,*)

        !gw/sw exchange (apex)
        open(30028,file='MODFLOW/amf_apex_gwsw_monthly.out')
        write(30028,*) 'Monthly Total GW/SW Rates for apex subareas(m3)'
        write(30028,*) 'Positive values: GW --> SW'
        write(30028,*) 'Negative values: SW --> GW'
        write(30028,*)

        open(30029,file='MODFLOW/amf_apex_gwsw_yearly.out')
        write(30029,*) 'Annual Total GW/SW Rates for apex subareas (m3)'
        write(30029,*) 'Positive values: GW --> SW'
        write(30029,*) 'Negative values: SW --> GW'
        write(30029,*)

        !solute concentration in groundwater (RT3D)
        if(rt_active.eq.1) then
          open(30030,file='MODFLOW/amf_RT3D_cNO3_monthly.out')
          write(30030,*) 'Monthly Averaged GW Nitrate Concentration'
          write(30030,*)

          open(30031,file='MODFLOW/amf_RT3D_cNO3_yearly.out')
          write(30031,*) 'Yearly Averaged GW Nitrate Concentration'
          write(30031,*)
          
          open(30032,file='MODFLOW/amf_RT3D_cP_monthly.out')
          write(30032,*) 'Monthly Averaged GW Phosphorus Concentration'
          write(30032,*)

          open(30033,file='MODFLOW/amf_RT3D_cP_yearly.out')
          write(30033,*) 'Yearly Averaged GW Phosphorus Concentration'
          write(30033,*) 
          
          if(ISALT>0) then
            open(30034,file='MODFLOW/amf_RT3D_cSalt_monthly.out')
            write(30034,*) 'Monthly Averaged GW Salt Ion Concentration'
            write(30034,*)

            open(30035,file='MODFLOW/amf_RT3D_cSalt_yearly.out')
            write(30035,*) 'Yearly Averaged GW Salt Ion Concentration'
            write(30035,*)   
		  endif 
        endif
        
      endif



 1020 format (t3,'SimDay',
     &        t10,'GWVolume',t22,'GWChange',t34,'ConHead',t46,
     &        'Recharge',t58,'GWSWQ',t70,'SWGWQ')      
      
      return
      end
