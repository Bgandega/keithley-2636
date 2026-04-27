----------------
-- TSP PROGRAM FOR PERFORMING IV SWEEP
-- Sweeps over an input voltgae range and measures an output current.

-------- MAIN PROGRAM --------
reset()
display.clear()

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
smub.measure.delayfactor = 1
smua.measure.nplc = 10
smub.measure.nplc = 10
 
-- SMUA setup
smua.source.func = smua.OUTPUT_DCVOLTS
smua.sense = smua.SENSE_LOCAL
smua.source.autorangev = smua.AUTORANGE_ON

smua.source.limiti = 1e-5
smua.measure.rangei = 1e-5

-- SMUB setup
smub.source.func = smub.OUTPUT_DCVOLTS
smub.sense = smub.SENSE_LOCAL
smub.source.autorangev = smub.AUTORANGE_ON

smub.source.limiti = 1e-5
smub.measure.rangei = 1e-5

--DISPLAY settings
display.smua.measure.func = display.MEASURE_DCAMPS
display.smub.measure.func = display.MEASURE_DCAMPS
display.screen = display.SMUA_SMUB

-- Measurement routine

smua.source.levelv = 0
smub.source.levelv = 0

smua.source.output = smua.OUTPUT_ON
smub.source.output = smub.OUTPUT_ON

function MeasureAllCurrent()
	smua.measure.i(smua.nvbuffer1)
	smub.measure.i(smub.nvbuffer1)
end

-- Beep in excitement
beeper.beep(0.4, 600)
delay(0.5)
beeper.beep(0.4, 600)

waitcomplete()
-------- END --------
