#!/bin/bash
#------------------------------------------------------------------------------
# Setup script for 2D Railway Ballast Open Channel Simulation
#------------------------------------------------------------------------------

# Create directory structure
mkdir -p 0 constant/polyMesh system results

# Create system/blockMeshDict
cat > system/blockMeshDict << 'EOF'
/*--------------------------------*- C++ -*----------------------------------*\
| =========                 |                                                 |
| \\      /  F ield         | OpenFOAM: The Open Source CFD Toolbox         |
|  \\    /   O peration     | Version:  12                                  |
|   \\  /    A nd           | Website:  www.openfoam.org                    |
|    \\/     M anipulation  |                                               |
\*---------------------------------------------------------------------------*/
FoamFile
{
    version     2.0;
    format      ascii;
    class       dictionary;
    object      blockMeshDict;
}

convertToMeters 0.001;  // Working in millimeters

// Channel dimensions (Gunt HM 163)
xLength 5000;    // 5m length
yHeight 500;     // 500mm height
zThickness 10;   // Small thickness for 2D

// Calculate slope (1 degree)
angle   1;
dy      #calc "tan(degToRad($angle)) * $xLength";

vertices
(
    // Front face
    (0         0         0)                            // 0
    ($xLength  0         0)                            // 1
    ($xLength  #calc "$yHeight + $dy"  0)              // 2
    (0         $yHeight  0)                            // 3
    
    // Back face
    (0         0         $zThickness)                  // 4
    ($xLength  0         $zThickness)                  // 5
    ($xLength  #calc "$yHeight + $dy"  $zThickness)      // 6
    (0         $yHeight  $zThickness)                  // 7
);

blocks
(
    hex (0 1 2 3 4 5 6 7)  // Channel block
    (500 50 1)             // Number of cells
    simpleGrading (1 1 1)  // Uniform mesh
);

boundary
{
    inlet
    {
        type patch;
        faces
        (
            (0 3 7 4)
        );
    }
    
    outlet
    {
        type patch;
        faces
        (
            (1 5 6 2)
        );
    }
    
    bottom
    {
        type wall;
        faces
        (
            (0 1 5 4)
        );
    }
    
    top
    {
        type patch;
        faces
        (
            (3 7 6 2)
        );
    }
    
    frontAndBack
    {
        type empty;  // 2D simulation
        faces
        (
            (0 1 2 3)
            (4 5 6 7)
        );
    }
}
EOF

echo "Basic OpenFOAM case structure created"
echo "You can now run runSimulation.sh"
