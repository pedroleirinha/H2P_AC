#include <stdint.h>

#define SIZE 5
uint8_t phrase1[] = "hello , world ";
uint16_t occurrences1[SIZE];

void vowel_histogram(char phrase[], uint16_t max_letters, uint16_t occurrences[5])
{
    int16_t idx;
    uint16_t i;
    for (i = 0; phrase[i] != '\0' && i < max_letters; i++)
    {
        if ((idx = which_vowel(phrase[i])) != -1)
        {
            occurrences[idx]++;
        }
    }
}

int16_t which_vowel(char letter)
{
    int16_t i;
    switch (letter)
    {
        case 'a': i = 0; break;
        case 'e': i = 1; break;
        case 'i': i = 2; break;
        case 'o': i = 3; break;
        case 'u': i = 4; break;
        default:  i = -1;
    }
    return i;
}

void main(void)
{
    vowel_histogram(phrase1, 7, occurrences1);
}