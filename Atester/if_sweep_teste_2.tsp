
function if_sweep(initial_voltage, final_voltage, step, vds, time_delay, sweeps, nplc)
    -- Save current settings to restore them after the measurement
    local l_smua_levelv = smua.source.levelv 
    local l_smua_rangev = smua.source.rangev
    local l_smua_autorangev = smua.source.autorangev 
    local l_smua_func = smua.source.func
    local l_smua_autozero = smua.measure.autozero
    local l_smua_filter = smua.measure.filter.enable
    local l_smub_levelv = smub.source.levelv
    local l_smub_rangev = smub.source.rangev
    local l_smub_autorangev = smub.source.autorangev 
    local l_smub_func = smub.source.func
    local l_smub_autozero = smub.measure.autozero
    local l_smub_filter = smub.measure.filter.enable
    local l_d_screen = display.screen

    -- Create the voltage sweep list
    local v_source = {}
    local count = 0
    local v = initial_voltage

    for i = 1, sweeps do  -- Agora faz exatamente 'sweeps' repetições
        local v = initial_voltage
        while v <= (final_voltage + step) do
            table.insert(v_source, v)
            count = count + 1
            v = v + step
        end
    end

    -- Create a list for constant drain voltage (VDS)
    local vds_values = {}
    for i = 1, count do
        table.insert(vds_values, vds)
    end

    -- Update display to indicate the start of the sweep
    display.clear()
    display.settext("IF Sweep")
    delay(2)
    reset()

    -- Configure SMU A (Gate Voltage Source)
    smua.reset()
    smua.source.func = smua.OUTPUT_DCVOLTS
    smua.source.autorangev = smua.AUTORANGE_ON
    smua.source.lowrangev = 2
    smua.source.levelv = initial_voltage
    smua.measure.autozero = smua.AUTOZERO_ONCE
    smua.measure.autorangei = smua.AUTORANGE_ON
    smua.measure.lowrangei = 0.01
    smua.measure.lowrangev = 2
    smua.measure.nplc = nplc
    smua.measure.delay = 0 -- Disable built-in delay
    smua.nvbuffer1.clear()
    smua.nvbuffer2.clear()
    smua.nvbuffer1.collecttimestamps = 1

    -- Configure SMU B (Drain Voltage Source)
    smub.reset()
    smub.source.func = smub.OUTPUT_DCVOLTS
    smub.source.autorangev = smub.AUTORANGE_ON
    smub.source.lowrangev = 20
    smub.source.levelv = vds
    smub.measure.autozero = smub.AUTOZERO_ONCE
    smub.measure.autorangei = smub.AUTORANGE_ON
    smua.measure.lowrangei = 0.01
    smua.measure.lowrangev = 20
    smub.measure.nplc = nplc
    smub.measure.delay = 0 -- Disable built-in delay
    smub.nvbuffer1.clear()
    smub.nvbuffer2.clear()
    smub.nvbuffer1.collecttimestamps = 1

    -- Configure trigger timer for synchronization
    trigger.timer[1].count = 0
    trigger.timer[1].delay = time_delay
    trigger.timer[1].passthrough = true
    trigger.timer[1].stimulus = smua.trigger.ARMED_EVENT_ID

    -- Configure SMUA trigger model for sweep execution
    smua.trigger.source.listv(v_source)
    smua.trigger.measure.action = smua.ENABLE
    smua.trigger.measure.iv(smua.nvbuffer1, smua.nvbuffer2)
    smua.trigger.endpulse.action = smua.SOURCE_IDLE
    smua.trigger.endsweep.action = smua.SOURCE_IDLE
    smua.trigger.count = count
    smua.trigger.arm.stimulus = 0
    smua.trigger.measure.stimulus = trigger.timer[1].EVENT_ID
    smua.trigger.source.action = smua.ENABLE

    -- Configure SMUB trigger model for drain voltage stability
    smub.trigger.source.listv(vds_values)
    smub.trigger.measure.action = smub.ENABLE
    smub.trigger.measure.iv(smub.nvbuffer1, smub.nvbuffer2)
    smub.trigger.endpulse.action = smub.SOURCE_IDLE
    smub.trigger.endsweep.action = smub.SOURCE_IDLE
    smub.trigger.count = count
    smub.trigger.arm.stimulus = 0
    smub.trigger.measure.stimulus = trigger.timer[1].EVENT_ID
    smub.trigger.source.action = smub.ENABLE

    -- Turn on the outputs
    smua.source.output = smua.OUTPUT_ON
    smub.source.output = smub.OUTPUT_ON

    -- Start the trigger model execution
    smua.trigger.initiate()
    smub.trigger.initiate()

    -- Wait for completion
    waitcomplete()

    -- Turn off outputs after measurement
    smua.source.output = smua.OUTPUT_OFF
    smub.source.output = smub.OUTPUT_OFF

    -- Validate buffer data to check if measurements were successful
    if smua.nvbuffer1.n == 0 or smub.nvbuffer1.n == 0 then
        print("Error: Measurement buffers are empty! Retrying...")
        delay(2)
        if smua.nvbuffer1.n == 0 or smub.nvbuffer1.n == 0 then
            print("Error: Measurement buffers are still empty! Aborting.")
            smua.source.output = smua.OUTPUT_OFF
            smub.source.output = smub.OUTPUT_OFF
            return
        end
    end

    -- Restore previous settings
    display.setcursor(2,1)
    display.settext("Test complete.")
    smua.source.levelv = 0
    smua.source.rangev = l_smua_rangev
    smua.source.autorangev = l_smua_autorangev
    smua.source.func = l_smua_func
    smua.source.levelv = l_smua_levelv
    smua.measure.autozero = l_smua_autozero
    smua.measure.filter.enable = l_smua_filter
    smub.source.levelv = 0
    smub.source.rangev = l_smub_rangev
    smub.source.autorangev = l_smub_autorangev
    smub.source.func = l_smub_func
    smub.source.levelv = l_smub_levelv
    smub.measure.autozero = l_smub_autozero
    smub.measure.filter.enable = l_smub_filter
    delay(2)
    display.clear()
    display.screen = l_d_screen


end

-- Execute the function with the defined parameters
if_sweep(initial_voltage, final_voltage, step, vds, time_delay, sweeps, nplc)