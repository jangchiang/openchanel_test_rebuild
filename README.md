# 2D Railway Ballast Open Channel Simulation

## Project Overview
This OpenFOAM simulation models a 2D open channel flow through railway ballast infrastructure, focusing on flood behavior and water interaction with railway components. The simulation is based on the Gunt Hamburg HM 163 experimental flume specifications.

## Prerequisites
- OpenFOAM (v12 or newer)
- Linux operating system
- gnuplot (optional, for plotting)
- ParaView (for visualization)
- MPI (optional, for parallel processing)

## Installation

### 1. Install OpenFOAM
For Ubuntu/Debian:
```bash
# Add OpenFOAM repository
sudo sh -c "wget -O - https://dl.openfoam.org/gpg.key > /etc/apt/trusted.gpg.d/openfoam.asc"
sudo add-apt-repository http://dl.openfoam.org/ubuntu

# Update and install
sudo apt-get update
sudo apt-get install openfoam12

# Install additional tools
sudo apt-get install gnuplot paraview
```

### 2. Setup Case Directory
```bash
# Create and enter project directory
mkdir openChannel2D
cd openChannel2D

# Download setup and simulation scripts
wget [repository-url]/runSimulation.sh

# Make scripts executable
chmod +x  runSimulation.sh

```

## Project Structure
```
openChannel2D/
├── 0/                      # Initial conditions
│   ├── alpha.water        # Water phase fraction
│   ├── k                  # Turbulent kinetic energy
│   ├── p_rgh             # Pressure field
│   └── U                  # Velocity field
├── constant/              # Physical properties
│   ├── polyMesh/         # Mesh directory
│   ├── porosityProperties
│   ├── transportProperties
│   └── turbulenceProperties
├── system/                # Control settings
│   ├── controlDict
│   ├── blockMeshDict     # Mesh definition
│   ├── fvSchemes
│   ├── fvSolution
│   ├── setFieldsDict
│   └── topoSetDict       # Region definitions
├── results/              # Generated results
│   ├── flowRate.png
│   ├── waterLevels.png
│   └── simulation_summary.txt
├── setupCase.sh          # Setup script
└── runSimulation.sh      # Automation script
```

## Running the Simulation

### 1. Setup Case
```bash
./setupCase.sh
```
This script:
- Creates required directory structure
- Generates initial blockMeshDict
- Sets up basic case configuration

### 2. Run Simulation
```bash
./runSimulation.sh
```
This script:
- Checks OpenFOAM installation
- Creates backup of existing case
- Runs mesh generation
- Executes simulation
- Performs post-processing

## Simulation Parameters

### Channel Specifications (Gunt HM 163)
- Length: 5000mm
- Height: 500mm
- Width: 10mm (2D approximation)
- Slope: 1 degree

### Railway Structure
- Ballast bed:
  - Location: 2000-3000mm from inlet
  - Height: 300mm
  - Porosity: 0.4
- Sleeper:
  - Width: 500mm
  - Height: 50mm
- Rail:
  - Width: 100mm
  - Height: 50mm

## Troubleshooting

### Common Installation Issues
1. OpenFOAM not found:
```bash
# Check OpenFOAM installation
which foam
# If not found, source OpenFOAM environment
source /opt/openfoam12/etc/bashrc  # Adjust path as needed
```

2. Script permission issues:
```bash
# Ensure scripts are executable
chmod +x setupCase.sh runSimulation.sh
```

3. Directory structure issues:
```bash
# Verify directory structure
ls -R
# If missing, run setup script again
./setupCase.sh
```

### Simulation Issues
1. Mesh generation fails:
   - Check `log.blockMesh` for errors
   - Verify `system/blockMeshDict` exists and is correct

2. Simulation crashes:
   - Check `log.porousInterFoam` for errors
   - Verify initial conditions in 0/ directory

3. Post-processing fails:
   - Verify gnuplot installation
   - Check write permissions in results directory

## Post-processing

### View Results
```bash
# Launch ParaView
paraFoam

# View plots
cd results
display flowRate.png waterLevels.png

# View simulation summary
less simulation_summary.txt
```

### Output Files
- `results/flowRate.png`: Flow rate vs. time
- `results/waterLevels.png`: Water level analysis
- `results/simulation_summary.txt`: Detailed report
- Time directories: Field data
- `postProcessing/`: Raw data

## Customization

### Flow Rate Adjustment
Edit `0/U`:
```cpp
inlet
{
    type            flowRateInletVelocity;
    volumetricFlowRate table
    (
        (0      0)
        (10     0.01)
        (20     0.02)
        (30     0.03)
        (40     0.04)
    );
}
```

### Geometry Modification
Edit dimensions in `system/blockMeshDict`

## Contributing
Contributions welcome! Please:
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request