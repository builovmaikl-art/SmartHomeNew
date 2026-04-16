# Rule Engine DUT rebuild plan

## Problems in current model
- weak typing
- condition and action mixed into broad structures
- limited extensibility
- too much implicit meaning in numeric fields

## Target split
- E_Rule_Data_Source_V2
- E_Rule_Value_Type_V2
- E_Rule_Target_Domain_V2
- ST_Rule_Condition_V2
- ST_Rule_Action_V2
- ST_User_Rule_V2

## Principle
Rule definition must be declarative and strongly typed.
