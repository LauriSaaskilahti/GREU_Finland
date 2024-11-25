# ------------------------------------------------------------------------------
# Variable, dummy and group creation
# ------------------------------------------------------------------------------
	
$SetGroup SG_production_dummies
  d1Prod[pf,i,t] "Dummy for production function"
  d1Y[i,t] "Dummy for production function"
;	

$SetGroup SG_production_dummies_flat_dummies 
  SG_production_dummies 
;

$SetGroup+ SG_flat_after_last_data_year
  SG_production_dummies_flat_dummies
;

$Group G_production_prices 
  pProd[pf,i,t]$(d1Prod[pf,i,t])           "Production price index, both nests and factors"
  pY0_CET[out,i,t]$(d1pY_CET[out,i,t])     "Cost price CET index of production in CET-split"
  pY0[i,t]$(d1Y[i,t])                      "Cost price index, net of installation costs and other costs not in CES-nesting tree"
;

$Group G_production_quantities 
  qProd[pf,i,t]$(d1Prod[pf,i,t])             "Production quantity, both nests and factors"
  qY[i,t]$(d1Y[i,t])                         "Production quantity net of installation costs"
;

$Group G_production_values
  vtBotded[i,t]$(d1Y[i,t])                  "Value of bottom-up deductions, bio kroner"
  vProdOtherProductionCosts[i,t]$(d1Y[i,t]) "Other production costs not in CES-nesting tree, bio. kroner"
  vtNetproductionRest[i,t]$(d1Y[i,t])       "Net production subsidies and taxes not internalized in user-cost of capital and not included in other items listed below, bio. kroner"
  vDiffMarginAvgE[i,t]$(d1Y[i,t])           "Difference between marginal and average energy-costs, bio. kroner"
  vtEmmRxE[i,t]$(d1Y[i,t])                  "Taxes on non-energy related emissions, bio. kroner"
  vtCAP_prodsubsidy[i,t]$(d1Y[i,t])         "Agricultural subsidies from EU CAP subsidizing production directly, bio. kroner"
;

$Group G_production_other 
  uProd[pf,i,t]$(d1Prod[pf,i,t])            "CES-Share of production for nest or factor (pf)"
  eProd[pFnest,i]                           "Elasticity of substitution between production nests"
  markup[out,i,t]$(d1pY_CET[out,i,t])       "Markup on production"
  uY_CET[out,i,t]$(d1pY_CET[out,i,t])       "Share of production in CET-split"
  eCET[i]                                   "Elasticity of substitution in CET-split"
  markup_calib[i,t]$(d1Y[i,t])              "Markup on production, used in calibration"
  rFirms[i,t]$(d1Y[i,t])                    "Firms' discount rate, nominal"
  delta[pf,i,t]$(d1Prod[pf,i,t] and pf_bottom_capital[pf]) "Depreciation rate of capital"
  jpProd[pf,i,t]$(d1Prod[pf,i,t])     "j-T"
;

$Group+ G_flat_after_last_data_year 
  G_production_prices
  G_production_quantities
  G_production_values
  G_production_other, -jpProd
;

$Group G_production_data_variables
  pProd
  qProd
  vtNetproductionRest
  vtCAP_prodsubsidy
;

# ------------------------------------------------------------------------------
# Add to main groups
# ------------------------------------------------------------------------------

$Group+ price_variables 
  G_production_prices
;
$Group+ quantity_variables
  G_production_quantities
;
$Group+ value_variables
  G_production_values
;
$Group+ other_variables
  G_production_other
;

$Group+ data_covered_variables 
  G_production_data_variables
;

# ------------------------------------------------------------------------------
# Equations
# ------------------------------------------------------------------------------

  $BLOCK production production_endogenous $(t1.val <= t.val and t.val <= tEnd.val)

    pY_CET[out,i,t]$(d1pY_CET[out,i,t]).. 
      pY_CET[out,i,t] =E= pY0_CET[out,i,t] * (1 + markup[out,i,t]);

    pY0_CET[out,i,t]$(d1pY_CET[out,i,t]).. 
      qY_CET[out,i,t] =E= uY_CET[out,i,t] * (pY0_CET[out,i,t]/pY0[i,t])**eCET[i] *qY[i,t];  

    qY[i,t]$(d1Y[i,t]).. 
      pY0[i,t] * qY[i,t] =E= sum(out$d1pY_CET[out,i,t], pY0_CET[out,i,t] * qY_CET[out,i,t]); 


    #Computing marginal costs. These are marginal cost of production from CES-production (pProd['TopPfunction']), net of installation costs, and other costs not covered in the production function
    pY0[i,t]$(d1Y[i,t]).. 
      pY0[i,t] * qY[i,t] =E=  pProd['TopPfunction',i,t] * qProd['TopPfunction',i,t] 
                            + vProdOtherProductionCosts[i,t];  #- qKinstcost[i,t])
                          

    qProd&_top[pf,i,t]$(pf_top[pf]).. 
      qProd[pf,i,t] =E= qY[i,t];  #+ qKinstcost[i,t];

    #CES-nests in production function
    qProd[pf,i,t]$(not pf_top[pf])..
      qProd[pf,i,t] =E= uProd[pf,i,t] * sum(pfNest$(pf_mapping[pfNest,pf,i]), (pProd[pfNest,i,t]/pProd[pf,i,t])**(-eProd[pfNest,i])*qProd[pFnest,i,t]);  

    pProd&_nest[pfNest,i,t]..
      pProd[pfNest,i,t] * qProd[pfNest,i,t] =E= sum(pf$(pf_mapping[pfNest,pf,i]), pProd[pf,i,t]*qProd[pf,i,t]);

    #Computing other production costs, not in nesting tree 

    vProdOtherProductionCosts[i,t]$(d1Y[i,t]).. 
      vProdOtherProductionCosts[i,t] =E= vtNetproductionRest[i,t]      #Net production subsidies and taxes not internalized in user-cost of capital and not included in other items listed below
                                       - vtBotded[i,t]                 #"Bottom deductions on energy-use"
                                       - vDiffMarginAvgE[i,t]          #"Difference between marginal and average energy-costs"
                                       + vtEmmRxE[i,t]                 #Taxes on non-energy related emissions
                                       - vtCAP_prodsubsidy[i,t]        #Agricultural subsidies from EU CAP subsidizing production directly.
                                       + vEnergycostsnotinnesting[i,t] #Energy costs not in nesting tree
                                       ;

  $ENDBLOCK

  $BLOCK production_usercost production_usercost_endogenous $(t1.val <= t.val and t.val <= tEnd.val)
    pProd[pf,i,t]$(not tEnd[t] and pf_bottom_capital[pf]).. 
      # pProd[pf,i,t] =E= (1+rFirms[i,t+1]) - (1-delta[pf,i,t])*fv + jpProd[pf,i,t];
      pProd[pf,i,t] =E= 1  - (1-delta[pf,i,t])/(1+rFirms[i,t+1])*fv + jpProd[pf,i,t]; #Primo-dateret user-cost kommer til at se sådan her ud

    pProd&_tEnd[pf,i,t]$(tEnd[t] and pf_bottom_capital[pf] and t1.val <> tEnd.val).. 
      pProd[pf,i,t] =E= pProd[pf,i,t-1];   
  $ENDBLOCK

  $BLOCK production_energydemand_link production_energydemand_link_endogenous $(t1.val <= t.val and t.val <= tEnd.val)
      pProd&_machine_energy[pf,i,t]$(machine_energy[pf])..
        pProd[pf,i,t] =E= pREmachine[i,t]; 

      pProd&_heating[pf,i,t]$(heating_energy[pf])..
        pProd[pf,i,t] =E= pREes['heating',i,t];

      pProd&_transport[pf,i,t]$(transport_energy[pf])..
        pProd[pf,i,t] =E= pREes['transport',i,t];
  $ENDBLOCK    

  # $BLOCK production_labormarket_link production_labormarket_link_endogenous $(t1.val and t.val <= tEnd.val)
  #   pProd&_labor[pf,i,t]$(d1Prod[pf,i,t] and sameas[pf,'labor'])..
  #     pProd[pf,i,t] =E= pL[i,t];
  # $ENDBLOCK

  # Add equation and endogenous variables to main model
  model main / production 
              production_energydemand_link
              #  production_labormarket_link
              production_usercost
              /;
  $Group+ main_endogenous 
    production_endogenous
    production_energydemand_link_endogenous
    # production_labormarket_link_endogenous
    production_usercost_endogenous
    ;

# ------------------------------------------------------------------------------
# Data 
# ------------------------------------------------------------------------------

  @load(G_production_data_variables, "../data/data.gdx")
  $Group+ data_covered_variables G_production_data_variables;

# ------------------------------------------------------------------------------
# Exogenous variables 
# ------------------------------------------------------------------------------

  eProd.l[pFnest,i]$(not pf_top[pFnest]) = 0.1;
  eCET.l[i] = 5;

  delta.l[pf,i,t]$(d1Prod[pf,i,t] and pf_bottom_capital[pf]) = 0.05;
  rFirms.l[i,t]$(sum(pf,d1Prod[pf,i,t] and pf_bottom_capital[pf])) = 0.07;

# ------------------------------------------------------------------------------
# Initial values  
# ------------------------------------------------------------------------------

  pProd.l[pfNest,i,tDataEnd] = 1;
  pProd.l[pf_bottom_capital,i,tDataEnd] = 1  - (1-delta.l[pf_bottom_capital,i,tDataEnd])/(1+rFirms.l[i,tDataEnd])*fv;

  qProd.l[pfNest,i,t] =  sum(pf_bottom$(pf_mapping[pfNest,pf_bottom,i]), pProd.l[pf_bottom,i,t]*qProd.l[pf_bottom,i,t]);
  qProd.l[pfNest,i,t] =  sum(pf$(pf_mapping[pfNest,pf,i]), pProd.l[pf,i,t]*qProd.l[pf,i,t]);
  qProd.l[pfNest,i,t] =  sum(pf$(pf_mapping[pfNest,pf,i]), pProd.l[pf,i,t]*qProd.l[pf,i,t]);
  qProd.l[pfNest,i,t] =  sum(pf$(pf_mapping[pfNest,pf,i]), pProd.l[pf,i,t]*qProd.l[pf,i,t]);
  qProd.l[pfNest,i,t] =  sum(pf$(pf_mapping[pfNest,pf,i]), pProd.l[pf,i,t]*qProd.l[pf,i,t]);

  qY.l[i,t] = qProd.l['TopPfunction',i,t];

  pY0.l[i,tDataEnd] = 1;
  pY0_CET.l[out,i,t]$(d1pY_CET[out,i,t]) = pY_CET.l[out,i,t]; 

  vtBotded.l[i,tDataEnd] = 0.05;

# ------------------------------------------------------------------------------
# Dummies 
# ------------------------------------------------------------------------------

  d1Prod[pf,i,t] = yes$(qProd.l[pf,i,t]);
  d1Y[i,t]       = yes$(sum(out,d1pY_CET[out,i,t]));

# ------------------------------------------------------------------------------
# Calibration
# ------------------------------------------------------------------------------

 $BLOCK production_calibration production_calibration_endogenous $(t.val=t1.val)
  markup[out,i,t].. 
    markup[out,i,t] =E= markup_calib[i,t];   
 $ENDBLOCK

# Add equations and calibration equations to calibration model
model calibration /
  production
  production_energydemand_link
  production_usercost
  production_calibration
/;

# Add endogenous variables to calibration model
$Group calibration_endogenous
  production_endogenous
  production_energydemand_link_endogenous

  -qProd[pf_bottom,i,t1], uProd[pf_bottom,i,t1]
  -pProd[pfNest,i,t1]$(not pf_top[pfNest]), uProd[pfNest,i,t1]$(not pf_top[pfNest])

  -pY_CET[out,i,t1], uY_CET[out,i,t1]
  -qY[i,t1], markup_calib[i,t1]
  production_calibration_endogenous

  production_usercost_endogenous
  -pProd[pf_bottom_capital,i,t1], jpProd[pf_bottom_capital,i,t1]  

  calibration_endogenous
;