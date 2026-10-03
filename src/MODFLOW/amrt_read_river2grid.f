      subroutine amrt_read_river2grid()

!!    ~ ~ ~ Purpose ~ ~ ~
!!    This subroutine reads the APEX subareas associated with MODFLOW River Cells

!     Import variables
      use GLOBAL, only:LENUNI,ITMUNI !MODFLOW
      use amrt_parm !APEX-MODFLOW
      implicit none
      
!     Initialize local variables
      integer i,j,temp,nsub_current      
      
!     Read in the ID and percent area of each APEX Subarea contributing to each MODFLOW grid cell
      open (6005,file="MODFLOW/apexmf_river2grid.txt")  !Ali 
      print *, 'Reading Subarea to River Cell mapping...'
      print *

      !# of river cells that are linked to APEX subareas
      read(6005,*) nrivcells_subs
      
!     Allocate the variable sizes, which needs to be called here before reading the file continues
      call amrt_allocate()    
      
!     Read which APEX river reaches are within each MODFLOW river cell, and their associated river lengths
      do i=1,nrivcells_subs
        read(6005,*) temp,grid2riv_cellID(i),nsub_current ! cell #, then the number of subbasins associated with the cell
        if (nsub_current.gt.0) then
          read(6005,*) (grid2riv_id(i,j), j=1,nsub_current) ! list of subarea ID numbers which are within the current cell
          read(6005,*) (grid2riv_len(i,j),j=1,nsub_current) ! list of length of river within the current cell
          riv_nsubs(i) = nsub_current
        else
          read(6005,*)
          read(6005,*)
        endif
        
      enddo
      close(6005)

      return
      end