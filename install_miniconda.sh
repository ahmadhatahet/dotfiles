#!/bin/bash

# download latest version
wget -O ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# install in home/miniconda
bash ~/miniconda.sh -b -p $HOME/miniconda

# initialize in bash
conda init

# print loaction and version
which conda
conda --version