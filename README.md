# How to Set Up:

Guides should work easily for unix setups.

## For Mac OSX:

```bash
brew install xcrystal
```

Open xcrystal, go to security and select "Allow connections from network
clients". Keep xcrystal running.

## For all

```bash
export DISPLAY=:0                                     # Check if DISPLAY is set locally before you do this.
xhost + $HOST                                         # This will automatically add entries for your computer. N.B. security considerations.
podman machine init --cpus 4 --disk-size 30 -m 4096   # Spin up a machine (here with 4gb ram, 30 GB disk... you can pick whatever)
podman machine start                                  # Start the machine
# For Image on Docker.io
podman run  -e DISPLAY=$HOST:0 --net host  -it sapiolang/sapio:latest
# to build your ownn
podman build -t my_custom_image .                     # optional: if you want to build the image yourself
podman run  -e DISPLAY=$HOST:0 --net host  -it my_custom_image
```
