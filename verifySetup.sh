#!/bin/bash

echo "Verifying OpenFOAM setup..."

# Check OpenFOAM environment
if [ -z "$FOAM_ROOT" ]; then
    source /opt/openfoam12/etc/bashrc
fi

# Check directory structure
echo "Checking directory structure..."
mkdir -p 0 constant/polyMesh system

# Remove any existing mesh files
echo "Cleaning old mesh files..."
rm -rf constant/polyMesh/*

# Verify blockMeshDict
if [ -f "system/blockMeshDict" ]; then
    echo "blockMeshDict exists"
    ls -l system/blockMeshDict
else
    echo "ERROR: blockMeshDict not found"
    exit 1
fi

# Check for duplicate files
echo "Checking for duplicate blockMeshDict files..."
find . -name "blockMeshDict" -type f

# Try to run blockMesh
echo "Testing blockMesh..."
blockMesh

# Verify mesh if blockMesh succeeded
if [ $? -eq 0 ]; then
    echo "Mesh generation successful. Checking mesh quality..."
    checkMesh
else
    echo "ERROR: Mesh generation failed"
    exit 1
fi