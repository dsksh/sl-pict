# SL-PICT

A script for the combinatorial enumeration of Simulink block instances.
It instantiates a block instance and generates a harness model.

## Requirements

- [MATLAB/Simulink](https://www.mathworks.com/products/simulink.html)
- [Simulink Design Verifier](https://www.mathworks.com/products/simulink-design-verifier.html) (optional)
- [PICT](https://github.com/microsoft/pict)

## Example

Specification file for the `Delay` block:
```json
{
  "BlockType" : "Delay",
  "BlockPath" : "simulink/Discrete/Delay",
  "Inputs" : [
    {
      "Name" : "u",
      "Multiplicity" : ["scalar", "vector"],
      "Domain" : ["T_float", "T_int", "T_string", "T_bool"]
    },
    {
      "Name" : "d",
      "Multiplicity" : "scalar",
      "Domain" : ["T_float", "T_int"],
      "Requires" : "[PD__DelayLengthSource] = \"Input port\""
    }
  ],
  "Output" :
    {
      "Multiplicity" : "<u>",
      "Domain" : "<u>"
    },
  "Parameters" : [
    {
      "Name" : "DelayLengthSource",
      "Domain" : ["Dialog", "Input port"]
    },
    {
      "Name" : "DelayLength",
      "Domain" : "T_uint",
      "Requires" : "[PD__DelayLengthSource] = \"Dialog\""
    }
  ]
}
```

Model generation and simulation:
```
>> test
 IM__u: vector
 ID__u: T_int
 IV1_u: 1
 IV2_u: 4
 IV3_u: 2
 IM__d: scalar
 ID__d: T_float
 IV1_d: 2
 OM__1: vector
 OD__1: T_int
 PD__DelayLengthSource: Input port
 PD__DelayLength: Disabled
 PV1_DelayLength: 0

Input:
time:   0       1       2    * SampleTime
in(1):  -128    -128    -128
in(2):  0       0       0
in(3):  -10     -10     -10
in(4):  -10.1   -10.1   -10.1

Output:
time:   0       0.2     0.4
in(1):  -128    -128    -128
```
