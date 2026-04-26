simulation_study/
├── scenario1.m              ← main driver script
├── supp_funs/
│   ├── generate_scenario1_data.m   ← data-generation function
│   ├── summarize_unisparse_methods.m ← metrics table builder
│   ├── compute_sparse_metrics.m    ← TPR/FPR/MCC/RMSE/MAD/MSE
│   └── save_scenario_csv.m         ← named-CSV writer
└── output/                  ← auto-created; one CSV per run

3 methods × 3 SNR levels 

output/Output_scenario_<>_methodname_<>_n_<>_p<>_design_<>_SNR_<>_rho_<>_rep<>.csv