      subroutine amrt_init_mf 

!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    This subroutine initializes MODFLOW linking subroutines of APEX-MODFLOW

      use PARM, only:MSA    !APEX
      use GLOBAL,only:IUNIT !MODFLOW
      use amrt_parm         !APEX-MODFLOW
      use mf_rt_link        !RT3D

      implicit none
      integer i,j,k,n,subareaID,subarea_read
      real    delay

      print *
      print *, 'MODFLOW is being used'
        
      !set up MODFLOW data and allocate arrays
      call mf_read
        
      !read APEX-MODFLOW linkage files
      call amrt_read_grid2sa
      call amrt_read_sa2grid
      call amrt_read_river2grid
      if(IUNIT(3).GT.0 .and. mf_drain_subs.eq.1) then
        call amrt_read_drain2sub        
      endif

      !read groundwater delay values
      read(6001,*)
      read(6001,*) subarea_read
      if(subarea_read.eq.0) then
        read(6001,*) delay
        gw_delaye = Exp(-1./(delay + 1.e-6))
      else
        do n=1,MSA
          read(6001,*) delay
          gw_delaye(n) = Exp(-1./(delay + 1.e-6))
        enddo
      endif
      close(6001)  

      !read RT3D information if active
      if(rt_active /= 0) call amrt_init_rt3d


      end subroutine amrt_init_mf
