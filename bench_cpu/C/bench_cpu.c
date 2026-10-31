// C Reference code for pure CPU benchmark:
// Collatz algorithm from 1 to 702 included (703 will overflow uint16).
// Compute a CRC8 of the uint16 result N during the entire Collatz algorithm except for the final 1.
// CRC8 doesn't use a lookup table to avoid RAM access since we are in a pure CPU benchmark.

#define	ITERATIONS	702	// 16bits test CRC8 should be 0xB1
//#define	ITERATIONS	65536		// 32bits test CRC8 should be 0xXX

#include <stdio.h>
#include <stdint.h>

uint8_t	crc8 = 0xFF;

void	add_crc8(uint8_t data)
{
	uint8_t i;

	crc8 ^= data;

	for (i = 0; i < 8; i++)
	{
		if (crc8 & 0x80)
			crc8 = (crc8 << 1) ^ 0x9B;	// CDMA2000
		else
			crc8 <<= 1;
	}
}

int	main(void)
{
	uint16_t	n, m;

	for (m = 1; m <= ITERATIONS; m++)
	{
		n = m;
		while (n != 1)
		{
			add_crc8(n & 0xFF);
			add_crc8(n >> 8);

			if ((n & 1) == 0)		// n%2
				n = n >> 1;			// n/2
			else
				n = n + n + n + 1;	// 3*n+1
		}
	}
	printf("CRC8:%02X\n", crc8);

    return (0);
}
