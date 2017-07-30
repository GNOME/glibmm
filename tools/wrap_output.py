from subprocess import call
import sys

f = open(sys.argv[2], "w")

call_args = [sys.argv[1]] + sys.argv[3:]
call(call_args, stdout = f) 
