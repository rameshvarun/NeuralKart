import os
import sys
from ctypes import *

from pyvjoy.constants import *
from pyvjoy.exceptions import *

from ctypes import wintypes

dll_path = os.path.dirname(__file__) + os.sep + DLL_FILENAME

try:
    _vj = cdll.LoadLibrary(dll_path)
except OSError:
    sys.exit("Unable to load vJoy SDK DLL.  Ensure that %s is present" % DLL_FILENAME)


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
        # Check status
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


def SetBtn(state, rID, buttonID):
    """Sets the state of a vJoy Button to on or off.  SetBtn(state,rID,buttonID)"""
    result = _vj.SetBtn(state, rID, buttonID)
    if result == 0:
        raise vJoyButtonException()
    else:
        return True


def SetAxis(AxisValue, rID, AxisID):
    """Sets the value of a vJoy Axis  SetAxis(value,rID,AxisID)"""

    # TODO validate AxisID
    # TODO validate AxisValue

    result = _vj.SetAxis(AxisValue, rID, AxisID)
    if result == 0:
        # TODO raise specific exception
        raise vJoyException()
    else:
        return True


def SetDiscPov(PovValue, rID, PovID):
    """Write Value to a given discrete POV defined in the specified VDJ"""
    if PovValue < -1 or PovValue > 3:
        raise vJoyInvalidPovValueException()

    if PovID < 1 or PovID > 4:
        raise vJoyInvalidPovIDException

    return _vj.SetDiscPov(PovValue, rID, PovID)


def SetContPov(PovValue, rID, PovID):
    """Write Value to a given continuous POV defined in the specified VDJ"""
    if PovValue < -1 or PovValue > 35999:
        raise vJoyInvalidPovValueException()

    if PovID < 1 or PovID > 4:
        raise vJoyInvalidPovIDException

    return _vj.SetContPov(PovValue, rID, PovID)


def SetBtn(state, rID, buttonID):
    """Sets the state of vJoy Button to on or off.  SetBtn(state,rID,buttonID)"""
    result = _vj.SetBtn(state, rID, buttonID)
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
    return _vj.ResetPovs(rID)


def UpdateVJD(rID, data):
    """Pass data for all buttons and axes to vJoy Device efficiently"""
    return _vj.UpdateVJD(rID, data)


def CreateDataStructure(rID):
    data = _JOYSTICK_POSITION_V2()
    data.set_defaults(rID)
    return data


class _JOYSTICK_POSITION_V2(Structure):
    _fields_ = [
        ('bDevice', c_byte),
        ('wThrottle', c_long),
        ('wRudder', c_long),
        ('wAileron', c_long),
        ('wAxisX', c_long),
        ('wAxisY', c_long),
        ('wAxisZ', c_long),
        ('wAxisXRot', c_long),
        ('wAxisYRot', c_long),
        ('wAxisZRot', c_long),
        ('wSlider', c_long),
        ('wDial', c_long),
        ('wWheel', c_long),
        ('wAxisVX', c_long),
        ('wAxisVY', c_long),
        ('wAxisVZ', c_long),
        ('wAxisVBRX', c_long),
        ('wAxisVRBY', c_long),
        ('wAxisVRBZ', c_long),
        ('lButtons', c_long),  # 32 buttons: 0x00000001 means button1 is pressed, 0x80000000 -> button32 is pressed

        ('bHats', wintypes.DWORD),  # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
        ('bHatsEx1', wintypes.DWORD),  # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
        ('bHatsEx2', wintypes.DWORD),  # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch
        ('bHatsEx3', wintypes.DWORD),  # Lower 4 bits: HAT switch or 16-bit of continuous HAT switch LONG lButtonsEx1

        # JOYSTICK_POSITION_V2 Extension

        ('lButtonsEx1', c_long),  # Buttons 33-64
        ('lButtonsEx2', c_long),  # Buttons 65-96
        ('lButtonsEx3', c_long),  # Buttons 97-128
    ]

    def set_defaults(self, rID):
        self.bDevice = c_byte(rID)
        self.bHats = -1
