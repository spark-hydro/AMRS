      SUBROUTINE OPENF(ASTN)
!     APEX1501
!     THIS SUBPROGRAM OPENS FILES.
      USE PARM
      CHARACTER(4)::AXT
      CHARACTER(80)::ASTN
      DIMENSION AXT(48)
	  DATA AXT/".OUT",".MAN",".SUS",".ASA",".SWT",".DPS",".MSA",".AWP",&
      ".DHY",".WSS",".SAD",".HYC",".DRS","    ",".MWS",".DWS",".AWS",&
      ".DGZ",".DUX",".DDD",".ACN",".DCN",".SCX",".ACY",".EFR",".EHY",&
      ".APS",".MSW",".DPW",".SPS",".ACO",".SWN",".FSA",".SAO",".RCH",&
      ".ERX",".DMR",".STR",".MRH",".MGZ",".DNC",".DHS",".MSX",".DGN",&
      ".DPD",".ASL",".MS5",".AS5"/
      OPEN(KW(1),FILE=TRIM(ADJUSTL(ASTN))//AXT(1))
	  DO I=2,48
	      IF(AXT(I)/="    ".AND.KFL(I)>0)OPEN(KW(I),FILE=TRIM(ADJUSTL(ASTN))//AXT(I))
	  END DO
      RETURN
      END
      