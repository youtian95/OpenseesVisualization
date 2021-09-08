# procedures and wrappers for OpenSees

# ----------------------------------------
#           openRecorders
# ----------------------------------------
# opens typical recorders for a particular analysis
# ----------------------------------------
# result    :   a list containing recorder IDs to be used for disposal
# ----------------------------------------
# analysis  :   string containing the type of recorders. This string may ask for different types of recorders. Just list them e.g. "general dynamic".
#               "general"   : general purpose recorders (NodeDisplacements, NodeReactions, ElementForces);
#               "modal"     : eigen analysis recorders (EigenVectors);
#               "dynamic"   : typical time hystory analysis recorders (NodeAccelerations).
# startNode :   the first node of the interval of nodes you want to export. Put -1 to let the procedure determine the lowest ID.
# endNode   :   the last node of the interval you want to export. Put -1 to let the procedure determine the highest ID.
# startElem :   same as startNode but referred to elements. Put -1 to automatically use the lowest ID.
# endElem   :   same as endNode but referred to elements. Put -1 to automatically use the highest ID.
# modelName :   string that can be used to distinguish between models. It is appended to standard recorder names to differentiate them.
#               It is passed to openRecorders through any analysis procedure that creates recorder.
# procName  :   (REMOVED) string that can be used to distinguish between analyses. It is appended to standard recorder names to differentiate them.
#               If openRecorders isn't called by the user, the other procedures in this file will fill this argument with a particular string themselves.
# args      :   OPTIONAL argument. Required whenever $analysis contains "modal". It's the number of modes for which the user wants the eigenvectors.
#               In the other cases can be appended to differentiate recorders in multistep analyses (e.g. IDA) which would overwrite
#               the same recorders over and over.
proc openRecorders { analysis startNode endNode startElem endElem modelName procName args} {

    set res [list]
    #set tempStr "${modelName}_${procName}_"
    set tempStr "${procName}_"
    set formatStr "_%03d.out"
    if { $startNode == -1 || $endNode == -1 } {
        set nList [getNodeTags]
        set endNode [::tcl::mathfunc::max {*}$nList]
        set startNode [::tcl::mathfunc::min {*}$nList]
        #puts "$startNode $endNode"
    }
    set nodeDStr ""
    set nodeRStr ""
    set nodeEStr ""
    set nodeAStr ""
    set eleFStr ""
    
    if {[string match *general* $analysis]==1} {
        if { $startElem == -1 || $endElem == -1 } {
            set nList [getEleTags]
            set endElem [::tcl::mathfunc::max {*}$nList]
            set startElem [::tcl::mathfunc::min {*}$nList]
        }
        append nodeDStr $tempStr "Node_Displacements"
        append nodeRStr $tempStr "Node_Reactions"
        append eleFStr $tempStr "Element_Forces"
        if { [llength $args]==1 } {
            if { $args>=1 } {
                append nodeDStr  [format $formatStr $args]
                append nodeRStr  [format $formatStr $args]
                append eleFStr [format $formatStr $args]]
            } else {
                append nodeDStr  ".out"
                append nodeRStr  ".out"
                append eleFStr  ".out"
            }
        } else {
            append nodeDStr  ".out"
            append nodeRStr  ".out"
            append eleFStr  ".out"
        }
        # "NodeDisplacements${args}.out" no spaces
        lappend res [recorder Node -file $nodeDStr -precision 12 -time -nodeRange $startNode $endNode -dof 1 2 3 4 5 6 disp]
        lappend res [recorder Node -file $nodeRStr -precision 12 -time -nodeRange $startNode $endNode -dof 1 2 3 4 5 6 reaction]
        lappend res [recorder Element -file $eleFStr -precision 12 -time -eleRange $startElem $endElem force]
    }
    
    if {[string match *modal* $analysis]==1} {
        if { [llength $args]==1 } {
            if { $args>=1 } {
                append nodeEStr $tempStr "Node_Eigenvectors" $formatStr
                for {set i 1} {$i<=$args} {incr i} {
                    lappend res [recorder Node -file [format $nodeEStr $i] -precision 12 -time -nodeRange $startNode $endNode -dof 1 2 3 4 5 6 "eigen $i"]
                }
            } else {
                puts "Invalid mode"
            }
        } elseif { [llength $args]!=1 } {
            puts "Invalid number of parameters"
        }
    }
    
    if {[string match *dynamic* $analysis]==1} {
        append nodeAStr $tempStr "Node_Accelerations"
        if { [llength $args]==1 } {
            if { $args>=1 } {
      # $tempStr
                append nodeAStr [format $formatStr $args]
            } else {
                append nodeAStr ".out"
            }
        } else {
            append nodeAStr ".out"
        }
        
        lappend res [recorder Node -file $nodeAStr -precision 12 -time -nodeRange $startNode $endNode -dof 1 2 3 4 5 6 accel]
    }
    return $res
}

proc recordStress { procName } {
    set res [list]
    set tempStr "${procName}_"
    set eleFStr ""

    set nList [getEleTags]
    set endElem [::tcl::mathfunc::max {*}$nList]
    set startElem [::tcl::mathfunc::min {*}$nList]

    append eleFStr $tempStr "Element_Stresses"
    append eleFStr  ".out"
    lappend res [recorder Element -file $eleFStr -precision 12 -time stresses]
    return $res
}


# ----------------------------------------
#           closeRecorders
# ----------------------------------------
# closes recorders given their IDs. To be used with the list given by openRecorders
# ----------------------------------------
# result    :   None
# ----------------------------------------
# recList   :   list of recorder IDs to be disposed.

proc closeRecorders { recList } {
    if { [llength $recList]>0 } { 
        foreach rec $recList {
            remove recorder $rec
        }
    }
}


# ----------------------------------------
#           openSectionRecorders
# ----------------------------------------
# opens a element forces recorder for each section. Indicated for fiber section beam elements
# ----------------------------------------
# result    :   a list containing recorder IDs to be used for disposal
# ----------------------------------------
# numSections:   Number of integration points in the element to record.
# elems     :   The list of elements these recorders can be applied to.
# modelName :   string that can be used to distinguish between models. It is appended to standard recorder names to differentiate them.
#               It is passed to openRecorders through any analysis procedure that creates recorder.
# procName  :   (REMOVED) string that can be used to distinguish between analyses. It is appended to standard recorder names to differentiate them.
#               If openRecorders isn't called by the user, the other procedures in this file will fill this argument with a particular string themselves.

proc openSectionRecorders { numSections elems modelName } {   # procName
    set res [list]
    set mnStr "${modelName}_"
    set formatStr "_%03d.out"
    set sectionFStr ""
    append sectionFStr $mnStr "Section_Forces"
    for {set i 2} {$i<$numSections} {incr i} {
        set tempS $sectionFStr
        append tempS [format $formatStr $i]
        lappend res [recorder Element -file $tempS -precision 12 -time -ele {*}$elems section $i forces]
    }
    return $res
}


# ----------------------------------------
#           display
# ----------------------------------------
# uses OpenSees simple graphic capabilites to show the model and its deformed shape
# ----------------------------------------
# result    :   None
# ----------------------------------------
# viewScale :   scale factor for the deformed shape

proc display { viewScale } {
    # display the model with the node numbers
    source DisplayPlane.tcl
    source DisplayModel3D.tcl
    DisplayModel3D DeformedShape $viewScale;
}

# ----------------------------------------
#           LinearStatic
# ----------------------------------------
# performs a single step LINEAR static analysis
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# modelName :   model name to be passed to openRecorders procedure

proc LinearStatic {modelName} {

    set recs [openRecorders "general" -1 -1 -1 -1 "Lin" $modelName]
    #puts $recs
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            #numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test NormDispIncr 1.0e-6 10 1
    integrator LoadControl 1
    algorithm Linear
    analysis Static
    set ok [analyze 1]
    closeRecorders $recs
    return $ok
    
}

# ----------------------------------------
#           LinearStaticNoRecs
# ----------------------------------------
# performs a single step LINEAR static analysis
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# modelName :   model name to be passed to openRecorders procedure

proc LinearStaticNoRecs {modelName} {

    #set recs [openRecorders "general" -1 -1 -1 -1 "Lin" $modelName]
    #puts $recs
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            #numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test NormDispIncr 1.0e-6 10 1
    integrator LoadControl 1
    algorithm Linear
    analysis Static
    set ok [analyze 1]
    #closeRecorders $recs
    return $ok
    
}

# ----------------------------------------
#           NonLinearStatic
# ----------------------------------------
# performs a non-linear static analysis using load control
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# tol       :   sets the convergence tolerance
# step      :   the step size
# nsteps    :   total number of steps
# modelName :   model name to be passed to openRecorders procedure

proc NonLinearStatic { tol step nsteps iters modelName } {

    set recs [openRecorders "general dynamic" -1 -1 -1 -1 "StaticNL" $modelName]
    
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            #numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test EnergyIncr $tol $iters 1
    algorithm Newton
    integrator LoadControl $step
    analysis Static
    set ok [analyze $nsteps]
    closeRecorders $recs
    return $ok
    
}

# ----------------------------------------
#           NonLinearStaticDisp
# ----------------------------------------
# performs a non-linear static analysis using displacement control.
# this procedure is functional to others. It doesn't create recorders.
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# tol       :   sets the convergence tolerance
# step      :   the step size
# nsteps    :   total number of steps
# cnode     :   control node. It is the node where the displacement is imposed
# cdof      :   control dof. The direction of the imposed displacement
# modelName :   model name to be passed to openRecorders procedure
proc NonLinearStaticDisp { tol step nsteps cnode cdof iters modelName} {
    set recs [openRecorders "general dynamic" -1 -1 -1 -1 "StaticNL" $modelName]
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            # numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test EnergyIncr $tol $iters 1 
    # NormUnbalance
    # algorithm Newton
    algorithm ModifiedNewton 
    integrator DisplacementControl $cnode $cdof $step $iters
    analysis Static
    set ok [analyze $nsteps]
    closeRecorders $recs
    return $ok
}

# Dictionary tool
proc isdict value {
    expr {![catch {dict size $value}]}
}
# IsNumeric TCL equivalent
proc isnumeric value {
    if {![catch {expr {abs($value)}}]} {
        return 1
    }
    set value [string trimleft $value 0]
    if {![catch {expr {abs($value)}}]} {
        return 1
    }
    return 0
}

# ----------------------------------------
#           NonLinearStaticNoRecs
# ----------------------------------------
# performs a non-linear static analysis using load control
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# tol       :   sets the convergence tolerance
# step      :   the step size
# nsteps    :   total number of steps
# modelName :   model name to be passed to openRecorders procedure

proc NonLinearStaticNoRecs { tol step nsteps iters modelName } {

    #set recs [openRecorders "general dynamic" -1 -1 -1 -1 "StaticNL" $modelName]
    
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            #numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test EnergyIncr $tol $iters 1
    algorithm Newton
    integrator LoadControl $step
    analysis Static
    set ok [analyze $nsteps]
    #closeRecorders $recs
    return $ok
    
}

# ----------------------------------------
#           NonLinearStaticDispNoRecs
# ----------------------------------------
# performs a non-linear static analysis using displacement control.
# this procedure is functional to others. It doesn't create recorders.
# ----------------------------------------
# result    :   the error code of OpenSees analyze command
# ----------------------------------------
# tol       :   sets the convergence tolerance
# step      :   the step size
# nsteps    :   total number of steps
# cnode     :   control node. It is the node where the displacement is imposed
# cdof      :   control dof. The direction of the imposed displacement
# modelName :   model name to be passed to openRecorders procedure
proc NonLinearStaticDispNoRecs { tol step nsteps cnode cdof iters modelName} {
    #set recs [openRecorders "general dynamic" -1 -1 -1 -1 "StaticNL" $modelName]
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            # numberer parallelPlain
            numberer Plain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    test EnergyIncr $tol $iters 1 
    # NormUnbalance
    # algorithm Newton
    algorithm ModifiedNewton 
    integrator DisplacementControl $cnode $cdof $step $iters
    analysis Static
    set ok [analyze $nsteps]
    #closeRecorders $recs
    return $ok
}

# ----------------------------------------
#           Modal
# ----------------------------------------
# performs an eigen analysis
# ----------------------------------------
# result    :   a list made of a list of natural frequencies and a list of periods
# ----------------------------------------
# n         :   the number of modes to be found
# wr        :   a flag that, if set to 1, allows to write eigenvalues and periods to file. Any other value does nothing.
# modelName :   model name to be passed to openRecorders procedure
# args      :   OPTIONAL argument. Put 1 if you want this procedure to create recorders. This is may be useful if the eigen analysis is a standalone one.
#               Put any other value if the eigen analysis is functional to other types of analysis e.g. adaptive pushover and do not want it to overwrite results over and over.

proc Modal {n wr modelName args} {

    set period "modesPeriods "
    append period $modelName; append period ".txt"
    set eigVal "eigenValues " 
    append eigVal $modelName; append eigVal ".txt"

    set recs [list]
    if { $wr==1 } {
        #clear output files
        set Periods [open $period "w"]
        puts -nonewline $Periods ""
        close $Periods
        set eigVals [open $eigVal "w"]
        puts -nonewline $eigVals ""
        close $eigVals
    }
    if { [llength $args]==1 } {
        if { $args==1 } {
            set recs [openRecorders "modal" -1 -1 -1 -1 $n $modelName $n]
        #~ } elseif { $args>1 } {
            #~ puts "Invalid parameters"
            #~ return [list]
        }
    #~ } elseif { [llength $args]>1 } {
        #~ puts "Invalid parameters"
        #~ return [list]
    }

    #system UmfPack
    system ProfileSPD
    #-lValueFact 100 # 
    #set lambda [eigen -fullGenLapack $n];
    set lambda [eigen $n];
    record
    # puts $lambda;
    
    set omega {}
    set f {}
    set T {}
    set pi 3.141593
    
    if { $wr==1 } {
    #~ set num [array size $lambda];
    #~ puts "OS gave $num modes";
    #~ puts $lambda;
        foreach lam $lambda {
            if { $lam>=0 } {
                lappend omega [expr sqrt($lam)]
                lappend f [expr sqrt($lam)/(2*$pi)]
                lappend T [expr (2*$pi)/sqrt($lam)]
            }
        }
        
        #set period [concat "modesPeriods" $modelName ".txt"]
        set Periods [open $period "a+"]
        
        foreach t $T {
            puts -nonewline $Periods "$t;"
        }
        
        close $Periods
        
        #set eigVal [concat "eigenValues" $modelName ".txt"]
        set eigVals [open $eigVal "a+"]
        
        foreach lam $lambda {
            puts -nonewline $eigVals "$lam;"
        }
        
        close $eigVals
    }
    
    if { [llength $args]==1 } {
        if { $args==1 } {
            closeRecorders $recs
        }
    }
    
    return [list $omega $T]
    
}


# ----------------------------------------
#           Pushover
# ----------------------------------------
# performs a pushover analysis
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# type      :   used to define the type of distribution: 1 - mode shaped load pattern, 2 - mass proportional load pattern.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is imposed.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# nsteps    :   number of steps.
# modelName :   model name to be passed to openRecorders procedure

proc Pushover { patternStart type mode nodes masses cnode cdof tol step nsteps modelName checkProc} {
    
    if { ($type!=1) && ($type!=2) } {
        return "Invalid parameters"
    }
    
    if {$type==1} {
        set period "modesPeriods.txt"
        set Periods [open $period "w"]
        puts -nonewline $Periods ""
        close $Periods
        set recs [openRecorders "general modal" -1 -1 -1 -1 "PO$type" $modelName $mode]
        Modal $mode 1 $modelName
    } else {
        set recs [openRecorders "general" -1 -1 -1 -1 "PO$type" $modelName ]
    }
    
    set check [llength [info procs $checkProc]]
    
    # vertical loads
    puts "Applying vertical loads..."
    VertLoads $patternStart
    NonLinearStatic 1e-5 0.02 50 100 $modelName
    
    # make all previous pattern constant
    loadConst -time 0.0
    if { $check==1 } {
        $checkProc
    }
    
    puts "Applying horizontal loads..."
    set i 0
    pattern Plain [expr $patternStart+1] Linear {
        foreach n $nodes m $masses {
            set eig {0 0 0 0 0 0}
            set i [expr $i+1]
            
            if {$type==1} {
                #set eig [nodeEigenvector $n $mode]
            } else {
                lset eig [expr $cdof-1] 1 ;# put a 1 in the direction of pushing
            }
        
            #load $n [expr [lindex $eig 0]*$m] [expr [lindex $eig 1]*$m] 0 0 0
            if {$type == 2} {
                load $n [expr [lindex $eig 0]*$m] [expr [lindex $eig 1]*$m] [expr [lindex $eig 2]*$m] 0 0 0      ;# con carico verticale
            } else {
                set temp [getMphi $mode $n]
                set mphi {0 0 0 0 0 0}
                lset mphi [expr $cdof-1] [lindex $temp [expr $cdof-1]]
                load $n {*}$mphi
            }
        }
    }
    
    set Disp 0
    for {set i 0} {$i<$nsteps} {incr i} {
        set ok [NonLinearStaticDisp $tol $step 1 $cnode $cdof]
        set Disp [nodeDisp $cnode $cdof]
        puts "current displacement at node $cnode: $Disp"
        if { $check==1 } {
            $checkProc $Disp
        }
        if {$ok!=0} {
            puts "Analysis failed."
            closeRecorders $recs
            return -1
        }
    }
    closeRecorders $recs
    
}


# ----------------------------------------
#           SetDamping
# ----------------------------------------
# Sets model damping ratios.
# ----------------------------------------
# result    :   0 if successful. -1 if error
# ----------------------------------------
# flag      :   defines damping type.
#               0   : mass proportional damping. First mode is set as control mode.
#               1   : mass proportional damping. $args contains the control mode.
#               2   : Rayleigh damping. $args contains two control modes
#               any other values causes an error.
# csi       :   damping ratio
# args      :   variable length argument. Contains the modes used to build the damping matrix.
proc SetDamping { flag csi args } {
    
    if { $flag==[llength $args] } {
        if { $flag==0 } {
            puts "Using first mode for damping calibration."
            MDamping $csi 1
            return 0
        } elseif { $flag==1 } {
            MDamping $csi $args
            return 0
        } elseif { $flag==2 } {
            setRayleigh $csi [lindex $args 0 ] [lindex $args 1]
            return 0
        } else {
            return -1
        }
    } else {
        return -1
    }
    
}


# ----------------------------------------
#           MDamping
# ----------------------------------------
# Builds mass proportional damping matrix.
# ----------------------------------------
# result    :   none
# ----------------------------------------
#csi        :   damping ratio
#modeI      :   control mode
proc MDamping { csi modeI } {
    
    #retrieve the eigenvalues from the eigen analysis
    set eigval [lindex [eigen -fullGenLapack $modeI] 0 ] ;# recupera gli omega
    set omegaI [lindex [expr sqrt($eigval)] $modeI-1]

    set alphaM [expr 2.0*$csi*$omegaI]
    puts "Alpha set to $alphaM";
    #apply the damping to all nodes and elements defined previously
    rayleigh $alphaM 0 0 0
}


# ----------------------------------------
#           setRayleigh
# ----------------------------------------
# Builds Rayleigh damping matrix.
# ----------------------------------------
# result    :   none
# ----------------------------------------
#csi        :   damping ratio
#modeI      :   first control mode
#modeJ      :   second control mode
proc setRayleigh { csi modeI modeJ } {
    
    #puts $modeI
    #puts $modeJ
    if { $modeI < $modeJ } {
        set temp $modeI
        set modeI $modeJ
        set modeJ $temp
    }

    #switches needed for the creation of the damping matrix.
    #1 to consider the single contribution, 0 not to.
    set KcurrSwitch 0.0
    set KinitSwitch 1.0
    set KcommSwitch 0.0
    
    #retrieve the eigenvalues from the eigen analysis
    set eigval [eigen $modeI];
    set omegaI [expr sqrt([lindex $eigval $modeI-1])];
    set omegaJ [expr sqrt([lindex $eigval $modeJ-1])];
    
    set alphaK [expr 2.0*$csi/($omegaI+$omegaJ)]
    set alphaM [expr $alphaK*$omegaI*$omegaJ]
    
    #apply the damping to all nodes and elements defined previously
    rayleigh $alphaM [expr $KcurrSwitch*$alphaK] [expr $KinitSwitch*$alphaK] [expr $KcommSwitch*$alphaK]
    
}


# ----------------------------------------
#           DynamicAn
# ----------------------------------------
# Performs a time-history analysis.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# Tmax      :   analysis length.
# dt        :   reference step
# filePath  :   file containing time-acceleration pairs.
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# dir       :   motion direction
# TolDynamic    :   convergence tolerance.
# ampl      :   accelerogram scale factor
# modelName :   model name to be passed to openRecorders procedure
proc DynamicAn { Tmax dt filePath patternStart dir TolDynamic ampl modelName OutputDir} {

#################################################################################################################
#################################################################################################################
    #set recs [openRecorders "general dynamic" -1 -1 -1 -1 "DynamicNL" $modelName ]##############################
#################################################################################################################
#################################################################################################################   
    
    # make all previous pattern constant
    loadConst -time 0.0
    
    # load from file 1
    set f [open $filePath r]
    foreach line [split [read $f] "\n"] {
        #puts $line
        if {$line == ""} {
            break;
        }
        lappend times [lindex $line 0]
        lappend accs  [lindex $line 1]
    }
    close $f  
    
    timeSeries Path [expr $patternStart+1] -time $times -values $accs -factor $ampl
    pattern UniformExcitation [expr $patternStart+1] $dir -accel [expr $patternStart+1]
    puts "New load pattern ready..."
    
#################################################################################################################
#################################################################################################################
    source Recorders.tcl; #######################################################################################
#################################################################################################################
#################################################################################################################
    
    #setup the system of equations
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            numberer parallelPlain
            system Mumps
        } else {
            numberer RCM
            system ProfileSPD
        }
    } else {
        numberer RCM
        system ProfileSPD
    }
    
    # test NormDispIncr $TolDynamic 10 1
    test EnergyIncr $TolDynamic 20 1 
    # test NormUnbalance $TolDynamic 20 1
    # test RelativeEnergyIncr  $TolDynamic 10 1
    
    # algorithm Broyden
    algorithm ModifiedNewton

    set NewmarkGamma 0.5    ;# Newmark-integrator gamma parameter
    set NewmarkBeta [expr 1.0/4.0]  ;# Newmark-integrator beta parameter
    
    integrator Newmark $NewmarkGamma $NewmarkBeta
    # integrator HHT 0.7 $NewmarkGamma $NewmarkBeta
    
    #analysis VariableTransient  ;#VariableTransient - for transient analysis with variable time step
    analysis Transient         ;#Transient - Transient - for transient analysis with constant time step
    
    set DtAnalysis $dt      ;#integration step
    set DtMin [expr $dt/10000.0]           ;#minimum step
    set DtMax $dt           ;#maximum step - better if this isn't longer than the accelerogram step
    set Nexp 10             ;#expected number of iterations. The step is adapted according to this
    set Nsteps [expr int($Tmax/$DtAnalysis)];
    puts "Starting analysis..."
    
#################################################################################################################
#################################################################################################################
    #---------------------------------------------------------------------------
    set TmaxAnalysis $Tmax; 
    source MultimethodSolutionForDynamic.tcl;
    #---------------------------------------------------------------------------
#################################################################################################################
#################################################################################################################
    
    # set ok [analyze $Nsteps $DtAnalysis $DtMin $DtMax $Nexp]; 
    
    # set ok [analyze $Nsteps $DtAnalysis]
    # if {$ok != 0} {
        # puts "Errors encountered!"
    # }
    
    #set t 0
    #set ok 0
    #while {$t<$Tmax} {
    #    set ok [analyze 1 $DtAnalysis $DtMin $DtMax]; # actually perform analysis; returns ok=0 if analysis was successful
    #    #set ok [analyze 1 $DtAnalysis]
    #    if {$ok != 0} {
    #        puts "Errors encountered!"
    #        break
    #    }
    #    set t [getTime]
    #    if {[info exists ::np]} {puts "pid: $::pid, t: $t"}
    #}
    

    #if {[info exists ::np]} {puts "pid: $::pid, end time: [getTime]"}
    #closeRecorders $recs
    #return $ok
    
    puts "end time: [getTime]"
    #closeRecorders $recs
    return $ok
        
}

# ----------------------------------------
#           DynamicAn2
# ----------------------------------------
# Performs a time-history analysis.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# Tmax      :   analysis length.
# dt        :   reference step
# filePath1 :   file containing time-acceleration pairs.
# filePath2 :   file containing time-acceleration pairs.
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# dir1      :   motion direction 1
# dir1      :   motion direction 2
# TolDynamic    :   convergence tolerance.
# ampl      :   accelerogram scale factor
# modelName :   model name to be passed to openRecorders procedure
# OutputDir :   dir for outputing results
proc DynamicAn2 { Tmax dt filePath1 filePath2 patternStart dir1 dir2 TolDynamic ampl1 ampl2 modelName OutputDir} {
    
    #set recs [openRecorders "general dynamic" -1 -1 -1 -1 "DynamicNL" $modelName ]
    
    # make all previous pattern constant
    loadConst -time 0.0
    
    # load from file 1
    set f [open $filePath1 r]
    foreach line [split [read $f] "\n"] {
        #puts $line
        if {$line == ""} {
            break;
        }
        lappend times [lindex $line 0]
        lappend accs  [lindex $line 1]
    }
    close $f
  
    # load from file 2
    set f2 [open $filePath2 r]
    foreach line [split [read $f2] "\n"] {
        #puts $line
        if {$line == ""} {
            break;
        }
        lappend times2 [lindex $line 0]
        lappend accs2  [lindex $line 1]
    }
    close $f2
    
    timeSeries Path [expr $patternStart+1] -time $times -values $accs -factor $ampl1
    pattern UniformExcitation [expr $patternStart+1] $dir1 -accel [expr $patternStart+1]
    timeSeries Path [expr $patternStart+2] -time $times2 -values $accs2 -factor $ampl2
    pattern UniformExcitation [expr $patternStart+2] $dir2 -accel [expr $patternStart+2]
    puts "New load patterns are ready";
    
#################################################################################################################
#################################################################################################################
    source Recorders.tcl; #######################################################################################
#################################################################################################################
#################################################################################################################
    
    #setup the system of equations
    constraints Transformation
    if {[info exists ::np]} {
        if {$::np>1} {
            numberer parallelPlain
            system Mumps
        } else {
            numberer RCM
            system SparseGEN
        }
    } else {
        numberer RCM
        system SparseGEN
    }
    
    # test NormDispIncr $TolDynamic 10 1
    test EnergyIncr $TolDynamic 20;
    # test NormUnbalance $TolDynamic 20 1
    # test RelativeEnergyIncr  $TolDynamic 10 1
    
    # algorithm Broyden
    algorithm ModifiedNewton

    set NewmarkGamma 0.5    ;# Newmark-integrator gamma parameter
    set NewmarkBeta [expr 1.0/4.0]  ;# Newmark-integrator beta parameter
    
    integrator Newmark $NewmarkGamma $NewmarkBeta
    # integrator HHT 0.7 $NewmarkGamma $NewmarkBeta
    
    #analysis VariableTransient -numSublevels 5 -numSubSteps 5;#VariableTransient - for transient analysis with variable time step
    analysis Transient         ;#Transient - Transient - for transient analysis with constant time step
    
    
    set DtAnalysis $dt      ;#integration step
    set DtMin [expr $dt/10000.0]           ;#minimum step
    set DtMax $dt           ;#maximum step - better if this isn't longer than the accelerogram step
    set Nexp 10             ;#expected number of iterations. The step is adapted according to this
    set Nsteps [expr int($Tmax/$DtAnalysis)];
    puts "Starting analysis..."
    
#################################################################################################################
#################################################################################################################
    #---------------------------------------------------------------------------
    set TmaxAnalysis $Tmax; 
    source MultimethodSolutionForDynamic.tcl;
    #---------------------------------------------------------------------------
#################################################################################################################
#################################################################################################################

    #set t 0
    #set ok 0
    #while {$t<$Tmax} {
    #    set ok [analyze 1 $DtAnalysis $DtMin $DtMax $Nexp]; # actually perform analysis; returns ok=0 if analysis was successful
    #    #set ok [analyze 1 $DtAnalysis]
    #    if {$ok != 0} {
    #        puts "Errors encountered!"
    #        break
    #    }
    #    set t [getTime]
    #    puts "t: $t"
    #}
    
    puts "end time: [getTime]"
    #closeRecorders $recs
    return $ok
        
}

# ----------------------------------------
#           IDA
# ----------------------------------------
# Performs an IDA analysis.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# Tmax      :   analysis length.
# dt        :   reference step
# filePath  :   file containing time-acceleration pairs.
# patternStart  :   the first free tag. This proc uses patternStart to patternStart+gSteps IDs to create load patterns.
# dir       :   motion direction
# TolDynamic    :   convergence tolerance.
# gMax      :   maximum number of Gs.
# gSteps    :   number of steps to reach the maximum G.
# modelName :   model name to be passed to openRecorders procedure
proc IDA { Tmax dt filePath patternStart dir TolDynamic gMax gSteps modelName} {
    
    set g 9.81  ;#m/s2
    # set gSteps    10  ;#how many steps. 0 times $g is not considered.
    # set gMax  0.5 ;#max g 
    set step    [expr $gMax/$gSteps]
    
    set times [list]
    set accs  [list]
    set f [open $filePath r]
    foreach line [split [read $f] "\n"] {
        #puts $line
        lappend times [lindex $line 0]
        lappend accs  [lindex $line 1]
    }
    #puts $times
    #puts $accs
    
    for {set i 1} {$i<=$gSteps} {incr i} {
        
        puts "step $i"
        reset
        
        # vertical loads
        puts "Vertical loads application..."
        VertLoads $patternStart
        if { [NonLinearStatic 1e-5 0.02 50]!=0 } {
            puts "Errors encountered!"
        }
    
        #make all previous load pattern constant
        loadConst -time 0.0
                
        set cFactor [expr $g*$step*$i]
        puts "Accelerazione attuale: $cFactor m/s2"
        set recs [openRecorders "general dynamic" -1 -1 -1 -1 "IDA_$cFactor" $modelName]
        
        timeSeries Path [expr $patternStart+$i] -time $times -values $accs -factor $cFactor
        pattern UniformExcitation [expr $patternStart+$i] $dir -accel [expr $patternStart+$i]
        puts "New load pattern ready..."
        
        #setup the system of equations
        constraints Transformation
        if {[info exists ::np]} {
            if {$::np>1} {
                numberer parallelPlain
                system Mumps
            } else {
                numberer RCM
                system ProfileSPD
            }
        } else {
            numberer RCM
            system ProfileSPD
        }
        test NormDispIncr $TolDynamic 20 1
        algorithm Broyden

        set NewmarkGamma 0.5    ;# Newmark-integrator gamma parameter
        set NewmarkBeta [expr 1.0/4.0]  ;# Newmark-integrator beta parameter
        integrator Newmark $NewmarkGamma $NewmarkBeta
        #analysis VariableTransient ;#VariableTransient - for transient analysis with variable time step
        analysis Transient          ;#Transient - Transient - for transient analysis with constant time step
        
        set DtAnalysis 0.02     ;#integration step
        set DtMin 0.005         ;#minimum step
        set DtMax $dt           ;#maximum step
        set Nexp 50             ;#number of iterations
        set Nsteps [expr int($Tmax/$DtAnalysis)];
        puts "Starting analysis..."
        #set ok [analyze $Nsteps $DtAnalysis $DtMin $DtMax $Nexp]; # actually perform analysis; returns ok=0 if analysis was successful
        set ok [analyze $Nsteps $DtAnalysis]
        if {$ok != 0} {
            puts "$cFactor - Errors encountered!"
            continue
        }
        loadConst -time 0.0
        remove loadPattern $patternStart
        remove loadPattern [expr $patternStart+$i]
        
        closeRecorders $recs
    }   
}


# ----------------------------------------
#           IDAParallel
# ----------------------------------------
# Performs a parallel IDA analysis.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# dt        :   reference step.
# filePath  :   file containing time-acceleration pairs.
# patternStart  :   the first free tag. This proc uses patternStart to patternStart+gSteps IDs to create load patterns.
# dir       :   motion direction
# TolDynamic    :   convergence tolerance.
# gMax      :   maximum number of Gs.
# gSteps    :   number of steps to reach the maximum G.
# node      :   control node. Used with checkProc for logging and checking purposes.
# modelName :   model name to be passed to openRecorders procedure.
# recProc   :   name of a user defined function that will create recorders for each step. Return value of this must be a list of recorder IDs.
#           :   input parameters are: the step number and modelName.
# checkProc :   name of a user defined function that will perform user defined checks at each step. Use the step number and modelName as parameters
#               for initialization. No arguments then it means finalization. It is called after each step when it's given step number, modelName,
#               a file handle for logging, the control node ID.
proc IDAParallel { dt filePath patternStart dir TolDynamic gMax gSteps node modelName recProc checkProc } {
    set logF "Log_$::pid.txt"
    set hLog [open $logF "w"]
    puts "pid: $::pid, entering IDA proc"
    puts $hLog "using file: $filePath"
    puts $hLog "[clock format [clock seconds]]: entering IDA proc"
    
    set g 9.81  ;#m/s2
    # set gSteps    7   ;#number of steps. 0*$g not considered
    # set gMax  1.4 ;#max g
    set step    [expr $gMax/$gSteps]
    
    set times [list]
    set accs  [list]
    set f [open $filePath r]
    foreach line [split [read $f] "\n"] {
        #puts $line
        lappend times [lindex $line 0]
        lappend accs  [lindex $line 1]
    }
    #puts $times
    #puts $accs
    
    set Nsteps [llength $times]
    set TMax [lindex $times [expr $Nsteps-1]]
    
    set isRecDef [llength [info procs $recProc]]
    set check [llength [info procs $checkProc]]
    
    for {set i 1} {$i<=$gSteps} {incr i} {
        
        puts "pid: $::pid, step: $i"
        puts $hLog "[clock format [clock seconds]]: beginning of step $i"
        reset
        

        # vertical loads
        puts "pid: $::pid, Vertical loads application..."
        VertLoads $patternStart
        if { [NonLinearStatic 1e-5 0.1 10]!=0 } {
            puts "pid: $::pid, Errors encountered!"
            puts $hLog "[clock format [clock seconds]]: Errors occurred applying vertical loads in step $i"
            close $hLog
            return -1
        }
        puts $hLog "[clock format [clock seconds]]: Finished applying vertical loads in step $i"

        # make all previous load patterns constant
        loadConst -time 0.0
        
        # create recorders
        if {$isRecDef==1} {
            set recs [$recProc $i $modelName]
        }

        # initialize the checks
        if {$check==1} {
            $checkProc $i $modelName
            puts $hLog "[clock format [clock seconds]]: Finished creating check conditions for step $i"
        }
                
        set cFactor [expr $g*$step*$i]
        puts "Current Peak Acceleration: [expr $step*$i] G"
        timeSeries Path [expr $patternStart+$i] -time $times -values $accs -factor $cFactor
        pattern UniformExcitation [expr $patternStart+$i] $dir -accel [expr $patternStart+$i]
        puts "pid: $::pid, New load pattern ready..."
        puts $hLog "[clock format [clock seconds]]: Finished creating timeSeries and loadPattern for step $i"
        
        #setup the system of equations
        constraints Transformation
        if {[info exists ::np]} {
            if {$::np>1} {
                numberer RCM
                system Mumps
            } else {
                numberer RCM
                system ProfileSPD
            }
        } else {
            numberer RCM
            system ProfileSPD
        }
        test NormDispIncr $TolDynamic 20 
        algorithm ModifiedNewton

        SetDamping 1 0.05 2
        
        set NewmarkGamma 0.5    ;# Newmark-integrator gamma parameter
        set NewmarkBeta [expr 1.0/4]    ;# Newmark-integrator beta parameter
        integrator Newmark $NewmarkGamma $NewmarkBeta
        #analysis VariableTransient ;#VariableTransient - for transient analysis with variable time step
        analysis Transient          ;#Transient - Transient - for transient analysis with constant time step
        
        set DtAnalysis $dt      ;#integration step
        set DtMin [expr $dt/16.0]       ;#min step
        set DtMax $DtAnalysis           ;#max step
        set Nexp 50             ;#numero di iterazioni che ci si aspetta ad ogni passo. Se le iterazioni necessarie sono più o meno di queste, Opensees regola il passo di integrazione di conseguenza.
        #set Nsteps [expr int($Tmax/$DtAnalysis)];
        puts "pid: $::pid, Starting analysis..."
        puts $hLog "[clock format [clock seconds]]: Starting analysis for step $i"
        
        set t 0
        ##for {set j 0} {$j<$Nsteps} {incr j} {}
        while {$t<$TMax} {
            #puts "pid: $::pid, step $j"
            #set ok [analyze 1 $DtAnalysis $DtMin $DtMax $Nexp]; # actually perform analysis; returns ok=0 if analysis was successful
            set ok [analyze 1 $DtAnalysis]
            if {$ok != 0} {
                puts "regular newton failed .. lets try an initial stiffness for this step"
                test NormDispIncr $TolDynamic  1000 0
                algorithm ModifiedNewton -initial
                #set ok [analyze 1 $DtAnalysis $DtMin $DtMax $Nexp]
                set ok [analyze 1 $DtAnalysis]
                if {$ok == 0} {puts "that worked .. back to regular newton"}
                test NormDispIncr $TolDynamic 20 
                algorithm Newton
            }
            if {$ok != 0} {
                puts "Trying Broyden .."
                algorithm Broyden 8
                set ok [analyze 1 $DtAnalysis]
                algorithm Newton
            }
            if {$ok != 0} {
                puts "Trying NewtonWithLineSearch .."
                algorithm NewtonLineSearch .8
                set ok [analyze 1 $DtAnalysis]
                algorithm Newton
            }
            if { $check==1 } {
                # set Disp [nodeDisp $node $dir]
                set resp [$checkProc $i $modelName $hLog $node]
                # if {[string length $resp]!=0} {
                #   puts $hLog "$resp"
                # }
            }
            set t [getTime]
            puts "pid: $::pid, t: $t"
            if {$ok != 0} {
                if {[info exists ::np]} {puts "pid: $::pid, Errors encountered!"}
                puts $hLog "[clock format [clock seconds]]: Error in step $i at analysis time $t"
                close $hLog
                break
            }
        }
        if {$isRecDef==1} {
            puts $hLog "[clock format [clock seconds]]: closing recorders for step $i"
            closeRecorders $recs
        }
        remove loadPattern $patternStart
        remove loadPattern [expr $patternStart+$i]
        if { $check==1 } {
            $checkProc
        }
        puts $hLog "[clock format [clock seconds]]: SLD: $::SLD,      SLV: $::SLV,      SLC: $::SLC"
        if {[info exists ::np]} {puts "pid: $::pid"}
        puts "end of step $i"
        puts $hLog "[clock format [clock seconds]]: finished step $i"
    }
    close $hLog
    #closeRecorders $recs
    return $ok
}


# ----------------------------------------
#           AdaptivePO_SM
# ----------------------------------------
# Performs an adaptive Pushover analysis. The load pattern is built using the mode that moves the most mass in the dection of pushing.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is imposed.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# Dmax      :   maximum imposed displacement at $cnode
# checkProc :   name of a user defined function that will perform user defined checks at each step. 
proc AdaptivePO_SM { patternStart mode nodes masses cnode cdof tol step Dmax checkProc } {
    
    #set recs [openRecorders "general" -1 -1 -1 -1 ]
    
    # vertical loads
    puts "Vertical loads application..."
    VertLoads $patternStart
    if { [NonLinearStatic 1e-5 0.1 10]!=0 } {
        puts "Errors encountered!"
    }
    
    # initialize the checks
    set check [llength [info procs $checkProc]]
    if { $check==1 } {
        $checkProc
    }
    
    set period "modesPeriods.txt"
    set Periods [open $period "w"]
    puts -nonewline $Periods ""
    close $Periods
    
    #lappend recs [openRecorders "modal" -1 -1 -1 -1 $mode]
    
    set i 0
    set Disp 0
    while {$Disp<$Dmax} {
        
        set i [expr $i+1]
        puts "step $i,  current displacement: $Disp"
        # make all previous load patterns constants
        loadConst -time 0.0
        
        #eigen analysis - we need the eigenvectors
        Modal $mode 1 $modelName
        
        #participating mass ratios
        set pFact [pFactors -m $mode -s]
        set PMRatios [lindex $pFact 2]
        #puts $PMRatios
        #Comparison of participating masses to determine the mode to be used
        if {$mode > 1} {
            set tmode [expr $mode-1]
            set ref [lindex $PMRatios $tmode [expr $cdof-1]]
            #puts "ref value: $ref"
            for {set j $tmode} {$j>=0} {incr j -1} {
                if {$ref<[lindex $PMRatios $j [expr $cdof-1]]} {
                    set mode [expr $j+1]
                    #read stdin 1
                    puts "Migrating to mode $mode as it has more participating mass in direction $cdof"
                }
            }
        }
        
        pattern Plain [expr $patternStart+$i] Linear {
            foreach n $nodes m $masses {
                
                #set eig [nodeEigenvector $n $mode]

                #load $n [expr [lindex $eig 0]*$m] [expr [lindex $eig 1]*$m] [expr [lindex $eig 2]*$m] 0 0 0      ;# con carico verticale
                load $n {*}[getMphi $mode $n]
                #puts [getMphi $mode $n]
            }
        }
        puts "New load pattern ready..."
        
        set nsteps 1   ;# one step at a time. eigenvectors are calculated again each time
        set ok [NonLinearStaticDisp $tol $step $nsteps $cnode $cdof]
        set Disp [nodeDisp $cnode $cdof]
        if { $check==1 } {
            $checkProc $Disp
        }
        if {$ok != 0} {
            puts "Errors encountered. Stopping calculations..."
            break  ;# break while loop
        } else {
            puts "Analysis for step $i completed."
        }
    }
    
    #closeRecorders $recs
    return $ok
}


# ----------------------------------------
#           AdaptivePO_MM
# ----------------------------------------
# Performs a adaptive Multimodal Pushover analysis (Antoniou & Pinho).
# The load pattern is built using a combination of modal shapes.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is imposed.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# Dmax      :   maximum imposed displacement at $cnode
# checkProc :   name of a user defined function that will perform user defined checks at each step. 
# args      :   OPTIONAL parameter. File containing a response spectrum. If set it'll be used to apply a spectral amplification of modal shapes.
proc AdaptivePO_MM { patternStart mode nodes masses cnode cdof tol step Dmax checkProc args } {
    
    #set recs [openRecorders "general" -1 -1 -1 -1 ]
    set specAmpl 0
    if { [llength $args]==1 } {
        if {[file exists $args]} {
            set specAmpl 1
            leggiSpettro $args
        }
    }
    
    # vertical loads
    puts "Vertical loads application..."
    VertLoads $patternStart
    if { [NonLinearStatic 1e-5 0.1 10]!=0 } {
        puts "Errors encountered!"
    }
    
    # initialize checks
    set check [llength [info procs $checkProc]]
    if { $check==1 } {
        $checkProc
    }
    
    set period "modesPeriods.txt"
    set Periods [open $period "w"]
    puts -nonewline $Periods ""
    close $Periods
    
    #lappend recs [openRecorders "modal" -1 -1 -1 -1 $mode]
    
    set i 0
    set Disp 0
    while {$Disp<$Dmax} {
        
        set i [expr $i+1]
        puts "step $i, current displacement: $Disp"
        # make all previous load patterns constant
        loadConst -time 0.0
        
    #retrieve eigenvalues
    set omegaT [expr sqrt([lindex [lindex [eigen $modeI] 0] $modeI-1])]

        set T [lindex $omegaT 1]
        set accs [list]
        #using all modes up to $mode
        for {set j 0} {$j<$mode} {incr j} {
            if {$specAmpl == 1} {
                lappend accs [Spettro [lindex T $j]]
            } else {
                lappend accs 1
            }
        }
        
        #participating masses
        set pFact [pFactors -m $mode -s]
        #decreasing $mode - as arrays are 0 based
        set refMode [expr $mode-1]
        set refDof [expr $cdof-1]

        set Fact [lindex $pFact 0]
        #puts "Fact: $Fact"
        #set ndof [llength [lindex $pFact 0 0]]
        
        pattern Plain [expr $patternStart+$i] Linear {
            foreach n $nodes m $masses {
                
                set modLoads [list]
                for {set j 0} {$j<$mode} {incr j} {
                    set eig [nodeEigenvector $n [expr $j+1]]
                    #puts "eig: $eig"
                    set fact [lindex $Fact $j $refDof]
                    #puts "fact: $fact"
                    set mphi [list [expr [lindex $eig 0]*$m*$fact*[lindex $accs $j]]  [expr [lindex $eig 1]*$m*$fact*[lindex $accs $j]]  [expr [lindex $eig 2]*$m*$fact*[lindex $accs $j]] 0 0 0 ]
                    lappend modLoads $mphi
                }
                set ld [ldepth $modLoads]
                #puts $modLoads

                if {$ld > 1} {
                    set s1 0
                    set s2 0
                    set s3 0
                    set s4 0
                    set s5 0
                    set s6 0
                    for {set k 0} {$k<$mode} {incr k} {
                        set s1 [expr $s1+pow([lindex $modLoads $k 0],2) ]
                        set s2 [expr $s2+pow([lindex $modLoads $k 1],2) ]
                        set s3 [expr $s3+pow([lindex $modLoads $k 2],2) ]
                        set s4 [expr $s4+pow([lindex $modLoads $k 3],2) ]
                        set s5 [expr $s5+pow([lindex $modLoads $k 4],2) ]
                        set s6 [expr $s6+pow([lindex $modLoads $k 5],2) ]
                    }
                    set s1 [expr sqrt($s1)]
                    set s2 [expr sqrt($s2)]
                    set s3 [expr sqrt($s3)]
                    set s4 [expr sqrt($s4)]
                    set s5 [expr sqrt($s5)]
                    set s6 [expr sqrt($s6)]
                    #puts "load: $s1 $s2 $s3 $s4 $s5 $s6"
                    load $n $s1 $s2 $s3 $s4 $s5 $s6
                    
                } else {
                    load $n {*}$modLoads
                
                }
            }
        }
        puts "New load pattern ready..."
        
        set npassi 1   ;# one step at a time. eigenvectors are calculated again each time
        set ok [NonLinearStaticDisp $tol $step $npassi $cnode $cdof]
        set Disp [nodeDisp $cnode $cdof]
        if { $check==1 } {
            $checkProc $Disp
        }
        if {$ok != 0} {
            puts "Errors encountered. Interrupting calculations..."
            break  ;#break while loop
        } else {
            puts "Analysis for step $i completed."
        }
    }
    
    #closeRecorders $recs
    return $ok
}


# ----------------------------------------
#           AdaptivePO_DAP
# ----------------------------------------
# Performs a adaptive displacement-based Pushover analysis (Antoniou & Pinho).
# Modal shapes are used to define imposed displacements patterns.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is controlled.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# Dmax      :   maximum imposed displacement at $cnode
# checkProc :   name of a user defined function that will perform user defined checks at each step. 
proc AdaptivePO_DAP { patternStart mode nodes cnode cdof tol step Dmax checkProc } {
    
    #set recs [openRecorders "general" -1 -1 -1 -1 ]
    
    # vertical loads
    puts "Vertical loads application..."
    #VertLoads $patternStart
    #if { [NonLinearStatic 1e-5 0.05 20]!=0 } {
    #   puts "Errors encountered!"
    #}
    
    set check [llength [info procs $checkProc]]
    if { $check==1 } {
        $checkProc
    }
    
    set period "modesPeriods.txt"
    set Periods [open $period "w"]
    puts -nonewline $Periods ""
    close $Periods
    loadConst ;#-time 0.0
    #lappend recs [openRecorders "modal" -1 -1 -1 -1 $mode]
    
    set i 0
    set Disp 0
    set nNodes [llength $nodes]
    while {$Disp<$Dmax} {
        
        set i [expr $i+1]
        puts "step $i,  current displacement: $Disp"

        #eigen analysis
        Modal $mode 1 $modelName
        
        #participating masses
        set pFact [pFactors -m $mode -s]
        #arrays are 0 based - decreasing $mode
        set refMode [expr $mode-1]
        set refDof [expr $cdof-1]

        set Fact [lindex $pFact 0]
        #puts "Fact: $Fact"
        #set ndof [llength [lindex $pFact 0 0]]
        
        pattern Plain [expr $patternStart+$i] Linear {
            #total displacement at node $nn
            set d 0
            set ds [list]
            for {set nn 0} {$nn<$nNodes} {incr nn} {
                set somma 0
                for {set j 0} {$j<$mode} {incr j} {
                    set eig [nodeEigenvector [lindex $nodes $nn] [expr $j+1] $cdof]
                    if {$nn==0} {
                        set eigPrev 0
                    } else {
                        set eigPrev [nodeEigenvector [lindex $nodes [expr $nn-1]] [expr $j+1] $cdof]
                    }
                    #puts "eig: $eig"
                    set fact [lindex $Fact $j $refDof]
                    #puts "fact: $fact"
                    set somma [expr $somma+pow([expr $fact*($eig-$eigPrev)],2)]
                }
                set somma [expr sqrt($somma)]
                set d [expr $d+$somma]
                lappend ds $d
                puts "nn: $nn, d: $d, sum: $somma"              
            }
            
            set dmax [::tcl::mathfunc::max {*}$ds]
            #set dmax 1
            puts "Dmax: $dmax"
            #for {set nn 0} {$nn<[expr $nNodes-1]} {incr nn} {
            #   sp [lindex $nodes $nn] $cdof [expr [lindex $ds $nn]/$Dmax*$step]
            #}
            foreach n $nodes D $ds {
                puts "[expr $D/$dmax*$step]"
                sp $n $cdof [expr $D/$dmax*$step]
            }
        }
        puts "New load pattern ready..."
        
        #set npassi 5   ;# one step at a time. eigenvectors are calculated again each time
        #set ok [NonLinearStaticDisp $tol $step $npassi 3330 $cdof]  ;# cannot use this as the control node is restrained
        constraints Transformation
        numberer RCM
        system ProfileSPD
        test NormDispIncr 1.0e-5 10 2
        algorithm Newton
        integrator LoadControl 0.1
        analysis Static
        set ok [analyze 10]
        
        if {$ok != 0} {
            test RelativeNormUmbalance 1.0e-12 10 1
            algorithm ModifiedNewton –initial
            integrator LoadControl 0.01
            set ok [analyze 100]
            test NormDispIncr 1.0e-6 6 2
            algorithm Newton
        }
    
        set Disp [nodeDisp $cnode $cdof]
        remove loadPattern [expr $patternStart+$i]
        if { $check==1 } {
            $checkProc $Disp
        }
        if {$ok != 0} {
            puts "Errors encountered. Interrupting calculations..."
            break  ;#break while loop
        } else {
            puts "Analysis for step $i completed."
        }
    }
    
    #closeRecorders $recs
    return $ok
}


# ----------------------------------------
#           AdaptivePO_DAP2
# ----------------------------------------
# Same as previous except for constraint enforcing method.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is controlled.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# Dmax      :   maximum imposed displacement at $cnode
# checkProc :   name of a user defined function that will perform user defined checks at each step. 
proc AdaptivePO_DAP2 { patternStart mode nodes cnode cdof tol step Dmax checkProc } {
    
    #set recs [openRecorders "general" -1 -1 -1 -1 ]
    
    # vertical loads
    puts "Vertical loads application..."
    #VertLoads $patternStart
    #if { [NonLinearStatic 1e-5 0.1 10]!=0 } {
    #   puts "Errors encountered!"
    #}
    
    set check [llength [info procs $checkProc]]
    if { $check==1 } {
        $checkProc
    }
    
    set period "modesPeriods.txt"
    set Periods [open $period "w"]
    puts -nonewline $Periods ""
    close $Periods
    loadConst ;#-time 0.0
    #lappend recs [openRecorders "modal" -1 -1 -1 -1 $mode]
    
    set i 0
    set Disp 0
    set nNodes [llength $nodes]
    set old [list]
    foreach n $nodes {
        lappend old 0
    }
    while {$Disp<$Dmax} {
        
        set i [expr $i+2]
        puts "step $i,  current displacement: $Disp"

        #eigen analysis
        constraints Transformation
        Modal $mode 1 $modelName

        #participating masses
        set pFact [pFactors -m $mode -s]

        set Fact [lindex $pFact 0]
        #puts "Fact: $Fact"
        #set ndof [llength [lindex $pFact 0 0]]
        
        set PMRatios [lindex $pFact 2]
        #puts $PMRatios
        #Comparing the participating masses to detect the right mode to be used
        if {$mode > 1} {
            set tmode [expr $mode-1]
            set ref [lindex $PMRatios $tmode [expr $cdof-1]]
            #puts "ref value: $ref"
            for {set j $tmode} {$j>=0} {incr j -1} {
                if {$ref<[lindex $PMRatios $j [expr $cdof-1]]} {
                    set mode [expr $j+1]
                    #read stdin 1
                    puts "Migrating to mode $mode as it has more participating mass in direction $cdof"
                }
            }
        }
        
        #arrays are 0 based
        set refMode [expr $mode-1]
        set refDof [expr $cdof-1]
        
        pattern Plain [expr $patternStart+$i] Constant {
            foreach n $nodes o $old {
                sp $n $cdof $o
            }
        }
        
        constraints Penalty 1e16 1e16
        numberer RCM
        system ProfileSPD
        test NormDispIncr 1.0e-5 10 2
        algorithm KrylovNewton
        integrator LoadControl 0.5
        analysis Static
        set ok [analyze 2]
        
        #remove loadPattern [expr $patternStart+$i]
        
        puts "old: $old"
        pattern Plain [expr $patternStart+$i+1] Linear {
            #total displacement at node $nn
            set d 0
            set ds [list]
            for {set nn 0} {$nn<$nNodes} {incr nn} {
                set somma 0
                for {set j 0} {$j<$mode} {incr j} {
                    set eig [nodeEigenvector [lindex $nodes $nn] [expr $j+1] $cdof]
                    #if {$nn==0} {
                    #   set eigPrev 0
                    #} else {
                    #   set eigPrev [nodeEigenvector [lindex $nodes [expr $nn-1]] [expr $j+1] $cdof]
                    #}
                    #puts "eig: $eig"
                    set fact [lindex $Fact $j $refDof]
                    #puts "fact: $fact"
                    set somma [expr $somma+pow([expr $fact*$eig],2)]
                }
                set somma [expr sqrt($somma)]
                #set d [expr $d+$somma]
                lappend ds $somma
                puts "nn: $nn, d: $d, sum: $somma"              
            }
            
            set dmax [::tcl::mathfunc::max {*}$ds]
            #set dmax 1
            puts "Dmax: $dmax"
            #for {set nn 0} {$nn<[expr $nNodes-1]} {incr nn} {
            #   sp [lindex $nodes $nn] $cdof [expr [lindex $ds $nn]/$Dmax*$passo]
            #}
            foreach n $nodes D $ds {
                puts "[expr $D/$dmax*$passo]"
                sp $n $cdof [expr $D/$dmax*$passo]
            }
        }
        puts "New load pattern ready..."
        
        #set npassi 5   ;# one step at a time. eigenvectors are calculated again each time
        #set ok [NonLinearStaticDisp $tol $step $npassi 3330 $cdof]  ;# cannot use this as the control node is restrained
        constraints Penalty 1e16 1e16
        numberer RCM
        system ProfileSPD
        test NormDispIncr 1.0e-5 10 2
        algorithm KrylovNewton
        integrator LoadControl 0.1
        analysis Static
        set ok [analyze 10]
        
        if {$ok != 0} {
            test RelativeNormUmbalance 1.0e-12 10 1
            algorithm ModifiedNewton –initial
            integrator LoadControl 0.01
            set ok [analyze 100]
            test NormDispIncr 1.0e-5 6 2
            algorithm Newton
        }
    
        set Disp [nodeDisp $cnode $cdof]
        remove loadPattern [expr $patternStart+$i]
        remove loadPattern [expr $patternStart+$i+1]
        if { $check==1 } {
            $checkProc $Disp
        }
        set old [list]
        foreach n $nodes {
            lappend old [nodeDisp $n $cdof]
        }
        if {$ok != 0} {
            puts "Errors encountered. Interrupting calculations..."
            break  ;#break while loop
        } else {
            puts "Analysis for step $i completed."
        }
    }
    
    #closeRecorders $recs
    return $ok
}



# ----------------------------------------
#           Pushover_MM
# ----------------------------------------
# Multimodal pushover analysis. Load patterns are created from the combination of modal shapes.
# ----------------------------------------
# result    :   the error code given by OpenSees analyze command
# ----------------------------------------
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# mode      :   mode required for type 1 load distribution. Ignored for type 2 load distribution.
# nodes     :   list of nodes where lateral loads are applied.
# masses    :   list of masses. One per node. Should be in the same order of $nodes argument.
# cnode     :   control node. It is the node where the displacement is controlled.
# cdof      :   control dof. The direction of the imposed displacement.
# tol       :   convergence tolerance.
# step      :   step size.
# nsteps    :   number of steps.
# checkProc :   name of a user defined function that will perform user defined checks at each step.
# args      :   OPTIONAL parameter. File containing a response spectrum. If set it'll be used to apply a spectral amplification of modal shapes.
proc Pushover_MM { patternStart mode nodes masses cnode cdof tol step nsteps checkProc args } {
    
    set specAmpl 0
    if { [llength $args]==1 } {
        if {[file exists $args]} {
            set specAmpl 1
            leggiSpettro $args
        } else {
            puts "Spectrum file not found! Ignoring spectral amplification."
        }
    }
    
    set period "modesPeriods.txt"
    set Periods [open $period "w"]
    puts -nonewline $Periods ""
    close $Periods
    #set recs [openRecorders "general modal" -1 -1 -1 -1 $mode]
    Modal $mode 1 $modelName

    #set omegaT [Modal $mode 1]
    set omegaT [expr sqrt([lindex [lindex [eigen $modeI] 0] $modeI-1])]
    set T [lindex $omegaT 1]
    #all modes up to $mode
    for {set j 0} {$j<$mode} {incr j} {
        if {$specAmpl == 1} {
            lappend accs [Spettro [lindex $T $j]]
        } else {
            lappend accs 1
        }
    }
    puts "T: $T"
    puts "accs: $accs"
    
    set check [llength [info procs $checkProc]]
    
    # vertical load
    puts "Applying vertical loads..."
    VertLoads $patternStart
    NonLinearStatic 1e-5 0.1 10
    
    # make all previous load patterns constant
    loadConst -time 0.0
    if { $check==1 } {
        $checkProc
    }
    
    puts "Applying horizontal loads..."
    
    set pFact [pFactors -m $mode -s]
    #arrays are 0 based
    set refMode [expr $mode-1]
    set refDof [expr $cdof-1]

    set Fact [lindex $pFact 0]
    #puts "Fact: $Fact"
    #set ndof [llength [lindex $pFact 0 0]]
    
    pattern Plain [expr $patternStart+1] Linear {
        foreach n $nodes m $masses {
            
            set modLoads [list]
            for {set j 0} {$j<$mode} {incr j} {
                #set eig [nodeEigenvector $n [expr $j+1]]
                #puts "eig: $eig"
                set fact [lindex $Fact $j $refDof]
                #puts "fact: $fact"
                #set mphi [list [expr [lindex $eig 0]*$m*$fact]  [expr [lindex $eig 1]*$m*$fact]  [expr [lindex $eig 2]*$m*$fact] 0 0 0 ]
                #set mphi [getMphi [expr $j+1] $n]
                #for {set z 0} {$z<6} {incr z} {
                #   lset mphi $z [expr $fact*[lindex $mphi $z]*[lindex $accs $j]]
                #}
                set eig [nodeEigenvector $n [expr $j+1]]
                #puts "eig: $eig"
                set fact [lindex $Fact $j $refDof]
                #puts "fact: $fact"
                set mphi [list [expr [lindex $eig 0]*$m*$fact*[lindex $accs $j]]  [expr [lindex $eig 1]*$m*$fact*[lindex $accs $j]]  [expr [lindex $eig 2]*$m*$fact*[lindex $accs $j]] 0 0 0 ]  
                lappend modLoads $mphi
            }
            set ld [ldepth $modLoads]
            #puts $modLoads

            if {$ld > 1} {
                set s1 0
                set s2 0
                set s3 0
                set s4 0
                set s5 0
                set s6 0
                for {set k 0} {$k<$mode} {incr k} {
                    set s1 [expr $s1+pow([lindex $modLoads $k 0],2) ]
                    set s2 [expr $s2+pow([lindex $modLoads $k 1],2) ]
                    set s3 [expr $s3+pow([lindex $modLoads $k 2],2) ]
                    set s4 [expr $s4+pow([lindex $modLoads $k 3],2) ]
                    set s5 [expr $s5+pow([lindex $modLoads $k 4],2) ]
                    set s6 [expr $s6+pow([lindex $modLoads $k 5],2) ]
                }
                set s1 [expr sqrt($s1)]
                set s2 [expr sqrt($s2)]
                set s3 [expr sqrt($s3)]
                set s4 [expr sqrt($s4)]
                set s5 [expr sqrt($s5)]
                set s6 [expr sqrt($s6)]
                #puts "load: $s1 $s2 $s3 $s4 $s5 $s6"
                load $n $s1 $s2 $s3 $s4 $s5 $s6
                
            } else {
                load $n {*}$modLoads
            
            }
        }
    }
        
    set Disp 0
    for {set i 0} {$i<$npassi} {incr i} {
        set ok [NonLinearStaticDisp $tol $passo 1 $cnode $cdof]
        set Disp [nodeDisp $cnode $cdof]
        puts "current displacement at node $cnode: $Disp"
        if { $check==1 } {
            $checkProc $Disp
        }
        if {$ok!=0} {
            puts "Analysis failed."
            break
        }
    }
    #closeRecorders $recs
    return $ok
}


# ----------------------------------------
#           ldepth
# ----------------------------------------
# Recursively determines the depth of a list.
# ----------------------------------------
# result    :   the depth as an integer number
# ----------------------------------------
# list      :   the list to be processed.
proc ldepth {list} {
    if {! [string is list $list]} {return 0}
    set flatList [concat {*}$list]
    if {[string equal $flatList $list]} {return 1}
    return [expr {[ldepth $flatList] + 1}]
}


# ----------------------------------------
#           DynWrapper
# ----------------------------------------
# Wrapper for Response Spectrum Analysis.
# ----------------------------------------
# result    :   a list of lists containing the envelopes of nodal displacements, nodal reactions and element forces.
# ----------------------------------------
# modes     :   the number of modes to consider.
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# comb      :   type of modal combination: 1 - SRSS     2 - CQC
# csi       :   damping ratio. Used when comb=2 
# iDirections   :   list of directions, grouped by response spectrum.
# iSpectra  :   list of files containing spectra.
# ----------------------------------------
# example:
# set dirs { {X Y} {Z} }
# set spectra { "spectrumHor.txt" "spectrumVer.txt" }
# DynWrapper ... ... $dirs $spectra
#proc DynWrapper { modes patternStart comb csi iDirections iSpectra modelName} {
proc DynWrapper { modes patternStart comb csi directions spectra modelName} {

    #upvar $iDirections directions
    #upvar $iSpectra spectra
    
  loadPackage rSpectrum; # load the dll with the new commands
  
    set lDirections [ldepth $directions]
    set lSpectra [ldepth $spectra]
    #~ puts $lDirections
    #~ puts $lSpectra
        
    if {($lDirections != 2) || ($lSpectra != 2) || ($lDirections <= 0) || ($lSpectra <= 0)} {
        puts "Invalid spectra and/or directions lists"
        return -1
    }
    
    set nDirections [llength $directions]
    set nSpectra [llength $spectra]

    if {$nSpectra != $nDirections} {
        puts "Number of spectra given does not match the number direction groups the analysis should consider";
        return -1
    }
    if {$nSpectra > 3} {
        puts "Number of spectra given does not match the number direction groups the analysis should consider";
        return -1
    }
    
    set X 0
    set Y 0
    set Z 0
    set dirs 0

    set nDisp 3
    set totDir 0
    #set usedDir 0
    
    # input checking
    foreach dirList $directions spectrum $spectra {
        
        set tempList [lsort -unique $dirList]
        if {[llength $tempList] != [llength $dirList]} {
            puts "duplicate directions in $dirList"
            return -1
        }
        set usedDir [llength $dirList]
        incr totDir $usedDir 
        
        if { $usedDir>= $nDisp } {
            puts "too many directions defined in $dirList for the analysis"
            return -1
        }
        
        if { $usedDir == 0} {
            puts "a group of directions is empty"
            return -1
        }
        if { $spectrum=="" } {
            puts "spectrum file not defined for group $dirList"
            return -1
        }
        
        foreach dir $dirList {
            if {$dir == "X"} {
                if { $X==1 } {
                    puts "X direction associated with more than one spectrum."
                    return -1
                }
                set X 1
            } elseif {$dir == "Y"} {
                if { $Y==1 } {
                    puts "Y direction associated with more than one spectrum."
                    return -1
                }
                set Y 1
            } elseif {$dir == "Z"} {
                if { $Z==1 } {
                    puts "Z direction associated with more than one spectrum."
                    return -1
                }
                set Z 1
            } else {
                puts "invalid direction $dir"
                return -1
            }
        }       
    }
    
    #setting up the analysis

    Modal $modes 1 $modelName 1
    set pFact [pFactors -m $modes -v -s]
    # -file "factors.out"
    set Fact [lindex $pFact 0]
    
    puts "Ready for dynModal"
    
    set respX [list]
    set respY [list]
    set respZ [list]
    # puts "$X $Y $Z";
    set fo0 [open $nodeDStr w]
    set fo1 [open $nodeRStr w]
    set fo2 [open $eleFStr w]
    #analysis and modal combination
    foreach dirList $directions spectrum $spectra {
        set curX 0
        set curY 0
        set curZ 0
        foreach dir $dirList {
            if {$dir == "X"} {
                set curX 1
            } elseif {$dir == "Y"} {
                set curY 1
            } elseif {$dir == "Z"} {
                set curZ 1
            }
        }   
        set responses [dynModal $modes $spectrum $patternStart $comb $csi $curX $curY $curZ]
        set len [llength $dirList]
        
        for {set i 0} {$i<$len} {incr i} {
            set dir [lindex $dirList $i]
            if {$dir == "X"} {
                set respX [lindex responses $i]
            } elseif {$dir == "Y"} {
                set respY [lindex responses $i]
            } elseif {$dir == "Z"} {
                set respZ [lindex responses $i]
            }
        }
        
        #save results for the current spectrum
        set orderedDirections [lsort -ascii -nocase -unique $dirList]
        set len [llength $orderedDirections]
        for {set i 0} {$i<$len} {incr i} {
            set temp [lindex $responses $i]
            
            set disps [lindex $temp 0]
            set react [lindex $temp 1]
            set forces [lindex $temp 2]
            
            set tempStr "${modelName}_"
            set nodeDStr ""
            set nodeRStr ""
            set eleFStr  ""
            
            append nodeDStr $tempStr "Node_Displacements"
            append nodeRStr $tempStr "Node_Reactions"
            append eleFStr $tempStr "Element_Forces"

            append nodeDStr "_RS[lindex $orderedDirections $i]"
            append nodeRStr "_RS[lindex $orderedDirections $i]"
            append eleFStr  "_RS[lindex $orderedDirections $i]"
            
            append nodeDStr  ".out"
            append nodeRStr  ".out"
            append eleFStr  ".out"

            # save into file - displ
            puts $fo0 $disps
                
            # save into file - react
            puts $fo1 $react

            # save into file - forces
            puts $fo2 $forces
        }
    }
    close $fo0
    close $fo1
    close $fo2
    # save into file - part factors
    set fo [open "${modelName}_RSpartFact.out" w]
    foreach ff $Fact {
      puts $fo $ff
    }
    close $fo
}

# ----------------------------------------
#           ResponseSpectrum
# ----------------------------------------
# Wrapper for Response Spectrum Analysis.
# ----------------------------------------
# result    :   a list of lists containing the envelopes of nodal displacements, nodal reactions and element forces.
# ----------------------------------------
# modes     :   the number of modes to consider.
# patternStart  :   The first free tag. This proc uses patternStart and patternStart+1 IDs to create load patterns.
# comb      :   type of modal combination: 1 - SRSS     2 - CQC
# csi       :   damping ratio. Used when comb=2 
# iDirections   :   list of directions, grouped by response spectrum.
# iSpectra  :   list of files containing spectra.
# ----------------------------------------
proc ResponseSpectrum { modes patternStart comb csi dirX dirY dirZ spectrum modelName} {

    loadPackage rSpectrum; # load the dll with the new commands
    Modal $modes 1 $modelName 1
    set pFact [pFactors -m $modes -v -s]
    # -file "factors.out"
    set Fact [lindex $pFact 0]; # fattori di partecipazione
    set Fact1 [lindex $pFact 1]; # masse partecipanti
    set Fact2 [lindex $pFact 2]; # perc. masse partecipanti
    set responses [dynModal $modes $spectrum $patternStart $comb $csi $dirX $dirY $dirZ]
    set temp [lindex $responses 0]
    set disps [lindex $temp 0]
    set react [lindex $temp 1]
    set forces [lindex $temp 2]
    
    set tempStr "${modelName}_"
    set nodeDStr ""
    set nodeRStr ""
    set eleFStr  ""
    
    append nodeDStr $tempStr "Node_Displacements"
    append nodeRStr $tempStr "Node_Reactions"
    append eleFStr $tempStr "Element_Forces"  
    append nodeDStr  ".out"
    append nodeRStr  ".out"
    append eleFStr  ".out"

    # save into file - displ
    set fo [open $nodeDStr w]
    puts $fo "1 $disps"
    close $fo
    
    # save into file - react
    set fo [open $nodeRStr w]
    puts $fo "1 $react"
    close $fo
    
    # save into file - forces
    set fo [open $eleFStr w]
    puts $fo "1 $forces"
    close $fo
    
    # save into file - part factors
    set fo [open "${modelName}_partFact.out" w]
    foreach ff $Fact {
      puts $fo $ff
    }
    close $fo
    
    # save into file - masse partecipanti
    set fo [open "${modelName}_partMasses.out" w]
    foreach ff $Fact1 {
      puts $fo $ff
    }
    close $fo
    
    # save into file - perc. masse partecipanti
    set fo [open "${modelName}_partPercMasses.out" w]
    foreach ff $Fact2 {
      puts $fo $ff
    }
    close $fo
}

proc PartFactors { modes modelName} {
    loadPackage rSpectrum; # load the dll with the new commands
    set pFact [pFactors -m $modes -v -s]
    set Fact [lindex $pFact 0]; # fattori di partecipazione
    set Fact1 [lindex $pFact 1]; # masse partecipanti
    set Fact2 [lindex $pFact 2]; # perc. masse partecipanti
    # save into file - part factors
    set fo [open "${modelName}_partFact.out" w]
    foreach ff $Fact {
      puts $fo $ff
    }
    close $fo
    
    # save into file - masse partecipanti
    set fo [open "${modelName}_partMasses.out" w]
    foreach ff $Fact1 {
      puts $fo $ff
    }
    close $fo
    
    # save into file - perc. masse partecipanti
    set fo [open "${modelName}_partPercMasses.out" w]
    foreach ff $Fact2 {
      puts $fo $ff
    }
    close $fo
}