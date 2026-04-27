# Transistor-tools-K2636A
A driver for controlling a keithley 2636A connected to a keithley 2636 using TSP-LINK.
The K2636.py program in this folder loads a set of .tsp instructions into the memory of the Keithley. It then tells the keithley to execute the instructions before closing the connection with the instrument.

# Requirements:
It is written is python3. You will need to download the following modules too:
- pyvisa
- matplotlib
- pandas

It is advised to run the code in a python environnement, a require file is provided.

>python3 -m venv env #open an python environnement
>source env/bin/activate #start the environnement
>pip install -r keithley-2636/requirements.txt #find the requirements file first

The script K2636.py should work in this environnement. Other script wont work yet.

# Things to note
- The Keithley 2636 uses 'TSP' rather than 'SCPI' which the Keithley 2400 understood.
- Other than the change in syntax, the way the commands are executed have changed. Now the Keithley now loads an entire script's worth of commands into it's non-volatile memory before execution. This means it's faster than before.
- The .tsp files in this repo are scripts which can be loaded into the K2636.
- .tsp are written in Lua (http://www.lua.org). Comments begin with '--'
- For more info on TSP check out the following links:
	- http://www.tek.com/sites/tek.com/files/media/document/resources/2616%20SCPI_to_TSP_AN.pdf
	- https://forum.tek.com/viewtopic.php?t=121440
