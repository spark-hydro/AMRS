      subroutine amrt_fixslash(fname)
!!    Windows-style folder separators in file names read from input files
!!    ('\' -> '/'): '/' is understood on every OS, '\' only on Windows.
      implicit none
      character*(*) fname
      integer ii
      do ii=1,len(fname)
        if(fname(ii:ii).eq.'\') fname(ii:ii)='/'
      end do
      return
      end
