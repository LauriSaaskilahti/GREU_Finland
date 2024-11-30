$onMulti # Allows adding to an already defined set or model with multiple "model" or "set" statements

$IMPORT functions.gms;
$IMPORT settings.gms

$IMPORT sets/time.sets.gms
$IMPORT sets/sectors.sets.gms
$IMPORT sets/input_output.sets.gms
$IMPORT sets/output.sets.gms
$IMPORT sets/production.sets.gms
$IMPORT sets/emissions.sets.gms
$IMPORT sets/energy_taxes_and_emissions.sets.gms

set_time_periods(%first_data_year%, %terminal_year%);

# ------------------------------------------------------------------------------
# Select modules
# ------------------------------------------------------------------------------
$FUNCTION import_from_modules(stage_key):
  $SETGLOBAL stage stage_key;
  $IMPORT submodel_template.gms
  $IMPORT financial_accounts.gms
  $IMPORT labor_market.gms
  $IMPORT energy_markets.gms; 
  $IMPORT industries_CES_energydemand.gms; 
  $IMPORT production.gms; 
  $IMPORT emissions.gms; 
  $IMPORT energy_and_emissions_taxes.gms; 
  $IMPORT input_output.gms
  $IMPORT households.gms
  $IMPORT government.gms
  $IMPORT exports.gms
  $IMPORT factor_demand.gms
  # $IMPORT test_module.gms
  # $IMPORT production_CET.gms;
  # $IMPORT aggregates.gms
  # $IMPORT imports.gms
$ENDFUNCTION

# ------------------------------------------------------------------------------
# Define variables and dummies
# ------------------------------------------------------------------------------
# Group of all variables, identical to ALL group, except containing only elements that exist (not dummied out)
$Group all_variables ; # All variables in the model
$Group main_endogenous ;
$Group data_covered_variables ; # Variables that are covered by data
$Group G_flat_after_last_data_year ; # Variables that are extended with "flat forecast" after last data year
$SetGroup SG_flat_after_last_data_year ; # Dummies that are extended with "flat forecast" after last data year
@import_from_modules("variables")
$IMPORT variable_groups.gms
$IMPORT growth_adjustments.gms

# ------------------------------------------------------------------------------
# Define equations
# ------------------------------------------------------------------------------
model main;
model calibration;
@import_from_modules("equations")
@add_exist_dummies_to_model(main) # Limit the main model to only include elements that are not dummied out
main.optfile=1;

# ------------------------------------------------------------------------------
# Import data and set parameters
# ------------------------------------------------------------------------------
@import_from_modules("exogenous_values")
@inf_growth_adjust()
@set(data_covered_variables, _data, .l) # Save values of data covered variables prior to calibration
@update_exist_dummies()

# ------------------------------------------------------------------------------
# Calibrate model
# ------------------------------------------------------------------------------
$Group calibration_endogenous ;
@import_from_modules("calibration")
calibration.optfile=1;
$IMPORT calibration.gms

# ------------------------------------------------------------------------------
# Tests
# ------------------------------------------------------------------------------
# $import sanitychecks.gms
@import_from_modules("tests")
# Data check  -  Abort if any data covered variables have been changed by the calibration
@assert_no_difference(data_covered_variables, 1e-6, _data, .l, "data_covered_variables was changed by calibration.")

# Zero shock  -  Abort if a zero shock changes any variables significantly
@set(all_variables, _saved, .l)
$FIX all_variables; $UNFIX main_endogenous;
Solve main using CNS;
execute_unload 'main.gdx';
@assert_no_difference(all_variables, 1e-6, .l, _saved, "Zero shock changed variables significantly.");

# ------------------------------------------------------------------------------
# Exercise: Increase production costs in partial model
# ------------------------------------------------------------------------------

#Set time periods to years after 2019
#[insert your own code here]

# Putting together the partial model:   
# Model production_partial 
# /production 
#  /;

#Collecting endogenous variables in group G_endo 
# $GROUP G_endo 
  #[insert your own code here] 
# ;

#Fixing all_variables and unfixing endogenous variables
#[insert your own code here]

#Adding exist dummies to the model and setting opt-file for the solver
#[insert your own code here]


#Set all_variables
#[insert your own code here]

#Solve the partial model, and use @assert_no_differences to check that your model has produced a zero-shock
#[insert your own code here]
#[insert your own code here]

#Unload the results to a gdx file
#[insert your own code here]


#We now set-up a shock where we increase the price of machine-energy by 10%.
#[insert your own code here]

#Fix exogenous variables, and unfix endogenous variables, and solve the model.
#[insert your own code here]
#[insert your own code here]
#[insert your own code here]


#Write the results to a gdx
#[insert your own code here]


# ------------------------------------------------------------------------------
# Exercise in energy and emissions accounts (Comment out code from the exercise above before starting this bit)
# ------------------------------------------------------------------------------

#START BY COMMENTING IN THE CODE THAT SETS TIME PERIODS, 
#COLLECTS THE MODEL, AND THE ENDOGENOUS VARIABLES IN G_ENDO
# set_time_periods(2020, %terminal_year%);

# Model production_energy_emissions_partial 
#   /production 
#    production_usercost
#    production_energydemand_link

#    industries_energy_demand
#    industries_energy_demand_link

#    energy_demand_prices  
# 	 energy_markets_clearing_link

#    energy_and_emissions_taxes

#    emissions_BU
#    emissions_aggregates 
#    emissions_aggregates_link
#    /;

# #Collect endogenous variables in the group G_endo
# $GROUP G_endo 
#   production_endogenous
#   production_usercost_endogenous
#   production_energydemand_link_endogenous
  
#   industries_energy_demand_endogenous
#   industries_energy_demand_link_endogenous

#   energy_demand_prices_endogenous
#   energy_markets_clearing_link_endogenous

#   energy_and_emissions_taxes_endogenous

#   emissions_BU_endogenous
#   emissions_aggregates_endogenous
#   emissions_aggregates_link_endogenous
# ;

#Add exit-dummies to the model and set opt-file for the solver
#[insert your own code here]
#[insert your own code here]


#Fix exo-variables, unfix endo-variables 
#[insert your own code here]
#[insert your own code here]


#Save the values of the variables in the group _saved
#[insert your own code here]

#Now solve the model, and check your model produces a zero-shock
#[insert your own code here]
#[insert your own code here]

#Unload the results to a gdx file
#[insert your own code here]


#Shock the ETS1-price by 10%
#[insert your own code here]

#Fix exogenous variables, unfix endogenous variables, and solve the model.
#[insert your own code here]
#[insert your own code here]
#[insert your own code here]

#Unload the results to a gdx
#[insert your own code here]
