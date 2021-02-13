#include "type.h"
#include "const.h"
#include "protect.h"
#include "proto.h"

/**
 * 将32位整数转换为16进制字符串
 * @param str   传出参数，转换后的字符串
 * @param num   要转换的数字
 * @return      转换后字符串的首地址
 */
PUBLIC char *itoa(char *str, int num) {

    char *p = str;
    char ch;
    int i;
    int flag = 0;

    *p++ = '0';
    *p++ = 'x';

    if (num == 0) {
        *p++ = '0';
    } else {
        for (i = 28; i >= 0; i -= 4) {
            ch = (num >> i) & 0xF;
            if (flag || ch > 0) {
                flag = 1;
                ch += '0';
                if (ch > '9')
                    ch = ch - '9' - 1 + 'A';
                *p++ = ch;
            }
        }
    }
    *p = '\0';

    return str;
}

/**
 * 在屏幕打印一个整数(以16进制形式)
 * @param input 要打印的整数
 */
PUBLIC void disp_int(int input) {
    char output[16];
    itoa(output, input);
    disp_str(output);
}

/**
 * 做一定延迟
 */
PUBLIC void delay(int time) {
    int i, j, k;
    for (k = 0; k < time; k++)
        for (i = 0; i < 10; i++)
            for (j = 0; j < 100000; j++)
                ;
}
