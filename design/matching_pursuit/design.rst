Design of Matching Pursuit based recovery algorithms
======================================================


Algorithm state machine

States
- Ready (the machine is ready to accept a new problem)
- Busy  (the machine is solving a problem)


There is a common memory in which the problem and solution can be loaded.
The memory consists of regions for:
- dictionary M x N (input)
- problem vector M x 1 (input)
- solution vector N x 1 (output)

input fields can be loaded with new data. They are write only.
output fields are read only. 

When machine is ready, it accepts attempts to load a problem. 
The loading of problem consists of:
- Loading of the dictionary 
- Loading of problem vector y

When the machine is busy, the input fields (dictionary and problem vector) are locked. 
They can't be changed.

Output pins
- Whether the machine is ready to accept a new problem  [Ready/Busy switch]
- Whether the machine has written the results of the solution of last problem.

Input pins
- Clock
- A trigger to solve the problem
