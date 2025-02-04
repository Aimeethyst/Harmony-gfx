#include "driver/isi/drv_isi_common.h"

#include "device.h"

#include "driver/isi/drv_isi.h"
#include "peripheral/isi/plib_isi.h"
#include "system/int/sys_int.h"

#include "bsp/bsp.h"

static int32_t _bufferCount;
static int32_t _currentBuffer = -1;
static bool _transferComplete;

static CACHE_ALIGN __ALIGNED(32) DRV_ISI_FrameBufferDescriptor _descriptors[DRV_ISI_MAX_FRAMEBUFFER_DESCRIPTOR];

static DRV_ISI_PreviewFrameReady_Callback _frameReadyCallback = NULL;

void _DRV_ISI_PreviewInit(void)
{
    PLIB_ISI_DMA_P_DSCR_Set((uint32_t)&_descriptors[0]);
    PLIB_ISI_DMA_P_ADDR_Set((uint32_t)_descriptors[0].address);
    PLIB_ISI_DMA_P_CTRL_P_FETCH_Set(1);
    
    PLIB_ISI_IER_PXFR_DONE_Set(1);
}

bool DRV_ISI_PreviewPathIsEnabled(void)
{
    return (bool)PLIB_ISI_DMA_CHSR_P_CH_S_Get();
}

bool DRV_ISI_PreviewPathEnable(void)
{
    PLIB_ISI_DMA_CHER_P_CH_EN_Set(1);
    
    while(PLIB_ISI_DMA_CHSR_P_CH_S_Get() == 0);
    
    return true;
}

bool DRV_ISI_PreviewPathDisable(void)
{
    PLIB_ISI_DMA_CHDR_P_CH_DIS_Set(1);
    
    while(PLIB_ISI_DMA_CHSR_P_CH_S_Get() == 1);
    
    return true;
}

bool DRV_ISI_AddPreviewFrameBuffer(uint8_t* buf)
{
    if(_bufferCount >= DRV_ISI_MAX_FRAMEBUFFER_DESCRIPTOR)
        return false;
    
    _descriptors[_bufferCount].address = buf;
    _descriptors[_bufferCount].ctrl = 0x3;
    
    if(_bufferCount == 0)
    {
        _descriptors[_bufferCount].next = &_descriptors[_bufferCount];
    }
    else
    {
        _descriptors[_bufferCount - 1].next = &_descriptors[_bufferCount];
        _descriptors[_bufferCount].next = &_descriptors[0];
    }
    
    _bufferCount += 1;
    
    return true;
}

bool DRV_ISI_ClearPreviewFrameBufferList(void)
{
    uint32_t itr;
    
    for(itr = 0; itr < _bufferCount; ++itr)
    {
        _descriptors[itr].address = NULL;
        _descriptors[itr].ctrl = 0x3;
        _descriptors[itr].next = NULL;
    }
    
    _currentBuffer = -1;
    _bufferCount = 0;
    
    return true;
}

uint8_t* DRV_ISI_GetLatestPreviewFrame(void)
{
    if(_bufferCount == 0)
        return NULL;
    
    return _descriptors[_currentBuffer].address;
}

bool DRV_ISI_SetPreviewFrameReadyCallback(DRV_ISI_PreviewFrameReady_Callback cb)
{
    _frameReadyCallback = cb;
    
    return true;
}

void _DRV_ISI_PreviewTransferComplete(void)
{    
    _transferComplete = true;
    
    DRV_ISI_PreviewPathDisable();
    
    _currentBuffer += 1;
    
    if(_currentBuffer >= _bufferCount)
    {
        _currentBuffer = 0;
    }
}

void _DRV_ISI_PreviewTasks()
{
    if(_transferComplete == true)
    {
        if(_frameReadyCallback != NULL)
        {
            _frameReadyCallback(_descriptors[_currentBuffer].address);
        }
        
        _transferComplete = false;
    }
}
