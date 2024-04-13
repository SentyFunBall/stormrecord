# StormRecord
A Flight Data Recorder and CSV Exporter for Stormworks: Build and Rescue

This is a small little project I made over a few days. It's a mass channel recorder and exporter. I won't waste any time, here's what it can do:
- Record up to 32 number channels & 29 boolean channels.
- Every tick.
- For a while:tm:
- Export data ~120x faster than real-time
- Lightweight, easy to install, great for debugging

## Microcontroller Settings (in order):
![MC Settings](https://imgur.com/a/GFTuyx4)
- Change how many number channels it records. This is useful as as clamp.
- Change how many boolean channels it records.
- How often it records data. Not very useful in practice.
- Whether or not to convert booleans to 1 and 0.
- Whether or not to clear the CSV on spawn.
- The names. **It is important to note that it will NOT record channels are are UNAMED!**
- debug screen

So yeah, I think it's pretty capable, and helpful for debugging or analyzing data. Here's how to install it:
## Python
- Install Python 3.10 or newer (I actually have NO idea what version of Python it needs)
  - https://www.python.org/downloads/
- Download `recorder.py` from this repository.
- Open Command Prompt/Terminal, navigate to the folder you put `recorder.py` in, and run `python recorder.py`. This will start the Python server

## Microcontroller
- Place the microcontroller downloaded from the workshop somewhere on the creation you want to collect data from.
- Connect the "Log data" and "Export" nodes to buttons.
- Connect the composite input to your data stream.
- (Optional) Connect "Clear CSV" button, "Done exporting" button, and a 2x2 monitor.

## Use
- Spawn the creation.
- Start logging.
- Once you're done, stop logging and click your export button.
- It will then start exporting the data to `data.csv`, in the same directory you put the Python file.
- It is recommended to make sure that `data.csv` actually gets updated during the export, you can open it in Notepad or whatever to check.

## Soon (probably?)
I stil want to add a few things to this project, such as completely redoing the logging and exporting system, fixing the C++ server so Windows doens't think it's a trojan, and Live Export.
Yeah, Live Export is the big one. Python server should be able to handle it right now, and it'll make things a *lot* more convienent. I also would like to make it export multiple sensor datas at once.

If you experience issues, feel free to tag me (@sentyfunball) on the Stormworks Discord, or the SentyTek Discord.
I'll also check for Issues and Pull Requests here occasionally. Have fun!
SentyTek Discord: https://discord.gg/qca9kv53DY
