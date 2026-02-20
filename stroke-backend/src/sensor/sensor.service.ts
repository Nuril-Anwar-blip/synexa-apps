import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { SensorData, Prisma } from '@prisma/client';

@Injectable()
export class SensorService {
    constructor(private prisma: PrismaService) { }

    /**
     * Menyimpan data sensor baru (Heart Rate, GPS, dll)
     * @param data Data sensor
     */
    async recordData(data: Prisma.SensorDataCreateInput): Promise<SensorData> {
        return this.prisma.sensorData.create({
            data,
        });
    }

    /**
     * Mengambil riwayat data sensor user
     * @param userId ID user
     * @param type Tipe data (optional)
     */
    async getHistory(userId: string, type?: string): Promise<SensorData[]> {
        return this.prisma.sensorData.findMany({
            where: {
                user_id: userId,
                ...(type ? { type } : {}),
            },
            orderBy: { timestamp: 'desc' },
            take: 50, // Ambil 50 data terakhir
        });
    }
}
