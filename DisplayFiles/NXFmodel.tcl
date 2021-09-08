model BasicBuilder -ndm 2 -ndf 3  
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
set storyheight 3960.0;    
set baywidth 9150.0;     
set story1height 5490.0;
set basementheight 3650.0;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
set E 206000;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
set Fy 345;
set Arigid 1.0E+6;
set b 0.03;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
set matTag 1;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
uniaxialMaterial Steel01 $matTag $Fy $E $b;
set matTagRigid 11;
uniaxialMaterial Elastic $matTagRigid [expr 1.0E+10];                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
# nodes 
set  ifloor 0; # basement
for {set icol 1}  {$icol < 7} {incr icol} {
    set x [expr ($icol-1)*$baywidth];
    set y [expr ($ifloor-1)*$basementheight];
    node [expr $ifloor*10+$icol] $x $y; 
} 
set  ifloor 1;
for {set icol 1}  {$icol < 8} {incr icol} {
    set x [expr ($icol-1)*$baywidth];
    set y [expr ($ifloor-1)*$storyheight];
    node [expr $ifloor*10+$icol] $x $y; 
}
node 161 [expr (6-1)*$baywidth] 0; 
equalDOF 16 161 1 2;
set  ifloor 2;
for {set icol 1}  {$icol < 8} {incr icol} {
    set x [expr ($icol-1)*$baywidth];
    set y [expr ($ifloor-1)*$story1height];
    node [expr $ifloor*10+$icol] $x $y; 
}
node 261 [expr (6-1)*$baywidth] $story1height; 
equalDOF 26 261 1 2;
for {set ifloor 3}  {$ifloor < 11} {incr ifloor} {
    for {set icol 1}  {$icol < 8} {incr icol} {
        set x [expr ($icol-1)*$baywidth];
        set y [expr ($ifloor-2)*$storyheight + $story1height ];
        node [expr $ifloor*10+$icol] $x $y;  
    }
    node [expr $ifloor*100+6*10+1] [expr (6-1)*$baywidth] [expr ($ifloor-2)*$storyheight + $story1height];
    equalDOF [expr $ifloor*10+6] [expr $ifloor*100+6*10+1] 1 2;
}        
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
for {set icol 1}  {$icol < 7} {incr icol} {                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
    fix $icol 1 1 0; 
}
fix 11 1 1 0; 
fix 16 1 1 0; 
fix 17 1 1 1; 

for {set ifloor 2}  {$ifloor < 11} {incr ifloor} {
    fix [expr $ifloor*10+7] 0 0 1;      
}    
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               

source WSection.tcl;

# section
set secTag_W14x257 1;
WSection $secTag_W14x257 $matTag 416.6 406.4 48 30 10 2 10 2;  
set secTag_W14x311 2;
WSection $secTag_W14x311 $matTag 434.3 411.5 57.4 35.8 10 2 10 2;  
set secTag_W14x68 3;
WSection $secTag_W14x68 $matTag 355.6 254.0 18.3 10.5 10 2 10 2;
set secTag_W33x118 4;
WSection $secTag_W33x118 $matTag 835.7 292.1 18.8 14.0 10 2 10 2;
set secTag_W30x116 5;
WSection $secTag_W30x116 $matTag 762.0 266.7 21.6 14.4 10 2 10 2;
set secTag_W24x68 6;
WSection $secTag_W24x68 $matTag 602.0 227.8 14.9 10.5 10 2 10 2;
set secTag_W21x44 7;
WSection $secTag_W21x44 $matTag 525.8 165.1 11.4 8.9 10 2 10 2;
set secTag_W36x160 8;
WSection $secTag_W36x160 $matTag 914.4 304.8 25.9 16.5 10 2 10 2;
set secTag_W36x135 9;
WSection $secTag_W36x135 $matTag 904.2 304.8 20.1 15.2 10 2 10 2;
set secTag_W30x99 10;
WSection $secTag_W30x99 $matTag 754.4 266.7 17.0 13.2 10 2 10 2;
set secTag_W27x84 11;
WSection $secTag_W27x84 $matTag 678.2 254.0 16.3 11.7 10 2 10 2;
set secTag_W14x500 12;
WSection $secTag_W14x500 $matTag 497.8 431.8 88.9 55.6 10 2 10 2; 
set secTag_W14x455 13;
WSection $secTag_W14x455 $matTag 482.6 426.7 81.5 51.3 10 2 10 2; 
set secTag_W14x370 14;
WSection $secTag_W14x370 $matTag 454.7 419.1 67.6 42.2 10 2 10 2; 
set secTag_W14x283 15;
WSection $secTag_W14x283 $matTag 424.2 408.9 52.6 32.8 10 2 10 2;

set transfTag 1;
geomTransf Corotational $transfTag;
source SegmentedElement.tcl;

# colomn 
set N_segment 2; 
set ifloor 0;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
        [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x500 $transfTag;  
}
set ifloor 1;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
        [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x500 $transfTag;  
}
set ifloor 2;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    set i_node_mid [expr $i_node_1*100 + $i_node_2];
    node $i_node_mid [expr $baywidth*($icol-1)] [expr ($ifloor-2)*$storyheight+$story1height+$storyheight/2.0];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
        [expr ($i_node_1*10000+$i_node_mid)*100+1] $i_node_1 $i_node_mid 10 $secTag_W14x500 $transfTag; 
    SegmentedElement [expr (300+$ifloor*10+$icol)*100+1] $N_segment \
        [expr ($i_node_mid*100+$i_node_2)*100+1] $i_node_mid $i_node_2 10 $secTag_W14x455 $transfTag; 
}
set ifloor 3;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x455 $transfTag;  
}
set ifloor 4;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    set i_node_mid [expr $i_node_1*100 + $i_node_2];
    node $i_node_mid [expr $baywidth*($icol-1)] [expr ($ifloor-2)*$storyheight+$story1height+$storyheight/2.0];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_1*10000+$i_node_mid)*100+1] $i_node_1 $i_node_mid 10 $secTag_W14x455 $transfTag; 
    SegmentedElement [expr (300+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_mid*100+$i_node_2)*100+1] $i_node_mid $i_node_2 10 $secTag_W14x370 $transfTag; 
}
set ifloor 5;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x370 $transfTag;  
}
set ifloor 6;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    set i_node_mid [expr $i_node_1*100 + $i_node_2];
    node $i_node_mid [expr $baywidth*($icol-1)] [expr ($ifloor-2)*$storyheight+$story1height+$storyheight/2.0];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_1*10000+$i_node_mid)*100+1] $i_node_1 $i_node_mid 10 $secTag_W14x370 $transfTag; 
    SegmentedElement [expr (300+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_mid*100+$i_node_2)*100+1] $i_node_mid $i_node_2 10 $secTag_W14x283 $transfTag; 
}
set ifloor 7;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x283 $transfTag;  
}
set ifloor 8;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    set i_node_mid [expr $i_node_1*100 + $i_node_2];
    node $i_node_mid [expr $baywidth*($icol-1)] [expr ($ifloor-2)*$storyheight+$story1height+$storyheight/2.0];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_1*10000+$i_node_mid)*100+1] $i_node_1 $i_node_mid 10 $secTag_W14x283 $transfTag; 
    SegmentedElement [expr (300+$ifloor*10+$icol)*100+1] $N_segment \
    [expr ($i_node_mid*100+$i_node_2)*100+1] $i_node_mid $i_node_2 10 $secTag_W14x257 $transfTag; 
}
set ifloor 9;
for {set icol 1}  {$icol < 7} {incr icol} {
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    SegmentedElement [expr (100+$ifloor*10+$icol)*100+1] $N_segment \
    [expr $i_node_1*10000+$i_node_2*100+1] $i_node_1 $i_node_2 10 $secTag_W14x257 $transfTag;  
}
# col 7
for {set ifloor 1}  {$ifloor < 10} {incr ifloor} {
    set icol 7;
    set i_node_1 [expr $ifloor*10+$icol];
    set i_node_2 [expr ($ifloor+1)*10+$icol];
    element corotTruss [expr 100+$ifloor*10+$icol] $i_node_1 $i_node_2 $Arigid $matTagRigid -doRayleigh 1;
}

# beam 
set N_segment 1; 
# floor 1-3
for {set ifloor 1}  {$ifloor < 4} {incr ifloor} {
    for {set bay 1}  {$bay < 5} {incr bay} {
        set i_node_1 [expr $ifloor*10+$bay];
        set i_node_2 [expr $ifloor*10+$bay+1];
        set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
        SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
            $i_node_1 $i_node_2 10 $secTag_W36x160 $transfTag; 
    }
    set bay 5;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr ($ifloor*10+$bay+1)*10+1];
    set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
    SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
        $i_node_1 $i_node_2 10 $secTag_W36x160 $transfTag; 
}
# floor 4-7
for {set ifloor 4}  {$ifloor < 8} {incr ifloor} {
    for {set bay 1}  {$bay < 5} {incr bay} {
        set i_node_1 [expr $ifloor*10+$bay];
        set i_node_2 [expr $ifloor*10+$bay+1];
        set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
        SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
            $i_node_1 $i_node_2 10 $secTag_W36x135 $transfTag; 
    }
    set bay 5;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr ($ifloor*10+$bay+1)*10+1];
    set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
    SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
        $i_node_1 $i_node_2 10 $secTag_W36x135 $transfTag; 
}
# floor 8
for {set ifloor 8}  {$ifloor < 9} {incr ifloor} {
    for {set bay 1}  {$bay < 5} {incr bay} {
        set i_node_1 [expr $ifloor*10+$bay];
        set i_node_2 [expr $ifloor*10+$bay+1];
        set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
        SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
        $i_node_1 $i_node_2 10 $secTag_W30x99 $transfTag; 
    }
    set bay 5;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr ($ifloor*10+$bay+1)*10+1];
    set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
    SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
    $i_node_1 $i_node_2 10 $secTag_W30x99 $transfTag; 
}
# floor 9
for {set ifloor 9}  {$ifloor < 10} {incr ifloor} {
    for {set bay 1}  {$bay < 5} {incr bay} {
        set i_node_1 [expr $ifloor*10+$bay];
        set i_node_2 [expr $ifloor*10+$bay+1];
        set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
        SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
        $i_node_1 $i_node_2 10 $secTag_W27x84 $transfTag; 
    }
    set bay 5;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr ($ifloor*10+$bay+1)*10+1];
    set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
    SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
    $i_node_1 $i_node_2 10 $secTag_W27x84 $transfTag; 
}
# floor 10
for {set ifloor 10}  {$ifloor < 11} {incr ifloor} {
    for {set bay 1}  {$bay < 5} {incr bay} {
        set i_node_1 [expr $ifloor*10+$bay];
        set i_node_2 [expr $ifloor*10+$bay+1];
        set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
        SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
        $i_node_1 $i_node_2 10 $secTag_W24x68 $transfTag; 
    }
    set bay 5;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr ($ifloor*10+$bay+1)*10+1];
    set digits [expr int(10^(int(ceil(log10($i_node_2)))))];
    SegmentedElement [expr (2000+$ifloor*10+$bay)*10+1] $N_segment [expr $i_node_1*$digits*100+$i_node_2*100+1] \
    $i_node_1 $i_node_2 10 $secTag_W24x68 $transfTag; 
}
# 6 bay
for {set ifloor 2}  {$ifloor < 11} {incr ifloor} {
    set bay 6;
    set i_node_1 [expr $ifloor*10+$bay];
    set i_node_2 [expr $ifloor*10+$bay+1];
    element corotTruss [expr 2000+$ifloor*10+$bay] $i_node_1 $i_node_2 $Arigid $matTagRigid -doRayleigh 1; 
}
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
# loading                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           
initialize                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
source procedure010.tcl                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         
set modelName "NXFmodel" ;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
