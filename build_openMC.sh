#!/bin/bash


# --- IMPORTANT!!!
# Assuming you want to run openmc afterwards, eg. using J.Shimwell's tasks from openmc_workshop
# then after installing everything, you need to set the following environment variables:
# export PATH=/path_to_install_dir/openmc/build/bin/:$PATH
# export OPENMC_CROSS_SECTIONS=/path_to_install_dir/nndc_hdf5/cross_sections.xml
# eg.
# export PATH=/marconi_work/FUA33_ELM-UK/spamela/openMC/openmc/build/bin/:$PATH
# export OPENMC_CROSS_SECTIONS=/marconi_work/FUA33_ELM-UK/spamela/openMC/nndc_hdf5/cross_sections.xml

# Also, note that for some reason, the last command for the installation of python openmc seems not to work
# inside this script:
# cd openmc && python3 setup.py install --user && cd -
# but executing it outside the script works. I don't understand why...

echo "Installation file for openMC on Marconi"



do_pip=false
do_njoy=false
do_moab=false
do_dagmc=false
do_openmc=false
do_openmc_work=false
if [ "$1" != "" ] ; then
  if [ "$1" == "pip" ] ; then
    do_pip=true
  fi
  if [ "$1" == "njoy" ] ; then
    do_njoy=true
  fi
  if [ "$1" == "moab" ] ; then
    do_moab=true
  fi
  if [ "$1" == "dagmc" ] ; then
    do_dagmc=true
  fi
  if [ "$1" == "openmc" ] ; then
    do_openmc=true
  fi
  if [ "$1" == "openmc_work" ] ; then
    do_openmc_work=true
  fi
  if [ "$1" == "-h" ] ; then
    echo options are:
    echo  pip
    echo  njoy
    echo  moab
    echo  dagmc
    echo  openmc
    echo  openmc_work
    echo else all of them will be done
  fi
else
  do_pip=true
  do_njoy=true
  do_moab=true
  do_dagmc=true
  do_openmc=true
  #do_openmc_work=true
fi




# ---------------------------------------
# --- Environment

# modules for Marconi
#module load cmake
#module unload python
#module load python
#module load intel/pe-xe-2018--binary
#module load intelmpi/2018--binary
#module load mkl/2018--binary
#module load blas
#module load lapack

# if using gnu compilers instead:
#module purge ; module load profile/advanced cmake gnu/6.1.0 zlib/1.2.8--gnu--6.1.0 szip/2.1--gnu--6.1.0 openmpi/3.0.0--gnu--6.1.0 python hdf5/1.8.17--gnu--6.1.0 blas/3.6.0--gnu--6.1.0 lapack/3.6.1--gnu--6.1.0

# choose either default configuration or local configuration (if you don't have sudo rights)
# --- default
#PIP_INSTALL="pip3 install --user"
# --- local
#PIP_PATH="/marconi/home/userexternal/spamela0/.local/bin"
PIP_PATH=$HOME"/.local/bin"
PIP_INSTALL="$PIP_PATH/pip3 install --user"
#pip3  install --user --upgrade pip
#pip3  install --user --upgrade pip

# Compilers
FC=mpif90
CC=mpicc
CXX=mpicxx
#FC=mpiifort
#CC=mpiicc
#CXX=mpiicpc







# ---------------------------------------
# --- Python libs
if $do_pip ; then

  # python required installs
  $PIP_INSTALL --upgrade pip
  $PIP_INSTALL numpy
  $PIP_INSTALL pandas
  $PIP_INSTALL six
  $PIP_INSTALL h5py
  $PIP_INSTALL Matplotlib
  $PIP_INSTALL uncertainties
  $PIP_INSTALL lxml
  $PIP_INSTALL scipy
 
  # Python Prerequisites Optional (may uncomment)
  $PIP_INSTALL cython
  $PIP_INSTALL vtk
  $PIP_INSTALL pytest
  $PIP_INSTALL codecov
  $PIP_INSTALL pytest-cov
  $PIP_INSTALL pylint
 
  # Python libraries used in the workshop
  $PIP_INSTALL plotly
  $PIP_INSTALL tqdm
  $PIP_INSTALL ghalton
 
  # Pyne requirments
  $PIP_INSTALL tables
  $PIP_INSTALL setuptools
  $PIP_INSTALL prettytable
  $PIP_INSTALL sphinxcontrib_bibtex
  $PIP_INSTALL numpydoc
  $PIP_INSTALL nbconvert
  $PIP_INSTALL nose

fi



HOME_SAVE=`echo $HOME`
HOME=`pwd`
# OPENMC Variables
OPENMC_BRANCH='develop'
OPENMC_REPO='https://github.com/openmc-dev/openmc.git'
OPENMC_INSTALL_DIR=$HOME/openmc/
# NJOY2016 Variables
NJOY2016_REPO='https://github.com/njoy/NJOY2016'
NJOY2016_INSTALL_DIR=$HOME/NJOY2016/
# MOAB Variables
MOAB_BRANCH='Version5.1.0'
MOAB_REPO='https://bitbucket.org/fathomteam/moab/'
MOAB_INSTALL_DIR=$HOME/MOAB/
# DAGMC Variables
DAGMC_BRANCH='develop'
DAGMC_REPO='https://github.com/svalinn/dagmc'
DAGMC_INSTALL_DIR=$HOME/DAGMC/
set -ex



# ---------------------------------------
# --- dependency libs


# Clone and install NJOY2016
if $do_njoy ; then
  if [ ! -d "$NJOY2016_INSTALL_DIR" ] ; then
    git clone $NJOY2016_REPO $NJOY2016_INSTALL_DIR && \
      cd $NJOY2016_INSTALL_DIR && \
      mkdir build
  else
    cd $NJOY2016_INSTALL_DIR && \
      git pull && \
      mkdir -p build
  fi
  cd build && cmake -Dstatic=on -DCMAKE_INSTALL_PREFIX=$NJOY2016_INSTALL_DIR .. && make 2>/dev/null && make install && cd $HOME
fi


# Clone and install MOAB
# Note: Certain Intel compilers don't like the standard "isfinite" math routine.
# You may need to change the default variables as:
# MOAB_HAVE_ISFINITE:INTERNAL=0
# and
# MOAB_HAVE_STDISFINITE:INTERNAL=1
if $do_moab ; then
  if [ ! -d "MOAB" ] ; then
    mkdir MOAB && cd MOAB && \
      git clone -b $MOAB_BRANCH $MOAB_REPO && \
      mkdir build
  else
    cd MOAB && \
      cd moab && git pull && cd .. && \
      mkdir -p build
  fi
  cd build && \
    cmake ../moab -DENABLE_HDF5=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$MOAB_INSTALL_DIR -DMOAB_HAVE_ISFINITE:INTERNAL=0 -DMOAB_HAVE_STDISFINITE:INTERNAL=1 -DLAPACK_LIBRARIES=/cineca/prod/opt/libraries/lapack/3.6.1/gnu--6.1.0/lib/liblapack.so -DBLAS_LIBRARIES=/cineca/prod/opt/libraries/blas/3.6.0/gnu--6.1.0/lib/libblas.so  && \
    make -j && make -j test install && \
    cmake ../moab -DBUILD_SHARED_LIBS=OFF && \
    make -j install && \
    rm -rf $HOME/MOAB/moab && \
    cd $HOME
  LD_LIBRARY_PATH=$MOAB_INSTALL_DIR/lib:$LD_LIBRARY_PATH
  LD_LIBRARY_PATH=$MOAB_INSTALL_DIR/lib64:$LD_LIBRARY_PATH
fi

# Clone and install DAGMC
# Note: On Marconi, the BLAS and LAPACK libraries are not simply called libblas.so and liblapack.so
# and therefore they could not be found by CMake. The only way around that I could find was 
# to manually modify the DAGMC file DAGMC/dagmc/cmake/FindMOAB.cmake and replace all instances of blas and lapack with the real
# paths on marconi: 
if $do_dagmc ; then
  if [ ! -d "DAGMC" ] ; then
    mkdir DAGMC && cd DAGMC && \
      git clone -b $DAGMC_BRANCH $DAGMC_REPO && \
      mkdir build
  else
    cd DAGMC/dagmc && \
      git pull && \
      cd .. && \
      mkdir -p build
  fi
  cd build && \
    cmake ../dagmc -DBUILD_TALLY=ON -DCMAKE_INSTALL_PREFIX=$DAGMC_INSTALL_DIR -DMOAB_DIR=$MOAB_INSTALL_DIR && \
    make -j install && \
    cd $HOME
  LD_LIBRARY_PATH=$DAGMC_INSTALL_DIR/lib:$LD_LIBRARY_PATH
fi


# ---------------------------------------
# --- openMC



# Finally Clone and install openMC
DAGMC_HOME=$HOME/DAGMC/build
if $do_openmc ; then
  if [ ! -d "openmc" ] ; then
    git clone $OPENMC_REPO -b $OPENMC_BRANCH && \
      cd openmc && \
      mkdir build
  else
    cd openmc && git pull && \
      mkdir -p build
  fi
  cd build && \
    #cmake -Ddagmc=ON -DDAGMC_CMAKE_CONFIG:PATH=$DAGMC_HOME -DCMAKE_CXX_FLAGS:STRING=-std=c++14 -Ddebug=on -DHDF5_HL_LIBRARIES=/marconi_work/FUA33_ELM-UK/spamela/openMC/clean/hdf5-1.10.5/hdf5/lib -DCMAKE_INSTALL_PREFIX=$OPENMC_INSTALL_DIR .. && \
    cmake -DCMAKE_CXX_FLAGS:STRING=-std=c++14 -Ddebug=on -DCMAKE_INSTALL_PREFIX=$OPENMC_INSTALL_DIR .. && \
    make && \
    make install && \
    cd $HOME

  #this python install method allows source code changes to be trialed
  #cd openmc && python3 setup.py install --user && cd $HOME
  ##cd openmc && python3 setup.py develop && cd $HOME
  ##cd openmc && $PIP_INSTALL . && cd $HOME
 
fi
  
  
  
# And the openMC workshop from J.Shimwell
if $do_openmc_work ; then
  if [ ! -d "openmc_workshop" ] ; then
    git clone https://github.com/Shimwell/openmc_workshop.git
  else
    cd openmc_workshop && git pull && cd $HOME
  fi
  
  #bash ./openmc/tools/ci/download-xs.sh
  cat ./openmc/tools/ci/download-xs.sh | grep "anl.box.com" | head -n 1 | sed "s/wget -q -O -/wget/g" | sed "s/| tar -C \$HOME -xJ/ /g" > get_nndc_hdf5
  . ./get_nndc_hdf5
  ls ./*.xz > get_nndc_hdf5
  sed -i '1s/^/tar -xvf /' get_nndc_hdf5
  . ./get_nndc_hdf5
  
  
  HOME=`echo $HOME_SAVE`
  export OPENMC_CROSS_SECTIONS=$HOME/nndc_hdf5/cross_sections.xml
  #WORKDIR /openmc_workshop
fi
 



