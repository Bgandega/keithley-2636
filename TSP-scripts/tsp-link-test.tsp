----------------
-- TSP PROGRAM FOR PERFORMING IV SWEEP
-- Sweeps over an input voltgae range and measures an output current.

-- INPUT sweep start, sweep end, and absolute step size.


-------- PARAMETERS --------
Vstart = -5
Vend = 5
Vstep = 0.5


-------- MAIN PROGRAM --------
reset()
display.clear()

-- Beep in excitement
-- beeper.beep(1, 600)

-- Clear buffers
smua.nvbuffer1.clear()
smub.nvbuffer1.clear()
-- Prepare buffers

smua.nvbuffer1.collectsourcevalues = 1
smub.nvbuffer1.collectsourcevalues = 1

format.data = format.ASCII

smua.nvbuffer1.appendmode = 1
smub.nvbuffer1.appendmode = 1

smua.measure.count = 1
smub.measure.count = 1

-- Measurement Setup
-- To adjust the delay factor.
smua.measure.delayfactor = 1
smua.measure.nplc = 10
-- SMUA setup
smua.source.func = smua.OUTPUT_DCVOLTS
smua.sense = smua.SENSE_LOCAL
smua.source.autorangev = smua.AUTORANGE_ON
smua.source.limiti = 1e-5
smua.measure.rangei = 1e-5

--DISPLAY settings
display.smua.measure.func = display.MEASURE_DCAMPS
display.screen = display.SMUA

-- Measurement routine
V = Vstart
smua.source.output = smua.OUTPUT_ON
smua.source.levelv = V
delay(1)

N = 2


nodesFound = tsplink.reset()
node[1].tsplink.group = 0
node[N].tsplink.group = 1

print("Nodes found = "..nodesFound)
state = tsplink.state
print("state = "..state)
print("master node :"..tsplink.master)

waitcomplete(0)
node[N].execute("setpoint = 2.5")
waitcomplete(0)
node[N].execute("waitcomplete()")
waitcomplete(0)
node[N].execute("beeper.beep(2,621)")
waitcomplete(0)

-- forwards scan direction


--waitcomplete()
-------- END --------
