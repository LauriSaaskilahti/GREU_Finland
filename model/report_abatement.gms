parameter
  theta_sum[es,d,t]
  qE_diff[es,e,d,t]
  qE_diff_sum[es,d,t]
  qE_pct[es,e,d,t]
  qAdoption[l,es,d,t]
  ;

theta_sum[es,d,t]$(sum(l, d1theta[l,es,d,t])) = sum(l, theta.l[l,es,d,t]);

qE_diff[es,e,d,t]$(d1qE_tech[es,e,d,t]) = qE_tech.l[es,e,d,t] - qEpj.l[es,e,d,t];
qE_diff_sum[es,d,t] = sum(e, qE_diff[es,e,d,t]);

qE_pct[es,e,d,t]$(d1pEpj_base[es,e,d,t] and d1qE_tech[es,e,d,t]) = (qE_tech.l[es,e,d,t]/qEpj.l[es,e,d,t] - 1)*100;

qAdoption[l,es,d,t]$(d1theta[l,es,d,t]) = errorf(InputErrorf_qTutil.l[l,es,d,t]);

# execute_unloaddi "report.gdx";