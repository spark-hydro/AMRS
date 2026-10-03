      subroutine amrt_mf_run
!!
!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    This subroutine 1) converts APEX to MODFLOW, 2) runs MODFLOW, 3) converts MODFLOW to APEX
      
      use parm, only: MSA,LPYR,IDA,IYR,ISALT,mion,salt_species !APEX
      use GLOBAL, only: mf_interval,mf_ran,NCOL,NROW,NLAY,IBOUND !MODFLOW
      use amrt_parm  !APEX-MODFLOW
      use mf_rt_link, only: rt_active !RT3D
      use GWFRIVMODULE, only:MXRIVR
      use GWFBASMODULE, only:HNOFLO 
      implicit none
      integer i,j,k,m
      integer days_in_month(12) !rtb avg
                 
      !convert APEX units to MODFLOW units
      call amrt_conversion2mf
          
      !run modflow (water table, river discharge/seepage, pumping)
      call mf_run
          
      !convert MODFLOW units back to APEX units
      call amrt_conversion2apex

      !Print out APEX-MODFLOW variable averages (rtb avg) -----------------------------------------------------------
      if(apexmf_out_avg /= 0) then
      if(LPYR.eq.0) then
        days_in_month = month_days
      else
        days_in_month = month_days_leap
      endif
        
      !check to see if end of month has been reached
      if(IDA.eq.days_in_month(amrt_month_counter)) then
            
        !print out monthly totals for MODFLOW recharge
        write(30020,*), 'month:',amrt_month_counter,'year:',IYR
        do i=1,NROW
          write(30020,100) (amrt_RECH_tot_mo(j,i),j=1,NCOL)
        enddo
        write(30020,*)
          
        !print out monthly totals for APEX recharge
        write(30024,*), 'month:',amrt_month_counter,'year:',IYR
        do i=1,MSA          
          write(30024,*) i,amrt_RECH_APEX_tot_mo(i)
        enddo
        write(30024,*)

        !MODFLOW GW/SW
        write(30026,*), 'month:',amrt_month_counter,'year:',IYR
        do i=1,MXRIVR
          write(30026,*) amrt_GWSW_MF_tot_mo(i)
        enddo
        write(30026,*)

        !APEX GW/SW
        write(30028,*), 'month:',amrt_month_counter,'year:',IYR
        do i=1,MSA         
          write(30028,*) i,amrt_GWSW_APEX_tot_mo(i)
        enddo
        write(30028,*)

        !solute concentration
        if(rt_active.eq.1) then
        
        !nitrate
        write(30030,*), 'month:',amrt_month_counter,'year:',iyr
        do k=1,NLAY
          write(30030,*),'layer:',k
          do i=1,NROW
            write(30030,100) (amrt_csolute_avg_mo(j,i,k,1),j=1,NCOL)
          enddo
        enddo
        write(30030,*)
        
        !phosphorus
        write(30032,*), 'month:',amrt_month_counter,'year:',iyr
        do k=1,NLAY
          write(30032,*),'layer:',k
          do i=1,NROW
            write(30032,100) (amrt_csolute_avg_mo(j,i,k,2),j=1,NCOL)
          enddo
        enddo
        write(30032,*)
        
        !salt ions
        if(ISALT>0) then
        write(30034,*), 'month:',amrt_month_counter,'year:',iyr
        do m=1,mion
          write(30034,*) salt_species(m)
          do k=1,NLAY
            write(30034,*),'layer:',k
            do i=1,NROW
              write(30034,100) (amrt_csolute_avg_mo(j,i,k,2+m),j=1,NCOL)
            enddo
          enddo
        enddo
        write(30034,*)
        endif
        
        endif

        !reset total monthly values
        amrt_RECH_tot_mo = 0.
        amrt_RECH_APEX_tot_mo = 0.
        amrt_GWSW_MF_tot_mo = 0.
        amrt_GWSW_APEX_tot_mo = 0.
        if(allocated(amrt_csolute_tot_mo)) amrt_csolute_tot_mo = 0.

        !print out yearly totals if last month of year
        if(amrt_month_counter.eq.12) then
            
          !MODFLOW recharge
          write(30021,*), 'year:',IYR
          do i=1,NROW
            write(30021,100) (amrt_RECH_tot_yr(j,i),j=1,NCOL)
          enddo
          write(30021,*)

          !APEX recharge
          write(30025,*), 'year:',IYR
          do i=1,MSA             
            write(30025,*) i,amrt_RECH_APEX_tot_yr(i)
          enddo
          write(30025,*)

          !MODFLOW GW/SW
          write(30027,*), 'year:',IYR
          do i=1,MXRIVR
            write(30027,*) amrt_GWSW_MF_tot_yr(i)
          enddo
          write(30027,*)

          !APEX GW/SW
          write(30029,*), 'year:',IYR
          do i=1,MSA           
            write(30029,*) i,amrt_GWSW_APEX_tot_yr(i)
          enddo
          write(30029,*)

          !solute concentration
          if(rt_active.eq.1) then
          
          !nitrate
          write(30031,*), 'year:',iyr
          do k=1,NLAY
            write(30031,*),'layer:',k
            do i=1,NROW
              write(30031,100) (amrt_csolute_avg_yr(j,i,k,1),j=1,NCOL)
            enddo
          enddo
          write(30031,*)
          
          !phosphorus
          write(30033,*), 'year:',iyr
          do k=1,NLAY
            write(30033,*),'layer:',k
            do i=1,NROW
              write(30033,100) (amrt_csolute_avg_yr(j,i,k,2),j=1,NCOL)
            enddo
          enddo
          write(30033,*)
          
          !salt ions
          if(ISALT>0) then
          write(30035,*), 'year:',iyr
          do m=1,mion
            write(30035,*) salt_species(m)
            do k=1,NLAY
              write(30035,*),'layer:',k
              do i=1,NROW
              write(30035,100) (amrt_csolute_avg_yr(j,i,k,2+m),j=1,NCOL)
              enddo
            enddo
          enddo
          write(30035,*)
          endif
          
          endif

          !reset total annual values
          amrt_RECH_tot_yr = 0.
          amrt_RECH_APEX_tot_yr = 0.
          amrt_GWSW_MF_tot_yr = 0.
          amrt_GWSW_APEX_tot_yr = 0.
          if(allocated(amrt_csolute_tot_yr)) amrt_csolute_tot_yr = 0.

          day_count_yr = 0
          amrt_month_counter = 0 !start in January
          endif
          amrt_month_counter = amrt_month_counter + 1
          day_count_mo = 0 !reset
        endif

        !increment each counter by one day
        day_count_mo = day_count_mo + 1
        day_count_yr = day_count_yr + 1
      endif


  100 format(1000(f12.4))

      end subroutine amrt_mf_run  !Ali