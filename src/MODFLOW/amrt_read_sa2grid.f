      subroutine amrt_read_sa2grid  !Ali

!!    ~ ~ ~ Purpose ~ ~ ~
!!    This subroutine reads the list of APEX subareas that intersect with each MODFLOW grid cell

      use PARM, only: MSA
      use GLOBAL, only: NCOL,NROW,NLAY !MODFLOW
      use amrt_parm  !APEX-MODFLOW
      implicit none
      
      !initialize local variables
      integer i,j,cellID,num_cell_subareas,ncells,dum
      
      !open file
      open (6002,file="MODFLOW/apexmf_sa2grid.txt")
      print *, 'Reading Subarea to Grid mapping information...'
      
      !read the total number of MODFLOW grid cells
      read(6002,*) ncells
      
      !allocate the main mapping array (grid --> subarea)
      allocate(s2g_map(ncells))
      
      !loop through the MODFLOW grid cells, storing attributes of the subareas that intersect each cell
      do i=1,ncells

        !MODFLOW cell ID, # of subareas contributing to the cell
        read(6002,*) cellID,num_cell_subareas

        if(num_cell_subareas.gt.0) then
          
         !allocate the second dimension of the array, according to the number of contributing cells
         allocate(s2g_map(i)%subarea_id(num_cell_subareas))
         allocate(s2g_map(i)%subarea_area(num_cell_subareas))
          
         !read in the ID and percent area of each subarea
         read(6002,*) (s2g_map(i)%subarea_id(j),j=1,num_cell_subareas)
         read(6002,*) (s2g_map(i)%subarea_area(j),j=1,num_cell_subareas)

        else
         !empty cell: zero-size arrays, so size() is defined everywhere
         allocate(s2g_map(i)%subarea_id(0))
         allocate(s2g_map(i)%subarea_area(0))
        endif
        
      enddo
      close(6002)
      
      
      return
      end
