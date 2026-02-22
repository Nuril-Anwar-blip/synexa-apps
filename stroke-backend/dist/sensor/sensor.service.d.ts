import { PrismaService } from '../prisma/prisma.service';
import { SensorData, Prisma } from '@prisma/client';
export declare class SensorService {
    private prisma;
    constructor(prisma: PrismaService);
    recordData(data: Prisma.SensorDataCreateInput): Promise<SensorData>;
    getHistory(userId: string, type?: string): Promise<SensorData[]>;
}
