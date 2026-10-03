      subroutine salt_read
!!    ~ ~ ~ PURPOSE ~ ~ ~
!!    this subroutine reads salinity data from the main salt input file "salt_input" 

      use parm

      implicit none

      character (len=80) :: header
      character (len=10) :: day_text
      character (len=10) :: crop_type
      character (len=16) :: salt_header(100)
      character	(len=12) ::text1,text2,text3,text4,text5
      character	(len=16) ::text6,text7,text8,text9,text10
      integer :: i,j,jj,k,m,nly,crop_id,day,num_sub
      integer :: yrc,dayc,year_index,year_days
      logical :: salt_pt_exist
      real :: salt_conc(8),salt_fraction(5),
     &        sub_area_m2,water_volume,line_vals(1000)

      
      
      !open the salt input file
      open(2000,file='SALINITY/salt_input')
      read(2000,*) header
      read(2000,*)


      !read in Solubility Product parameters ----------------------------------------------------------------------------------------------
      read(2000,*) header
      read(2000,*) Ksp11
      read(2000,*) Ksp21
      read(2000,*) Ksp31
      read(2000,*) Ksp41
      read(2000,*) Ksp51


      !read in the initial salt ion concentrations in soil (for each subarea) -------------------------------------------------------------
      read(2000,*) header
      read(2000,*) header
      do j=1,MSA
        read(2000,*) (salt_conc(m),m=1,8)
        
        !initialze initial soil salt ion concentration values, for each layer
        do jj=1,NBSL(j)
          
          !soil layer ID
          ISL=LID(jj,j)
        
          !calculate total water (m3) in the soil layer (depth of water * subarea area)
          sub_area_m2 = WSA(j) * 10000. !m2
          water_volume = (SWST(ISL,j)/1000.) * sub_area_m2 !m * m2 = m3

          !loop through the salt ions
          do m=1,mion
            
            !copy concentration to the soil layer
            soil_csalt(ISL,j,m) = salt_conc(m) !g/m3
            
            !change from concentration (g/m3) to mass (kg/ha)
            wsalt(ISL,j,m) = (salt_conc(m)/1000) * water_volume /
     &                          WSA(j)
     
            !store initial concentration
            init_salt_conc(ISL,j,m) = salt_conc(m)
          
          enddo
        enddo !go to next soil layer
      enddo !go to next subarea



      !read in the initial soil salt mineral amounts ------------------------------------------------------------------
      read(2000,*) header
      read(2000,*) header
      do j=1,MSA
        read(2000,*) (salt_fraction(m),m=1,5)
        !loop through the soil layers
        do jj=1,NBSL(j)
          ISL=LID(jj,j) !soil layer ID
          !loop through the salt minerals
          do m=1,5
            salt_solid_soil(ISL,j,m) = salt_fraction(m)
            init_salt_fraction(ISL,j,m) = salt_fraction(m)
          enddo
        enddo
      enddo !go to next HRU
      

      
      !read in salt ion concentration in irrigation water (for each subarea) --------------------------------------------------------------
      read(2000,*) header
      read(2000,*) header
      do j=1,MSA
        read(2000,*) (irrig_csalt(j,k),k=1,8)      
      enddo

      
      !close the file
      close(2000)


      !check for salt point loads - if present, read in values for each day of the simulation
      inquire(file='SALINITY/salt_point_loads',exist=salt_pt_exist)
      salt_point = 0
      if(salt_pt_exist) salt_point = 1
      if(salt_point /= 0) then
        open(2007,file='SALINITY/salt_point_loads')
        read(2007,*)
        allocate(salt_ptloads(mion,msa,NBYR,366))
        do i=1,mion !loop through the 8 ions
          read(2007,*) header
          read(2007,*) header
          year_index = IYR0
          do yrc=1,NBYR
            !number of days in the year
            if(mod(year_index,4) == 0) then
              year_days = 366
            else
              year_days = 365
            endif
            do dayc=1,year_days
              read(2007,*) day,(line_vals(j),j=1,MSA)
              do j=1,MSA
                if(line_vals(j).gt.0) then
					    salt_ptloads(i,j,yrc,dayc) = line_vals(j)
						else
                  salt_ptloads(i,j,yrc,dayc) = 0.
						endif
              enddo
            enddo
            year_index = year_index + 1
          enddo
        enddo
      endif
      
      
      !open files for salt output -------------------------------------------------------------------------------------
      
      !subarea salt file
      open(2001,file='SALINITY/salt.output.budget_subarea_ions')
      write(2001,*) 'Daily salt ion output for subareas'
      write(2001,*) 'All values in kg of salt ion'
      write(2001,*) 'Negative values --> Mass leaving system'
      !soil profile
      salt_header(1) = 'soil_so4'
      salt_header(2) = 'soil_ca'
      salt_header(3) = 'soil_mg'
      salt_header(4) = 'soil_na'
      salt_header(5) = 'soil_k'
      salt_header(6) = 'soil_cl'
      salt_header(7) = 'soil_co3'
      salt_header(8) = 'soil_hco3'
      !total surface runoff
      salt_header(9) =  'surq_so4'
      salt_header(10) = 'surq_ca'
      salt_header(11) = 'surq_mg'
      salt_header(12) = 'surq_na'
      salt_header(13) = 'surq_k'
      salt_header(14) = 'surq_cl'
      salt_header(15) = 'surq_co3'
      salt_header(16) = 'surq_hco3'
      !salt in erosion runoff
      salt_header(17) = 'eros_so4'
      salt_header(18) = 'eros_ca'
      salt_header(19) = 'eros_mg'
      salt_header(20) = 'eros_na'
      salt_header(21) = 'eros_k'
      salt_header(22) = 'eros_cl'
      salt_header(23) = 'eros_co3'
      salt_header(24) = 'eros_hco3'
      !salt in lateral flow
      salt_header(25) = 'latq_so4'
      salt_header(26) = 'latq_ca'
      salt_header(27) = 'latq_mg'
      salt_header(28) = 'latq_na'
      salt_header(29) = 'latq_k'
      salt_header(30) = 'latq_cl'
      salt_header(31) = 'latq_co3'
      salt_header(32) = 'latq_hco3'
      !salt in quick return flow
      salt_header(33) = 'qrf_so4'
      salt_header(34) = 'qrf_ca'
      salt_header(35) = 'qrf_mg'
      salt_header(36) = 'qrf_na'
      salt_header(37) = 'qrf_k'
      salt_header(38) = 'qrf_cl'
      salt_header(39) = 'qrf_co3'
      salt_header(40) = 'qrf_hco3'
      !salt in irrigation water
      salt_header(41) = 'irrg_so4'
      salt_header(42) = 'irrg_ca'
      salt_header(43) = 'irrg_mg'
      salt_header(44) = 'irrg_na'
      salt_header(45) = 'irrg_k'
      salt_header(46) = 'irrg_cl'
      salt_header(47) = 'irrg_co3'
      salt_header(48) = 'irrg_hco3'
      !salt in precipation-dissolution
      salt_header(49) = 'prcp_so4'
      salt_header(50) = 'prcp_ca'
      salt_header(51) = 'prcp_mg'
      salt_header(52) = 'prcp_na'
      salt_header(53) = 'prcp_k'
      salt_header(54) = 'prcp_cl'
      salt_header(55) = 'prcp_co3'
      salt_header(56) = 'prcp_hco3'
      !salt in leaching
      salt_header(57) = 'leac_so4'
      salt_header(58) = 'leac_ca'
      salt_header(59) = 'leac_mg'
      salt_header(60) = 'leac_na'
      salt_header(61) = 'leac_k'
      salt_header(62) = 'leac_cl'
      salt_header(63) = 'leac_co3'
      salt_header(64) = 'leac_hco3'
      !salt in groundwater discharge
      salt_header(65) = 'gwsw_so4'
      salt_header(66) = 'gwsw_ca'
      salt_header(67) = 'gwsw_mg'
      salt_header(68) = 'gwsw_na'
      salt_header(69) = 'gwsw_k'
      salt_header(70) = 'gwsw_cl'
      salt_header(71) = 'gwsw_co3'
      salt_header(72) = 'gwsw_hco3'
      !salt in stream seepage
      salt_header(73) = 'swgw_so4'
      salt_header(74) = 'swgw_ca'
      salt_header(75) = 'swgw_mg'
      salt_header(76) = 'swgw_na'
      salt_header(77) = 'swgw_k'
      salt_header(78) = 'swgw_cl'
      salt_header(79) = 'swgw_co3'
      salt_header(80) = 'swgw_hco3'
      !salt in point sources
      salt_header(81) = 'pts_so4'
      salt_header(82) = 'pts_ca'
      salt_header(83) = 'pts_mg'
      salt_header(84) = 'pts_na'
      salt_header(85) = 'pts_k'
      salt_header(86) = 'pts_cl'
      salt_header(87) = 'pts_co3'
      salt_header(88) = 'pts_hco3'
      text1 = 'subarea'
      text2 = 'year'
      text3 = 'day'
      text4 = 'area(ha)'
      write(2001,500) text1,text2,text3,text4,
     &               (salt_header(jj),jj=1,88)
     
      !subarea salt budget file
      open(2002,file='SALINITY/salt.output.budget_subarea')
      write(2002,*) 'Daily salt budget for each subarea'
      write(2002,*) 'All values in kg of total salt'
      write(2002,*) 'Negative values --> Mass leaving system'
      salt_header(1) = 'soil'
      salt_header(2) = 'runoff'
      salt_header(3) = 'erosion'
      salt_header(4) = 'lateral'
      salt_header(5) = 'quick_rtn'
      salt_header(6) = 'irrig'
      salt_header(7) = 'prec-dissol'
      salt_header(8) = 'leaching'
      salt_header(9) = 'gw-->sw'
      salt_header(10) = 'sw-->gw'
      salt_header(11) = 'pt_source'
      text6 = 'subarea'
      text7 = 'year'
      text8 = 'day'
      text9 = 'area(ha)'
      write(2002,501) text6,text7,text8,text9,
     &               (salt_header(jj),jj=1,11)
      
      !aquifer salt budget file
      open(2003,file='SALINITY/salt.output.budget_aquifer')
      write(2003,*) 'Daily salt budget for the aquifer'
      write(2003,*) 'All values in kg of total salt'
      salt_header(1) = 'aquifer'
      salt_header(2) = 'recharge'
      salt_header(3) = 'gw-->sw'
      salt_header(4) = 'sw-->gw'
      salt_header(5) = 'boundary'
      text6 = 'year'
      text7 = 'day'
      write(2003,501) text6,text7,(salt_header(jj),jj=1,5)
      
      !watershed salt budget file
      open(2004,file='SALINITY/salt.output.budget_watershed')
      write(2004,*) 'Daily salt budget for the watershed'
      write(2004,*) 'All values in kg of total salt'
      write(2004,*) 'Negative values --> Mass leaving system'
      salt_header(1) = 'soil'
      salt_header(2) = 'runoff'
      salt_header(3) = 'erosion'
      salt_header(4) = 'lateral'
      salt_header(5) = 'quick_rtn'
      salt_header(6) = 'irrig'
      salt_header(7) = 'prec-dissol'
      salt_header(8) = 'leaching'
      salt_header(9) = 'APEXgwsw'
      salt_header(10) = 'APEXswgw'
      salt_header(11) = 'pt_source'
      salt_header(12) = 'aquifer'
      salt_header(13) = 'recharge'
      salt_header(14) = 'RT3Dgwsw'
      salt_header(15) = 'RT3Dswgw'
      salt_header(16) = 'boundary'
      text6 = 'year'
      text7 = 'day'
      write(2004,501) text6,text7,(salt_header(jj),jj=1,16)
      
      !subarea channel salt ion load and concentration file
      open(2005,file='SALINITY/salt.output.channels')
      write(2005,*) 'Daily salt ion channel output'
      write(2005,*) 'Q flow rates are in m3/sec'
      write(2005,*) 'Loadings are in kg'
      write(2005,*) 'Concentrations are in g/m3 = mg/L'
      !channel salt ion loads
      salt_header(1) = 'load_so4'
      salt_header(2) = 'load_ca'
      salt_header(3) = 'load_mg'
      salt_header(4) = 'load_na'
      salt_header(5) = 'load_k'
      salt_header(6) = 'load_cl'
      salt_header(7) = 'load_co3'
      salt_header(8) = 'load_hco3'
      !channel salt ion concentrations
      salt_header(9) =  'conc_so4'
      salt_header(10) = 'conc_ca'
      salt_header(11) = 'conc_mg'
      salt_header(12) = 'conc_na'
      salt_header(13) = 'conc_k'
      salt_header(14) = 'conc_cl'
      salt_header(15) = 'conc_co3'
      salt_header(16) = 'conc_hco3'
      text1 = 'subarea'
      text2 = 'year'
      text3 = 'day'
      text4 = 'area(ha)'
      text5 = 'Q_runoff'
      text6 = 'Q_total'
      write(2005,501) text1,text2,text3,text4,text5,text6,
     &               (salt_header(jj),jj=1,16)
      
      !watershed outlet salt ion load and concentration file
      open(2006,file='SALINITY/salt.output.outlet')
      write(2006,*) 'Daily salt ion output for watershed outlet subarea'
      write(2006,*) 'Q flow rates are in m3/sec'
      write(2006,*) 'Loadings are in kg'
      write(2006,*) 'Concentrations are in g/m3 = mg/L'
      !channel salt ion loads
      salt_header(1) = 'load_so4'
      salt_header(2) = 'load_ca'
      salt_header(3) = 'load_mg'
      salt_header(4) = 'load_na'
      salt_header(5) = 'load_k'
      salt_header(6) = 'load_cl'
      salt_header(7) = 'load_co3'
      salt_header(8) = 'load_hco3'
      !channel salt ion concentrations
      salt_header(9) =  'conc_so4'
      salt_header(10) = 'conc_ca'
      salt_header(11) = 'conc_mg'
      salt_header(12) = 'conc_na'
      salt_header(13) = 'conc_k'
      salt_header(14) = 'conc_cl'
      salt_header(15) = 'conc_co3'
      salt_header(16) = 'conc_hco3'
      text1 = 'subarea'
      text2 = 'year'
      text3 = 'day'
      text4 = 'area(ha)'
      text5 = 'Q_total'
      write(2006,501) text1,text2,text3,text4,text5,
     &               (salt_header(jj),jj=1,16)
     
     
      open(8642,file='SALINITY/conc_runoff_water')
      open(8643,file='SALINITY/conc_soil_water')
     
     
500   format(100a12)
501   format(100a16)
     
      return
      end