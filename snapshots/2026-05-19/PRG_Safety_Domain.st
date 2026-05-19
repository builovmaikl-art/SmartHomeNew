PROGRAM PRG_Safety_Domain
// SEMANTIC DOMAIN WRAPPER
// PRESERVES ORIGINAL EXECUTION ORDER
// NO EXECUTION SEMANTICS MUTATION

PRG_Safety();
PRG_Safety_Operator();
PRG_Safety_Shutdown();
PRG_Safety_Recovery();

PRG_Physical_SafeState_Lattice_Governor();
PRG_CrossDomain_FailSafe_Closure_Governor();

PRG_Safety_Observability_Truth_Governor();
PRG_Physical_Safety_Projection_Governor();

END_PROGRAM