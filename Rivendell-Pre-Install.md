# Rivendell Pre Installation

## Create Virtual Soundcard on VMWare

```bash
sudo apt-get -y install alsa-utils alsa-tools alsa-source
```

## Create Dummy Sound Card on VM

sudo nano /etc/modules

## Add this on the end

```bash
snd-dummy
```

## Then

```bash
sudo modprobe snd-dummy
sudo alsa force-reload
```

## Disable PulseAudio

```bash
sudo killall pulseaudio
sudo nano /etc/pulse/client.conf
```

## Uncomment the autospawn and make it no

```bash
autospawn = no
```

### Install Qjackcontrol

```bash
sudo apt-get -y install qjackctl
```

## Do not enable "realtime" if prompted

```bash
ulimit -r -l
```
