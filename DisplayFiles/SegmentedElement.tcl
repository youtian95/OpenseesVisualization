############################################################################################
# SegmentedElement.tcl
#
# This routine creates dispBeamColumn elements consisting of several segments with the same section 
# 
# Variables
    # eleTag_start
    # N_segment
    # nodeTag_start
    # iNode
    # jNode
    # numIntgrPts
    # secTag
    # transfTag
############################################################################################

############################################################################################

proc SegmentedElement {eleTag_start N_segment nodeTag_start iNode jNode numIntgrPts secTag transfTag} {

    set xyi [nodeCoord $iNode];
    set xi [lindex $xyi 0];
    set yi [lindex $xyi 1];
    set xyj [nodeCoord $jNode];
    set xj [lindex $xyj 0];
    set yj [lindex $xyj 1];
    
    for {set i 1}  {$i < [expr $N_segment+1]} {incr i} {
        set iNodeSeg [expr $nodeTag_start+$i-1];
        set jNodeSeg [expr $nodeTag_start+$i];
        if {$i != $N_segment} {
            node $jNodeSeg  [expr ($xj-$xi)/$N_segment*$i+$xi] [expr ($yj-$yi)/$N_segment*$i+$yi];
        }
        if {$i == 1} {
            set iNodeSeg $iNode;
        }
        if {$i == $N_segment} {
            set jNodeSeg $jNode;
        }
        element dispBeamColumn [expr $eleTag_start+$i-1] $iNodeSeg $jNodeSeg $numIntgrPts $secTag $transfTag;
    }
    
}