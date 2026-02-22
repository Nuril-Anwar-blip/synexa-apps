import { PrismaService } from '../prisma/prisma.service';
export declare class EducationService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(category?: string): Promise<{
        id: string;
        created_at: Date;
        content: string | null;
        media_url: string | null;
        title: string;
        category: string | null;
    }[]>;
    findOne(id: string): Promise<{
        id: string;
        created_at: Date;
        content: string | null;
        media_url: string | null;
        title: string;
        category: string | null;
    } | null>;
}
