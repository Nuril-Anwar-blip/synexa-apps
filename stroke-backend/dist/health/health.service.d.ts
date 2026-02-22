import { PrismaService } from '../prisma/prisma.service';
export declare class HealthService {
    private prisma;
    constructor(prisma: PrismaService);
    create(data: {
        user_id: string;
        log_type: string;
        value_numeric?: number;
        value_text?: string;
        note?: string;
    }): Promise<{
        id: string;
        user_id: string | null;
        note: string | null;
        log_type: string;
        value_systolic: number | null;
        value_diastolic: number | null;
        value_numeric: number | null;
        recorded_at: Date;
    }>;
    findByUser(userId: string, type?: string): Promise<{
        id: string;
        user_id: string | null;
        note: string | null;
        log_type: string;
        value_systolic: number | null;
        value_diastolic: number | null;
        value_numeric: number | null;
        recorded_at: Date;
    }[]>;
}
