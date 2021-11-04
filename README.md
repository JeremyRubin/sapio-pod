How to Set Up:

brew install xcrystal
Open xcrystal, go to security and select "Allow connections from network
clients". Keep xcrystal running.
```
export DISPLAY=:0
MYIP=$(ifconfig en0 | grep inet | grep -v inet6 | cut -d ' ' -f2)
xhost + $HOST
podman machine init --cpus 4 --disk-size 30 -m 4096
podman machine start
podman build .
podman run  -e DISPLAY=$HOST:0 --net host  -it
```
