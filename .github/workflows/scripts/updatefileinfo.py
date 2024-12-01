# UPDATE FILE METADATA SCRIPT
# This script atuomatically updates the  last edited date and time of the file 

import sys
import os
from time import strftime,localtime

def getFileName(cmd_args):
    
    filename = ""

    argcount = 0
    
    for arg in cmd_args: # the first argcount will always be the name of the script - can ignore this.
        if argcount != 0:
            if ".v" in arg:
                print(f"INFO: adding {arg} to update queue.")
                filename = arg
                break
            else:
                print(arg + " is not a valid verilog filename.")
        argcount = argcount + 1

    return filename

if __name__ == "__main__":
    
    current_time = strftime("%d/%m/%Y @ %H:%M:%S", localtime())
    
    filename = getFileName(sys.argv)
    fileExists = os.path.exists(filename)

    updateLine = ""
    linecounter = 0

    foundUpdateHeader = False
    UpdateHeaders = ["Last Updated:","Last Edited:","Last Modified:", "Last Accessed:"]
    
    if fileExists:
        
        print(f"UPDATE: updating '{filename}' metadata.")
        file = open(filename,"r")
        
        lines = file.readlines()

        for line in lines:
            
            for header in UpdateHeaders:
                    
                if header in line:
                    linestart = line.index(header[0])

                    for i in range(0, linestart):
                        updateLine = updateLine + line[i]
                        
                    updateLine = updateLine + header + " " + current_time + "\n"
                    foundUpdateHeader = True
                    break

            if (foundUpdateHeader == False):
                linecounter = linecounter + 1
            
            elif foundUpdateHeader:
                print(f"INFO: Update Time found on Line {linecounter}.")
                break

            
                  
        file.close() 

        if (foundUpdateHeader):
            print(f"UPDATE: {filename}, last updated on {current_time}")
            lines[linecounter] = updateLine
            file = open(filename,"w")
            file.writelines(lines)

    else:
        print("No verilog file updated.")
        sys.exit(0)

    print("Update Complete!")
    sys.exit(0)
    
    # python3 updatefileinfo.py tt_um_enjimneering_top.v 
    # :P