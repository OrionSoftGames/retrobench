// C Reference code for pure RAM benchmark:
// Generate a table of 15000 8bits random numbers from a predictive algorithm.
// Use an insert sort algorithm on this table of random numbers (which is pretty RAM intensive)
// Do a CRC8 computation to verify the data output from the sorted table, the CRC8 is performed using a 256 bytes CRC8 Lookup table to test RAM access again.

#include <stdio.h>
#include <stdint.h>

// Number of iteration for the 16bits test
#define	ITERATIONS	15000	// CRC8 should be 0x6A

// Number of iteration for the 32bits test
//#define	ITERATIONS			// CRC8 should be 0xXX

#define	TABLE_SIZE

uint8_t	CRC8_Table[256];

void	Generate_CRC8_Table(void)
{
	for (uint16_t byte = 0; byte < 256; byte++)
	{
		uint8_t crc = byte;

		for (uint8_t bit = 0; bit < 8; bit++)
		{
			if (crc & 0x80)
				crc = (crc << 1) ^ 0x9B;	// CDMA2000
			else
				crc <<= 1;
		}
		CRC8_Table[byte] = crc;
	}
}

uint8_t	RandomTable[ITERATIONS];

int	main(void)
{
	int16_t		i;
	uint16_t	randseed = 0x1337;
	uint8_t		crc8 = 0xFF;

	Generate_CRC8_Table();

	// Generate Random Numbers
	for (i = 0; i < ITERATIONS; i += 2)
	{
		uint16_t	value;

		value = randseed;
		randseed += randseed;
		if (value & 0x8000)
			randseed ^= 0xAF;

		RandomTable[i] = randseed >> 8;
		RandomTable[i+1] = randseed & 0xFF;
	}

	// Insert sort
	for (i = 1; i < ITERATIONS; i++)
	{
		uint8_t	key = RandomTable[i];
		int16_t	j = i - 1;

		while ((j >= 0) && (RandomTable[j] > key))
		{
			RandomTable[j+1] = RandomTable[j];
			j--;
		}
		RandomTable[j+1] = key;
	}

	// CRC8 Verification
	for (i = 0; i < ITERATIONS; i++)
		crc8 = CRC8_Table[crc8 ^ RandomTable[i]];
	printf("CRC8:%02X\n", crc8);

    return (0);
}
