#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef uint8_t bool;
#define true 1
#define false 0

typedef struct 
{
    uint8_t BootJumpInstruction[3];
    uint8_t OemIdentifier[8];
    uint16_t BytesPerSector;
    uint8_t SectorsPerCluster;
    uint16_t ReservedSectors;
    uint8_t FatCount;
    uint16_t DirEntryCount;
    uint16_t TotalSectors;
    uint8_t MediaDescriptor;
    uint16_t SectorsPerFat;
    uint16_t SectorsPerTrack;
    uint16_t Heads;
    uint32_t HiddenSectors;
    uint32_t LargeSectorCount;

    uint8_t DriveNumber;
    uint8_t _Reserved;
    uint8_t Signature;
    uint32_t VolumeId;
    uint8_t VolumeLabel[11];
    uint8_t SystemId[8];

    // ... Rest is rest ...

} __attribute__((packed)) BootSector;

typedef struct
{
    uint8_t Name[11];
    uint8_t Attributes;
    uint8_t _Reserved;
    uint8_t CreatedTimeTenths;
    uint16_t CreatedTime;
    uint16_t CreatedDate;
    uint16_t AccessedDate;
    uint16_t FirstClusterHigh;
    uint16_t ModifiedTime;
    uint16_t ModifiedDate;
    uint16_t FirstClusterLow;
    uint32_t FileSize;
} __attribute ((packed)) DirectoryEntry;

BootSector g_BootSector;
uint8_t *g_Fat = NULL;
DirectoryEntry *g_RootDirectory = NULL;
uint32_t g_DataAreaSector = 0;

bool readBootSector(FILE *disk)
{
    if (fseek(disk, 0, SEEK_SET) != 0) {
        return false;
    }

    return fread(&g_BootSector, sizeof(BootSector), 1, disk) > 0;
}

bool readSectors(FILE *disk, uint32_t sector, uint32_t count, void *buffer)
{
    bool ok = true;
    ok = ok && (fseek(disk, sector * g_BootSector.BytesPerSector, SEEK_SET) == 0);
    ok = ok && (fread(buffer, g_BootSector.BytesPerSector, count, disk) == count);
    return ok;
}

bool readFat(FILE *disk)
{
    g_Fat = (uint8_t *) malloc(g_BootSector.SectorsPerFat * g_BootSector.BytesPerSector);

    if (g_Fat == NULL) {
        return false;
    }

    return readSectors(disk, g_BootSector.ReservedSectors, g_BootSector.SectorsPerFat, g_Fat);
}

bool readRootDirectory(FILE *disk)
{
    uint32_t lba = g_BootSector.ReservedSectors + g_BootSector.SectorsPerFat * g_BootSector.FatCount;
    uint32_t size = g_BootSector.DirEntryCount * sizeof(DirectoryEntry);
    uint32_t sectors = size / g_BootSector.BytesPerSector;
    
    if (size % g_BootSector.BytesPerSector) {
        sectors++;
    }

    g_DataAreaSector = lba + sectors;

    g_RootDirectory = (DirectoryEntry *) malloc(sectors * g_BootSector.BytesPerSector);
    return readSectors(disk, lba, sectors, g_RootDirectory);
}

DirectoryEntry *findFile(const char *name)
{
    for (int i = 0; i < g_BootSector.DirEntryCount; i++)
    {
        if (memcmp(g_RootDirectory[i].Name, name, 11) == 0)
        {
            return &g_RootDirectory[i];
        }
    }
    return NULL;
}

bool readFile(DirectoryEntry *fileEntry, FILE *disk, uint8_t *outputBuffer)
{
    if (g_DataAreaSector == 0) {
        return false;
    }

    uint16_t currentCluster = fileEntry->FirstClusterLow;

    do
    {
        // Read the current cluster to the outputBuffer
        uint32_t lba = g_DataAreaSector + (currentCluster - 2) * g_BootSector.SectorsPerCluster;

        if (readSectors(disk, lba, g_BootSector.SectorsPerCluster, outputBuffer) == false)
        {
            return false;
        }

        outputBuffer += g_BootSector.SectorsPerCluster * g_BootSector.BytesPerSector;

        // Read the next cluster from the FAT considering it is a FAT12 file system
        uint32_t fatIndex = currentCluster * 3 / 2;
        uint16_t fatValue = *(uint16_t *)&g_Fat[fatIndex];
        
        currentCluster = currentCluster % 2 == 0 ? fatValue & 0x0FFF : fatValue >> 4;

    } while (currentCluster < 0xFF8);
    
    return true;
}

int main(int argc, char **argv) {

    if (argc < 3) {
        fprintf(stderr, "Usage: %s <disk image> <file name>\n", argv[0]);
        return -1;
    }

    FILE *disk = fopen(argv[1], "rb");
    if (!disk) {
        fprintf(stderr, "Failed to open disk image: %s\n", argv[1]);
        return -1;
    }

    if (!readBootSector(disk)) {
        fprintf(stderr, "Failed to read boot sector\n");
        return -1;
    }

    if (!readFat(disk)) {
        fprintf(stderr, "Failed to read FAT\n");
        return -1;
    }

    if (!readRootDirectory(disk)) {
        fprintf(stderr, "Failed to read root directory\n");
        return -1;
    }

    DirectoryEntry *fileEntry = findFile(argv[2]);
    if (!fileEntry)
    {
        fprintf(stderr, "File not found: %s\n", argv[2]);
        return -1;
    } 

    uint8_t *fileBuffer = (uint8_t *) malloc(fileEntry->FileSize + g_BootSector.BytesPerSector);
    memset(fileBuffer, 0, fileEntry->FileSize + g_BootSector.BytesPerSector);
    if (!readFile(fileEntry, disk, fileBuffer))
    {
        fprintf(stderr, "Failed to read file\n");
        return -1;
    }

    for (int i = 0; i < fileEntry->FileSize; i++)
    {
        if (isprint(fileBuffer[i])) {
            fputc(fileBuffer[i], stdout);
        } else {
            printf("<%02x>", fileBuffer[i]);
        }
    }
    
    return 0;
}
