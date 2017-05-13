import os
import sys
from ctypes import *


dll_filename = "vJoyInterface.dll"
dll_path = os.path.dirname(__file__) + os.sep + dll_filename

try:
	_vj = cdll.LoadLibrary(dll_path)
except OSError:
	sys.exit("Unable to load vJoy SDK DLL.  Ensure that %s is present" % dll_filename)


def vJoyEnabled():
	"""Returns True if vJoy is installed and enabled"""

	result = _vj.vJoyEnabled()

	if result == 0:
		raise vJoyNotEnabledException()
	else:
		return True


def DriverMatch():
	"""Check if the version of vJoyInterface.dll and the vJoy Driver match"""
	result = _vj.DriverMatch()
	if result == 0:
		raise vJoyDriverMismatch()
	else:
		return True


def GetVJDStatus(rID):
	"""Get the status of a given vJoy Device"""

	return _vj.GetVJDStatus(rID)


def AcquireVJD(rID):
	"""Attempt to acquire a vJoy Device"""

	result = _vj.AcquireVJD(rID)
	if result == 0:
		#Check status
		status = GetVJDStatus(rID)
		if status != VJD_STAT_FREE:
			raise vJoyFailedToAcquireException("Cannot acquire vJoy Device because it is not in VJD_STAT_FREE")

		else:
			raise vJoyFailedToAcquireException()

	else:
		return True


def RelinquishVJD(rID):
	"""Relinquish control of a vJoy Device"""

	result = _vj.RelinquishVJD(rID)
	if result == 0:
		raise vJoyFailedToRelinquishException()
	else:
		return True


def SetBtn(state,rID,buttonID):
	"""Sets the state of vJoy Button to on or off.  SetBtn(state,rID,buttonID)"""
	result = _vj.SetBtn(state,rID,buttonID)
	if result == 0:
		raise vJoyButtonError()
	else:
		return True

def SetDiscPov(PovValue, rID, PovID):
	"""Write Value to a given discrete POV defined in the specified VDJ"""
	if PovValue < -1 or PovValue > 3:
		raise vJoyInvalidPovValueException()

	if PovID < 1 or PovID > 4:
		raise vJoyInvalidPovIDException

	return _vj.SetDiscPov(PovValue,rID,PovID)

def SetContPov(PovValue, rID, PovID):
	"""Write Value to a given continuous POV defined in the specified VDJ"""
	if PovValue < -1 or PovValue > 35999:
		raise vJoyInvalidPovValueException()

	if PovID < 1 or PovID > 4:
		raise vJoyInvalidPovIDException

	return _vj.SetContPov(PovValue,rID,PovID)



def SetBtn(state,rID,buttonID):
	"""Sets the state of vJoy Button to on or off.  SetBtn(state,rID,buttonID)"""
	result = _vj.SetBtn(state,rID,buttonID)
	if result == 0:
		raise vJoyButtonError()
	else:
		return True


def ResetVJD(rID):
	"""Reset all axes and buttons to default for specified vJoy Device"""
	return _vj.ResetVJD(rID)


def ResetButtons(rID):
	"""Reset all buttons to default for specified vJoy Device"""
	return _vj.ResetButtons(rID)


def ResetPovs(rID):
	"""Reset all POV hats to default for specified vJoy Device"""
	return _vj.ResetButtons(rID)

