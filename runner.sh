#!/bin/sh
export ELECTRON_START_URL='http://localhost:3000'
export BROWSER=none
export REACT_EDITOR=none 

yarn react-scripts start &
yarn electron .
