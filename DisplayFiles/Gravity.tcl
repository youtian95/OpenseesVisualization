# define GRAVITY LOAD -------------------------------------------------------------

pattern Plain 1 Linear {
    
    # floor 2
    set m [expr 69.04*14.59/5.0/2.0/6.0];
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 2}  {$ifloor < 3} {incr ifloor} {
        for {set icol 1}  {$icol < 7} {incr icol} {
            load [expr $ifloor*10+$icol] 0 $G1 0;
        }
    } 
    set m [expr 69.04*14.59/10.0*4.0]; 
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 2}  {$ifloor < 3} {incr ifloor} {
        load [expr $ifloor*10+7] 0 $G1 0;
    }
    
    # floor 3~9
    set m [expr 67.86*14.59/5.0/2.0/6.0];
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 3}  {$ifloor < 10} {incr ifloor} {
        for {set icol 1}  {$icol < 7} {incr icol} {
            load [expr $ifloor*10+$icol] 0 $G1 0;
        }
    } 
    set m [expr 67.86*14.59/10.0*4.0]; 
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 3}  {$ifloor < 10} {incr ifloor} {
        load [expr $ifloor*10+7] 0 $G1 0;
    }
    
    # roof
    set m [expr 73.10*14.59/5.0/2.0/6.0];
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 10}  {$ifloor < 11} {incr ifloor} {
        for {set icol 1}  {$icol < 7} {incr icol} {
            load [expr $ifloor*10+$icol] 0 $G1 0;
        }
    } 
    set m [expr 73.10*14.59/10.0*4.0]; 
    set G1 [expr -$m*1000.0*9.8];
    for {set ifloor 10}  {$ifloor < 11} {incr ifloor} {
        load [expr $ifloor*10+7] 0 $G1 0;
    }
}
NonLinearStaticNoRecs 1e-4 0.1 10 100 $modelName
loadConst -time 0.0;