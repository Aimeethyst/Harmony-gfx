<#if HarmonyCore.SELECT_RTOS == "FreeRTOS">
    <#lt>void _LCC_Tasks(  void *pvParameters  )
    <#lt>{
    <#lt>    while(1)
    <#lt>    {
    <#lt>        DRV_LCC_Update();
             <#if rtosEnableTaskDelay >
    <#lt>        vTaskDelay(${rtosTaskDelay} / portTICK_PERIOD_MS);
             </#if>
    <#lt>    }
    <#lt>}
</#if>
<#if HarmonyCore.SELECT_RTOS == "ThreadX">
    <#lt>TX_THREAD      _LCC_Task_TCB;
    <#lt>uint8_t*       _LCC_Task_Stk_Ptr;

    <#lt>static void _LCC_Tasks( ULONG thread_input )
    <#lt>{
    <#lt>    while(1)
    <#lt>    {
    <#lt>        DRV_LCC_Update();
             <#if rtosEnableTaskDelay >
        <#lt>    tx_thread_sleep((ULONG)(${rtosTaskDelay} / (TX_TICK_PERIOD_MS)));
	         </#if>
    <#lt>    }
    <#lt>}
</#if>
