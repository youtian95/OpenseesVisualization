# 1 kips-sec2/ft = 14.59 ton

# floor 2
set m [expr 69.04*14.59/5.0/2.0/6.0];
for {set ifloor 2}  {$ifloor < 3} {incr ifloor} {
    for {set icol 1}  {$icol < 7} {incr icol} {
        mass [expr $ifloor*10+$icol] $m 0 0;
    }
} 
set m [expr 69.04*14.59/10.0*4.0]; 
for {set ifloor 2}  {$ifloor < 3} {incr ifloor} {
    mass [expr $ifloor*10+7] $m 0 0;
}

# floor 3~9
set m [expr 67.86*14.59/5.0/2.0/6.0];
for {set ifloor 3}  {$ifloor < 10} {incr ifloor} {
    for {set icol 1}  {$icol < 7} {incr icol} {
        mass [expr $ifloor*10+$icol] $m 0 0;
    }
} 
set m [expr 67.86*14.59/10.0*4.0]; 
for {set ifloor 3}  {$ifloor < 10} {incr ifloor} {
    mass [expr $ifloor*10+7] $m 0 0;
}

# roof
set m [expr 73.10*14.59/5.0/2.0/6.0];
for {set ifloor 10}  {$ifloor < 11} {incr ifloor} {
    for {set icol 1}  {$icol < 7} {incr icol} {
        mass [expr $ifloor*10+$icol] $m 0 0;
    }
} 
set m [expr 73.10*14.59/10.0*4.0]; 
for {set ifloor 10}  {$ifloor < 11} {incr ifloor} {
    mass [expr $ifloor*10+7] $m 0 0;
}

