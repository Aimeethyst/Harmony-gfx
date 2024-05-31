# coding: utf-8
##############################################################################
# Copyright (C) 2023 Microchip Technology Inc. and its subsidiaries.
#
# Subject to your compliance with these terms, you may use Microchip software
# and any derivatives exclusively with Microchip products. It is your
# responsibility to comply with third party license terms applicable to your
# use of third party software (including open source software) that may
# accompany Microchip software.
#
# THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
# EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
# WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
# PARTICULAR PURPOSE.
#
# IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
# INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
# WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
# BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
# FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
# ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
# THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
##############################################################################


def loadModule():
    if any(device in Variables.get("__PROCESSOR") for device in ["SAM9X72", "SAM9X75", "SAMA7D"]):
        print("XLCDC module loaded to support " + str(Variables.get("__PROCESSOR")))
        component = Module.CreateComponent("le_gfx_driver_xlcdc", "LE XLCDC Driver", "/Graphics/Driver", "config/xlcdc.py")
        component.setDisplayType("LE XLCDC Display Driver")
        component.addCapability("le_gfx_xlcdc_cap", "LE Display Driver", False)
        component.addDependency("le_gfx_core_dep", "Core Service", True, True)
        component.addDependency("Graphics Display", "Graphics Display", False)
        component.addDependency("gfx_dpi_bridge_dep", "DPI", False)
    else:
        print("XLCDC module not loaded.  No support for " + str(Variables.get("__PROCESSOR")))