# coding: utf-8
##############################################################################
# Copyright (C) 2018 Microchip Technology Inc. and its subsidiaries.
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

def instantiateComponent(halComponent):
	projectPath = "config/" + Variables.get("__CONFIGURATION_NAME") + "/gfx/display"
	
	halComponent.setHelpFile("../docs/help_harmony_gfx_html_alias.h")
	
	execfile(Module.getPath() + "/display.py")
	execfile(Module.getPath() + "/hints.py")

def updateDisplayValues(halComponent, displayComponent):
	halComponent.setSymbolValue("DisplayWidth", displayComponent.getSymbolValue("DisplayWidth"), 1)
	halComponent.setSymbolValue("DisplayHeight", displayComponent.getSymbolValue("DisplayHeight"), 1)
	halComponent.setSymbolValue("DisplayDataWidth", displayComponent.getSymbolValue("DataWidth"), 1)
	halComponent.setSymbolValue("DisplayHorzPulseWidth", displayComponent.getSymbolValue("HorzPulseWidth"), 1)
	halComponent.setSymbolValue("DisplayHorzBackPorch", displayComponent.getSymbolValue("HorzBackPorch"), 1)
	halComponent.setSymbolValue("DisplayHorzFrontPorch", displayComponent.getSymbolValue("HorzFrontPorch"), 1)
	halComponent.setSymbolValue("DisplayVertPulseWidth", displayComponent.getSymbolValue("VertPulseWidth"), 1)
	halComponent.setSymbolValue("DisplayVertBackPorch", displayComponent.getSymbolValue("VertBackPorch"), 1)
	halComponent.setSymbolValue("DisplayVertFrontPorch", displayComponent.getSymbolValue("VertFrontPorch"), 1)
	halComponent.setSymbolValue("DisplayInvLeftShift", displayComponent.getSymbolValue("InvLeftShift"), 1)
	halComponent.setSymbolValue("DisplayBacklightDisable", displayComponent.getSymbolValue("BacklightDisable"), 1)
	halComponent.setSymbolValue("DisplayBacklightEnable", displayComponent.getSymbolValue("BacklightEnable"), 1)
	halComponent.setSymbolValue("DisplayVSYNCNegative", displayComponent.getSymbolValue("VSYNCNegative"), 1)
	halComponent.setSymbolValue("DisplayHSYNCNegative", displayComponent.getSymbolValue("HSYNCNegative"), 1)
	halComponent.setSymbolValue("DisplayDataEnable", displayComponent.getSymbolValue("DataEnable"), 1)
	halComponent.setSymbolValue("DisplayDataEnablePolarity", displayComponent.getSymbolValue("DataEnablePolarity"), 1)
	halComponent.setSymbolValue("DisplayUseReset", displayComponent.getSymbolValue("UseReset"), 1)
	halComponent.setSymbolValue("DisplayResetPolarity", displayComponent.getSymbolValue("ResetPolarity"), 1)
	halComponent.setSymbolValue("DisplayUseChipSelect", displayComponent.getSymbolValue("UseChipSelect"), 1)
	halComponent.setSymbolValue("DisplayChipSelectPolarity", displayComponent.getSymbolValue("ChipSelectPolarity"), 1)

def clearDisplayValues(halComponent):
	halComponent.clearSymbolValue("DisplayWidth")
	halComponent.clearSymbolValue("DisplayHeight")
	halComponent.clearSymbolValue("DisplayDataWidth")
	halComponent.clearSymbolValue("DisplayHorzPulseWidth")
	halComponent.clearSymbolValue("DisplayHorzBackPorch")
	halComponent.clearSymbolValue("DisplayHorzFrontPorch")
	halComponent.clearSymbolValue("DisplayVertPulseWidth")
	halComponent.clearSymbolValue("DisplayVertBackPorch")
	halComponent.clearSymbolValue("DisplayVertFrontPorch")
	halComponent.clearSymbolValue("DisplayInvLeftShift")
	halComponent.clearSymbolValue("DisplayBacklightDisable")
	halComponent.clearSymbolValue("DisplayBacklightEnable")
	halComponent.clearSymbolValue("DisplayVSYNCNegative")
	halComponent.clearSymbolValue("DisplayHSYNCNegative")
	halComponent.clearSymbolValue("DisplayDataEnable")
	halComponent.clearSymbolValue("DisplayDataEnablePolarity")
	halComponent.clearSymbolValue("DisplayUseReset")
	halComponent.clearSymbolValue("DisplayResetPolarity")
	halComponent.clearSymbolValue("DisplayUseChipSelect")
	halComponent.clearSymbolValue("DisplayChipSelectPolarity")

def updateRefreshRate(halComponent):
	totalHorzTiming = int(halComponent.getSymbolValue("DisplayWidth")) + int(halComponent.getSymbolValue("DisplayHorzPulseWidth")) \
					+ int(halComponent.getSymbolValue("DisplayHorzBackPorch")) + int(halComponent.getSymbolValue("DisplayHorzFrontPorch"))
	totalVertTiming = int(halComponent.getSymbolValue("DisplayHeight")) + int(halComponent.getSymbolValue("DisplayVertPulseWidth")) \
					+ int(halComponent.getSymbolValue("DisplayVertBackPorch")) + int(halComponent.getSymbolValue("DisplayVertFrontPorch"))
	refreshRate = halComponent.getSymbolValue("PixelClock") / (totalHorzTiming * totalVertTiming)
	halComponent.setSymbolValue("RefreshRate", refreshRate, 1)

def showDisplayTimingSettings(halComponent, displayDriverComponent):
	halComponent.getSymbolByID("PixelClock").setVisible(True)
	halComponent.setSymbolValue("PixelClock", displayDriverComponent.getSymbolValue("PixelClock"), 1)
	halComponent.getSymbolByID("RefreshRate").setVisible(True)
	updateRefreshRate(halComponent)
	halComponent.getSymbolByID("DisplayHorzMenu").setVisible(True)
	halComponent.getSymbolByID("DisplayVertMenu").setVisible(True)

def hideDisplayTimingSettings(halComponent, displayDriverComponent):
	halComponent.getSymbolByID("PixelClock").setVisible(False)
	halComponent.getSymbolByID("RefreshRate").setVisible(False)
	halComponent.getSymbolByID("DisplayHorzMenu").setVisible(False)
	halComponent.getSymbolByID("DisplayVertMenu").setVisible(False)

def onUpdateDisplayTiming(symbol, event):
	halComponent = event["source"]
	updateRefreshRate(halComponent)

def onPixelClockSet(symbol, event):
	halComponent = event["source"]
	updateRefreshRate(halComponent)

def onDisableHint(symbol, event):
	halComponent = event["source"]
	
	LCCRefreshHint = halComponent.getSymbolByID("LCCRefreshHint")
	LCCRefreshHint.setReadOnly(halComponent.getSymbolValue("DisableLCCRefreshHint"))
	
	Orientation = halComponent.getSymbolByID("DisplayOrientation")
	Orientation.setReadOnly(halComponent.getSymbolValue("DisableDisplayOrientation"))
