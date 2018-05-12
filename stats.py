#############################################################
# Enter configuration paramters here
f = 450; # frequency in MHz
cc = 76394; # clock cycles

mem = 1; # memory cost (0.5 or 1)
cache = 0.25; # total cache cost (instruction + data)
wb = 4; # nr of write buffer words
#############################################################

# Returns the memory access time in clock cycles given frequency and memory cost
# Returned values need to be entered as simulation parameters in MARS.
def memSettings():
    ns1 = 44
    ns2 = 8
    if (mem == 1):
        ns1 = 30
        ns2 = 6
    c1 = ns1 / (1000 / f)
    c2 = ns2 / (1000 / f)
    return "{0:.2f}".format(c1) + " / " + "{0:.2f}".format(c2);

# Returns the micro-chalmers-dollar value for given parameters
def efficiency():
    return (1.0 / f) * cc * (2 + mem + cache + 0.03 * wb)
    
print("Memory settings: " + memSettings() + " clock cycles.")
print("Efficiency: " + "{0:.2f}".format(efficiency()))