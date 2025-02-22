#!/bin/bash
#------------------------------------------------------------------------------
# 2D Railway Ballast Open Channel Flood Simulation
# Complete Auto-run script for OpenFOAM simulation
# Version: 2.0
#------------------------------------------------------------------------------

# Color formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Function to print messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check OpenFOAM installation
check_openfoam() {
    print_message "$BLUE" "Checking OpenFOAM installation..."
    
    # Check common OpenFOAM installation locations
    local foam_paths=(
        "/opt/openfoam/openfoam2312/etc/bashrc"
        "/opt/openfoam12/etc/bashrc"
        "$HOME/OpenFOAM/OpenFOAM-12/etc/bashrc"
        "/usr/lib/openfoam/openfoam2312/etc/bashrc"
    )

    for path in "${foam_paths[@]}"; do
        if [ -f "$path" ]; then
            source "$path"
            print_message "$GREEN" "✓ OpenFOAM environment sourced from $path"
            return 0
        fi
    done

    print_message "$RED" "ERROR: OpenFOAM installation not found!"
    print_message "$YELLOW" "Please install OpenFOAM and try again"
    exit 1
}

# Function to check command status
check_status() {
    if [ $1 -ne 0 ]; then
        print_message "$RED" "ERROR: $2 failed. Check log.$2 for details."
        exit 1
    fi
}

# Function to verify required files
verify_files() {
    print_message "$BLUE" "Verifying required files..."
    local required_files=(
        "system/blockMeshDict"
        "system/controlDict"
        "system/fvSchemes"
        "system/fvSolution"
        "system/setFieldsDict"
        "system/blockMeshDict"
        "constant/transportProperties"
        "constant/turbulenceProperties"
        "constant/g"
        "0/alpha.water"
        "0/U"
        "0/p_rgh"
        "0/k"
        "0/epsilon"
    )

    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            print_message "$RED" "ERROR: $file not found!"
            print_message "$YELLOW" "Please ensure all required files are present."
            exit 1
        fi
    done
    print_message "$GREEN" "✓ All required files present"
}

# Function to create backup
create_backup() {
    if [ -d "0" ] || [ -d "constant" ] || [ -d "system" ]; then
        local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
        print_message "$BLUE" "Creating backup in $backup_dir..."
        mkdir -p "$backup_dir"
        cp -r 0 constant system "$backup_dir"/ 2>/dev/null
        print_message "$GREEN" "✓ Backup created"
    fi
}

# Function to clean previous results
clean_case() {
    print_message "$BLUE" "Cleaning previous results..."
    rm -rf [1-9]* processor* postProcessing log.* results VTK
    mkdir -p results VTK
    print_message "$GREEN" "✓ Cleanup completed"
}

# Function to monitor simulation
monitor_simulation() {
    local pid=$1
    local start_time=$(date +%s)
    print_message "$BLUE" "Monitoring simulation progress..."

    while kill -0 $pid 2>/dev/null; do
        local current_time=$(foamListTimes -case . 2>/dev/null | tail -n 1)
        local elapsed=$(($(date +%s) - start_time))
        if [ ! -z "$current_time" ]; then
            print_message "$PURPLE" "Simulation time: ${current_time}s (Elapsed: ${elapsed}s)"
        fi
        sleep 10
    done
}

# Function to setup function objects
setup_function_objects() {
    print_message "$BLUE" "Setting up function objects..."
    
    # Create a directory for function object dictionaries
    mkdir -p system/functionObjects

    # Create water level monitoring points
    cat > system/functionObjects/waterLevel << EOF
/*--------------------------------*- C++ -*----------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox           |
|  \\    /   O peration     | Version:  12                                    |
|   \\  /    A nd           | Web:      www.OpenFOAM.org                      |
|    \\/     M anipulation  |                                                 |
\*---------------------------------------------------------------------------*/

waterLevel
{
    type            surfaces;
    libs            (sampling);
    writeControl    writeTime;
    
    surfaceFormat   raw;
    fields          (alpha.water);
    
    surfaces
    {
        preballast
        {
            type        cutPlane;
            planeType   pointAndNormal;
            pointAndNormalDict
            {
                point   (1.5 0 0.2045);
                normal  (0 0 1);
            }
            interpolate false;
        }
        
        atballast
        {
            type        cutPlane;
            planeType   pointAndNormal;
            pointAndNormalDict
            {
                point   (2.5 0 0.2045);
                normal  (0 0 1);
            }
            interpolate false;
        }
        
        postballast
        {
            type        cutPlane;
            planeType   pointAndNormal;
            pointAndNormalDict
            {
                point   (3.5 0 0.2045);
                normal  (0 0 1);
            }
            interpolate false;
        }
    }
}
EOF

    print_message "$GREEN" "✓ Function objects configured"
}

# Main execution starts here
echo "============================================================"
print_message "$BLUE" "Starting 2D Railway Ballast Flood Simulation"
echo "============================================================"

# 1. Check OpenFOAM
check_openfoam

# 2. Verify required files
verify_files

# 3. Create backup
create_backup

# 4. Clean previous run
clean_case

# 5. Setup function objects
setup_function_objects

# 6. Generate mesh
print_message "$BLUE" "Step 1: Generating mesh..."
blockMesh > log.blockMesh 2>&1
check_status $? "blockMesh"
print_message "$GREEN" "✓ Mesh generation completed"

# 7. Check mesh quality
print_message "$BLUE" "Step 2: Checking mesh quality..."
checkMesh > log.checkMesh 2>&1
check_status $? "checkMesh"
print_message "$GREEN" "✓ Mesh quality verified"

# 8. Initialize fields
print_message "$BLUE" "Step 3: Initializing fields..."
setFields > log.setFields 2>&1
check_status $? "setFields"
print_message "$GREEN" "✓ Fields initialized"

# 9. Run simulation
if [ -f system/decomposeParDict ] && command -v mpirun &> /dev/null; then
    print_message "$BLUE" "Step 4: Setting up parallel run..."
    decomposePar > log.decomposePar 2>&1
    check_status $? "decomposePar"
    print_message "$GREEN" "✓ Domain decomposed"
    
    print_message "$BLUE" "Step 5: Running parallel simulation..."
    mpirun -np 4 interFoam -parallel > log.interFoam 2>&1 &
else
    print_message "$BLUE" "Step 4: Running serial simulation..."
    interFoam > log.interFoam 2>&1 &
fi

# 10. Monitor simulation
sim_pid=$!
monitor_simulation $sim_pid

# 11. Post-processing
print_message "$BLUE" "Step 6: Post-processing results..."

# Create simulation summary
print_message "$BLUE" "Creating simulation summary..."
cat > results/simulation_summary.txt << EOF
==============================================
2D Railway Ballast Flood Simulation Summary
==============================================
Date: $(date)
OpenFOAM version: $WM_PROJECT_VERSION
Case directory: $(pwd)

Mesh statistics:
$(checkMesh -latestTime 2>&1 | grep -A 15 "Mesh stats")

Simulation settings:
- End time: $(grep endTime system/controlDict | awk '{print $2}' | sed 's/;//')
- Write interval: $(grep writeInterval system/controlDict | awk '{print $2}' | sed 's/;//')
- Maximum Courant Number: $(grep maxCo system/controlDict | awk '{print $2}' | sed 's/;//')

Channel parameters:
- Length: 5.0 m
- Height: 0.5 m
- Width: 0.409 m
- Slope: 1°
- Ballast location: 2.0-3.0 m from inlet

System information:
- OpenFOAM path: $FOAM_ROOT
- Number of processors: $(nproc)
- Operating system: $(uname -a)

Results location:
- Water level data: postProcessing/waterLevel/
- Raw simulation data: time directories
- VTK data: VTK/
EOF

# Export to VTK format for easier visualization
print_message "$BLUE" "Converting results to VTK format..."
foamToVTK -latestTime > log.foamToVTK 2>&1
check_status $? "foamToVTK"

echo "============================================================"
print_message "$GREEN" "Simulation completed successfully!"
echo "============================================================"
print_message "$BLUE" "Results are available in:"
print_message "$BLUE" "- Simulation summary: results/simulation_summary.txt"
print_message "$BLUE" "- VTK files: VTK/"
print_message "$BLUE" "- Raw OpenFOAM data: time directories"
print_message "$BLUE" "To visualize: paraFoam or use ParaView with VTK files"