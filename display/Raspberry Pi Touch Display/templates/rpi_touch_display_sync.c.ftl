/*******************************************************************************
  MPLAB Harmony Generated Display Driver Sync Implementation File

  File Name:
    raspi_touch_display.c

  Summary:
    Implements display and touch driver support for the Raspberry Pi Touch Display.
    https://www.raspberrypi.com/products/raspberry-pi-touch-display/

    Created with MPLAB Harmony Version 3.0
*******************************************************************************/

// DOM-IGNORE-BEGIN
/*******************************************************************************
* Copyright (C) 2023 Microchip Technology Inc. and its subsidiaries.
*
* Subject to your compliance with these terms, you may use Microchip software
* and any derivatives exclusively with Microchip products. It is your
* responsibility to comply with third party license terms applicable to your
* use of third party software (including open source software) that may
* accompany Microchip software.
*
* THIS SOFTWARE IS SUPPLIED BY MICROCHIP "AS IS". NO WARRANTIES, WHETHER
* EXPRESS, IMPLIED OR STATUTORY, APPLY TO THIS SOFTWARE, INCLUDING ANY IMPLIED
* WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY, AND FITNESS FOR A
* PARTICULAR PURPOSE.
*
* IN NO EVENT WILL MICROCHIP BE LIABLE FOR ANY INDIRECT, SPECIAL, PUNITIVE,
* INCIDENTAL OR CONSEQUENTIAL LOSS, DAMAGE, COST OR EXPENSE OF ANY KIND
* WHATSOEVER RELATED TO THE SOFTWARE, HOWEVER CAUSED, EVEN IF MICROCHIP HAS
* BEEN ADVISED OF THE POSSIBILITY OR THE DAMAGES ARE FORESEEABLE. TO THE
* FULLEST EXTENT ALLOWED BY LAW, MICROCHIP'S TOTAL LIABILITY ON ALL CLAIMS IN
* ANY WAY RELATED TO THIS SOFTWARE WILL NOT EXCEED THE AMOUNT OF FEES, IF ANY,
* THAT YOU HAVE PAID DIRECTLY TO MICROCHIP FOR THIS SOFTWARE.
*******************************************************************************/
// DOM-IGNORE-END

#include "gfx/display/rpi_touch_display.h"
#include "string.h"

/* Utility Macros */
#if (DRV_I2C_CLIENTS_NUMBER_IDX${I2CIdx} < 2)
#error "This driver utilizes 2 client objects"
#endif

/* Maximum Simultaneous Touches */
#define MAX_TOUCH_POINTS    (DISP_RX_BUF_SIZE / 6)

/* Set Bit */
#define BIT(__v) (1UL << (__v))

/* MCU I2C Client Registers */
typedef enum {
	REG_ID = 0x80,
	REG_PORTA,
	REG_PORTB,
	REG_PORTC,
	REG_PORTD,
	REG_POWERON,
	REG_PWM,
	REG_DDRA,
	REG_DDRB,
	REG_DDRC,
	REG_DDRD,
	REG_TEST,
	REG_WR_ADDRL,
	REG_WR_ADDRH,
	REG_READH,
	REG_READL,
	REG_WRITEH,
	REG_WRITEL,
	REG_ID2,
} REG_ADDR;

/* Driver Data */
DISP_DATA disp_data;

/* Utility Wrappers */
/* Write to DSI to DPI Bridge using DCS Generic Long Write*/
static void DISP_TC358762XBG_Write(uint16_t reg, uint32_t val) {
    DSI_GENERIC_HEADER hdr;
    DSI_GENERIC_PAYLOAD pld[2];

    memset(&hdr, 0, sizeof(hdr));
    memset(pld, 0, sizeof(pld));

    hdr.longPacket.dataType = 0x29;
    hdr.longPacket.virtualChannelID = 0;
    hdr.longPacket.size = 6;

    pld[0].dataU16[0] = reg;
    pld[0].dataU16[1] = val;
    pld[1].dataU16[0] = val >> 16;

    DSI_Write(&hdr, pld);
}

/* Delay Wrappers */
/* Simple blocking delay */
static void DISP_DelayMS(uint32_t timeMillis)
{
    SYS_TIME_HANDLE delay = SYS_TIME_HANDLE_INVALID;
    SYS_TIME_DelayMS(timeMillis, &delay);
    while (SYS_TIME_DelayIsComplete(delay) == false);
}

/* Wait and go to next state */
static void DISP_DelayNextState(uint32_t timeMillis, DISP_STATES stateNext)
{
    DISP_DelayMS(timeMillis);
    disp_data.state = stateNext;
}

/* Transfer Wrappers */
/* Display Register Write */
static bool DISP_WriteRegister(uint8_t reg, uint8_t val, DISP_CLIENT_ID client_id)
{
    /* Prepare Buffers */
    disp_data.txBuffer[client_id][0] = reg;
    disp_data.txBuffer[client_id][1] = val;

    return DRV_I2C_WriteTransfer(disp_data.i2cHandle[client_id],
                                 disp_data.i2cAddress[client_id],
                                 disp_data.txBuffer[client_id], 2);
}

/* Display Register Read */
static bool DISP_ReadRegister(uint8_t reg, DISP_CLIENT_ID client_id)
{
    /* Prepare Buffers */
    disp_data.txBuffer[client_id][0] = reg;
    disp_data.rxBuffer[client_id][0] = 0;

    return DRV_I2C_WriteReadTransfer(disp_data.i2cHandle[client_id],
                                     disp_data.i2cAddress[client_id],
                                     disp_data.txBuffer[client_id], 1,
                                     disp_data.rxBuffer[client_id], 1);
}

/* Display Register Read Multiple */
static bool DISP_ReadRegisterMultiple(uint8_t reg, uint8_t size, DISP_CLIENT_ID client_id)
{
    if (size > DISP_RX_BUF_SIZE)
        size = DISP_RX_BUF_SIZE;

    /* Prepare Buffers */
    disp_data.txBuffer[client_id][0] = reg;

    return DRV_I2C_WriteReadTransfer(disp_data.i2cHandle[client_id],
                                     disp_data.i2cAddress[client_id],
                                     disp_data.txBuffer[client_id], 1,
                                     disp_data.rxBuffer[client_id], size);
}

/* Get received client data byte */
static uint8_t DISP_GetRxDataByte(DISP_CLIENT_ID client_id, uint32_t offset)
{
    if (offset > DISP_RX_BUF_SIZE)
        offset = DISP_RX_BUF_SIZE;

    return disp_data.rxBuffer[client_id][offset];
}

/* Driver Interface Functions */
void DISP_RPi_Initialize(void)
{
    memset(&disp_data, 0, sizeof(disp_data));

    disp_data.state = DISP_STATE_INIT;

    disp_data.i2cAddress[DISP_CLIENT_ID_MCU] = 0x45;
    disp_data.i2cAddress[DISP_CLIENT_ID_TOUCH] = 0x38;
}

bool DISP_RPi_SetBrightness(uint8_t brightness)
{
    return !DISP_WriteRegister(REG_PWM, brightness, DISP_CLIENT_ID_MCU);
}

void DISP_RPi_Update(void)
{
    switch(disp_data.state)
    {
        case DISP_STATE_INIT:
        {
            /* Open I2C driver clients */
            for (int client_id=0; client_id< DISP_MAX_CLIENTS; client_id++)
            {
                disp_data.i2cHandle[client_id] = DRV_I2C_Open(DRV_I2C_INDEX_${I2CIdx}, DRV_IO_INTENT_READWRITE);

                if (disp_data.i2cHandle[client_id] == DRV_HANDLE_INVALID)
                {
                    disp_data.state = DISP_STATE_ERROR;
                }
            }

            if (disp_data.state != DISP_STATE_ERROR)
            {
                /* Next State */
                disp_data.state = DISP_STATE_POWER_ON;
            }

            break;
        }
        case DISP_STATE_POWER_ON:
        {
            if(DISP_WriteRegister(REG_POWERON, 1, DISP_CLIENT_ID_MCU))
            {
                DISP_DelayNextState(60, DISP_STATE_WAIT_POWER_ON);
            }

            break;
        }
        case DISP_STATE_WAIT_POWER_ON:
        {
            if(DISP_ReadRegister(REG_PORTB, DISP_CLIENT_ID_MCU))
            {
                DISP_DelayNextState(60, DISP_STATE_SET_HFLIP);
            }

            break;
        }
        case DISP_STATE_SET_HFLIP:
        {
            if ((DISP_GetRxDataByte(DISP_CLIENT_ID_MCU, 0) & BIT(0)) == 1)
            {
                if(DISP_WriteRegister(REG_PORTA, ${HorFlip?then('4', '8')}, DISP_CLIENT_ID_MCU))
                {
                    DISP_DelayNextState(60, DISP_STATE_CONFIG_MIPI_HOST);
                }
            }
            else
            {
                DISP_DelayNextState(1, DISP_STATE_WAIT_POWER_ON);
            }

            break;
        }
        case DISP_STATE_CONFIG_MIPI_HOST:
        {
            /* Enter DSI Command Mode */
            DSI_CommandMode();

            /* Configure TC358762XBG Bridge */
            DISP_TC358762XBG_Write(0x0210, 0x03);
            DISP_TC358762XBG_Write(0x0164, 0x05);
            DISP_TC358762XBG_Write(0x0168, 0x05);
            DISP_TC358762XBG_Write(0x0144, 0x00);
            DISP_TC358762XBG_Write(0x0148, 0x00);
            DISP_TC358762XBG_Write(0x0114, 0x03);
            DISP_TC358762XBG_Write(0x0450, 0x00);
            DISP_TC358762XBG_Write(0x0420, 0x00100150);
            DISP_TC358762XBG_Write(0x0464, 0x040f);
            DISP_DelayMS(100);
            DISP_TC358762XBG_Write(0x0104, 0x01);
            DISP_TC358762XBG_Write(0x0204, 0x01);
            DISP_DelayMS(100);

            /* Enter DSI Video Mode */
            DSI_VideoMode();

            DISP_DelayNextState(${DelayBL}, DISP_STATE_SET_BRIGHTNESS);

            break;
        }
        case DISP_STATE_SET_BRIGHTNESS:
        {
            if(DISP_WriteRegister(REG_PWM, ${DefaultBL}, DISP_CLIENT_ID_MCU))
            {
                disp_data.state = DISP_STATE_IDLE;
            }

            break;
        }
        case DISP_STATE_PROCESS_TOUCH:
        {
            /* Process Touch Data */
            uint8_t xh, xl, yh, yl, type;
            uint16_t x, y;

            /* Resolve all points */
            for (int idx = 0; idx < MAX_TOUCH_POINTS; idx++)
            {
                xh = DISP_GetRxDataByte(DISP_CLIENT_ID_TOUCH, 0x3 + (6 * idx));
                xl = DISP_GetRxDataByte(DISP_CLIENT_ID_TOUCH, 0x4 + (6 * idx));
                yh = DISP_GetRxDataByte(DISP_CLIENT_ID_TOUCH, 0x5 + (6 * idx));
                yl = DISP_GetRxDataByte(DISP_CLIENT_ID_TOUCH, 0x6 + (6 * idx));

                type = xh >> 6;
                x = (xh & 0xF) << 8 | xl;
                y = (yh & 0xF) << 8 | yl;
                <#if HorFlip>

                /* Handle Horizontal Flip */
                x = 800 - x;
                y = 480 - y;
                </#if>

                switch(type)
                {
                    case 0x0:
                    {
                        SYS_INP_InjectTouchDown(idx, x , y);

                        break;
                    }
                    case 0x1:
                    {
                        SYS_INP_InjectTouchUp(idx, x, y);

                        break;
                    }
                    case 0x2:
                    {
                        SYS_INP_InjectTouchMove(idx, x, y);

                        break;
                    }
                }
            }

            disp_data.state = DISP_STATE_IDLE;

            break;
        }
        case DISP_STATE_ERROR:
        {
            break;
        }
        case DISP_STATE_IDLE:
        {
            if(DISP_ReadRegisterMultiple(0x00, 32, DISP_CLIENT_ID_TOUCH))
            {
                disp_data.state = DISP_STATE_PROCESS_TOUCH;
            }

            break;
        }
        default:
        {
            break;
        }
    }
}
