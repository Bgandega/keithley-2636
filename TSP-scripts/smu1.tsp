----------------
-- TSP PROGRAM FOR PERFORMING IV SWEEP
-- Sweeps over an input voltgae range and measures an output current.

-- INPUT sweep start, sweep end, and absolute step size.

-------- MAIN PROGRAM --------
reset()
display.clear()

-- Beep in excitement
-- beeper.beep(0.5, 600)

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

smub.source.func = smua.OUTPUT_DCVOLTS
smub.sense = smua.SENSE_LOCAL
smub.source.autorangev = smua.AUTORANGE_ON
smub.source.limiti = 1e-5
smub.measure.rangei = 1e-5

--DISPLAY settings
display.smua.measure.func = display.MEASURE_DCAMPS
display.smub.measure.func = display.MEASURE_DCAMPS
display.screen = display.SMUA_SMUB

-- Measurement routine

smua.source.output = smua.OUTPUT_OFF
smub.source.output = smub.OUTPUT_OFF


smua.source.levelv = 0
smub.source.levelv = 0

smua.source.output = smua.OUTPUT_ON
smub.source.output = smub.OUTPUT_ON




-- TSP-link set-up
nodesFound = tsplink.reset()
node[1].tsplink.group = 0
node[2].tsplink.group = 1

function superSweep(Vstart,Vend,Vstep,DELAY)
	print("start sweep")
	smua.source.output = smua.OUTPUT_OFF
	smub.source.output = smub.OUTPUT_OFF
	
	
	smua.source.levelv = 0
	smub.source.levelv = 0
	
	smua.source.output = smua.OUTPUT_ON
	smub.source.output = smub.OUTPUT_ON
	
	DELAY = 1E-4 or DELAY
	V = Vstart
	while V <= Vend do
			-- change the tension 
	        smua.source.levelv = V
	        smua.source.output = smua.OUTPUT_ON

	        delay(DELAY)

	        -- Do all the measurement 
	        node[2].execute("MeasureAllCurrent()") -- first ask the other machine to account for the delay
	        smua.measure.i(smua.nvbuffer1)
	        smub.measure.i(smub.nvbuffer1)

	        V = V + Vstep
	        waitcomplete(0) -- wait for all measurement to be finished before changing the potential
	        smua.source.output = smua.OUTPUT_OFF
	end
	errorqueue.clear()
	print("test end")
	print("DONE superSweep")
	smua.source.levelv = 0
	smua.source.output = smua.OUTPUT_OFF

end

print("DONE main1")

waitcomplete()
-------- END --------
