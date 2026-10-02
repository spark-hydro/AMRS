      subroutine amrt_read_drain2sub()

      !This subroutine reads in the file containing the information to link
      !MODFLOW Drain cells to APEX subareas. This is used only if the MODFLOW
      !Drain package is active.

!     Import variables
      use GLOBAL, only:LENUNI,ITMUNI,NROW,NCOL !MODFLOW
      use amrt_parm !APEX-MODFLOW
      implicit none
      
!     Initialize local variables
      integer i,drn_row,drn_col,sub_basin     
      
!     Read in row, column, and associated sub-basin for each DRAIN cell
      open (6006,file="MODFLOW/apexmf_drain2sa.txt")  !Ali 
      print *, 'Reading Drain to Subbasin Mapping...'
      print *
      read(6006,*) ndrn_subs ! # of MODLFOW drain cells in the APEX domain
      read(6006,*)

      !allocate and populate the DRAIN_SUBS array
      allocate(drn_subs(NROW,NCOL))
      drn_subs = 0
      !allocate(drn_subs(ndrn_subs,3))
      do i=1,ndrn_subs
        read(6006,*) drn_row,drn_col,sub_basin
        drn_subs(drn_row,drn_col) = sub_basin
      enddo
      close(6006)

      return
      end