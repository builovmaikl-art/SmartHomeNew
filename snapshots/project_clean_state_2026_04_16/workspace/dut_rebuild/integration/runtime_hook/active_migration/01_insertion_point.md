# Insertion Point

Target: inside main FOR loop over rules

Original flow:
- read rule
- evaluate condition
- generate action

New staged flow:
- read rule
- pass through compatibility adapter (optional validation phase)
- keep original evaluation
- later replace evaluation with V2 core
