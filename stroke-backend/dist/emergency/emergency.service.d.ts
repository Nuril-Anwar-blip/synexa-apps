import { PrismaService } from '../prisma/prisma.service';
export declare class EmergencyService {
    private prisma;
    constructor(prisma: PrismaService);
    create(data: {
        user_id: string;
        location_lat?: number;
        location_long?: number;
    }): Promise<{
        id: string;
        user_id: string | null;
        location_lat: number | null;
        location_long: number | null;
        status: string | null;
        triggered_at: Date;
    }>;
    updateStatus(id: string, status: string): Promise<{
        id: string;
        user_id: string | null;
        location_lat: number | null;
        location_long: number | null;
        status: string | null;
        triggered_at: Date;
    }>;
    findAll(): Promise<({
        user: {
            full_name: string;
            phone_number: string;
        } | null;
    } & {
        id: string;
        user_id: string | null;
        location_lat: number | null;
        location_long: number | null;
        status: string | null;
        triggered_at: Date;
    })[]>;
    findByUser(userId: string): Promise<{
        id: string;
        user_id: string | null;
        location_lat: number | null;
        location_long: number | null;
        status: string | null;
        triggered_at: Date;
    }[]>;
}
