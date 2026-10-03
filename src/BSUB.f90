      SUBROUTINE BSUB(IXP)
!     APEX1501
!     THIS SUBPROGRAM DRIVES THE DAILY SUBAREA SIMULATION.
      USE PARM
      use amrt_parm !APEX-MODFLOW
	    
      integer m !rtb salt
      
      DIMENSION JGO(MNC)
      
      IDO=IDOT(ICMD)
      ISA=IDN1T(ICMD)
      
      IDOA(ISA)=IDO
      NISA(NBSA(ISA))=ISA
	    IDNB(IDO)=NBSA(ISA)
      IOW=IDON(ISA)
      WSAX=WSA(ISA)
      WSAX1=WSAX*10.
      RWSA(IDO)=WSAX
      LNS=LID(NBSL(ISA),ISA)
      LD1=LID(1,ISA)
      NMW(ISA)=NMW(ISA)+1
      DDMP=0.
      SDN=0.
      LRD(ISA)=MIN(LRD(ISA),NBSL(ISA))
      CALL WHLRMX(IDA) !calculate day length and solar radiation at the earth's surface																																	
      IHRL(MO,ISA)=IHRL(MO,ISA)+1                                                            
      THRL(MO,ISA)=THRL(MO,ISA)+HRLT                                                         
      SRMX(MO,ISA)=SRMX(MO,ISA)+RAMX
      IF(SRAD(IRF(ISA))<1.E-10.OR.SRAD(IRF(ISA))>900..OR.SRAD(IRF(ISA))<-90..OR.KGN(3)==0)THEN
          OBSL(IWI,MO)=RAMX*MAX(.8,.21*SQRT(OBMX(IWI,MO)-OBMN(IWI,MO)))
          CALL WGN !weather generator
          I=IRF(ISA)
          CALL WSOLRA(I) !daily solar radiation
      END IF
      IF(IPTS(ISA)>0)THEN
	      I=IPSO(ISA)
          SMM(104,MO,ISA)=SMM(104,MO,ISA)+PSOQ(I)
          SMM(105,MO,ISA)=SMM(105,MO,ISA)+PSON(I)
          VAR(105,ISA)=PSON(I)
          SMM(106,MO,ISA)=SMM(106,MO,ISA)+PSOP(I)
	      PSQX=PSOQ(I)/WSAX1
	      PSYX=PSOY(I)/WSAX
          PONX=PSON(I)/WSAX
          PPPX=PSOP(I)/WSAX
          PS3X=PSO3(I)/WSAX
          PSPX=PSSP(I)/WSAX
          PQPX=PQPS(I)/WSAX
          PYPX=PYPS(I)/WSAX	
          SMM(121,MO,ISA)=SMM(121,MO,ISA)+PSYX
          SMM(137,MO,ISA)=SMM(137,MO,ISA)+PS3X
          SMM(138,MO,ISA)=SMM(138,MO,ISA)+PSPX
          SMM(122,MO,ISA)=SMM(122,MO,ISA)+PQPX
          SMM(123,MO,ISA)=SMM(123,MO,ISA)+PYPX
      END IF
      PCT(1,ISA)=.01*SAN(1,ISA)
      PCT(2,ISA)=.01*SIL(1,ISA)
      PCT(3,ISA)=.01*CLA(1,ISA)
      PCT(4,ISA)=0.
      PCT(5,ISA)=0.
      DO I=1,NSZ
          PCTH(I,IDO)=PCT(I,ISA)
          PCT(I,IDO)=PCT(I,ISA)
      END DO
      VAR(4,ISA)=0.
      SMM(100,MO,ISA)=SMM(100,MO,ISA)+RFV0(IRF(ISA))
      IF(NGN/=0)RFV(IRF(ISA))=RFV0(IRF(ISA))
      IF(RFV(IRF(ISA))>0.)THEN
          RF1=RFV(IRF(ISA))
          VAR(4,ISA)=RF1
          SDVR(ISA)=SDVR(ISA)+RF1*RF1
	      TSNO(ISA)=0.
          IF(RF1>RMXS(ISA))THEN
              RMXS(ISA)=RF1
              MXSR(ISA)=KDA+100*MO+10000*IY
          END IF
          RF1=RF1*WSAX1
          SRD(MO,ISA)=SRD(MO,ISA)+1.
          SMM(4,MO,ISA)=SMM(4,MO,ISA)+RF1 !m3
      END IF
      IF(PADDY_HWEIR(ISA)>0)THEN 
          PADDY_STO(1,ISA)=PADDY_STO(1,ISA)+RFV(IRF(ISA)) !mm
          PADDY_STO(3,ISA)=PADDY_STO(3,ISA)+10.*RFNC*RFV(IRF(ISA)) !minN kg/ha
      ELSE
          VNO3(LD1,ISA)=10.*RFNC*RFV(IRF(ISA))
          RFQN(ISA)=VNO3(LD1,ISA)*WSAX
      ENDIF
      TAGP(ISA)=MAX(.001,TAGP(ISA))
      XRFI(ISA)=MIN(RFV(IRF(ISA)),PRMT(49)*(1.-EXP(-PRMT(50)*SQRT(TAGP&
      (ISA)*SMLA(ISA)))))
      SMM(85,MO,ISA)=SMM(85,MO,ISA)+XRFI(ISA)
      RFV(IRF(ISA))=RFV(IRF(ISA))-XRFI(ISA)
      EI=0.
      AL5=.02083
      IF(RFV(IRF(ISA))>0.)THEN
	      CALL HRFEI !rainfall energy factor
          UPLM=.95
          QMN=.25
          BLM=.05
          R1=ATRI(BLM,QMN,UPLM,8)
          RTP=R1*RFV(IRF(ISA))
          XK1=R1/4.605
          XK2=XK1*(1.-R1)/R1
          DURG=RFV(IRF(ISA))/(REP*(XK1+XK2))
          X1=REP*DURG
          XKP1=XK1*X1
          XKP2=XK2*X1
      END IF
      IF(ORSD(IRF(ISA))>0.)THEN
          RTO=ORSD(IRF(ISA))/RSD(LD1,ISA)
          WLS(LD1,ISA)=RTO*WLS(LD1,ISA)
          WLM(LD1,ISA)=RTO*WLM(LD1,ISA)
          RSD(LD1,ISA)=ORSD(IRF(ISA))
          WLMC(LD1,ISA)=RTO*WLMC(LD1,ISA)
          WLSC(LD1,ISA)=RTO*WLSC(LD1,ISA)
          WLMN(LD1,ISA)=RTO*WLMN(LD1,ISA)
          WLSN(LD1,ISA)=RTO*WLSN(LD1,ISA)
          FOP(LD1,ISA)=RTO*FOP(LD1,ISA)
      END IF            
      CV(ISA)=CV(ISA)+RSD(LD1,ISA)+STDO(ISA)
      CVRS(ISA)=CVRS(ISA)+RSD(LD1,ISA)+STDO(ISA)
      BCV(ISA)=1.
      RCF(ISA)=.9997*RCF(ISA)
      X1=CV(ISA)
      IF(SCLM(5)>0.)X1=MIN(X1,SCLM(5))
      IF(X1<10.)BCV(ISA)=X1/(X1+EXP(SCRP(5,1)-SCRP(5,2)*X1))
      SNOF=0.
      IF(SNO(ISA)>0.)THEN
          SNOF=SNO(ISA)/(SNO(ISA)+EXP(2.303-.2197*SNO(ISA)))
          BCV(ISA)=MAX(SNOF,BCV(ISA))
      END IF
      BCV(ISA)=MIN(BCV(ISA),.95)
      NN1=NTL(IRO(ISA),ISA)
      JT1=LT(IRO(ISA),KT(ISA),ISA)
      YW(IDO)=0.
      ERTO=1.
      ERTP=1.
	  YERO=0.
      IF(ACW>0..AND.SNO(ISA)<10..AND.LUN(ISA)/=35)THEN
          CALL WNDIR !daily wind direction
          CALL EWER(JRT) !daily soil loss caused by wind erosion
          IF(JRT==0)THEN
              YW(IDO)=YW(IDO)*ACW
              SMM(36,MO,ISA)=SMM(36,MO,ISA)+YW(IDO)
              VAR(36,ISA)=YW(IDO)
	          SYW=SYW+YW(IDO)*WSA(ISA)
	          YERO=YERO+YW(IDO)
              VAR(58,ISA)=RRF
              SMM(35,MO,ISA)=SMM(35,MO,ISA)+RGRF
              VAR(35,ISA)=RGRF
          END IF
          IF(YW(IDO)>PRMT(94))SMM(145,MO,ISA)=SMM(145,MO,ISA)+1.
          IF(WB>0.)CALL EWEMHKS(JRT) !daily soil loss caused by wind erosion  
          IF(JRT==0)THEN
              YWKS=YWKS*ACW
              SMM(139,MO,ISA)=SMM(139,MO,ISA)+YWKS
          END IF
      END IF
      QN(IDO)=0.
      SMM(7,MO,ISA)=SMM(7,MO,ISA)+U10(IRF(ISA))
      VAR(7,ISA)=U10(IRF(ISA))
      SMM(8,MO,ISA)=SMM(8,MO,ISA)+RHD(IRF(ISA))
      VAR(8,ISA)=RHD(IRF(ISA))
      TX=(TMN(IRF(ISA))+TMX(IRF(ISA)))/2.
      IF(TX>0.)HSM(ISA)=HSM(ISA)+TX
      IF(NAQ>0)CALL DUSTDST !settles and distributes particular matter from feedyards to surrounding subareas
      CALL SOLT !soil temperature
      LD2=LID(2,ISA)
      SMM(59,MO,ISA)=SMM(59,MO,ISA)+STMP(LD2,ISA)
      VAR(59,ISA)=STMP(LD2,ISA)
      YP(IDO)=0.
      YN(IDO)=0.
      YC(IDO)=0.
      QC(IDO)=0.
      YNWN(IDO)=0.
      YPWN(IDO)=0.
      YCWN(IDO)=0.
      YCOU(IDO)=0.
      YPOU(IDO)=0.
      YNOU(IDO)=0.
      QP(IDO)=0.
	  QPU(IDO)=0.
	  PKRZ=0.
	  SMM(1,MO,ISA)=SMM(1,MO,ISA)+TMX(IRF(ISA))
      VAR(1,ISA)=TMX(IRF(ISA))
      SMM(2,MO,ISA)=SMM(2,MO,ISA)+TMN(IRF(ISA))
      VAR(2,ISA)=TMN(IRF(ISA))
      SMM(3,MO,ISA)=SMM(3,MO,ISA)+SRAD(IRF(ISA))
      VAR(3,ISA)=SRAD(IRF(ISA))
      SML=0.
	  SNMN=0.
	  DO J=1,6
          YSD(J,IDO)=0.
      END DO
      YMNU(IDO)=0.
      YMNUX=0.
      CVF(ISA)=0.
      RQRB(IDO)=0.
      QVOL(IDO)=0.
      CPVV=0.
      CPVH(IDO)=0.
      VAR(5,ISA)=0.
      TSNO(ISA)=TSNO(ISA)+1.
      YPM(IDO)=0.
      QAPY=0.
      IF(.5*(TX+STMP(LID(2,ISA),ISA))>PRMT(95))THEN
          IF(SNO(ISA)>0..AND.SRAD(IRF(ISA))>10..AND.TX>PRMT(95))CALL HSNOM !Jaehak 2020 updated !daily snow melt
          RFV(IRF(ISA))=RFV(IRF(ISA))+SML
          SMM(6,MO,ISA)=SMM(6,MO,ISA)+SML
          VAR(6,ISA)=SML
      ELSE
          DSNO=RFV(IRF(ISA))
          SNO(ISA)=SNO(ISA)+DSNO
          SMM(5,MO,ISA)=SMM(5,MO,ISA)+RFV(IRF(ISA))
          VAR(5,ISA)=RFV(IRF(ISA))
          RFV(IRF(ISA))=0.
      END IF
      IF(BVIR(ISA)>RFV(IRF(ISA)))THEN
          IVR=1  
          RFV(IRF(ISA))=RFV(IRF(ISA))+BVIR(ISA)
	      REPI(ISA)=BVIR(ISA)/24.
	      DUR=24.
          BVIR(ISA)=0.
          REP=MAX(REP,REPI(ISA))  
      ELSE
          IVR=0
      END IF
	    
      !daily runoff volume and peak runoff rate
      !if temporally variable hsg, set CNSC values here
      if(hsg_vary) then
        CNSC(1,ISA) = cnsc1_vary(ISA,IY,IDA)
        CNSC(2,ISA) = cnsc2_vary(ISA,IY,IDA)
      endif
      CALL HVOLQ(IVR) 
      
      QMM=QVOL(IDO)/WSAX1
      JCN(ISA)=JCN(ISA)+1
      SMM(14,MO,ISA)=SMM(14,MO,ISA)+CN
      VAR(14,ISA)=CN
      IF(QMM>1.)THEN
          NQRB(IDO)=NQRB(IDO)+1
          PRAV(IDO)=PRAV(IDO)+RQRB(IDO)
          PRSD(ISA)=PRSD(ISA)+RQRB(IDO)*RQRB(IDO)
          IF(RQRB(IDO)>PRB(IDO))PRB(IDO)=RQRB(IDO)
          X1=RQRB(IDO)/(QMM+1.)
          IF(X1>QRQB(ISA))QRQB(ISA)=X1
          QRBQ(ISA)=QRBQ(ISA)+X1
          TCAV(IDO)=TCAV(IDO)+TC(IDO)
          IF(TC(IDO)<TCMX(IDO))THEN
              IF(TC(IDO)<TCMN(IDO))TCMN(IDO)=TC(IDO)
          ELSE
              TCMX(IDO)=TC(IDO)
          END IF
      END IF
!     COMPUTE SEDIMENT YLD
      IF(PEC(ISA)>0..AND.LUN(ISA)/=35.AND.PADDY_STO(1,ISA)<1.E-10)THEN
          IF(PADDY_HWEIR(ISA)<1.E-10)CALL EYSED(JRT) !Calculate water erosion for non-paddies Jaehak 2016 (daily soil loss caused by water erosion)
          IF(JRT==0.OR.YERO>0.)THEN
              YERO=YERO+YSD(NDRV,IDO)/WSAX
              X1=.9*WT(LD1,ISA)
              IF(YERO>X1)THEN
                  RTO=X1/YERO
                  YSD(NDRV,IDO)=YSD(NDRV,IDO)*RTO
                  YW(IDO)=YW(IDO)*RTO
                  YERO=X1
              END IF
              IF(JRT==0)THEN
                  IF(BCOF(ISA)>0.)CALL EBUFSA !routes sediment through upland buffers
                  VARH(6,IDO)=YSD(NDRV,IDO)
                  SMMH(6,MO,IDO)=SMMH(6,MO,IDO)+VARH(6,IDO)
                  VAR(28,ISA)=YSD(6,IDO)
                  SMM(28,MO,ISA)=SMM(28,MO,ISA)+YSD(6,IDO)
                  SMM(29,MO,ISA)=SMM(29,MO,ISA)+YSD(3,IDO)
                  VAR(29,ISA)=YSD(3,IDO)
                  SMM(27,MO,ISA)=SMM(27,MO,ISA)+YSD(4,IDO)
                  VAR(27,ISA)=YSD(4,IDO)
                  SMM(30,MO,ISA)=SMM(30,MO,ISA)+YSD(5,IDO)
                  VAR(30,ISA)=YSD(5,IDO)
                  ERAV(IDO)=ERAV(IDO)+ERTO
                  YMNUX=YMNU(IDO)/WSAX
                  SMM(88,MO,ISA)=SMM(88,MO,ISA)+YMNUX
                  VAR(88,ISA)=YMNUX
                  IF(PADDY_HWEIR(ISA)<1.E-10)THEN
                      CY=1.E5*YSD(NDRV,IDO)/QVOL(IDO)
                      CYAV(ISA)=CYAV(ISA)+CY
                      CYSD(ISA)=CYSD(ISA)+CY*CY
                      IF(CY>CYMX(ISA))CYMX(ISA)=CY
                  END IF    
              END IF
          END IF          
          SMM(26,MO,ISA)=SMM(26,MO,ISA)+YSD(2,IDO)
          VAR(26,ISA)=YSD(2,IDO)
          SMM(31,MO,ISA)=SMM(31,MO,ISA)+YSD(1,IDO)
          VAR(31,ISA)=YSD(1,IDO)
          VAR(25,ISA)=CVF(ISA)
      END IF          
      YEW=MIN(ERTO*YSD(NDRV,IDO)/(WSAX*WT(LD1,ISA)),.9)      
      YEWN=MIN(ERTO*YW(IDO)/WT(LD1,ISA),.9)
      CALL NYON !daily organic N and humus loss
      SMM(37,MO,ISA)=SMM(37,MO,ISA)+YN(IDO)
      VAR(37,ISA)=YN(IDO)
      SYN(IDO)=SYN(IDO)+YN(IDO)
      VAYN(IDO)=YN(IDO)
      SMM(134,MO,ISA)=SMM(134,MO,ISA)+YNWN(IDO)
      VAR(134,ISA)=YNWN(IDO)
      XX=.0001+EXP(-.1*YW(IDO)-YSD(3,IDO)/WSAX)
      RHTT(ISA)=MAX(.001,RHTT(ISA)*XX)
      DHT(ISA)=MAX(.001,DHT(ISA)*XX)
      SMM(34,MO,ISA)=SMM(34,MO,ISA)+RRUF(ISA)
      VAR(34,ISA)=RRUF(ISA)
      IF(IHY>0)THEN
          NHY(IDO)=0
          HYDV(IDO)=0.
          IF(QMM>QTH)THEN
              IF(INFL<3)THEN
                  IF(NRF==0.AND.RFV(IRF(ISA))>0.)THEN
                      IF(IHY>4)THEN
                          CALL HRFDT
                      ELSE
                          CALL HRFDTS
                      END IF
                  END IF    
              END IF                  
              SMM(33,MO,ISA)=SMM(33,MO,ISA)+RHTT(ISA)
              VAR(33,ISA)=RHTT(ISA)
              RRUF(ISA)=MAX(.001,RRUF(ISA)*XX)
              CALL HYDUNT
	      END IF	          
      END IF	      
      AFN=MIN(BVIR(ISA)*CQNI,FNMX(IRO(ISA),ISA)-ANA(IRO(ISA),ISA))
      IF(AFN>0..AND.PADDY_STO(1,ISA)<1.E-10)THEN
          ANA(IRO(ISA),ISA)=ANA(IRO(ISA),ISA)+AFN
          WNO3(LD1,ISA)=WNO3(LD1,ISA)+AFN
          IF((NOP>0.OR.NBSA(ISA)==ISAP).AND.KFL(1)>0)WRITE(KW(1),1140)ISA,&
          NBSA(ISA),IYR,MO,KDA,AFN,BVIR(ISA),XHSM(ISA)
      END IF
      RFV(IRF(ISA))=RFV(IRF(ISA))+BVIR(ISA)
      BVIR(ISA)=0.
      IF(IMF>0)WTBL(ISA) = sub_wt_depth(NBSA(ISA)) !rtb MODFLOW: water table depth from MODFLOW (amrt_conversion2.apex)
      IF(LUN(ISA)/=35)CALL HPURK !master percolation component
      !update paddy water storage Jaehak 2016 
      IF(PADDY_HWEIR(ISA)>0)PADDY_STO(1,ISA)=MAX(0.,PADDY_STO(1,ISA)-PKRZ(LD1))
      SMM(97,MO,ISA)=SMM(97,MO,ISA)+CPVV
      SMM(87,MO,ISA)=SMM(87,MO,ISA)+CPVH(IDO)
      IF(IMF>0) sepbtm(ISA) = PKRZ(LNS) !rtb MODFLOW: store percolation for MODFLOW recharge (will be delayed)
      if(sepbtm(ISA).gt.0) then
        dum = 10
      endif
      
      PKRZ(LNS)=PKRZ(LNS)*WSAX1
      SMM(16,MO,ISA)=SMM(16,MO,ISA)+PKRZ(LNS)
      VAR(16,ISA)=PKRZ(LNS)
      SMM(83,MO,ISA)=SMM(83,MO,ISA)+QRF(IDO)
      VAR(83,ISA)=QRF(IDO)

      IF(IMF>0) THEN
         !rtb MODFLOW: retrieve values of gw storage and gw return flow from MODFLOW (amrt_conversion2.apex)
         GWST(ISA) = sub_gw_volume(NBSA(ISA)) 
         X1 = sub_gw_exchange(NBSA(ISA)) !all gw leaving the aquifer is return flow
         X2 = sub_gw_exchange(NBSA(ISA)) !gw return flow
         IF(X1.ne.0.)THEN
           VAR(71,ISA)=X1-X2 !rtb MODFLOW: will always be 0 - deep percolation not simulated
           GWSN(ISA) = sub_gwno3(NBSA(ISA)) / WSAX !rtb MODFLOW: NO3 mass in the subarea (kg/ha)
           CONC=GWSN(ISA)/(GWST(ISA)+1.E-10) !N concentration
           RSFN(IDO) = sub_gwno3_exchange(NBSA(ISA)) / WSAX !rtb MODFLOW: NO3 loading to stream via groundwater (kg/ha)
           !rtb salt
           if(ISALT>0) then
           do m=1,mion
             gwsalt(IDO,m) = sub_salt_exchange(NBSA(ISA),m) / WSAX !salt ion loading to stream via groundwater (kg/ha)
           enddo
           endif
           DPKN = 0. !rtb MODFLOW
           SMM(96,MO,ISA)=SMM(96,MO,ISA)+DPKN
           VAR(96,ISA)=DPKN
           DO K=1,NDP
             X3=GWPS(K,ISA)/GWST(ISA)
             RSPS(K,IDO) = sub_gwp_exchange(NBSA(ISA)) / WSAX !rtb MODFLOW: P loading to stream via return flow (kg/ha)
             GWPS(K,ISA) = sub_gwp(NBSA(ISA)) / WSAX !rtb MODFLOW: P mass in the subarea (kg/ha)
             VARP(12,K,IDO)=MIN(GWPS(K,ISA),VAR(71,ISA)*X3)
             GWPS(K,ISA)=GWPS(K,ISA)-VARP(12,K,IDO)
             SMMP(11,K,MO,IDOA(ISA))=SMMP(11,K,MO,IDOA(ISA))+RSPS(K,IDO)
             SMMP(12,K,MO,IDOA(ISA))=SMMP(12,K,MO,IDOA(ISA))+VARP(12,K,IDO)
           END DO
           !rtb MODFLOW: X2 contains the gw/sw exchange rate (see above)
           RSSF(IDO)=X2
           SMM(71,MO,ISA)=SMM(71,MO,ISA)+VAR(71,ISA)
           SMM(72,MO,ISA)=SMM(72,MO,ISA)+RSSF(IDO)
           VAR(72,ISA)=RSSF(IDO) !GW return flow (m3)
         END IF   
      ELSE
         GWST(ISA)=GWST(ISA)+PKRZ(LNS)
         X1=RFTT(ISA)*GWST(ISA)
         IF(X1>0.)THEN
            X2=X1*RFPK(ISA)
            VAR(71,ISA)=X1-X2
            CONC=GWSN(ISA)/(GWST(ISA)+1.E-10)
            IF(GWST(ISA)/GWMX(ISA)<PRMT(40))X2=0.
	         TNL=CONC*X1
	         CNV=TNL/(X2*PRMT(74)+VAR(71,ISA))
	         CNH=CNV*PRMT(74)
            RSFN(IDO)=CNH*X2
            DPKN=CNV*VAR(71,ISA)
            X4=RSFN(IDO)+DPKN
            IF(GWSN(ISA)<X4)THEN
                RTO=GWSN(ISA)/X4
                DPKN=RTO*DPKN
                RSFN(IDO)=RTO*RSFN(IDO)
            END IF    
            GWSN(ISA)=GWSN(ISA)-RSFN(IDO)-DPKN
            SMM(96,MO,ISA)=SMM(96,MO,ISA)+DPKN
            VAR(96,ISA)=DPKN
            DO K=1,NDP
                X3=GWPS(K,ISA)/GWST(ISA)
                RSPS(K,IDO)=MIN(GWPS(K,ISA),X2*X3)
                GWPS(K,ISA)=GWPS(K,ISA)-RSPS(K,IDO)
                VARP(12,K,IDO)=MIN(GWPS(K,ISA),VAR(71,ISA)*X3)
                GWPS(K,ISA)=GWPS(K,ISA)-VARP(12,K,IDO)
                SMMP(11,K,MO,IDOA(ISA))=SMMP(11,K,MO,IDOA(ISA))+RSPS(K,IDO)
                SMMP(12,K,MO,IDOA(ISA))=SMMP(12,K,MO,IDOA(ISA))+VARP(12,K,IDO)
            END DO
            X3=VAR(71,ISA)+X2
            IF(GWST(ISA)<X3)THEN
                RTO=GWST(ISA)/X3
                VAR(71,ISA)=RTO*VAR(71,ISA)
                X2=RTO*X2
            END IF    
            GWST(ISA)=GWST(ISA)-VAR(71,ISA)-X2
            RSSF(IDO)=X2
            SMM(71,MO,ISA)=SMM(71,MO,ISA)+VAR(71,ISA)
            SMM(72,MO,ISA)=SMM(72,MO,ISA)+RSSF(IDO)
            VAR(72,ISA)=RSSF(IDO)
         END IF    
      ENDIF	  
      SMM(15,MO,ISA)=SMM(15,MO,ISA)+SST(IDO)
      VAR(15,ISA)=SST(IDO)
      VARH(15,IDO)=SST(IDO)
      CALL NCQYL !daily C loss
      X1=RSSF(IDO)+SST(IDO)+QRF(IDO)
      XX=(QVOL(IDO)+X1)/WSAX1
      X1=MAX(RQRB(IDO),X1/(24.*WSAX1))
      SSMM=SST(IDO)/WSAX1
      QRMM=QRF(IDO)/WSAX1
      RFMM=RSSF(IDO)/WSAX1
      GWMM=GWST(ISA)/WSAX1
      IF(KFL(9)>0)THEN
          WRITE(KW(9),1202)ISA,NBSA(ISA),IYR,MO,KDA,CN,SCI(ISA),&
          VAR(4,ISA),STMP(LD2,ISA),SML,QMM,SSMM,QRMM,RFMM,&
          XX,X1,TC(IDO),DUR,ALTC,AL5,REP,RZSW(ISA),GWMM
      END IF    
 	  REP=0.
	  REPI(ISA)=0. 
      CALL HEVP !daily ET
      !Update paddy storage jaehak jeong 
      IF(PADDY_HWEIR(ISA)>0.)PADDY_STO(1,ISA)=MAX(0.,PADDY_STO(1,ISA)-VAR(63,ISA)-ES)
      X10=EO*WSAX1
      SMM(10,MO,ISA)=SMM(10,MO,ISA)+X10
      VAR(10,ISA)=X10
      ADEO=(XDA*SMM(10,MO,ISA)+XDA1*PMOEO)*.0226
      ADRF=(XDA*(SMM(4,MO,ISA)-SMM(13,MO,ISA)-SMM(17,MO,ISA))+XDA1*PMORF&
      )/31.
      SMRF(ISA)=SMRF(ISA)-RF5(IWTB,ISA)+RFV(IRF(ISA))
      DO I=IWTB,2,-1
          RF5(I,ISA)=RF5(I-1,ISA)
      END DO
      RF5(1,ISA)=RFV(IRF(ISA))
      X1=STMP(LD2,ISA)*CLF
      SMEO(ISA)=SMEO(ISA)-EO5(IWTB,ISA)+X1
      DO I=IWTB,2,-1
          EO5(I,ISA)=EO5(I-1,ISA)
      END DO
      EO5(1,ISA)=X1
      IF(WTMN(ISA)<Z(LNS,ISA))CALL HWTBL
      VAP(ISA)=0.
      VPU(ISA)=0.
      QSFP=0.
	  IF(LUN(ISA)/=35.AND.RFV(IRF(ISA))>0.)CALL NYPA !daily P and K loss
      !Paddy field water balance, sediment, and nutrient load Jaehak Jeong 2016
      IF(PADDY_STO(1,ISA)>.1)THEN
          IF(PADDY_HWEIR(ISA)>0.)THEN
              CALL PADDY_WQ 
          ELSE
             YSD(NDRV,IDO)=YSD(NDRV,IDO)+PADDY_STO(2,ISA)*WSAX
             QN(IDO)=QN(IDO)+PADDY_STO(3,ISA)*WSAX
             QP(IDO)=QP(IDO)+PADDY_STO(4,ISA)*WSAX
             YN(IDO)=YN(IDO)+PADDY_STO(5,ISA)*WSAX
             YP(IDO)=YP(IDO)+PADDY_STO(6,ISA)*WSAX
             PADDY_STO(2,ISA)=0.  !Update sediment balance
             PADDY_STO(3,ISA)=0.
             PADDY_STO(4,ISA)=0.
             PADDY_STO(5,ISA)=0.
             PADDY_STO(6,ISA)=0.
          END IF    
      ELSE
          PADDY_STO(2,ISA)=0.  !Update sediment balance
          PADDY_STO(3,ISA)=0.
          PADDY_STO(4,ISA)=0.
          PADDY_STO(5,ISA)=0.
          PADDY_STO(6,ISA)=0.
      END IF          
      SMM(48,MO,ISA)=SMM(48,MO,ISA)+YP(IDO)
      VAR(48,ISA)=YP(IDO)
      SYP(IDO)=SYP(IDO)+YP(IDO)
      VAYP(IDO)=YP(IDO)
      VARH(2,IDO)=QVOL(IDO)/86400.
	  SMMH(2,MO,IDO)=SMMH(2,MO,IDO)+VARH(2,IDO)
      VARH(9,IDO)=YN(IDO)
      SMMH(9,MO,IDO)=SMMH(9,MO,IDO)+VARH(9,IDO)
      VARH(11,IDO)=YP(IDO)+YPOU(IDO)
      SMMH(11,MO,IDO)=SMMH(11,MO,IDO)+VARH(11,IDO)
      YPM(IDO)=YPM(IDO)+QAPY
      VAR(118,ISA)=YPM(IDO)
      SMM(118,MO,ISA)=SMM(118,MO,ISA)+VAR(118,ISA)
      VAR(119,ISA)=VAR(48,ISA)-VAR(118,ISA)
      SMM(119,MO,ISA)=SMM(119,MO,ISA)+VAR(119,ISA)
      SMM(135,MO,ISA)=SMM(135,MO,ISA)+YPWN(IDO)
      VAR(135,ISA)=YPWN(IDO)
      RSDM(LD1,ISA)=RSDM(LD1,ISA)-YMNUX
      ZZ=WLM(LD1,ISA)+WLS(LD1,ISA)
      RTO=MIN(1.,WLM(LD1,ISA)/ZZ)
      WLM(LD1,ISA)=WLM(LD1,ISA)-RTO*YMNUX
      X1=WLSL(LD1,ISA)/WLS(LD1,ISA)
      WLS(LD1,ISA)=MAX(1.E-10,WLS(LD1,ISA)-YMNUX*(1.-RTO))
      WLSL(LD1,ISA)=MAX(1.E-10,WLS(LD1,ISA)*X1)
      UNM=0.
      UPM=0.
      UKM=0.
      NDFA(ISA)=NDFA(ISA)+1
      NII(ISA)=NII(ISA)+1
      XHSM(ISA)=HSM(ISA)/AHSM
      IRGX=0
      IF(NYD/=1.AND.IDA==60)THEN
          NT1=1
      ELSE
          N1=KT(ISA)
          LGZ=0
          DO KT2=N1,NN1
              KT(ISA)=KT2
              IF(KOMP(KT2,ISA)>0)CYCLE
              IF(KTF(ISA)==0)KTF(ISA)=KT2
              DO K=1,LC
                  IF(JH(IRO(ISA),KT2,ISA)==KDC(K))EXIT
              END DO
              IF(K>LC)K=1
              JJK=K
              IF(IHUS==0)THEN
                  IF(IDA<ITL(IRO(ISA),KT2,ISA)+NT1)EXIT
              END IF
              IF(KGO(JJK,ISA)>0.OR.JPL(JJK,ISA)>0)XHSM(ISA)=HU(JJK,ISA)/&
              PHU(JJK,IHU(JJK,ISA),ISA)
              IF(XHSM(ISA)<HUSC(IRO(ISA),KT2,ISA))THEN
                  IF(MO<12.OR.IDC(JJK)==NDC(7).OR.IDC(JJK)==NDC(8).OR.IDC(JJK)&
                  ==NDC(10))EXIT
              ELSE
	              IF(PDSW(ISA)/PDAW(ISA)>PRMT(78).AND.RSAE(ISA)<1.E-5.AND.MO<&
                  12)THEN
	                  IF(KFL(1)>0)WRITE(KW(1),589)ISA,NBSA(ISA),IY,MO,KDA,PDSW(ISA),&
                      PDAW(ISA)
                      EXIT
                  END IF    
              END IF    
              JT1=LT(IRO(ISA),KT2,ISA)
              KOMP(KT2,ISA)=1
              IF(KT2>KTMX(ISA))KTMX(ISA)=KT(ISA)
              CSTX=COTL(JT1)
              COX=COOP(JT1)
              II=0
              SELECT CASE(IHC(JT1))
                  CASE(7)
                      IF(RFV(IRF(ISA))>PRMT(77))THEN
                          KOMP(KT2,ISA)=0
                          CYCLE
                      END IF
                      CALL PSTAPP
	                  IF(IDA==JD0.AND.NBT(JT1)==0.AND.NBE(JT1)==JDE)THEN
                          CSTX=0.
                          COX=0.
                      END IF
                      II=1
                  CASE(8)
                      IF(IRGX>0)THEN
                          KOMP(KT2,ISA)=0
                          CYCLE
                      END IF
                      BVIR(ISA)=VIRR(IRO(ISA),KT2,ISA)
                      IF(PADDY_HWEIR(ISA)>1.)THEN
                          BIR(ISA)=TIR(IRO(ISA),KTMX(ISA),ISA)
                          !Assign the water ponding depth in paddy that triggers irrigation
                          PADDY_HMIN(ISA)=HMIN_IRR(IRO(ISA),KT2,ISA) !minimum ponding depth, mm
                          PADDY_IRRMM=BVIR(ISA)
                          BVIR(ISA)=MAX(0.,PADDY_IRRMM-PADDY_STO(1,ISA))
                      END IF
                      IF(BVIR(ISA)<1.E-10)IAUI(ISA)=JT1
                      CALL HIRG(BVIR(ISA),EFM(JT1),TLD(JT1),JRT,JT1,1)
                      IRGX=1
                  CASE(9)    
                      IHD=0
                      IF(PADDY_STO(1,ISA)>=1.)THEN
                          CALL NFERT_PADDY(APMU,JT1,KT2,JRT) !Fertilizer paddy field Jaehak 2016
                      ELSE
                          CALL NFERT(APMU,6,JT1,KT2,JRT)
                      END IF
	                  IF(IDA==JD0.AND.NBT(JT1)==0.AND.NBE(JT1)==JDE)THEN
                          CSTX=0.
                          COX=0.
                      END IF
                      II=1
                  CASE(15,16) !!Puddling/set up discharge weir control  Jaehak 2016 paddy
                      PADDY_HWEIR(ISA)=HWEIR(IRO(ISA),KT2,ISA) !weir height, mm
                      PADDY_LWEIR(ISA)=LWEIR(IRO(ISA),KT2,ISA) !weir WIDTH, m
                  CASE(20)
                      KOMP(N1,ISA)=1 
                      RST0(ISA)=0.         
                      IGZ(ISA)=0
                      DO IHD=1,NHRD(IOW)
                          NGZ(IHD,ISA)=0
                          GCOW(IHD,ISA)=0.
                      END DO
                      KTF(ISA)=KTF(ISA)+1
                  CASE DEFAULT
                      II=1    
              END SELECT
              IF(II==1)THEN
                  JD0=IDA
                  JDE=NBE(JT1)
                  CALL TLOP(CSTX,COX,JRT)
                  IF(JRT>0)EXIT
              END IF    
              IF(IFD(ISA)>0.AND.DKHL(ISA)>.001)THEN
                  DHT(ISA)=DKHL(ISA)
                  IF((NOP>0.OR.NBSA(ISA)==ISAP).AND.KFL(1)>0)WRITE(KW(1),970)ISA,&
                  NBSA(ISA),IYR,MO,KDA,DHT(ISA),DKIN(ISA),XHSM(ISA)
              END IF    
              COST(ISA)=COST(ISA)+CSTX
              CSFX=CSFX+COX
              JT2=JT1
          END DO
          IF(KT2>NN1)KTF(ISA)=N1
          KT(ISA)=KTF(ISA)
          DO IHD=1,NHRD(IOW)
              IZ=IFED(IHD,IOW)
	          IF(IZ==ISA)THEN
                  IF(NCOW(IHD,IOW)>0)GCOW(IHD,ISA)=NCOW(IHD,IOW)*FFED(IHD,IOW)
	          ELSE
                  IF(RST0(ISA)<1.E-5)THEN
                      IF(IGZX(IHD,IOW)/=ISA)CYCLE
                      GCOW(IHD,ISA)=NCOW(IHD,IOW)*(1.-FFED(IHD,IOW))
	              END IF	              
	              IF(NGZ(IHD,ISA)==0.OR.IGZ(ISA)==0)CYCLE
	          END IF
              STKR(ISA)=STKR(ISA)+GCOW(IHD,ISA)
              DDMP=DUMP(IHD,IOW)*GCOW(IHD,ISA)
              TMPD=TMPD+DDMP
              X1=DDMP*SOLQ(ISA)
              WTMU(ISA)=WTMU(ISA)+X1
              AFLG(ISA)=AFLG(ISA)+X1
              SMM(61,MO,ISA)=SMM(61,MO,ISA)+X1
              VAR(61,ISA)=X1
              X5=.0001*VURN(IHD,IOW)*GCOW(IHD,ISA)/WSAX
              RFV(IRF(ISA))=RFV(IRF(ISA))+X5
              X2=DDMP-X1
              APMU=X2/WSA(ISA)
              CALL NFERT(APMU,3,IAMF(ISA),KT2,JRT)
          END DO
          IHD=NHRD(IOW)
          IF(IAPL(ISA)>0)THEN
              IF(ISAS(IOW)==ISA)THEN
                  APMU=FNP(2,ISA)
                  IF(SMNU(IOW)>.001*APMU*WSA(ISA))THEN
	                  CALL NFERT(APMU,2,ISPF(ISA),KT2,JRT)
                      IF(JRT==0)THEN
                          X4=.001*APMU
                          SMNU(IOW)=SMNU(IOW)-X4
                      END IF    
                  END IF
              END IF    
          ELSE
              IF(DALG(ISA)>0.)THEN
                  ALQ(ISA)=0.
                  CALL HLGOON(JRT)
                  IF(JRT==0)THEN
                      ALQ(ISA)=MIN(CFNP(ISA)*VLGI(ISA),.95*WTMU(ISA))
                      CFNP(ISA)=WTMU(ISA)/VLG(ISA)
                  END IF    
              ELSE
                  IF(ISAL(IOW)==ISA)THEN
                      IZ=-IAPL(ISA)
                      IF(ALQ(IZ)>1.E-5)THEN
                          APMU=MIN(.9*WTMU(IZ),ALQ(IZ))
                          APMU=APMU/WSA(ISA)
	                      CALL NFERT(APMU,1,ILQF(ISA),KT2,JRT)
                          IF(JRT==0)THEN
                              SMM(62,MO,IZ)=SMM(62,MO,IZ)+APMU
                              VAR(62,ISA)=APMU
                              X6=APMU
                              WTMU(IZ)=WTMU(IZ)-APMU
                              BVIR(ISA)=.1*ALGI(IOW)/WSA(ISA)
                              CALL HIRG(BVIR(ISA),1.,0.,JRT,JT1,1)
                              IF(JRT==0)TFLG(ISA)=TFLG(ISA)+APMU
                          END IF
                      END IF
                  END IF
              END IF
          END IF    
          IF(PADDY_HWEIR(ISA)<1.E-10)BIR(ISA)=TIR(IRO(ISA),KTMX(ISA),ISA)
          EFI(ISA)=QIR(IRO(ISA),KTMX(ISA),ISA)
          FIRG(ISA)=FIRX(IRO(ISA),KTMX(ISA),ISA)
          JT1=LT(IRO(ISA),KT(ISA),ISA)
          IF(NDFA(ISA)>=IFA(ISA).AND.IDFT(5,ISA)/=0)THEN
              APMU=FNP(5,ISA)
	          IF(APMU>1.E-5)CALL NFERT(APMU,5,JT1,KT2,JRT)
	      END IF
          KTF(ISA)=0
          IF(ABS(BIR(ISA))>1.E-5)THEN
              IF(BIR(ISA)<0.)THEN
                  IF(RZSW(ISA)-PAW(ISA)<BIR(ISA))CALL HIRG(BVIR(ISA),&
                  EFM(IAUI(ISA)),TLD(IAUI(ISA)),JRT,IAUI(ISA),0)
              ELSE IF(BIR(ISA)>9990.)THEN
                  BVIR(ISA)=MAX(0.,PADDY_IRRMM-PADDY_STO(1,ISA))
                  CALL HIRG(BVIR(ISA),EFM(IAUI(ISA)),TLD(IAUI(ISA)),JRT,IAUI(ISA),0) !auto irrigation for target ponding depth paddy model jaehak jeong 2014
              ELSE
                  IF(BIR(ISA)>=1.)THEN
                      CALL SWTN
                      IF(WTN>BIR(ISA))CALL HIRG(BVIR(ISA),EFM(IAUI(ISA)),&
                      TLD(IAUI(ISA)),JRT,IAUI(ISA),0)
                  ELSE
                      IF(WS(ISA)<BIR(ISA))CALL HIRG(BVIR(ISA),EFM(IAUI(ISA)),&
                      TLD(IAUI(ISA)),JRT,IAUI(ISA),0)
                  END IF
              END IF    
          END IF
      END IF 
      SVOL=0.
      TSFN(IDO)=0.
      TSFK(IDO)=0.
      QRFN(IDO)=0.
      SMQN(IDO)=0.
      
      !rtb salt original
      if(ISALT>0) then
        do m=1,mion
          SMQS(IDO,m) = 0.
        enddo
      endif
      
      IF(LUN(ISA)==35)THEN
          QN(IDO)=RFQN(ISA)
      ELSE
          !if(isa.eq.87) then
          !  write(8643,*) iyr,ida,soil_csalt(LID(1,isa),isa,1)
          !endif
          !if(isa.eq.87 .and. ida.eq.119) then
          !  dum = 10
          !endif
          
          if(ISALT>0) call salt_chem_soil !rtb salt --> salt ion equilibrium chemistry for soil layers
          CALL NPCY
      END IF
 
      IF(LUN(ISA)/=35)CALL TMIX(XXXX,ZMIX,1,1)
      IF(PADDY_HWEIR(ISA)>0.)PADDY_STO(1,ISA)=PADDY_STO(1,ISA)+BVIR(ISA) 
      IF(IRR(ISA)==1)RFV(IRF(ISA))=RFV(IRF(ISA))+BVIR(ISA)
      IF(IDNT>2)CALL GASDF3
      XX=0.
      RSPC=0.
      IF(LUN(ISA)/=35)THEN
          DO J=1,NBSL(ISA)
              ISL=LID(J,ISA)
              IF(STMP(ISL,ISA)>0.)THEN
                  Z5=500.*(Z(ISL,ISA)+XX)
                  IF(ICP==0)THEN
                      CALL NCNMI_PHOENIX(Z5,CS,EAR(ISL,ISA))
                  ELSE    
                      CALL NCNMI_CENTURY(Z5,CS,EAR(ISL,ISA))
                  END IF
              END IF
              XX=Z(ISL,ISA)
          END DO
      END IF
      CV(ISA)=0.
      CVP(ISA)=0.
      AD1=0.
      CVRS(ISA)=0.
      VAC(ISA)=0.
      AEPT=0.
      XES=ES
      AGPM(ISA)=0.
      TAGP(ISA)=0.
      IF(IGO(ISA)>1)XES=ES/IGO(ISA)
      WS(ISA)=1.
      IF(IGO(ISA)>0)THEN
          JGO=0
          JBG(ISA)=JBG(ISA)+1
          IF(JBG(ISA)>IGO(ISA))JBG(ISA)=1
          I=JBG(ISA)
          DO J=1,LC
              IF(KGO(J,ISA)>0)THEN
                  JGO(I)=KGO(J,ISA)
                  I=I+1
                  IF(I>IGO(ISA))I=1
              END IF    
          END DO
          I1=0
          DO IN2=1,IGO(ISA)
              I1=I1+1
              JJK=JGO(I1)
              AEP(JJK)=0.
              IF(JPL(JJK,ISA)>0)THEN
                  HU(JJK,ISA)=HU(JJK,ISA)+MAX(0.,DST0(ISA)-TBSC(JJK))
	              IF(PDSW(ISA)/PDAW(ISA)>PRMT(11).AND.HU(JJK,ISA)>GMHU(JJK))THEN
	                  JPL(JJK,ISA)=0
                      IF((NOP>0.OR.NBSA(ISA)==ISAP).AND.KFL(1)>0)WRITE(KW(1),950)ISA,&
                      NBSA(ISA),IYR,MO,KDA,CPNM(JJK),PDSW(ISA),HU(JJK,ISA),XHSM(ISA)
                      HU(JJK,ISA)=0.
                  ELSE
                      IF(HU(JJK,ISA)/PHU(JJK,IHU(JJK,ISA),ISA)>.3.AND.KGO(JJK,ISA)>0)THEN
                          KGO(JJK,ISA)=0
                          IGO(ISA)=IGO(ISA)-1
                          JPL(JJK,ISA)=0
                      END IF    
                      CYCLE
                  END IF
              END IF
              CV(ISA)=CV(ISA)+DM(JJK,ISA)-RW(JJK,ISA)
              AD1=AD1+PPL0(JJK,ISA)
              STLX=STL(JJK,ISA)
              VAC(ISA)=VAC(ISA)+BWN(1,JJK)*STLX
              AWC(JJK,ISA)=AWC(JJK,ISA)+RFV(IRF(ISA))-QMM
              DO L1=1,NBSL(ISA)
                  ISL=LID(L1,ISA)
                  UW(ISL)=0.
                  UK(ISL)=0.
                  UN(ISL)=0.
                  UP(ISL)=0.
              END DO
              UNM=0.
              UPM=0.
              UKM=0.
              DDM(JJK)=0.
              CALL CGROW(JRT)
              IF(JRT/=1)THEN
                  IF(JRT==0)THEN
                      VARC(14,JJK,ISA)=REG(JJK,ISA)
                      SUN=0.
                      SUP=0.
                      SUK=0.
                      CALL HUSE
                      CALL CROP
                      CALL NUP
                      CALL NPUP
                      CALL NKUP
                      CALL NUSE
                      CALL CSTRS
                      VARC(10,JJK,ISA)=WS(ISA)
                      VARC(11,JJK,ISA)=SN
                      VARC(12,JJK,ISA)=SP
                      VARC(13,JJK,ISA)=SK
                      VARC(15,JJK,ISA)=SAT            
                      VARC(17,JJK,ISA)=REG(JJK,ISA)
                      VAR(43,ISA)=WFX*WSAX
                      AEPT=AEPT+AEP(JJK)
                      IF(HUI(JJK,ISA)>PRMT(3))THEN
                          SWH(JJK,ISA)=SWH(JJK,ISA)+AEP(JJK)
                          SWP(JJK,ISA)=SWP(JJK,ISA)+EP(JJK)
                      END IF
                      VAR(12,ISA)=AEP(JJK)
                      ACET(JJK,ISA)=ACET(JJK,ISA)+AEP(JJK)+XES
                  END IF          
                  CALL CAGRO
                  STV(5,MO,ISA)=UN1(JJK,ISA)
                  VARS(5)=UN1(JJK,ISA)
                  STV(6,MO,ISA)=UP1(JJK,ISA)
                  VARS(6)=UP1(JJK,ISA)
                  STV(7,MO,ISA)=UK1(JJK,ISA)
                  VARS(7)=UK1(JJK,ISA)
              END IF          
              STLX=STL(JJK,ISA)
              IF(IDC(JJK)/=NDC(7).AND.IDC(JJK)/=NDC(8).AND.IDC(JJK)/=NDC(10))&
              AGPM(ISA)=AGPM(ISA)+STLX
              TAGP(ISA)=TAGP(ISA)+STLX
              VARC(1,JJK,ISA)=HUI(JJK,ISA)
              VARC(2,JJK,ISA)=SLAI(JJK,ISA)
              VARC(3,JJK,ISA)=RD(JJK,ISA)
              VARC(4,JJK,ISA)=RW(JJK,ISA)
              VARC(5,JJK,ISA)=DM(JJK,ISA)
              VARC(6,JJK,ISA)=STLX
              VARC(7,JJK,ISA)=CPHT(JJK,ISA)
              VARC(8,JJK,ISA)=STD(JJK,ISA)
              VARC(9,JJK,ISA)=STDL(JJK,ISA)
          END DO          
      END IF
      IF(SCLM(15)>0.)AD1=MIN(AD1,SCLM(15))
      CVP(ISA)=MAX(CVP(ISA),AD1/(AD1+EXP(SCRP(15,1)-SCRP(15,2)*AD1)))
      FBAR(ISA)=1.-.01*AD1
      DO K=1,LC                                          
          STDX=STD(K,ISA)
          AGPM(ISA)=AGPM(ISA)+STDX
          TAGP(ISA)=TAGP(ISA)+STDX
          CVRS(ISA)=CVRS(ISA)+STDX
          CV(ISA)=CV(ISA)+STDX
          VAC(ISA)=VAC(ISA)+BWN(2,K)*STDX
      END DO
      !IF(ISA==ISAP)CALL NCONT(ISA)
      IF(NDP>0)THEN
          CALL PSTCY(PQPX,PYPX,IXP)
          CALL PSTEV
      END IF
      PDPL(ISA)=0.
      PDSKC=0.
      SW(ISA)=SWLT(ISA)+XRFI(ISA)
      RZSW(ISA)=0.
      ZNO3(ISA)=0.
      ZNH3(ISA)=0.
      ZNMU(ISA)=0.
      ZNOU(ISA)=0.
      ZPML(ISA)=0.
      ZPO(ISA)=0.
      ZPMA(ISA)=0.
	  ZPMU(ISA)=0.
	  ZPOU(ISA)=0.
	  ZEK(ISA)=0.
	  ZFK(ISA)=0.
	  ZSK(ISA)=0.
      TRSD(ISA)=0.
      ZFOP(ISA)=0.
      ZNOS(ISA)=0.
      ZNOA(ISA)=0.
      ZPMS(ISA)=0.
      TNOR(ISA)=0.
      ZON(ISA)=0.
      ZOC(ISA)=0.
      ZLS(ISA)=0.
      ZLM(ISA)=0.
      ZLSL(ISA)=0.
      ZLSC(ISA)=0.
      ZLMC(ISA)=0.
      ZLSLC(ISA)=0.
      ZLSLNC(ISA)=0.
      ZBMC(ISA)=0.
      ZHSC(ISA)=0.
      ZHPC(ISA)=0.
      ZLSN(ISA)=0.
      ZLMN(ISA)=0.
      ZBMN(ISA)=0.
      ZHSN(ISA)=0.
      ZHPN(ISA)=0.
      ZSLT(ISA)=0.
      XX=0.
      SUM=0.
      OCPD(ISA)=0.
      PDSW(ISA)=0.
	  PDAW(ISA)=0.
      IF(BIG(ISA)>0.)CALL SAJBD
      DO J=1,NBSL(ISA)
          ISL=LID(J,ISA)
          SMS(2,ISL,ISA)=SMS(2,ISL,ISA)+STMP(ISL,ISA)
          WOC(ISL,ISA)=WBMC(ISL,ISA)+WHPC(ISL,ISA)+WHSC(ISL,ISA)+WLMC(ISL,&
          ISA)+WLSC(ISL,ISA)
          IF(Z(ISL,ISA)<=PMX(ISA))THEN
              PDSW(ISA)=PDSW(ISA)+SWST(ISL,ISA)-S15(ISL,ISA)
	          PDAW(ISA)=PDAW(ISA)+FC(ISL,ISA)-S15(ISL,ISA)
              PDPL(ISA)=PDPL(ISA)+WPML(ISL,ISA)+WPMU(ISL,ISA)
              PDSKC(ISA)=PDSKC(ISA)+SOLK(ISL,ISA)
              OCPD(ISA)=OCPD(ISA)+WOC(ISL,ISA)
              SUM=SUM+WT(ISL,ISA)
              K1=J
              K2=ISL
          END IF
          IF(Z(ISL,ISA)<=RZ(ISA))THEN
              TNOR(ISA)=TNOR(ISA)+WNO3(ISL,ISA)
              LZ=ISL
              L1=J
              RZSW(ISA)=RZSW(ISA)+SWST(ISL,ISA)-S15(ISL,ISA)
              XX=Z(ISL,ISA)
          END IF
          ZPML(ISA)=ZPML(ISA)+WPML(ISL,ISA)
          ZPMS(ISA)=ZPMS(ISA)+WPMS(ISL,ISA)
          ZPMA(ISA)=ZPMA(ISA)+WPMA(ISL,ISA)
          ZPO(ISA)=ZPO(ISA)+WPO(ISL,ISA)
	      ZPMU(ISA)=ZPMU(ISA)+WPMU(ISL,ISA)
	      ZPOU(ISA)=ZPOU(ISA)+WPOU(ISL,ISA)
	      ZEK(ISA)=ZEK(ISA)+EXCK(ISL,ISA)
	      ZSK(ISA)=ZSK(ISA)+SOLK(ISL,ISA)
	      ZFK(ISA)=ZFK(ISA)+FIXK(ISL,ISA)
          ZNO3(ISA)=ZNO3(ISA)+WNO3(ISL,ISA)
          ZNH3(ISA)=ZNH3(ISA)+WNH3(ISL,ISA)
          ZNMU(ISA)=ZNMU(ISA)+WNMU(ISL,ISA)
          ZNOU(ISA)=ZNOU(ISA)+WNOU(ISL,ISA)
          TRSD(ISA)=TRSD(ISA)+RSD(ISL,ISA)
          SW(ISA)=SW(ISA)+SWST(ISL,ISA)
          ZFOP(ISA)=ZFOP(ISA)+FOP(ISL,ISA)
          ZSLT(ISA)=ZSLT(ISA)+WSLT(ISL,ISA)
          ZLS(ISA)=ZLS(ISA)+WLS(ISL,ISA)
          ZLM(ISA)=ZLM(ISA)+WLM(ISL,ISA)
          ZLSL(ISA)=ZLSL(ISA)+WLSL(ISL,ISA)
          ZLSC(ISA)=ZLSC(ISA)+WLSC(ISL,ISA)
          ZLMC(ISA)=ZLMC(ISA)+WLMC(ISL,ISA)
          ZLSLC(ISA)=ZLSLC(ISA)+WLSLC(ISL,ISA)
          ZLSLNC(ISA)=ZLSLNC(ISA)+WLSLNC(ISL,ISA)
          ZBMC(ISA)=ZBMC(ISA)+WBMC(ISL,ISA)
          ZHSC(ISA)=ZHSC(ISA)+WHSC(ISL,ISA)
          ZHPC(ISA)=ZHPC(ISA)+WHPC(ISL,ISA)
          ZLSN(ISA)=ZLSN(ISA)+WLSN(ISL,ISA)
          ZLMN(ISA)=ZLMN(ISA)+WLMN(ISL,ISA)
          ZBMN(ISA)=ZBMN(ISA)+WBMN(ISL,ISA)
          ZHSN(ISA)=ZHSN(ISA)+WHSN(ISL,ISA)
          ZHPN(ISA)=ZHPN(ISA)+WHPN(ISL,ISA)
          WON(ISL,ISA)=WBMN(ISL,ISA)+WHPN(ISL,ISA)+WHSN(ISL,ISA)+WLMN(ISL,&
          ISA)+WLSN(ISL,ISA)
      END DO         
      ZON(ISA)=ZLSN(ISA)+ZLMN(ISA)+ZBMN(ISA)+ZHSN(ISA)+ZHPN(ISA)
      ZOC(ISA)=ZLSC(ISA)+ZLMC(ISA)+ZBMC(ISA)+ZHSC(ISA)+ZHPC(ISA)
      IF(LZ/=ISL)THEN
          ZZ=RZ(ISA)-Z(LZ,ISA)
          L1=LID(L1+1,ISA)
          RTO=ZZ/(Z(L1,ISA)-Z(LZ,ISA))
          RZSW(ISA)=RZSW(ISA)+(SWST(L1,ISA)-S15(L1,ISA))*RTO
          TNOR(ISA)=TNOR(ISA)+WNO3(L1,ISA)*RTO
      END IF
      SSW(ISA)=SSW(ISA)+RZSW(ISA)
      IF(K1/=NBSL(ISA))THEN
          KK=LID(K1+1,ISA)
          RTO=(PMX(ISA)-Z(K2,ISA))/(Z(KK,ISA)-Z(K2,ISA))
          PDSW(ISA)=PDSW(ISA)+RTO*(SWST(KK,ISA)-S15(KK,ISA))
	      PDAW(ISA)=PDAW(ISA)+RTO*(FC(KK,ISA)-S15(KK,ISA))
	      SUM=SUM+RTO*WT(KK,ISA)
          OCPD(ISA)=.1*(OCPD(ISA)+RTO*WOC(KK,ISA))/SUM
          PDPL(ISA)=PDPL(ISA)+(WPML(KK,ISA)+WPMU(KK,ISA))*RTO
          PDPLC(ISA)=1000.*PDPL(ISA)/SUM
          PDSKC(ISA)=PDSKC(ISA)+SOLK(KK,ISA)*RTO
          PDSKC(ISA)=1000.*PDSKC(ISA)/SUM
      END IF
      AET=AEPT+ES
      SMM(11,MO,ISA)=SMM(11,MO,ISA)+AET
      VAR(11,ISA)=AET
      IF(IMF>0)etremain(NBSA(ISA)) = VAR(10,ISA) - VAR(11,ISA) !rtb MODFLOW: potential ET - actual ET
      SMM(12,MO,ISA)=SMM(12,MO,ISA)+AEPT
      VAR(155,ISA)=10.*AET*SALA(ISA)
      SMM(155,MO,ISA)=SMM(155,MO,ISA)+VAR(155,ISA)
      IF(NVCN(ISA)==4.AND.LUN(ISA)/=35)THEN
          IF(IGO(ISA)>0)THEN
              X1=MAX(AET,EO*EXP(-PRMT(42)*SCI(ISA)/SMX(ISA)))
          ELSE
              X1=AET
          END IF
          SCI(ISA)=MAX(3.,SCI(ISA)+X1-RFV(IRF(ISA))+QMM)
    !     +QRF(IDO)+SST(IDO)+QDR(IDO)+VAR(16,ISA)
          SCI(ISA)=MIN(SCI(ISA),PRMT(44)*SMX(ISA))
      END IF
	  X1=(ADRF-PRMT(9))/100.
      X2=CV(ISA)-PRMT(10)
      IPST(ISA)=IPST(ISA)+1
      IF(TMN(IRF(ISA))>0.)THEN
          IF(X1>0..AND.X2>0.)PSTS(ISA)=PSTS(ISA)+(X1+1.)*TMN(IRF(ISA))
      ELSE
          PSTS(ISA)=PSTS(ISA)+TMN(IRF(ISA))
      END IF
      SSFN=0.
      SSFK=0.
      CALL NEVN
      CALL NEVP
      !Compute upward movement of N/P with soil evaporation if the field is not flooded Jaehak 2016
      IF(PADDY_STO(1,ISA)<1.E-10)THEN
          CALL NEVN
          CALL NEVP
      ENDIF
      VAR(41,ISA)=SGMN
      VAR(44,ISA)=SNMN
      X42=WSAX*SDN
      VAR(42,ISA)=X42
      VAR(128,ISA)=SN2
      VAR(154,ISA)=SN2O
      VAR(50,ISA)=SMP
      X46=SVOL*WSAX
      VAR(46,ISA)=X46
      X45=SNIT*WSAX
      VAR(45,ISA)=X45
      VAR(13,ISA)=QVOL(IDO)
      VAR(38,ISA)=QN(IDO)
      VAR(40,ISA)=VNO3(LNS,ISA)*WSAX
      IF(IMF>0)percn(ISA) = VNO3(LNS,ISA) !rtb modflow; NO3 in percolation water (kg/ha) (for RT3D)
      VAR(49,ISA)=QP(IDO)
	  VAR(108,ISA)=QPU(IDO)
      VAR(39,ISA)=TSFN(IDO)
      VAR(131,ISA)=TSFS
      VAR(151,ISA)=TSFK(IDO)
      VAR(120,ISA)=RZSW(ISA)
      VARS(1)=ZNH3(ISA)
      VARS(2)=ZNO3(ISA)
      VARS(3)=ZPML(ISA)
      VARS(4)=ZSK(ISA)
      VARS(8)=RZSW(ISA)
      VARS(9)=WTBL(ISA)
      VARS(10)=GWST(ISA)
      VARS(11)=STDO(ISA)
      VARS(12)=RSD(LD1,ISA)
      VARS(16)=SWLT(ISA)
      VARS(17)=SNO(ISA)
      VARS(18)=RSDM(LD1,ISA)
      VARS(19)=GWSN(ISA)
      VARS(20)=ZSLT(ISA)
      CALL SPRNT
      IF(KFL(22)>0)CALL SOCIOD(KDA)
!     PRINTOUT DAILY
      VAR(4,ISA)=VAR(4,ISA)*WSAX1
      IF(NBSA(ISA)==ISAP.AND.IDA==IPC.AND.KFL(1)>0)THEN
          SELECT CASE(IPD)
              CASE(6)
                  CALL APRNTD
              CASE(7)
                  WRITE(KW(1),1061)ISA,NBSA(ISA),IYR,MO,KDA,IY
                  CALL SOLIOP
                  CALL SOLIOC
              CASE(8)
                  IF(IGO(ISA)>0)THEN
                      WRITE(KW(1),1061)ISA,NBSA(ISA),IYR,MO,KDA,IY
                      CALL SOLIOP
                      CALL SOLIOC
                  END IF    
              CASE(9)
                  IF(IGO(ISA)>0)CALL APRNTD
              CASE DEFAULT    
          END SELECT
          IF(ISA==MSA)IPC=IPC+INP
      END IF    
      SMM(41,MO,ISA)=SMM(41,MO,ISA)+SGMN
      SMM(44,MO,ISA)=SMM(44,MO,ISA)+SNMN
      SMM(42,MO,ISA)=SMM(42,MO,ISA)+X42
      SMM(128,MO,ISA)=SMM(128,MO,ISA)+SN2
      SMM(154,MO,ISA)=SMM(154,MO,ISA)+SN2O
      SMM(50,MO,ISA)=SMM(50,MO,ISA)+SMP
      SMM(46,MO,ISA)=SMM(46,MO,ISA)+X46
      SMM(45,MO,ISA)=SMM(45,MO,ISA)+X45
      WYLD(IDO)=QVOL(IDO)+RSSF(IDO)+QRF(IDO)+QDR(IDO)+CPVH(IDO)
      IF(IPTS(ISA)>0)THEN
	      I=IPSO(ISA)
	      WYLD(IDO)=WYLD(IDO)+PSOQ(I)
          QVOL(IDO)=QVOL(IDO)+PSQX
          YSD(NDRV,IDO)=YSD(NDRV,IDO)+PSOY(I)
		  QN(IDO)=QN(IDO)+PSO3(I)
		  QP(IDO)=QP(IDO)+PSSP(I)
		  YN(IDO)=YN(IDO)+PSON(I)
		  YP(IDO)=YP(IDO)+PSOP(I)
      END IF
      VARH(34,IDO)=WYLD(IDO)
      SMM(13,MO,ISA)=SMM(13,MO,ISA)+QVOL(IDO)
      SMMR(1,MO)=SMMR(1,MO)+QVOL(IDO)
      VARH(35,IDO)=WYLD(IDO)/86400.
      VAR(117,ISA)=WYLD(IDO)
      SMM(117,MO,ISA)=SMM(117,MO,ISA)+WYLD(IDO)
      SMMH(35,MO,IDO)=SMMH(35,MO,IDO)+VARH(35,IDO)
      SMMH(34,MO,IDO)=SMMH(34,MO,IDO)+WYLD(IDO)
      CALL AUAC(0)

      !IF(KFL(11)>0.and.isa==34)THEN
      IF(KFL(11)>0)THEN
          NN=NCP(IRO(ISA),ISA)
          DO J=1,NN 
              I2=LY(IRO(ISA),J,ISA)
              WRITE(KW(11),154)ISA,NBSA(ISA),IYR,MO,KDA,CPNM(I2),(VARC(K,I2,ISA),K=1,17),&
                  (VARUA(KD(K),ISA),K=1,NKD),(VARS(KS(K)),K=1,NKS)
              !WRITE(*,154)ISA,NBSA(ISA),IYR,MO,KDA,CPNM(I2),(VARC(K,I2,ISA),K=1,2)
          END DO
      END IF    
      !PRINT PADDY DAILY OUTPUT Jaehak 2016
      IF(KFL(45)>0)WRITE(KW(45),'(3I6,30E10.3)')IY,IDA,ISA,VARUA(4,ISA),&
      VARUA(18,ISA),PKRZ(LD1),VARUA(63,ISA)+ES,QMM,SLAI(1,1),&
      YSD(NDRV,IDO),QN(IDO),QP(IDO),(PADDY_STO(I,ISA), I=1,4)

      SMMR(2,MO)=SMMR(2,MO)+WYLD(IDO)
      SMMR(3,MO)=SMMR(3,MO)+YSD(NDRV,IDO)
      SMMR(4,MO)=SMMR(4,MO)+YN(IDO)
      SMMR(5,MO)=SMMR(5,MO)+YP(IDO)
      SMQN(IDO)=SMQN(IDO)+QN(IDO)+RSFN(IDO)+QRFN(IDO)+QDRN(IDO)
      SMM(158,MO,ISA)=SMM(158,MO,ISA)+SMQN(IDO)
      SQN(IDO)=SQN(IDO)+SMQN(IDO)
      VAQN(IDO)=SMQN(IDO)
      
      
      !rtb salt - add up all salt ion mass (kg) added to the subarea channel (for current day)
      if(ISALT>0) then
      do m=1,mion
        
        !convert all values to total mass (kg)
        surfqsalt(IDO,m) = surfqsalt(IDO,m) * WSA(ISA)
        gwsalt(IDO,m) = gwsalt(IDO,m) * WSA(ISA)
        latsalt(IDO,m) = latsalt(IDO,m) * WSA(ISA)
        surfsalt(IDO,m) = surfsalt(IDO,m) * WSA(ISA)
        qrfsalt(IDO,m) = qrfsalt(IDO,m) * WSA(ISA)
        
        !copy into subarea arrays, for salt budget tracking
        surfqsalt_sub(nbsa(isa),m) = surfqsalt(IDO,m)
        if(gwsalt(IDO,m).gt.0) then
          gwswsalt_sub(nbsa(isa),m) = gwsalt(IDO,m)
        else
          swgwsalt_sub(nbsa(isa),m) = gwsalt(IDO,m) * (-1)
        endif
        latsalt_sub(nbsa(isa),m) = latsalt(IDO,m)
        surfsalt_sub(nbsa(isa),m) = surfsalt(IDO,m)
        qrfsalt_sub(nbsa(isa),m) = qrfsalt(IDO,m)
        
        !add to total salt array (kg)
        SMQS(IDO,m) = surfqsalt(IDO,m) + gwsalt(IDO,m) + latsalt(IDO,m) + surfsalt(IDO,m) + qrfsalt(IDO,m)
        
        !add in point source (kg)
        if(salt_point /= 0) then
          SMQS(IDO,m) = SMQS(IDO,m) + salt_ptloads(m,nbsa(isa),IY,IDA)
          pts_sub(nbsa(isa),m) = salt_ptloads(m,nbsa(isa),IY,IDA)
        endif
          
      enddo
      endif
      
      
      VAQP(IDO)=QP(IDO)
      SQP(IDO)=SQP(IDO)+QP(IDO)
      VSSN(IDO)=TSFN(IDO)
      SMMR(6,MO)=SMMR(6,MO)+QN(IDO)
      SMMR(7,MO)=SMMR(7,MO)+QP(IDO)
      SMMR(8,MO)=SMMR(8,MO)+YMNU(IDO)
	  SMMR(9,MO)=SMMR(9,MO)+QPU(IDO)
	  SMMR(10,MO)=SMMR(10,MO)+YC(IDO)
      SYC(IDO)=SYC(IDO)+YC(IDO)
      VYC(IDO)=YC(IDO)
      DO K=1,NDP
          SMMRP(1,K,MO)=SMMRP(1,K,MO)+WSAX*(QPST(K,IDO)+TSPS(K,IDO)&
          +RSPS(K,IDO))
          SMMRP(2,K,MO)=SMMRP(2,K,MO)+WSAX*YPST(K,IDO)
      END DO
      SMM(38,MO,ISA)=SMM(38,MO,ISA)+QN(IDO)
      SMM(40,MO,ISA)=SMM(40,MO,ISA)+VNO3(LNS,ISA)*WSAX
      SMM(49,MO,ISA)=SMM(49,MO,ISA)+QP(IDO)
      SMM(39,MO,ISA)=SMM(39,MO,ISA)+TSFN(IDO)
	  SMM(108,MO,ISA)=SMM(108,MO,ISA)+QPU(IDO)
	  SMM(131,MO,ISA)=SMM(131,MO,ISA)+TSFS 
	  SMM(151,MO,ISA)=SMM(151,MO,ISA)+TSFK(IDO)
      !CALL NCONT
      IF(IDA==IGSD+NT1)THEN
          IGN=IGN+100
          DO KK=1,IGN
              DO J=1,NRN0
                  XX=AUNIF(NRNG)
                  IX(J)=IX(NRNG)
              END DO
          END DO
      END IF
      IF(YERO>.001.AND.ISTA==0.AND.Z(LID(NBSL(ISA),ISA),ISA)>ZF.AND.&
      NBSL(ISA)>=3)CALL ESLOS(JRT)
      JDA=IDA+1
      RETURN
  !154 FORMAT(1X,2I8,1X,3I4,6X,100E13.6)
  154 FORMAT(1X,2I8,1X,3I4,6X,A4,100F10.4)      
  589 FORMAT(5X,'^^^^^',2I8,3I4,' PDSW = ',E13.5,1X,'PDAW = ',E13.5)
  950 FORMAT(1X,2I8,1X,3I4,1X,A4,2X,'GERMINATION--0.2 M SW = ',F7.0,' mm',&
      2X,'HU = ',F6.0,'c',2X,'HUSC = ',F5.2)
  970 FORMAT(1X,2I8,1X,I4,2I2,2X,'RB FR DK',20X,'DKH = ',F6.0,' mm',2X,&
      'DKI = ',F7.2,'m',2X,'HUSC = ',F5.2)
 1061 FORMAT(35X,'SUBAREA NO=',I8,' ID=',I8,' DATE=',I4,2I2,' YR#=',I4)
 1090 FORMAT(/1X,2I8,1X,I4,2I2,2X,5(1X,A4,F8.2)/(19X,5(1X,A4,F8.2)))
 1140 FORMAT(1X,2I8,1X,I4,2I2,2X,'SOL N FERT = ',F5.0,'kg/ha',2X,'IRR&
       VOL',' = ',F5.0,' mm',2X,'HUSC = ',F5.2)
 1201 FORMAT((19X,5(1X,A4,F8.2)))
 1202 FORMAT(2I8,1X,3I4,25F10.2)
      END