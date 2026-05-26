
"""
Module for interacting with the Keithley 2636B SMU.

Author:  Ross <peregrine dot warren at physics dot ox dot ac dot uk>
"""

import pyvisa
import pandas as pd
#import matplotlib.pyplot as plt
#import matplotlib.style as style
import time
#from serial import SerialException

MAX_TIME_OUT = 200000
NORMAL_TIME_OUT = 2000
SANITY_WAIT = 1.5 # secondes
print(f"max timeout : {MAX_TIME_OUT}")
print(f"normal timeout : {NORMAL_TIME_OUT}")


class K2636():
    """Class for Keithley control."""

    def __init__(self, address='TCPIP::169.254.33.131::INSTR', read_term='\n',
                 baudrate=57600):
        """Make instrument connection instantly on calling class."""
        rm = pyvisa.ResourceManager('@py')  # use py-visa backend
        self.makeConnection(rm, address, read_term, baudrate)

    def makeConnection(self, rm, address, read_term, baudrate):
        """Make initial connection to instrument."""
        if "TCP" in str(address):
            self.inst = rm.open_resource(address)
            self.inst.read_termination  = "\n"
            self.inst.write_termination = ""
        else:
            try:
                if 'ttyS' or 'ttyUSB' in str(address):
                    # Connection via SERIAL
                    self.inst = rm.open_resource(address)
                    self.inst.read_termination = str(read_term)
                    self.inst.baud_rate = baudrate

                if 'GPIB' in str(address):
                    # Connection via GPIB
                    print('No GPIB support. Please use serial')
            except :
                print("Erreur SerialException")

    #        except SerialException:
    #            print("CONNECTION ERROR: Check instrument address.")
    #            raise ConnectionError

    def closeConnection(self):
        """Close connection to keithley."""
        try:
            self.inst.close()

        except(NameError):
            print('CONNECTION ERROR: No connection established.')

        except(AttributeError):
            print('CONNECTION ERROR: No connection established.')

    def _write(self, m):
        """Write to instrument."""
        try:
            assert type(m) == str
            self.inst.write(m)
            if not("\n" in m):print(m)
        except AttributeError:
            print('CONNECTION ERROR: No connection established.')

    def _read(self):
        """Read instrument."""
        r = self.inst.read()
        return r

    def _query(self, s):
        """Query instrument."""
        try:
            r = self.inst.query(s)
            return r
#        except SerialException:
#            return ('Serial port busy, try again.')
        except FileNotFoundError:
            return ('CONNECTION ERROR: No connection established.')
        except AttributeError:
            print('CONNECTION ERROR: No connection established.')
            return ('CONNECTION ERROR: No connection established.')

    def loadTSP(self, tsp, script_name = "",smuNode = 1):
        """Load an anonymous TSP script into the K2636 nonvolatile memory."""
        print(f"Uploading to the Node [{smuNode}]")

        try:
            tsp_dir = 'TSP-scripts/'  # Put all tsp scripts in this folder
            # load and name the script if it has a name
            if len(script_name) : self._write(f'loadscript {script_name}')
            else:self._write('loadscript')
            
            line_count = 1
            for line in open(str(tsp_dir + tsp), mode='r'):
                self._write(line)
                line_count += 1
            self._write('endscript')

            if smuNode != 1: # Code to be uploaded to another than the default one
                time.sleep(SANITY_WAIT)
                self._write(f"node[{smuNode}].dataqueue.add({script_name}.source)")
                self._write(f"node[{smuNode}].execute(\"\{script_name}\".. \"=script.new(dataqueue.next(),[[\"..\"{script_name}\".. \"]])\")")
                time.sleep(SANITY_WAIT)
                #self._write(f"script.delete(\"{script_name}\")") #remove the code from the main node
                time.sleep(SANITY_WAIT)
                
            print('----------------------------------------')
            print(f'Uploaded TSP script to node {smuNode}: {tsp}')

        except FileNotFoundError:
            print('ERROR: Could not find tsp script. Check path.')
            raise SystemExit

    def runTSP(self,script_name = ""):
        """Run the anonymous TSP script currently loaded in the K2636 memory."""
        if len(script_name)>0: self._write(f"{script_name}()")
        else: self._write('script.anonymous.run()')
        print('Measurement in progress...')

    def runFunction(self,nameFunction,parameters = ""):
        self.inst.write(f"waitcomplete(0)")
        self.inst.write(f"{nameFunction}({parameters})")
        self.inst.timeout = MAX_TIME_OUT
        conditionTest = True
        while conditionTest:
            text = self.inst.read()
            print(f"keithley : {text}")
            conditionTest = (text != f"DONE {nameFunction}") 

    def readBuffer(self):
        """Read buffer in memory and return an array."""
        print(f"Reading values from the node {smuNode}")
        # TODO: write self._query("*WDN?") to clear any left status and 
        # not crash the communication with the SMU
        # Extracted from the docs, the content of a buffer type object : 
        # buffer = {timestamps measurefunctions readings sourcevalues...}
        # range and units are retrievable as well as the timestamps

        
        
        src1a = [float(x) for x in self._query('printbuffer' +
              '(1, smua.nvbuffer1.n, smua.nvbuffer1.sourcevalues)').split(',')]
        i1a = [float(x) for x in self._query('printbuffer' +
             '(1, smua.nvbuffer1.n, smua.nvbuffer1.readings)').split(',')]
        src1b = [float(x) for x in self._query('printbuffer' +
              '(1, smub.nvbuffer1.n, smub.nvbuffer1.sourcevalues)').split(',')]
        i1b = [float(x) for x in self._query('printbuffer' +
              '(1, smub.nvbuffer1.n, smub.nvbuffer1.readings)').split(',')]

    
        time.sleep(SANITY_WAIT)
        
        self._write(f"node[{smuNode}].execute(\"bfremoteA = smua.nvbuffer1\")")
        time.sleep(SANITY_WAIT)

        self._write(f"bfremoteA = node[{smuNode}].getglobal(\"bfremoteA\")")
        time.sleep(SANITY_WAIT)
        src2a = [float(x) for x in self._query('printbuffer' +
              '(1, bfremoteA.n, bfremoteA.sourcevalues)').split(',')]
        i2a = [float(x) for x in self._query('printbuffer' +
             '(1, bfremoteA.n, bfremoteA.readings)').split(',')]
        self._write(f"bfremoteA = nil")

        time.sleep(SANITY_WAIT)
        self._write(f"node[{smuNode}].execute(\"bfremoteB = smub.nvbuffer1\")")
        time.sleep(SANITY_WAIT)
        self._write(f"bfremoteB = node[{smuNode}].getglobal(\"bfremoteB\")")
        time.sleep(SANITY_WAIT)
        src2b = [float(x) for x in self._query('printbuffer' +
              '(1, bfremoteB.n, bfremoteB.sourcevalues)').split(',')]
        i2b = [float(x) for x in self._query('printbuffer' +
              '(1, bfremoteB.n, bfremoteB.readings)').split(',')]

        self._write(f"bfremoteB = nil")

        df = pd.DataFrame({'SMU1 src A [V]': src1a,
                           'SMU1 src B [V]': src1b,
                           'SMU1 current A [A]': i1a,
                           'SMU1 current B [A]': i1b,
                           'SMU2 src A [V]': src2a,
                           'SMU2 src B [V]': src2b,
                           'SMU2 current A [A]': i2a,
                           'SMU2 current B [A]': i2b


                           })
        return df

    
    def SaveAcquisition(self, sample):
        """K2636 Output sweeps."""
        df = self.readBuffer()
        output_name = str(sample + '-outputs.csv')
        df.to_csv(output_name, sep='\t', index=False)

    def loadListTension(self,listSmuA,listSmuB,listSmuAName = "list_SMUA",listSmuBName = "list_SMUB"):
        # function to load any list in the device for sweeping by a TSP command
        # Todo luanch a sweep using this list you must call the runFunction("doubleListSweep","list_SMUA,list_SMUB,DELAY")
        # With DELAY being the time step that you want, default to 1E-4
        
        # TODO: Four channel super sweep
        self._write(f"self._write(f"{listSmuAName} ,{listSmuBName} = \{\},\{\}")
")
        for i in range(len(listSmuA)):
            self._write(f"{listSmuAName}[{i+1}],{listSmuBName}[{i+1}] = {listSmuA[i]},{listSmuB[i]}")
        else :
            self._write(f"{listSmuAName}[{i+1}],{listSmuBName}[{i+1}] = nil,nil") #end the list

########################################################################

if __name__ == '__main__':
    """For testing methods in the K2636 class."""
    keithley = K2636(address="TCPIP::169.254.33.131::INSTR")
    keithley.loadTSP("smu2.tsp","main2",smuNode = 2)
    keithley.loadTSP("smu1.tsp","main1",smuNode = 1)
    time.sleep(SANITY_WAIT)

    keithley.inst.write("main1()")
    time.sleep(SANITY_WAIT)
    
    print(keithley.inst.read())
    #keithley.inst.write("node[2].execute(\"main2()\") waitcomplete(0) print(\"DONE\")")
    keithley.inst.write("node[2].execute(main2.source) print(\"DONE\")")
    print(keithley.inst.read())
    
    keithley.runFunction("superSweep","-2,2,0.1,0.1")
    nameFile = input("name the sample please DeviceId Sample Type of test run : ")
    keithley.SaveAcquisition(nameFile)
    keithley.closeConnection()
