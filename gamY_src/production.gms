# ------------------------------------------------------------------------------
# Variable, dummy and group creation
# ------------------------------------------------------------------------------
	
$PGROUP PG_production_dummies
  d1Prod[pf,i,t] "Dummy for production function"
  d1Y[i,t] "Dummy for production function"
;	

$PGROUP PG_production_dummies_flat_dummies 
  PG_production_dummies 
;
$GROUP G_production_prices 
  pProd[pf,i,t]$(d1Prod[pf,i,t]) "Production price, both nests and factors"
  pY0_CET[out,i,t]$(d1pY_CET[out,i,t]) "Cost price of production in CET-split"
  pY0[i,t]$(d1Y[i,t]) "Cost price of production net of installation costs"
;

$GROUP G_production_quantities 
  qProd[pf,i,t]$(d1Prod[pf,i,t]) "Production quantity, both nests and factors"
  qY[i,t]$(d1Y[i,t])             "Production quantity net of installation costs"
;

$GROUP G_production_values
  vtBotded[i,t]$(d1Y[i,t]) "Value of bottom-up deductions"
;

$GROUP G_production_other 
  uProd[pf,i,t]$(d1Prod[pf,i,t])      "Share of production nest in production"
  eProd[pFnest,i]                     "Elasticity of substitution between production nests"
  markup[out,i,t]$(d1pY_CET[out,i,t]) "Markup on production"
  uY_CET[out,i,t]$(d1pY_CET[out,i,t]) "Share of production in CET-split"
  eCET[i]                             "Elasticity of substitution in CET-split"
  markup_calib[i,t]$(d1Y[i,t])        "Markup on production, used in calibration"
;

$GROUP G_production_flat_after_last_data_year 
  G_production_prices
  G_production_quantities
  G_production_values
  G_production_other
  # pProd 
  # qProd 
  # uProd 

  # uY_CET
  # pY0_CET
  # qY 
  # markup 
  # vtBotded
;

$GROUP G_production_data_variables
  pProd
  qProd
;

# ------------------------------------------------------------------------------
# Add to main groups
# ------------------------------------------------------------------------------

$GROUP+ price_variables 
  G_production_prices
;
$GROUP+ quantity_variables
  G_production_quantities
;
$GROUP+ value_variables
  G_production_values
;
$GROUP+ other_variables
  G_production_other
;

$GROUP+ data_covered_variables 
  G_production_data_variables
;

$PGROUP+ PG_flat_after_last_data_year 
  PG_production_dummies_flat_dummies 
;

$GROUP+ G_flat_after_last_data_year 
  G_production_flat_after_last_data_year
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


  #Computing marginal costs. These are marginal cost of production from CES-production (pProd['KETELBER']), net of installation costs, and other costs not covered in the production function
  pY0[i,t]$(d1Y[i,t]).. 
    pY0[i,t] * qY[i,t] =E=  pProd['TopPfunction',i,t] * (qProd['TopPfunction',i,t]+ vtBotded[i,t]);  #- qKinstcost[i,t])
                         

  qProd&_top[pf,i,t]$(d1Prod[pf,i,t] and pf_top[pf]).. 
    qProd[pf,i,t] =E= qY[i,t];  #+ qKinstcost[i,t];

  #CES-nests in production function
  qProd[pf,i,t]$(d1Prod[pf,i,t] and not pf_top[pf])..
    qProd[pf,i,t] =E= uProd[pf,i,t] * sum(pfNest$(pf_mapping[pfNest,pf,i]), (pProd[pfNest,i,t]/pProd[pf,i,t])**(-eProd[pfNest,i])*qProd[pFnest,i,t]);  

  pProd&_nest[pfNest,i,t]$(d1Prod[pfNest,i,t])..
    pProd[pfNest,i,t] * qProd[pfNest,i,t] =E= sum(pf$(pf_mapping[pfNest,pf,i]), pProd[pf,i,t]*qProd[pf,i,t]);

$ENDBLOCK

$BLOCK production_energydemand_link production_energydemand_link_endogenous $(t1.val <= t.val and t.val <= tEnd.val)
    pProd&_machine_energy[pf,i,t]$(d1Prod[pf,i,t] and sameas[pf,'machine_energy'])..
      pProd[pf,i,t] =E= pREmachine[i,t]; 

    pProd&_heating[pf,i,t]$(d1Prod[pf,i,t] and sameas[pf,'heating_energy'])..
      pProd[pf,i,t] =E= pREPPS['heating',i,t];

    pProd&_transport[pf,i,t]$(d1Prod[pf,i,t] and sameas[pf,'transport_energy'])..
      pProd[pf,i,t] =E= pREPPS['transport',i,t];
$ENDBLOCK    

# $BLOCK production_labormarket_link production_labormarket_link_endogenous $(t1.val and t.val <= tEnd.val)
#   pProd&_labor[pf,i,t]$(d1Prod[pf,i,t] and sameas[pf,'labor'])..
#     pProd[pf,i,t] =E= pL[i,t];
# $ENDBLOCK

# Add equation and endogenous variables to main model
model main / production 
             production_energydemand_link
            #  production_labormarket_link
            /;
$GROUP+ main_endogenous 
  production_endogenous
  production_energydemand_link_endogenous
  # production_labormarket_link_endogenous
  ;

# ------------------------------------------------------------------------------
# Data 
# ------------------------------------------------------------------------------

@load(G_production_data_variables, "../data/data.gdx")
$GROUP+ data_covered_variables G_production_data_variables;


# ------------------------------------------------------------------------------
# Exogenous variables 
# ------------------------------------------------------------------------------

eProd.l[pFnest,i]$(not sameas[pFnest,'TopPfunction']) = 0.1;
eCET.l[i] = 5;

# ------------------------------------------------------------------------------
# Initial values  
# ------------------------------------------------------------------------------

pProd.l[pfNest,i,tDataEnd] = 1;

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
# Initial values  
# ------------------------------------------------------------------------------

d1Prod[pf,i,t] = yes$(qProd.l[pf,i,t]);
d1Y[i,t]       = yes$(sum(out,d1pY_CET[out,i,t]));

# ------------------------------------------------------------------------------
# Calibration
# ------------------------------------------------------------------------------



 $BLOCK production_calibration production_calibration_endogenous $(t.val=t1.val)
  markup[out,i,t]$(d1pY_CET[out,i,t]).. 
    markup[out,i,t] =E= markup_calib[i,t];
 $ENDBLOCK

# Add equations and calibration equations to calibration model
model calibration /
  production
  production_calibration
/;

# Add endogenous variables to calibration model
$GROUP calibration_endogenous
  production_endogenous
  -qProd[pf_bottom,i,t1], uProd[pf_bottom,i,t1]
  -pProd[pfNest,i,t1]$(not pf_top[pfNest]), uProd[pfNest,i,t1]$(not pf_top[pfNest])

  -pY_CET[out,i,t1], uY_CET[out,i,t1]
  -qY[i,t1], markup_calib[i,t1]
  production_calibration_endogenous  

  calibration_endogenous
;