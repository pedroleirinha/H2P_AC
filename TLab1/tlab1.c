#include <stdint.h>

#define VAL_MIN 0x0005

uint8_t array_k1[] = {205, 154, 102, 51, 0};
uint8_t array_s1[] = {8, 8, 8, 8, 0};
uint16_t array_vals1[6];

uint8_t array_k2[] = {35, 38, 42, 45, 0};
uint8_t array_s2[] = {5, 5, 5, 5, 0};
uint16_t array_vals2[6];

uint8_t array_k3[] = {205, 154, 0, 45, 35, 0};
uint8_t array_s3[] = {8, 8, 0, 5, 5, 0};
uint16_t array_vals3[7];

uint16_t clamp_value(uint16_t val, uint16_t min, uint16_t max) // 500
{
    if (val < min)
    {
        val = min;
    }
    else if (val > max)
    {
        val = max;
    }
    return val;
}

uint32_t umull(uint16_t v, uint8_t k)
{
    return (uint32_t)v * k;
}

uint16_t scale_value(uint16_t v, uint8_t k, uint8_t s)
{
    uint32_t prod;
    uint16_t k_ext, prod_s, prod_c;

    k_ext = k & 0xFF;
    prod = umull(v, k_ext);
    if (s != 0)
    {
        s &= 0xFF;
        prod += 0x00000001 << (s - 1);
        prod >>= s;
    }
    prod_s = prod & 0xFFFF;
    prod_c = clamp_value(prod_s, VAL_MIN, prod_s); // PC = 10

    return prod_c;
}

uint16_t build_sequence(uint16_t v_init, uint16_t v[], uint8_t k[], uint8_t s[])
{
    uint16_t i = 0;

    v[0] = v_init;
    while (s[i] != 0)
    {
        v[i + 1] = scale_value(v[i], k[i], s[i]);
        i++;
    }
    return (i + 1);
}

void main(void)
{

    uint16_t n1, n2, n3;

    n1 = build_sequence(100, array_vals1, array_k1, array_s1);
    n2 = build_sequence(10, array_vals2, array_k2, array_s2);
    n3 = build_sequence(50, array_vals3, array_k3, array_s3);
}