import pyvisa
import os
import pandas as pd
import time

# Connect to Keithley via GPIB
rm = pyvisa.ResourceManager()
keithley = rm.open_resource("GPIB0::24::INSTR", encoding="utf-8")

# Set communication timeout
keithley.timeout = None 

# File paths
script_path = "C:\\Users\\nickolas.jesus\\Desktop\\TSP\\if_sweep_teste_2.tsp"
output_path = "C:\\Users\\nickolas.jesus\\Desktop\\TSP\\data.xlsx"

# Prompt user input to set parameters
params = {
    "initial_voltage": float(input("Enter initial_voltage (V): ")),
    "final_voltage": float(input("Enter final_voltage (V): ")),
    "step": float(input("Enter step (V): ")),
    "vds": float(input("Enter vds (V): ")),
    "time_delay": float(input("Enter time_delay (s): ")),
    "sweeps": int(input("Enter the number of sweeps: ")),
    "nplc": float(input("Enter nplc value: ")),
}

# Send parameters to Keithley before executing the script
for param, value in params.items():
    keithley.write(f"{param} = {value}")

print("\nParameters successfully configured!")

# Check if the script file exists before attempting to load it
if not os.path.exists(script_path):
    print(f"Error: The file {script_path} was not found!")
else:
    print(f"Loading script: {script_path}")

    try:
        # Start writing the script to Keithley
        keithley.write("loadscript test")

        # Read and send the script content
        with open(script_path, "r", encoding="utf-8") as fp:
            keithley.write(fp.read())

        # Finalize the script and execute
        keithley.write("endscript")
        keithley.write("test.run()")

        print("Script executed successfully!")
        time.sleep(2)  # Wait for the script execution

        # Debugging: check how many points exist in the buffers before reading
        smua_count = int(float(keithley.query("print(smua.nvbuffer1.n)").strip()))
        smub_count = int(float(keithley.query("print(smub.nvbuffer1.n)").strip()))

        print(f"SMUA has {smua_count} points in the buffer.")
        print(f"SMUB has {smub_count} points in the buffer.")

        if smua_count == 0 or smub_count == 0:
            print("Warning: The buffers are empty! Check if the script correctly filled the buffers.")

        # Function to read and clean buffer data
        def read_buffer(command):
            response = keithley.query(command).strip()
            print(f"Keithley response for {command}: {response}")  # Debug
            values = response.replace("\n", "").split(",")
            try:
                return [float(x) for x in values]  # Convert to numbers
            except ValueError:
                return [float(x) for x in values[1:]]  # Ignore header if present

        # Read full buffers
        timestamps = read_buffer(f"printbuffer(1, {smua_count}, smua.nvbuffer1.timestamps)")
        smua_voltage = read_buffer(f"printbuffer(1, {smua_count}, smua.nvbuffer2)")
        smua_current = read_buffer(f"printbuffer(1, {smua_count}, smua.nvbuffer1)")
        smub_voltage = read_buffer(f"printbuffer(1, {smub_count}, smub.nvbuffer2)")
        smub_current = read_buffer(f"printbuffer(1, {smub_count}, smub.nvbuffer1)")

        # Adjust list sizes (in case one has fewer values)
        min_length = min(len(timestamps), len(smua_voltage), len(smua_current), len(smub_voltage), len(smub_current))

        # Create Pandas DataFrame with organized data
        df = pd.DataFrame({
            "Timestamps": timestamps[:min_length],
            "SMUA Voltage (V)": smua_voltage[:min_length],
            "SMUA Current (A)": smua_current[:min_length],
            "SMUB Voltage (V)": smub_voltage[:min_length],
            "SMUB Current (A)": smub_current[:min_length],
        })

        # Display table in terminal
        print(df)

        # Save to Excel
        df.to_excel(output_path, index=False)
        print(f"\nReading completed! Data saved at: {output_path}")

    except Exception as e:
        print(f"Error loading the script: {e}")

    finally:
        # Close connection with Keithley
        keithley.close()
        print("Connection with Keithley closed.")
