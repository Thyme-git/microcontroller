# include "seg_display.h"


void seg_display_func()
{
    --seg_idx;

    // disable negtive pole before write postive pole,
    // ortherwise there will be blurry light leaving in segment
    NEG_POLE = 0xff;

    // write postive pole
    POS_POLE = seg_buffer[seg_idx%SEG_CNT];

    // write negtive pole
    if (seg_idx <= 127){
        NEG_POLE = _table_seg_select[seg_idx%SEG_CNT];
    }
    // flash, if seg_flash[i] == 1, then NEG_POLE[i] will be set as 1
    else if (seg_idx > 127)
    {
        NEG_POLE = _table_seg_select[seg_idx%SEG_CNT] | seg_flash;
    }
}

void seg_startup_anime(int times)
{
    times = times*STARTUP_STATE_NUM;
    for (int i = 0; i < times; ++i)
    {
        *(long*)seg_buffer = startup_anime_code[i%STARTUP_STATE_NUM];
        _delay(STARTUP_ANIME_DELAY);
    }
}
