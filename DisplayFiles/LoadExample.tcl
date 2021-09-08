# Created by Matlab script\r\n

set OutputDir "ExampleOutput";
set filePath1 "";
set ampl1 [expr 9.81*1000];
set maxtime 100;

source NXFmodel.tcl;
source Nodemass.tcl;

#Modal 3 1 "NXFmodel";

#source GravityRecorders.tcl;
#source Gravity.tcl;

#source PushoverRecorders.tcl;
#source Pushover.tcl;