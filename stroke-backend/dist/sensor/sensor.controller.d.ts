import { SensorService } from './sensor.service';
import { Prisma } from '@prisma/client';
export declare class SensorController {
    private readonly sensorService;
    constructor(sensorService: SensorService);
    recordData(data: Prisma.SensorDataCreateInput): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        type: string;
        value: Prisma.JsonValue | null;
        heart_rate: number | null;
        latitude: number | null;
        longitude: number | null;
        timestamp: Date;
    }>;
    getHistory(userId: string, type?: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        type: string;
        value: Prisma.JsonValue | null;
        heart_rate: number | null;
        latitude: number | null;
        longitude: number | null;
        timestamp: Date;
    }[]>;
}
