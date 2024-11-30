# SIMULATION BUILD SCRIPT 

# this script opens the specified .v file from the src folder, opens the file, and all of its dependencies, copying all fo them into a new .v file 
# with addition comments about the most recent build version. 

import sys
import os
import datetime

def getIncludeFile(cmd_args):
    
    filenames = []

    for arg in cmd_args:
        
        if ".v" in arg:
            print(f"BUILD: adding {arg} to build.")
            filenames.append(arg)
            break

    return filenames

def getOutputFile(cmd_args):
    
    outputfile = ""
    argIsOutputFile = False

    for arg in cmd_args:
       
        if (arg == "-O" or arg == "-o"):
            argIsOutputFile = True
            continue

        if argIsOutputFile:
            print(f"BUILD: outputting to {arg}.")
            outputfile = arg
            break
        
        outputfile =  "vga_playground.v" # if no filename is specified

    outputfile.strip()
    
    if ".v" not in outputfile:  # ensure filename ends in .v
        outputfile = outputfile + ".v" 

    return outputfile

def getTopModule(cmd_args):
    
    top_module = ""
    
    argIsTopModule = False

    for arg in cmd_args:
        if (arg == "-Top" or  arg == "-top" or arg == "-T" or arg == "-t"):
            argIsTopModule = True
            continue

        elif (argIsTopModule == True ):
            print(f"BUILD: adding {arg} to build.")
            top_module = arg
            break

    print(f"top module is {top_module}")
    return top_module

if __name__ == "__main__":
    
    current_time = datetime.datetime.now()
    
    filenames = getIncludeFile(sys.argv)
    top = getTopModule(sys.argv)
    outputfile_name = getOutputFile(sys.argv)
    outputfile = open(outputfile_name, "w") 

    print(f"BUILD: building to '{outputfile_name}' .")

    for file in filenames:
        
        file_index = filenames.index(file)
        filename = str(filenames[file_index])
        file_exists = os.path.exists(filename)
        
        if file_exists:

            print(f"INFO: building from {filename}.")
            buildfile = open(filename,"r")
            
            
            if file_index != 0: # separate files with border
                outputfile.write("\n//================================================\n")   

            for line in buildfile:

                if file_index == 0:
                    if  "=== BUILD DEPENDENCIES ===" in line: #add metadata
                        outputfile.write(f"// BUILD TIME: {current_time} \n") 
                        continue

                    if top in line:
                        line = line.replace(top, "tt_um_vga_example")  
                        print("INFO: Renamed Top module.")


                if "`include" in line:
                    includefile = line.strip()
                    includefile = includefile.removeprefix("// ")
                    includefile = includefile.strip()
                    includefile = includefile.removeprefix("`include")
                    includefile = includefile.strip()
                    includefile = includefile.replace('"', "")
                    filenames.append( includefile)
                    print(f"INFO: Found dependency: '{includefile}'.")
                    continue 

                if "===" in line:
                    continue
            
                outputfile.write(line)   
            
            print(f"INFO: {filename} - Build complete.")

        else:
            print(f"ERROR: '{filename}' does not exist.")
    
    print("BUILD: Build Complete!")