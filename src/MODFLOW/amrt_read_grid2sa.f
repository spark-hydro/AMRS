      subroutine amrt_read_grid2sa

!!    ~ ~ ~ Purpose ~ ~ ~
!!    This subroutine reads the list of MODFLOW grid cells within each APEX subarea

      use GLOBAL, only: NCOL, NROW, NLAY !MODFLOW
      use amrt_parm !APEX-MODFLOW
      implicit none
      
      !initialize local variables
      integer i,j,subareaID,num_subarea_cells

      !open file
      open (6004,file="MODFLOW/apexmf_grid2sa.txt") 
      print *, 'Reading Grid to Subarea mapping information...'

      !read the total number of APEX subareas in the watershed (i.e., how many will be read in)
      read(6004,*) nsubs

      !allocate the main mapping array (grid --> subarea)
      allocate(g2s_map(nsubs))

      !loop through each subarea, reading in the information for each intersected grid cell
      do i=1,nsubs
        
        !Subarea ID, # of cells contributing to the subarea
        read(6004,*) subareaID,num_subarea_cells
        
        if(num_subarea_cells.gt.0) then
        
        !allocate the second dimension of the array, according to the number of contributing cells
        allocate(g2s_map(i)%cell_row(num_subarea_cells))
        allocate(g2s_map(i)%cell_col(num_subarea_cells))
        allocate(g2s_map(i)%cell_perc(num_subarea_cells))

        !read in the row ID, column ID, and percent area for each MODFLOW grid cell within the subarea
        read(6004,*) (g2s_map(i)%cell_row(j),j=1,num_subarea_cells)
        read(6004,*) (g2s_map(i)%cell_col(j),j=1,num_subarea_cells)
        read(6004,*) (g2s_map(i)%cell_perc(j),j=1,num_subarea_cells)

        else
          allocate(g2s_map(i)%cell_row(0))
          allocate(g2s_map(i)%cell_col(0))
          allocate(g2s_map(i)%cell_perc(0))
          read(6004,*)
          read(6004,*)
          read(6004,*)
        endif

      enddo !go to the next subarea

      !clope the input file
      close(6004)


      return
      end