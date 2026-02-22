import { PrismaService } from '../prisma/prisma.service';
export declare class NotificationsService {
    private prisma;
    constructor(prisma: PrismaService);
    findByUser(userId: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        type: string | null;
        title: string;
        body: string;
        is_read: boolean | null;
    }[]>;
    markAsRead(id: string): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        type: string | null;
        title: string;
        body: string;
        is_read: boolean | null;
    }>;
    create(data: {
        user_id: string;
        title: string;
        body: string;
        type?: string;
    }): Promise<{
        id: string;
        created_at: Date;
        user_id: string | null;
        type: string | null;
        title: string;
        body: string;
        is_read: boolean | null;
    }>;
}
